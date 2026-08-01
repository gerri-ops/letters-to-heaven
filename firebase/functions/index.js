const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret, defineString } = require("firebase-functions/params");
const admin = require("firebase-admin");
const Stripe = require("stripe");

admin.initializeApp();

const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");
const stripePriceMonthly = defineSecret("STRIPE_PRICE_MONTHLY");
const stripePriceAnnual = defineSecret("STRIPE_PRICE_ANNUAL");
const appBaseUrl = defineString("APP_BASE_URL", {
  default: "https://letters-to-heaven-64491.web.app",
});

const REGION = "us-central1";

function stripeClient() {
  return new Stripe(stripeSecretKey.value());
}

function priceIdForPlan(plan) {
  if (plan === "monthly") {
    return stripePriceMonthly.value();
  }
  if (plan === "annual") {
    return stripePriceAnnual.value();
  }
  throw new HttpsError("invalid-argument", "plan must be monthly or annual");
}

function planFromPriceId(priceId) {
  if (!priceId) {
    return null;
  }
  if (priceId === stripePriceMonthly.value()) {
    return "monthly";
  }
  if (priceId === stripePriceAnnual.value()) {
    return "annual";
  }
  return null;
}

function isEntitledStatus(status) {
  return status === "active" || status === "trialing";
}

async function ensureStripeCustomer({ uid, email, stripe }) {
  const userRef = admin.firestore().collection("users").doc(uid);
  const snap = await userRef.get();
  const existing = snap.exists ? snap.data()?.stripeCustomerId : null;
  if (existing) {
    return existing;
  }

  const customer = await stripe.customers.create({
    email: email || undefined,
    metadata: { firebaseUid: uid },
  });
  await userRef.set(
    {
      uid,
      stripeCustomerId: customer.id,
      updatedAt: new Date().toISOString(),
    },
    { merge: true },
  );
  return customer.id;
}

async function writePremiumEntitlement(uid, data) {
  const ref = admin
    .firestore()
    .collection("users")
    .doc(uid)
    .collection("entitlements")
    .doc("premium");
  await ref.set(
    {
      ...data,
      updatedAt: new Date().toISOString(),
    },
    { merge: true },
  );
}

async function findUidForCustomer(customerId) {
  if (!customerId) {
    return null;
  }
  const users = await admin
    .firestore()
    .collection("users")
    .where("stripeCustomerId", "==", customerId)
    .limit(1)
    .get();
  if (!users.empty) {
    return users.docs[0].id;
  }
  try {
    const stripe = stripeClient();
    const customer = await stripe.customers.retrieve(customerId);
    if (customer && !customer.deleted && customer.metadata?.firebaseUid) {
      return customer.metadata.firebaseUid;
    }
  } catch (_) {
    // ignore
  }
  return null;
}

async function upsertFromSubscription(subscription) {
  const customerId =
    typeof subscription.customer === "string"
      ? subscription.customer
      : subscription.customer?.id;
  const uid =
    subscription.metadata?.firebaseUid ||
    (await findUidForCustomer(customerId));
  if (!uid) {
    console.warn("No firebase uid for subscription", subscription.id);
    return;
  }
  const item = subscription.items?.data?.[0];
  const priceId = item?.price?.id || null;
  const status = subscription.status;
  await writePremiumEntitlement(uid, {
    status,
    entitled: isEntitledStatus(status),
    plan: planFromPriceId(priceId) || subscription.metadata?.plan || null,
    stripeCustomerId: customerId || null,
    stripeSubscriptionId: subscription.id,
    priceId,
    currentPeriodEnd: subscription.current_period_end
      ? new Date(subscription.current_period_end * 1000).toISOString()
      : null,
    cancelAtPeriodEnd: Boolean(subscription.cancel_at_period_end),
    source: "stripe",
  });
}

/**
 * Creates a Stripe Checkout Session for monthly or annual Premium.
 */
exports.createCheckoutSession = onCall(
  {
    region: REGION,
    secrets: [
      stripeSecretKey,
      stripePriceMonthly,
      stripePriceAnnual,
    ],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to subscribe.");
    }
    const uid = request.auth.uid;
    const email = request.auth.token.email || null;
    const plan = request.data?.plan;
    if (plan !== "monthly" && plan !== "annual") {
      throw new HttpsError("invalid-argument", "plan must be monthly or annual");
    }

    const stripe = stripeClient();
    const priceId = priceIdForPlan(plan);
    const customerId = await ensureStripeCustomer({ uid, email, stripe });
    const base = appBaseUrl.value().replace(/\/$/, "");

    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      customer: customerId,
      client_reference_id: uid,
      line_items: [{ price: priceId, quantity: 1 }],
      subscription_data: {
        trial_period_days: 14,
        metadata: { firebaseUid: uid, plan },
      },
      metadata: { firebaseUid: uid, plan },
      success_url: `${base}/shell/subscribe?checkout=success`,
      cancel_url: `${base}/shell/subscribe?checkout=cancel`,
      allow_promotion_codes: true,
    });

    if (!session.url) {
      throw new HttpsError("internal", "Stripe did not return a Checkout URL.");
    }
    return { url: session.url, sessionId: session.id };
  },
);

