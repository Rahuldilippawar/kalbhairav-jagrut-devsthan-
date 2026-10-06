/// Minimal RFC 4180 CSV writer used for admin report exports.
String toCsv(List<String> headers, Iterable<List<Object?>> rows) {
  final buf = StringBuffer()..writeln(headers.map(_cell).join(','));
  for (final row in rows) {
    buf.writeln(row.map(_cell).join(','));
  }
  return buf.toString();
}

String _cell(Object? v) {
  final s = v?.toString() ?? '';
  if (s.contains(RegExp(r'[",\n\r]'))) return '"${s.replaceAll('"', '""')}"';
  return s;
}
