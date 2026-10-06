import '../utils/convert.dart';
import '../rbac.dart';

/// `admin_users/{uid}`. The authoritative role lives in the Firebase Auth
/// custom claim `role` (set by the `setAdminRole` function); this document
/// mirrors it for listing in the admin panel.
class AdminUser {
  const AdminUser({
    required this.uid,
    required this.email,
    required this.role,
    this.name = '',
    this.active = true,
    this.createdAt,
  });

  final String uid;
  final String email;
  final String name;
  final AdminRole role;
  final bool active;
  final DateTime? createdAt;

  factory AdminUser.fromMap(String uid, Map<String, dynamic> m) => AdminUser(
        uid: uid,
        email: asString(m['email']),
        name: asString(m['name']),
        role: AdminRole.fromKey(m['role']) ?? AdminRole.volunteer,
        active: asBool(m['active'], true),
        createdAt: asDate(m['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'role': role.key,
        'active': active,
        'createdAt': createdAt,
      };
}

/// `audit_logs` – append-only record of admin actions.
class AuditLog {
  const AuditLog({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.collection,
    this.recordId,
    this.summary,
    this.at,
  });

  final String id;
  final String actorId;
  final String actorName;

  /// create / update / delete / publish / check_in / role_change …
  final String action;
  final String collection;
  final String? recordId;
  final String? summary;
  final DateTime? at;

  factory AuditLog.fromMap(String id, Map<String, dynamic> m) => AuditLog(
        id: id,
        actorId: asString(m['actorId']),
        actorName: asString(m['actorName']),
        action: asString(m['action']),
        collection: asString(m['collection']),
        recordId: asStringOrNull(m['recordId']),
        summary: asStringOrNull(m['summary']),
        at: asDate(m['at']),
      );

  Map<String, dynamic> toMap() => {
        'actorId': actorId,
        'actorName': actorName,
        'action': action,
        'collection': collection,
        'recordId': recordId,
        'summary': summary,
        'at': at,
      };
}
