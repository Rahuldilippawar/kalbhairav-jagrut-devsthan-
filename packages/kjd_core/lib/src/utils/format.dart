import 'package:intl/intl.dart';

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

/// Amounts are stored in paise (Razorpay convention) to avoid float errors.
String formatPaise(int paise) => _inr.format(paise / 100);

String formatRupees(num rupees) => _inr.format(rupees);

String formatDate(DateTime? d, {String locale = 'mr'}) =>
    d == null ? '' : DateFormat('d MMM yyyy', locale).format(d);

String formatDateTime(DateTime? d, {String locale = 'mr'}) =>
    d == null ? '' : DateFormat('d MMM yyyy, h:mm a', locale).format(d);

String formatWeekday(DateTime d, {String locale = 'mr'}) =>
    DateFormat('EEEE', locale).format(d);

/// Formats a sequence number as e.g. `KJD-SEVA-000001`.
String formatSequence(String prefix, int n) =>
    '$prefix-${n.toString().padLeft(6, '0')}';

/// Normalises an Indian mobile number to E.164 (`+91XXXXXXXXXX`).
/// Returns null when the input is not a valid 10 digit Indian mobile.
String? normaliseIndianMobile(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('91')) digits = digits.substring(2);
  if (digits.length == 11 && digits.startsWith('0')) digits = digits.substring(1);
  if (digits.length != 10 || !RegExp(r'^[6-9]').hasMatch(digits)) return null;
  return '+91$digits';
}

/// Extracts the video id from any common YouTube URL form.
String? youtubeId(String? url) {
  if (url == null || url.isEmpty) return null;
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;
  if (uri.host.contains('youtu.be')) {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  }
  if (uri.host.contains('youtube.com')) {
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    final segs = uri.pathSegments;
    final i = segs.indexWhere((s) => s == 'live' || s == 'embed' || s == 'shorts');
    if (i >= 0 && i + 1 < segs.length) return segs[i + 1];
  }
  return null;
}

String? youtubeThumbnail(String? url) {
  final id = youtubeId(url);
  return id == null ? null : 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}
