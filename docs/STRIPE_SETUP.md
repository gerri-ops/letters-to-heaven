# Stripe subscriptions setup

Letters to Heaven uses a **Stripe Pricing Table** for plan selection, plus Firebase Cloud Functions (webhooks + Customer Portal) and Firestore entitlements.

## What was built

| Piece | Location |
|-------|----------|
| Pricing Table page | `web/pricing.html` |
| Table IDs (publishable) | `lib/core/billing/stripe_pricing_table_config.dart` |
| Checkout callable + Portal + Webhook | `firebase/functions/index.js` |
| Entitlement rules (client read-only) | `firebase/firestore.rules` |
| Flutter billing client | `lib/core/billing/stripe_billing_service.dart` |
| Paywall CTAs | `lib/features/settings/trust_paywall_screen.dart` |

Subscribe flow: app opens `/pricing.html?uid=…&email=…` → Stripe Pricing Table → Checkout → return to `/shell/subscribe?checkout=success` → app reads `users/{uid}/entitlements/premium`.

The in-app “Start 14-Day Free Trial” button remains a **cardless local trial**.

## Pricing Table confirmation URL (required)

In Stripe Dashboard → Product catalog → Pricing tables → your table → **Confirmation page**:

Set after-payment redirect to:

`https://letters-to-heaven-64491.web.app/shell/subscribe?checkout=success`

## Enable Secret Manager + set secrets

1. Enable: https://console.developers.google.com/apis/api/secretmanager.googleapis.com/overview?project=letters-to-heaven-64491

2. Set secrets:

```bash
cd firebase/functions
npm install
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
firebase functions:secrets:set STRIPE_PRICE_MONTHLY
firebase functions:secrets:set STRIPE_PRICE_ANNUAL
firebase deploy --only functions,firestore:rules
```

Webhook URL:

`https://us-central1-letters-to-heaven-64491.cloudfunctions.net/stripeWebhook`

Events: `checkout.session.completed`, `customer.subscription.created|updated|deleted`, `invoice.paid`, `invoice.payment_failed`.

## Security

- Publishable key + pricing table id are public by design.
- Never put `STRIPE_SECRET_KEY` in Flutter.
- Clients cannot write entitlements.
- `client-reference-id` is the Firebase uid for webhook mapping.
