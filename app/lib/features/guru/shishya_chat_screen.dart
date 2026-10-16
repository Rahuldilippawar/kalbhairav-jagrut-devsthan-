import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
  ChatMessage? _replyTo;
  bool _marking = false;
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
      await ref.read(shishyaChatRepoProvider).send(me, ChatKind.text, text: t, replyTo: _replyTo);
      _text.clear();
      _replyTo = null;
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
          .send(me, pick.isVideo ? ChatKind.video : ChatKind.image, mediaUrl: url, text: caption, replyTo: _replyTo);
      _text.clear();
      _replyTo = null;
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
      await ref
          .read(shishyaChatRepoProvider)
          .send(me, ChatKind.voice, mediaUrl: url, durationMs: clip.durationMs, replyTo: _replyTo);
      _replyTo = null;
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

  /// Long-press menu, like WhatsApp: reply, copy, info, remove.
  void _menu(ChatMessage m, {required bool mine, required bool moderator}) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.reply),
            title: Text(l.chatReply),
            onTap: () {
              Navigator.pop(sheet);
              setState(() => _replyTo = m);
            },
          ),
          if (m.text != null)
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(l.chatCopy),
              onTap: () {
                Navigator.pop(sheet);
                Clipboard.setData(ClipboardData(text: m.text!));
                context.toast(l.chatCopied);
              },
            ),
          if (mine || moderator)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l.chatInfo),
              onTap: () {
                Navigator.pop(sheet);
                _info(m);
              },
            ),
          if (mine || moderator)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: KjdColors.kumkum),
              title: Text(l.chatDelete, style: const TextStyle(color: KjdColors.kumkum)),
              onTap: () {
                Navigator.pop(sheet);
                _remove(m);
              },
            ),
        ]),
      ),
    );
  }

  /// Who has seen a message, and when.
  void _info(ChatMessage m) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Consumer(builder: (context, ref, _) {
        final seen = m.seenBy(ref.watch(chatReadsProvider).value ?? const <ChatRead>[])
          ..sort((a, b) => b.readAt!.compareTo(a.readAt!));
        return SafeArea(
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
            Text('✓✓ ${l.chatSeenTitle} (${seen.length})',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _seenBlue)),
            const SizedBox(height: 8),
            if (seen.isEmpty) Text(l.chatNotSeen, style: const TextStyle(color: KjdColors.inkMuted)),
            for (final r in seen)
              ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: _nameColor(r.uid),
                  child: Text(r.name.isEmpty ? '🙏' : r.name.characters.first, style: const TextStyle(color: Colors.white)),
                ),
                title: Text(r.name),
                subtitle: Text(formatDateTime(r.readAt, locale: context.lang)),
              ),
          ]),
        );
      }),
    );
  }

  /// Marks the chat read up to now when someone else wrote something newer.
  void _maybeMarkRead(Shishya me, List<ChatMessage> msgs, List<ChatRead>? reads) {
    if (_marking || reads == null) return;
    final newest = msgs.where((m) => m.uid != me.uid && m.createdAt != null).firstOrNull;
    if (newest == null) return;
    final mine = reads.where((r) => r.uid == me.uid).firstOrNull?.readAt;
    if (mine != null && !mine.isBefore(newest.createdAt!)) return;
    _marking = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shishyaChatRepoProvider).markRead(me).whenComplete(() => _marking = false).ignore();
    });
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
              final reads = ref.watch(chatReadsProvider).value;
              _maybeMarkRead(me, msgs, reads);
              final today = DateUtils.dateOnly(ref.watch(clockProvider)());
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final m = msgs[i];
                  final mine = m.uid == me.uid;
                  // Day header above the first message of each day (the list runs newest first).
                  final day = m.createdAt == null ? null : DateUtils.dateOnly(m.createdAt!);
                  final olderDay = i + 1 < msgs.length && msgs[i + 1].createdAt != null
                      ? DateUtils.dateOnly(msgs[i + 1].createdAt!)
                      : null;
                  final bubble = _Bubble(
                    m: m,
                    mine: mine,
                    seen: mine ? m.seenBy(reads ?? const []).length : 0,
                    onLongPress: () => _menu(m, mine: mine, moderator: moderator),
                  );
                  if (day == null || day == olderDay) return bubble;
                  return Column(children: [_DayChip(day: day, today: today), bubble]);
                },
              );
            }),
          ),
          if (_sending) const LinearProgressIndicator(minHeight: 2),
          if (_replyTo != null && !recording)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 6, 4, 0),
              child: Row(children: [
                Expanded(child: _Quote(name: _replyTo!.name, uid: _replyTo!.uid, text: _replyTo!.preview)),
                IconButton(
                  tooltip: l.cancel,
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _replyTo = null),
                ),
              ]),
            ),
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

const _seenBlue = Color(0xFF34B7F1);

/// Each shishya's name in their own colour, as in WhatsApp groups.
Color _nameColor(String uid) => const [
      Color(0xFFB71C1C),
      Color(0xFF1565C0),
      Color(0xFF2E7D32),
      Color(0xFF6A1B9A),
      Color(0xFFEF6C00),
      Color(0xFF00838F),
      Color(0xFFAD1457),
      Color(0xFF4E342E),
    ][uid.hashCode.abs() % 8];

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.today});
  final DateTime day;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final label = day == today
        ? l.periodToday
        : day == today.subtract(const Duration(days: 1))
            ? l.chatYesterday
            : formatDate(day, locale: context.lang);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFE1F0F7), borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// The quoted message inside a reply.
class _Quote extends StatelessWidget {
  const _Quote({required this.name, required this.uid, required this.text});
  final String name;
  final String? uid;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = uid == null ? KjdColors.saffron : _nameColor(uid!);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 12.5)),
        Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.m, required this.mine, required this.seen, required this.onLongPress});
  final ChatMessage m;
  final bool mine;

  /// How many others have seen this message (own messages only).
  final int seen;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final url = m.mediaUrl;
    final time = m.createdAt == null ? null : DateFormat.jm(context.lang).format(m.createdAt!);
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
              Text(m.name, style: TextStyle(fontWeight: FontWeight.w800, color: _nameColor(m.uid), fontSize: 12.5)),
            if (m.replyName != null) _Quote(name: m.replyName!, uid: null, text: m.replyText ?? ''),
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
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (mine && seen > 0)
                  Text('${l.chatSeenBy(seen)} ', style: const TextStyle(fontSize: 10.5, color: KjdColors.inkMuted)),
                Text(time ?? '', style: const TextStyle(fontSize: 10.5, color: KjdColors.inkMuted)),
                if (mine) ...[
                  const SizedBox(width: 3),
                  // 🕓 on its way · ✓ sent · ✓✓ blue once someone has seen it.
                  if (time == null)
                    const Icon(Icons.schedule, size: 14, color: KjdColors.inkMuted)
                  else if (seen == 0)
                    const Icon(Icons.done, size: 15, color: KjdColors.inkMuted)
                  else
                    const Icon(Icons.done_all, size: 15, color: _seenBlue),
                ],
              ]),
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
