/**
 * Admin roles and the modules they may manage. Mirrors
 * packages/kjd_core/lib/src/rbac.dart and the helpers in firestore.rules.
 */
export const ROLES = [
  "super_admin",
  "temple_admin",
  "event_manager",
  "seva_manager",
  "accounts_manager",
  "content_manager",
  "gallery_manager",
  "volunteer",
] as const;

export type Role = (typeof ROLES)[number];

export type Module =
  | "dashboard" | "temple" | "darshan" | "events" | "seva" | "bookings" | "checkIn"
  | "donations" | "payments" | "devotees" | "content" | "banners" | "gallery" | "live"
  | "notifications" | "reports" | "users" | "settings" | "auditLogs";

const ALL: Module[] = [
  "dashboard", "temple", "darshan", "events", "seva", "bookings", "checkIn", "donations",
  "payments", "devotees", "content", "banners", "gallery", "live", "notifications",
  "reports", "users", "settings", "auditLogs",
];

export const roleModules: Record<Role, Module[]> = {
  super_admin: ALL,
  temple_admin: ALL.filter((m) => m !== "users"),
  event_manager: ["dashboard", "events", "gallery", "live", "notifications"],
  seva_manager: ["dashboard", "seva", "bookings", "checkIn", "devotees", "reports"],
  accounts_manager: ["dashboard", "donations", "payments", "bookings", "reports"],
  content_manager: ["dashboard", "temple", "darshan", "content", "banners", "live", "notifications"],
  gallery_manager: ["dashboard", "gallery"],
  volunteer: ["dashboard", "checkIn"],
};

export function isRole(v: unknown): v is Role {
  return typeof v === "string" && (ROLES as readonly string[]).includes(v);
}

export function can(role: unknown, module: Module): boolean {
  return isRole(role) && roleModules[role].includes(module);
}
