import 'dart:typed_data';

/// Outside the browser (tests) photos are uploaded as they are.
Future<({Uint8List bytes, bool isJpeg})> shrinkPhoto(Uint8List bytes, {int maxSide = 2000, double quality = .85}) async =>
    (bytes: bytes, isJpeg: false);