/**
 * Opens the Stripe Customer Portal for managing billing.
 */
exports.createCustomerPortalSession = onCall(
  {
    region: REGION,
    secrets: [stripeSecretKey],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to manage billing.");
    }
    const uid = request.auth.uid;
    const email = request.auth.token.email || null;
    const stripe = stripeClient();
    const customerId = await ensureStripeCustomer({ uid, email, stripe });
    const base = appBaseUrl.value().replace(/\/$/, "");

    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: `${base}/shell/subscribe`,
    });
    return { url: session.url };
  },
);

/**
 * Stripe webhook — grants/revokes Premium entitlements.
 */
exports.stripeWebhook = onRequest(
  {
    region: REGION,
    secrets: [
      stripeSecretKey,
      stripeWebhookSecret,
      stripePriceMonthly,
      stripePriceAnnual,
    ],
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const stripe = stripeClient();
    const signature = req.headers["stripe-signature"];
    let event;
    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        signature,
        stripeWebhookSecret.value(),
      );
    } catch (err) {
      console.error("Webhook signature verification failed", err.message);
      res.status(400).send(`Webhook Error: ${err.message}`);
      return;
    }

    try {
      switch (event.type) {
        case "checkout.session.completed": {
          const session = event.data.object;
          const uid =
            session.client_reference_id ||
            session.metadata?.firebaseUid ||
            null;
          const customerId =
            typeof session.customer === "string"
              ? session.customer
              : session.customer?.id;
          if (uid && customerId) {
            await admin
              .firestore()
              .collection("users")
              .doc(uid)
              .set(
                {
                  stripeCustomerId: customerId,
                  updatedAt: new Date().toISOString(),
                },
                { merge: true },
              );
          }
          if (session.subscription) {
            const subId =
              typeof session.subscription === "string"
                ? session.subscription
                : session.subscription.id;
            const subscription = await stripe.subscriptions.retrieve(subId);
            if (uid && !subscription.metadata?.firebaseUid) {
              await stripe.subscriptions.update(subId, {
                metadata: {
                  firebaseUid: uid,
                  plan: session.metadata?.plan || "",
                },
              });
              subscription.metadata = {
                ...subscription.metadata,
                firebaseUid: uid,
                plan: session.metadata?.plan || "",
              };
            }
            await upsertFromSubscription(subscription);
          }
          break;
        }
        case "customer.subscription.created":
        case "customer.subscription.updated":
        case "customer.subscription.deleted": {
          await upsertFromSubscription(event.data.object);
          break;
        }
        case "invoice.paid":
        case "invoice.payment_failed": {
          const invoice = event.data.object;
          const subId =
            typeof invoice.subscription === "string"
              ? invoice.subscription
              : invoice.subscription?.id;
          if (subId) {
            const subscription = await stripe.subscriptions.retrieve(subId);
            await upsertFromSubscription(subscription);
          }
          break;
        }
        default:
          break;
      }
      res.json({ received: true });
    } catch (err) {
      console.error("Webhook handler error", err);
      res.status(500).send("Webhook handler failed");
    }
  },
);

/**
 * Builds a PDF export for a user's memorial entries and stores it in Cloud Storage.
 * Triggered when the client creates an exportJobs document or calls this callable.
 * TODO: Load entries from Firestore, render PDF, upload to users/{uid}/exports/.
 */
exports.generatePdfExport = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Unauthenticated");
  }
  const { memorialId, jobId } = request.data ?? {};
  return {
    status: "stub",
    memorialId,
    jobId,
    message: "generatePdfExport not implemented",
  };
});

/**
 * Processes uploaded media (resize, thumbnails, metadata) for entries.
 * TODO: Storage trigger or callable that writes media docs under users/{uid}/media.
 */
exports.processMedia = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Unauthenticated");
  }
  const { mediaId, storagePath } = request.data ?? {};
  return {
    status: "stub",
    mediaId,
    storagePath,
    message: "processMedia not implemented",
  };
});

/**
 * Deletes all user-owned Firestore data and Storage objects on account deletion.
 * TODO: Batch delete subcollections, revoke entitlements, remove Storage prefix.
 */
exports.deleteAccountData = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Unauthenticated");
  }
  const uid = request.auth.uid;
  return {
    status: "stub",
    uid,
    message: "deleteAccountData not implemented",
  };
});

/**
 * Validates App Store / Play Store purchase receipts and updates entitlements.
 * TODO: Verify with store APIs and write users/{uid}/entitlements/{sku}.
 */
exports.validateReceipt = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Unauthenticated");
  }
  const { platform, receiptData, productId } = request.data ?? {};
  return {
    status: "stub",
    platform,
    productId,
    valid: false,
    message: "validateReceipt not implemented",
  };
});

/**
 * Sends local/FCM reminders for upcoming remembrance dates.
 * TODO: Scheduled job querying remembranceDates and notifying via FCM.
 */
exports.sendRemembranceNotification = onSchedule(
  {
    region: REGION,
    schedule: "0 9 * * *",
    timeZone: "America/New_York",
  },
  async () => {
    console.log("sendRemembranceNotification stub: no notifications sent");
    return null;
  },
);
