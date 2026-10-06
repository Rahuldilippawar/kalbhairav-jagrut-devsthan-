import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Triggers a browser download of [content] (UTF-8 with BOM so Excel opens
/// Marathi text correctly).
void downloadText(String fileName, String content, {String mime = 'text/csv'}) {
  final bytes = utf8.encode('﻿$content');
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: '$mime;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  a.click();
  web.URL.revokeObjectURL(url);
}
