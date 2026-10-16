import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../services/chat_media.dart';
import '../../widgets/common.dart';
import '../../widgets/media_viewer.dart';
import '../../widgets/secure_screen.dart';

/// Photo or video picked for the chat.
typedef ChatPick = ({XFile file, bool isVideo});

enum ChatPickSource { gallery, camera, video }

/// Picks a photo or video; replaced in tests.
final chatPickerProvider = Provider<Future<ChatPick?> Function(ChatPickSource)>((_) => (source) async {
      final p = ImagePicker();
      return switch (source) {
        ChatPickSource.video => switch (await p.pickVideo(
              source: ImageSource.gallery, maxDuration: const Duration(minutes: 3))) {
            final f? => (file: f, isVideo: true),
            null => null,
          },
        _ => switch (await p.pickImage(
              source: source == ChatPickSource.camera ? ImageSource.camera : ImageSource.gallery,
              maxWidth: 1600,
              imageQuality: 80)) {
            final f? => (file: f, isVideo: false),
            null => null,
          },
      };
    });

/// Devotional emoji offered next to the keyboard's own.
const _quickEmoji = ['🙏', '🔱', '🕉️', '🚩', '🌺', '🪔', '🌼', '🐚', '🔔', '📿', '🛕', '❤️', '😊', '👍', '🎉', '✨'];

/// The shishya parivar group chat: text, emoji, photos, videos and voice
/// messages, for approved shishyas only.
class ShishyaChatScreen extends ConsumerStatefulWidget {
  const ShishyaChatScreen({super.key});

  @override
  ConsumerState<ShishyaChatScreen> createState() => _ShishyaChatScreenState();
}

class _ShishyaChatScreenState extends ConsumerState<ShishyaChatScreen> {
  final _text = TextEditingController();
  bool _emoji = false;
  bool _sending = false;
  VoiceRecorder? _recorder;
  final _recordClock = Stopwatch();
  Timer? _tick;

  @override
  void dispose() {
    _text.dispose();
    _tick?.cancel();
    _recorder?.cancel();
    _recorder?.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() f) async {
    setState(() => _sending = true);
    try {
      await f();
    } catch (e) {
      if (mounted) context.toast('${context.l10n.error}: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendText(Shishya me) async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    await _guard(() async {
      await ref.read(shishyaChatRepoProvider).send(me, ChatKind.text, text: t);
      _text.clear();
    });
  }

  Future<void> _sendMedia(Shishya me, ChatPickSource source) async {
    final l = context.l10n;
    final pick = await ref.read(chatPickerProvider)(source);
    if (pick == null || !mounted) return;
    final bytes = await pick.file.readAsBytes();
    final limitMb = pick.isVideo ? 100 : 15;
    if (bytes.length >= limitMb * 1024 * 1024) {
      if (mounted) context.toast(l.chatFileTooBig(limitMb));
      return;
    }
    final name = pick.file.name.toLowerCase();
    final ext = name.contains('.') ? name.split('.').last : (pick.isVideo ? 'mp4' : 'jpg');
    final type = pick.file.mimeType ??
        (pick.isVideo ? 'video/${ext == 'mov' ? 'quicktime' : ext}' : 'image/${ext == 'jpg' ? 'jpeg' : ext}');
    await _guard(() async {
      final url = await ref.read(chatMediaUploaderProvider).upload(me.uid, bytes, extension: ext, contentType: type);
      final caption = _text.text.trim();
      await ref
          .read(shishyaChatRepoProvider)
          .send(me, pick.isVideo ? ChatKind.video : ChatKind.image, mediaUrl: url, text: caption);
      _text.clear();
    });
  }

  Future<void> _startVoice() async {
    final r = ref.read(voiceRecorderProvider)();
    if (!await r.start()) {
      r.dispose();
      if (mounted) context.toast(context.l10n.chatMicDenied);
      return;
    }
    _recordClock
      ..reset()
      ..start();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    setState(() => _recorder = r);
  }

