import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kjd_app/services/push_service.dart';
import 'package:kjd_core/kjd_core.dart';

class FakePush implements PushPlatform {
  final topics = <String>{};
  final opened = StreamController<String?>.broadcast();
  final refresh = StreamController<String>.broadcast();
  String? initial;
  int permissionRequests = 0;

  @override
  Future<void> requestPermission() async => permissionRequests++;
  @override
  Future<void> subscribe(String topic) async => topics.add(topic);
  @override
  Future<void> unsubscribe(String topic) async => topics.remove(topic);
  @override
  Future<String?> token() async => 'tok-1';
  @override
  Stream<String> get tokenRefresh => refresh.stream;
  @override
  Stream<String?> get openedRoutes => opened.stream;
  @override
  Future<String?> initialRoute() async => initial;
}

void main() {
  late FakePush platform;
  late MemoryDataStore store;
  late PushService push;

  setUp(() {
    platform = FakePush();
    store = MemoryDataStore();
    push = PushService(platform, UserRepository(store));
  });

  test('taps open in-app routes only, and start runs once', () async {
    platform.initial = '/pass/abc';
    final opened = <String>[];
    expect(await push.start(opened.add), '/pass/abc');
    expect(await push.start(opened.add), isNull);
    expect(platform.permissionRequests, 1);
    platform.opened
      ..add('/receipt/r1')
      ..add('https://evil.example')
      ..add('//evil.example')
      ..add(null);
    await Future<void>.delayed(Duration.zero);
    expect(opened, ['/receipt/r1']);
  });

  test('stores tokens for the signed-in devotee, including refreshes', () async {
    await push.start((_) {});
    await push.setUser('u1');
    expect(store.dump('users/u1/tokens').keys, ['tok-1']);
    platform.refresh.add('tok-2');
    await Future<void>.delayed(Duration.zero);
    expect(store.dump('users/u1/tokens').keys, containsAll(['tok-1', 'tok-2']));
    await push.setUser(null);
    platform.refresh.add('tok-3');
    await Future<void>.delayed(Duration.zero);
    expect(store.dump('users/u1/tokens').keys, isNot(contains('tok-3')));
  });

  test('detaching on logout removes the token from the account', () async {
    await push.setUser('u1');
    await push.detachUser();
    expect(store.dump('users/u1/tokens'), isEmpty);
  });

  test('broadcast topic follows the notification preference', () async {
    await push.setBroadcastEnabled(true);
    expect(platform.topics, {'all'});
    await push.setBroadcastEnabled(false);
    expect(platform.topics, isEmpty);
  });
}
