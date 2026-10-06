import { initializeApp } from "firebase-admin/app";
import { setGlobalOptions } from "firebase-functions/v2";

initializeApp();
setGlobalOptions({ region: "asia-south1", maxInstances: 10 });

export { createPaymentOrder, verifyPayment, razorpayWebhook } from "./payments.js";
export { setAdminRole, claimSuperAdmin, checkInBooking, cancelBooking } from "./admin.js";
export { onNotificationCreated, sendScheduledNotifications, dailyJobs } from "./notifications.js";
