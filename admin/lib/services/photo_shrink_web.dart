import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Resizes with the browser's own decoder (createImageBitmap applies the
/// EXIF rotation) and encodes on an OffscreenCanvas, so even 100+ phone
/// photos shrink quickly without freezing the page.
Future<({Uint8List bytes, bool isJpeg})> shrinkPhoto(Uint8List bytes, {int maxSide = 2000, double quality = .85}) async {
  try {
    final bitmap = await web.window.createImageBitmap(web.Blob([bytes.toJS].toJS)).toDart;
    final w = bitmap.width, h = bitmap.height;
    final longer = w > h ? w : h;
    if (longer <= maxSide && bytes.length < 1200 * 1024) {
      bitmap.close();
      return (bytes: bytes, isJpeg: false);
    }
    final scale = longer > maxSide ? maxSide / longer : 1.0;
    final tw = (w * scale).round(), th = (h * scale).round();
    final canvas = web.OffscreenCanvas(tw, th);
    final ctx = canvas.getContext('2d')! as web.OffscreenCanvasRenderingContext2D;
    ctx.imageSmoothingQuality = 'high';
    ctx.drawImage(bitmap, 0, 0, tw, th);
    bitmap.close();
    final blob = await canvas.convertToBlob(web.ImageEncodeOptions(type: 'image/jpeg', quality: quality)).toDart;
    final out = (await blob.arrayBuffer().toDart).toDart.asUint8List();
    return out.length < bytes.length ? (bytes: out, isJpeg: true) : (bytes: bytes, isJpeg: false);
  } catch (_) {
    return (bytes: bytes, isJpeg: false);
  }
}
