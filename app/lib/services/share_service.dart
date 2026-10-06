import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders the widget under [key] (wrapped in a RepaintBoundary) to PNG.
/// Rendering through Flutter keeps Devanagari shaping correct, which the
/// PDF engine alone cannot do.
Future<Uint8List> captureWidget(GlobalKey key, {double pixelRatio = 3}) async {
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

/// Opens the system share sheet (WhatsApp, Status, Instagram, Facebook,
/// Telegram, Save to Photos/Files…).
Future<void> sharePng(Uint8List png, {required String fileName, String? text}) =>
    SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(png, mimeType: 'image/png', name: '$fileName.png')],
      fileNameOverrides: ['$fileName.png'],
      text: text,
    ));

/// Wraps a captured receipt image into an A5 PDF and opens the system
/// share/save dialog.
Future<void> sharePngAsPdf(Uint8List png, {required String fileName}) async {
  final doc = pw.Document(title: fileName, author: 'Kalbhairav Jagrut Devsthan');
  final img = pw.MemoryImage(png);
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a5,
    margin: const pw.EdgeInsets.all(16),
    build: (_) => pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
  ));
  await Printing.sharePdf(bytes: await doc.save(), filename: '$fileName.pdf');
}

Future<bool> openUrl(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Opens a page inside the app (Custom Tab / SFSafariViewController).
Future<bool> openInApp(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);

Future<bool> callNumber(String phone) => launchUrl(Uri(scheme: 'tel', path: phone));

Future<bool> openWhatsApp(String phone, {String text = ''}) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  return openUrl('https://wa.me/$digits${text.isEmpty ? '' : '?text=${Uri.encodeComponent(text)}'}');
}
