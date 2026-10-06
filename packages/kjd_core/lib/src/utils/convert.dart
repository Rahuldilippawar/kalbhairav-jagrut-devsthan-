import 'package:cloud_firestore/cloud_firestore.dart';

/// Converts any date-like value coming from Firestore, JSON or the in-memory
/// demo store into a [DateTime].
DateTime? asDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

String asString(Object? value, [String fallback = '']) =>
    value == null ? fallback : value.toString();

String? asStringOrNull(Object? value) {
  final s = value?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

int asInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double? asDoubleOrNull(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool asBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) return value == 'true';
  return fallback;
}

List<String> asStringList(Object? value) =>
    value is List ? value.map((e) => e.toString()).toList() : const [];

Map<String, dynamic> asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

/// Removes null values so partial updates never overwrite fields with null.
Map<String, dynamic> compact(Map<String, dynamic> map) =>
    Map.fromEntries(map.entries.where((e) => e.value != null));

/// `yyyy-MM-dd` key used for date-addressed documents (tithi, greetings).
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
