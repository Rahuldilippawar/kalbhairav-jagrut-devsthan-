import 'package:cross_file/cross_file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Uploads shishya chat photos, videos and voice messages to
/// `shishya_chat/{uid}/…` (see storage.rules) and returns the download URL.
abstract class ChatMediaUploader {
  bool get enabled;
  Future<String> upload(String uid, Uint8List bytes, {required String extension, required String contentType});
}

class FirebaseChatMediaUploader implements ChatMediaUploader {
  @override
  bool get enabled => true;

  @override
  Future<String> upload(String uid, Uint8List bytes, {required String extension, required String contentType}) async {
    final ref = FirebaseStorage.instance.ref('shishya_chat/$uid/${DateTime.now().microsecondsSinceEpoch}.$extension');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }
}

class DisabledChatMediaUploader implements ChatMediaUploader {
  @override
  bool get enabled => false;

  @override
  Future<String> upload(String uid, Uint8List bytes, {required String extension, required String contentType}) =>
      throw UnsupportedError('Media needs Firebase Storage');
}

/// A finished voice recording.
typedef VoiceClip = ({Uint8List bytes, String extension, String contentType, int durationMs});

/// Records a voice message from the microphone.
abstract class VoiceRecorder {
  /// Asks for the microphone; false when the person says no.
  Future<bool> start();

  /// Stops and returns the recording (null if nothing was recorded).
  Future<VoiceClip?> stop();
  Future<void> cancel();
  void dispose();
}

class MicVoiceRecorder implements VoiceRecorder {
  final _rec = AudioRecorder();
  final _clock = Stopwatch();

  // Browsers record Opus in WebM; phones record AAC in M4A.
  static const _web = kIsWeb;

  @override
  Future<bool> start() async {
    if (!await _rec.hasPermission()) return false;
    final path = _web ? '' : '${(await getTemporaryDirectory()).path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _rec.start(RecordConfig(encoder: _web ? AudioEncoder.opus : AudioEncoder.aacLc, numChannels: 1, bitRate: 64000),
        path: path);
    _clock
      ..reset()
      ..start();
    return true;
  }

  @override
  Future<VoiceClip?> stop() async {
    _clock.stop();
    final path = await _rec.stop();
    if (path == null) return null;
    final bytes = await XFile(path).readAsBytes();
    return (
      bytes: bytes,
      extension: _web ? 'webm' : 'm4a',
      contentType: _web ? 'audio/webm' : 'audio/mp4',
      durationMs: _clock.elapsedMilliseconds,
    );
  }

  @override
  Future<void> cancel() async {
    _clock.stop();
    await _rec.cancel();
  }

  @override
  void dispose() => _rec.dispose();
}
