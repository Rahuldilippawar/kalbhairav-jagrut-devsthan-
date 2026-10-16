import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

enum InstallResult { started, needsPermission, failed }

/// Updates the sideloaded Android app from inside the app: downloads the
/// new APK and hands it to Android's installer, so the devotee only taps
/// "Update" on the system screen (Android always asks once).
abstract class ApkInstaller {
  bool get supported;
  Future<InstallResult> downloadAndInstall(String url, {void Function(double progress)? onProgress});
}

class AndroidApkInstaller implements ApkInstaller {
  static const _channel = MethodChannel('kjd/installer');

  @override
  bool get supported => !kIsWeb && Platform.isAndroid;

  @override
  Future<InstallResult> downloadAndInstall(String url, {void Function(double progress)? onProgress}) async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/updates');
    await dir.create(recursive: true);
    final file = File('${dir.path}/update-${url.hashCode.toUnsigned(32)}.apk');
    if (!file.existsSync() || file.lengthSync() == 0) {
      // Only the newest download is kept.
      for (final old in dir.listSync()) {
        old.deleteSync();
      }
      final part = File('${file.path}.part');
      final client = HttpClient();
      try {
        final res = await (await client.getUrl(Uri.parse(url))).close();
        if (res.statusCode != HttpStatus.ok) return InstallResult.failed;
        final total = res.contentLength;
        var got = 0;
        final sink = part.openWrite();
        await for (final chunk in res) {
          sink.add(chunk);
          got += chunk.length;
          if (total > 0) onProgress?.call(got / total);
        }
        await sink.close();
        await part.rename(file.path);
      } finally {
        client.close();
      }
    }
    final r = await _channel.invokeMethod<String>('install', {'path': file.path});
    return switch (r) {
      'started' => InstallResult.started,
      'permission' => InstallResult.needsPermission,
      _ => InstallResult.failed,
    };
  }
}