  Future<void> _stopVoice(Shishya me, {required bool send}) async {
    final r = _recorder;
    if (r == null) return;
    _tick?.cancel();
    _recordClock.stop();
    setState(() => _recorder = null);
    if (!send) {
      await r.cancel();
      r.dispose();
      return;
    }
    await _guard(() async {
      final clip = await r.stop();
      r.dispose();
      if (clip == null || clip.durationMs < 700) return; // a tap, not a message
      final url = await ref
          .read(chatMediaUploaderProvider)
          .upload(me.uid, clip.bytes, extension: clip.extension, contentType: clip.contentType);
      await ref.read(shishyaChatRepoProvider).send(me, ChatKind.voice, mediaUrl: url, durationMs: clip.durationMs);
    });
  }

  void _attach(Shishya me) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Text('🖼️', style: TextStyle(fontSize: 24)),
            title: Text(l.chatPhoto),
            onTap: () {
              Navigator.pop(sheet);
              _sendMedia(me, ChatPickSource.gallery);
            },
          ),
          ListTile(
            leading: const Text('📸', style: TextStyle(fontSize: 24)),
            title: Text(l.chatCamera),
            onTap: () {
              Navigator.pop(sheet);
              _sendMedia(me, ChatPickSource.camera);
            },
          ),
          ListTile(
            leading: const Text('🎥', style: TextStyle(fontSize: 24)),
            title: Text(l.chatVideo),
            onTap: () {
              Navigator.pop(sheet);
              _sendMedia(me, ChatPickSource.video);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _remove(ChatMessage m) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.chatDeleteAsk),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l.chatDelete)),
        ],
      ),
    );
    if (ok == true) await _guard(() => ref.read(shishyaChatRepoProvider).remove(m.id));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final me = ref.watch(myShishyaProvider).value;
    final moderator = ref.watch(isGadhipatiProvider).value ?? false;
    if (me == null || !me.isApproved) {
      return Scaffold(
        appBar: AppBar(title: Text(l.chatTitle)),
        body: EmptyState(message: l.lessonsLocked, icon: Icons.lock_outline),
      );
    }
    final canMedia = ref.watch(chatMediaUploaderProvider).enabled;
    final recording = _recorder != null;
    return SecureScreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8EC),
        appBar: AppBar(title: Text('💬 ${l.chatTitle}')),
        body: Column(children: [
          Expanded(
            child: AsyncView(ref.watch(chatMessagesProvider), data: (msgs) {
              if (msgs.isEmpty) return EmptyState(message: l.chatEmpty, icon: Icons.forum_outlined);
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final m = msgs[i];
                  final mine = m.uid == me.uid;
                  return _Bubble(
                    m: m,
                    mine: mine,
                    onLongPress: mine || moderator ? () => _remove(m) : null,
                  );
                },
              );
            }),
          ),
          if (_sending) const LinearProgressIndicator(minHeight: 2),
          if (_emoji && !recording)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(6),
              child: Wrap(spacing: 4, children: [
                for (final e in _quickEmoji)
                  InkWell(
                    onTap: () {
                      final sel = _text.selection;
                      final at = sel.isValid ? sel.start : _text.text.length;
                      _text.text = _text.text.replaceRange(at, sel.isValid ? sel.end : at, e);
                      _text.selection = TextSelection.collapsed(offset: at + e.length);
                      setState(() {});
                    },
                    child: Padding(padding: const EdgeInsets.all(6), child: Text(e, style: const TextStyle(fontSize: 24))),
                  ),
              ]),
            ),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(4, 6, 6, 6),
              child: recording
                  ? Row(children: [
                      IconButton(
                        tooltip: l.cancel,
                        icon: const Icon(Icons.delete_outline, color: KjdColors.kumkum),
                        onPressed: () => _stopVoice(me, send: false),
                      ),
                      const Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('${l.chatRecording} ${_clockText(_recordClock.elapsedMilliseconds)}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      IconButton.filled(
                        tooltip: l.chatSend,
                        icon: const Icon(Icons.send),
                        onPressed: () => _stopVoice(me, send: true),
                      ),
                    ])
                  : Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      IconButton(
                        tooltip: 'Emoji',
                        icon: Icon(_emoji ? Icons.keyboard : Icons.emoji_emotions_outlined),
                        onPressed: () => setState(() => _emoji = !_emoji),
                      ),
                      if (canMedia)
                        IconButton(
                          tooltip: l.chatAttach,
                          icon: const Icon(Icons.attach_file),
                          onPressed: _sending ? null : () => _attach(me),
                        ),
                      Expanded(
                        child: TextField(
                          controller: _text,
                          minLines: 1,
                          maxLines: 5,
                          maxLength: 2000,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: l.chatTypeMessage,
                            counterText: '',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (_text.text.trim().isEmpty && canMedia)
                        IconButton.filled(
                          tooltip: l.chatVoice,
                          icon: const Icon(Icons.mic),
                          onPressed: _sending ? null : _startVoice,
                        )
                      else
                        IconButton.filled(
                          tooltip: l.chatSend,
                          icon: const Icon(Icons.send),
                          onPressed: _sending ? null : () => _sendText(me),
                        ),
                    ]),
            ),
          ),
        ]),
      ),
    );
  }
}

