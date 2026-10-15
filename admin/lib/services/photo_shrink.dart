import 'dart:typed_data';

import 'photo_shrink_stub.dart' if (dart.library.js_interop) 'photo_shrink_web.dart' as impl;

/// A photo made ready for upload: at most [maxSide] px on its longer side,
/// re-encoded as JPEG. [bytes] is the original when shrinking would not
/// help or the browser cannot decode it (e.g. HEIC).
typedef ShrunkPhoto = ({Uint8List bytes, bool isJpeg});

Future<ShrunkPhoto> shrinkPhoto(Uint8List bytes, {int maxSide = 2000, double quality = .85}) =>
    impl.shrinkPhoto(bytes, maxSide: maxSide, quality: quality);
