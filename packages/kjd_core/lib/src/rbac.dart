/// Admin modules. Keep in sync with `roleModules` in
/// `functions/src/rbac.ts` and the helper functions in `firestore.rules`.
enum AdminModule {
  dashboard,
  temple,
  darshan,
  events,
  seva,
  bookings,
  checkIn,
  donations,
  payments,
  devotees,
  content,
  banners,
  gallery,
  live,
  notifications,
  reports,
  users,
  settings,
  auditLogs,
}

enum AdminRole {
  superAdmin('super_admin', 'Super Admin'),
  templeAdmin('temple_admin', 'Temple Admin'),
  eventManager('event_manager', 'Event Manager'),
  sevaManager('seva_manager', 'Seva Manager'),
  accountsManager('accounts_manager', 'Accounts Manager'),
  contentManager('content_manager', 'Content Manager'),
  galleryManager('gallery_manager', 'Gallery Manager'),
  volunteer('volunteer', 'Volunteer');

  const AdminRole(this.key, this.label);

  /// Value stored in the `role` custom claim.
  final String key;
  final String label;

  static AdminRole? fromKey(Object? key) {
    for (final r in values) {
      if (r.key == key) return r;
    }
    return null;
  }

  Set<AdminModule> get modules => roleModules[this]!;

  bool can(AdminModule m) => modules.contains(m);
}

const _everything = {...AdminModule.values};

final Map<AdminRole, Set<AdminModule>> roleModules = {
  AdminRole.superAdmin: _everything,
  AdminRole.templeAdmin: _everything.difference({AdminModule.users}),
  AdminRole.eventManager: {
    AdminModule.dashboard,
    AdminModule.events,
    AdminModule.gallery,
    AdminModule.live,
    AdminModule.notifications,
  },
  AdminRole.sevaManager: {
    AdminModule.dashboard,
    AdminModule.seva,
    AdminModule.bookings,
    AdminModule.checkIn,
    AdminModule.devotees,
    AdminModule.reports,
  },
  AdminRole.accountsManager: {
    AdminModule.dashboard,
    AdminModule.donations,
    AdminModule.payments,
    AdminModule.bookings,
    AdminModule.reports,
  },
  AdminRole.contentManager: {
    AdminModule.dashboard,
    AdminModule.temple,
    AdminModule.darshan,
    AdminModule.content,
    AdminModule.banners,
    AdminModule.live,
    AdminModule.notifications,
  },
  AdminRole.galleryManager: {
    AdminModule.dashboard,
    AdminModule.gallery,
  },
  AdminRole.volunteer: {
    AdminModule.dashboard,
    AdminModule.checkIn,
  },
};
