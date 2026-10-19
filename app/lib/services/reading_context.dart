import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Where a shishya is reading from: the phone's name and an approximate
/// (town-level) location, shown to gadhipatis and the admin with each visit.
typedef ReadingPlace = ({String? device, String? place, double? lat, double? lng});

abstract class ReadingContext {
  Future<ReadingPlace> current();
}

/// Nothing recorded (tests, desktop).
class NoReadingContext implements ReadingContext {
  @override
  Future<ReadingPlace> current() async => (device: null, place: null, lat: null, lng: null);
}

class DeviceReadingContext implements ReadingContext {
  String? _device;
  ReadingPlace? _last;
  DateTime? _lastAt;

  @override
  Future<ReadingPlace> current() async {
    _device ??= await _deviceName().catchError((Object _) => null);
    // One location lookup covers a reading session.
    if (_last != null && DateTime.now().difference(_lastAt!) < const Duration(minutes: 15)) return _last!;
    final p = await _position().catchError((Object _) => null);
    String? place;
    if (p != null && !kIsWeb) place = await _placeName(p).catchError((Object _) => null);
    _last = (
      device: _device,
      place: place,
      lat: p == null ? null : double.parse(p.latitude.toStringAsFixed(3)),
      lng: p == null ? null : double.parse(p.longitude.toStringAsFixed(3)),
    );
    _lastAt = DateTime.now();
    return _last!;
  }

  static Future<String?> _deviceName() async {
    final info = DeviceInfoPlugin();
    if (kIsWeb) {
      final w = await info.webBrowserInfo;
      return 'Browser – ${w.browserName.name}${w.platform == null ? '' : ' (${w.platform})'}';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final a = await info.androidInfo;
        final brand = a.manufacturer.isEmpty ? '' : '${a.manufacturer[0].toUpperCase()}${a.manufacturer.substring(1)} ';
        return '$brand${a.model} (Android ${a.version.release})';
      case TargetPlatform.iOS:
        final i = await info.iosInfo;
        return '${i.name} (${i.model}, iOS ${i.systemVersion})';
      default:
        return null;
    }
  }

  /// Town-level position; asks for location permission once. Null when
  /// location is off or the shishya says no.
  static Future<Position?> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
    final last = kIsWeb ? null : await Geolocator.getLastKnownPosition();
    if (last != null && DateTime.now().difference(last.timestamp) < const Duration(hours: 1)) return last;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 15)),
    );
  }

  /// "Village/town, district, state".
  static Future<String?> _placeName(Position p) async {
    final marks = await Geocoding().placemarkFromCoordinates(p.latitude, p.longitude);
    if (marks.isEmpty) return null;
    final m = marks.first;
    final parts = <String>[];
    for (final s in [m.locality, m.subLocality, m.subAdministrativeArea, m.administrativeArea]) {
      if (s != null && s.trim().isNotEmpty && !parts.contains(s.trim())) parts.add(s.trim());
    }
    return parts.isEmpty ? null : parts.take(3).join(', ');
  }
}