String _clockText(int ms) {
  final s = ms ~/ 1000;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.m, required this.mine, this.onLongPress});
  final ChatMessage m;
  final bool mine;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final url = m.mediaUrl;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: mine ? const Color(0xFFFFE3B3) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!mine)
              Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, color: KjdColors.kumkum, fontSize: 12.5)),
            if (url != null && m.kind == ChatKind.image)
              GestureDetector(
                onTap: () => MediaViewer.open(context, [MediaEntry(url: url, caption: m.text)]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(width: 240, height: 240, child: NetImage(url)),
                ),
              ),
            if (url != null && m.kind == ChatKind.video)
              InkWell(
                onTap: () => MediaViewer.open(context, [MediaEntry(url: url, isVideo: true, caption: m.text)]),
                child: Container(
                  width: 240,
                  height: 140,
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.play_circle_fill, color: Colors.white, size: 54),
                    Text('🎥 ${l.chatVideo}', style: const TextStyle(color: Colors.white70)),
                  ]),
                ),
              ),
            if (url != null && m.kind == ChatKind.voice) _VoicePlayer(url: url, durationMs: m.durationMs ?? 0),
            if (m.text != null)
              Padding(
                padding: EdgeInsets.only(top: m.kind == ChatKind.text ? 0 : 4),
                child: Text(m.text!, style: const TextStyle(fontSize: 15.5)),
              ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(m.createdAt == null ? '…' : formatDateTime(m.createdAt, locale: context.lang),
                  style: const TextStyle(fontSize: 10.5, color: KjdColors.inkMuted)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _VoicePlayer extends StatefulWidget {
  const _VoicePlayer({required this.url, required this.durationMs});
  final String url;
  final int durationMs;

  @override
  State<_VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<_VoicePlayer> {
  AudioPlayer? _player;
  PlayerState _state = PlayerState.stopped;
  Duration _pos = Duration.zero;
  final _subs = <StreamSubscription<Object?>>[];

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final p = _player ??= () {
      final p = AudioPlayer();
      _subs
        ..add(p.onPlayerStateChanged.listen((s) => mounted ? setState(() => _state = s) : null))
        ..add(p.onPositionChanged.listen((d) => mounted ? setState(() => _pos = d) : null))
        ..add(p.onPlayerComplete.listen((_) => mounted ? setState(() => _pos = Duration.zero) : null));
      return p;
    }();
    if (_state == PlayerState.playing) {
      await p.pause();
    } else {
      await p.play(UrlSource(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.durationMs;
    final playing = _state == PlayerState.playing;
    return SizedBox(
      width: 230,
      child: Row(children: [
        IconButton(
          tooltip: context.l10n.chatVoice,
          icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 36, color: KjdColors.saffron),
          onPressed: _toggle,
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : (_pos.inMilliseconds / total).clamp(0, 1).toDouble(),
            backgroundColor: KjdColors.goldLight,
            color: KjdColors.saffron,
          ),
        ),
        const SizedBox(width: 8),
        Text('🎤 ${_clockText(playing ? _pos.inMilliseconds : total)}', style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}
