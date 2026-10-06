import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import 'services/admin_services.dart';

final demoModeProvider = Provider<bool>((_) => true);
final dataStoreProvider = Provider<DataStore>((_) => throw UnimplementedError());
final authServiceProvider = Provider<AuthService>((_) => throw UnimplementedError());
final adminFunctionsProvider = Provider<AdminFunctions>((_) => throw UnimplementedError());
final uploaderProvider = Provider<MediaUploader>((_) => DisabledMediaUploader());
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

final authStateProvider = StreamProvider<AuthUser?>((ref) => ref.watch(authServiceProvider).authStateChanges());
final currentAdminProvider = Provider<AuthUser?>((ref) {
  final u = ref.watch(authStateProvider).value;
  return u != null && u.isAdmin ? u : null;
});

final adminRepoProvider = Provider((ref) => AdminRepository(ref.watch(dataStoreProvider)));
final categoriesProvider = StreamProvider((ref) => EventRepository(ref.watch(dataStoreProvider)).watchCategories());

/// Raw live list of a collection, newest/ordered per [Query].
final collectionProvider = StreamProvider.family<List<Doc>, (String, String?, bool)>((ref, args) {
  final (col, orderBy, desc) = args;
  return ref.watch(dataStoreProvider).watch(col, Query(orderBy: orderBy, descending: desc));
});
