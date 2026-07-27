const { onCall } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Builds a PDF export for a user's memorial entries and stores it in Cloud Storage.
 * Triggered when the client creates an exportJobs document or calls this callable.
 * TODO: Load entries from Firestore, render PDF, upload to users/{uid}/exports/.
 */
exports.generatePdfExport = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("Unauthenticated");
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
exports.processMedia = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("Unauthenticated");
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
exports.deleteAccountData = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("Unauthenticated");
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
exports.validateReceipt = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("Unauthenticated");
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
    schedule: "0 9 * * *",
    timeZone: "America/New_York",
  },
  async () => {
    console.log("sendRemembranceNotification stub: no notifications sent");
    return null;
  },
);
