import { initializeApp } from "firebase-admin/app";
import { setGlobalOptions } from "firebase-functions/v2";

initializeApp();
setGlobalOptions({ region: "asia-south1", maxInstances: 10 });

export { createUpiPayment, submitUpiPayment, reviewUpiPayment } from "./upi.js";
export { setAdminRole, claimSuperAdmin, checkInBooking, cancelBooking } from "./admin.js";
export { reviewShishya, resetShishyaPassword } from "./shishya.js";
export { onNotificationCreated, sendScheduledNotifications, dailyJobs } from "./notifications.js";
