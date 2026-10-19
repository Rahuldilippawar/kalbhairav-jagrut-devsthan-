import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

/// Page colours for reading lessons and granths: day, sepia paper, night.
enum ReadingMode { day, sepia, night }

extension ReadingModeColors on ReadingMode {
  Color get background => switch (this) {
        ReadingMode.day => KjdColors.cream,
        ReadingMode.sepia => const Color(0xFFF4E7CF),
        ReadingMode.night => const Color(0xFF15100C),
      };

  Color get text => switch (this) {
        ReadingMode.day => KjdColors.ink,
        ReadingMode.sepia => const Color(0xFF3B2A1A),
        ReadingMode.night => const Color(0xFFE9DCC8),
      };

  IconData get icon => switch (this) {
        ReadingMode.day => Icons.light_mode_outlined,
        ReadingMode.sepia => Icons.menu_book_outlined,
        ReadingMode.night => Icons.dark_mode_outlined,
      };

  ReadingMode get next => ReadingMode.values[(index + 1) % ReadingMode.values.length];
}

class ReadingModeController extends Notifier<ReadingMode> {
  @override
  ReadingMode build() => ReadingMode.day;
  void cycle() => state = state.next;
}

/// Shared by the lesson and granth readers for the whole app session.
final readingModeProvider = NotifierProvider<ReadingModeController, ReadingMode>(ReadingModeController.new);

/// App-bar button that switches day → sepia → night.
class ReadingModeButton extends ConsumerWidget {
  const ReadingModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(readingModeProvider);
    return IconButton(
      tooltip: 'वाचन रंग',
      icon: Icon(mode.next.icon),
      onPressed: () => ref.read(readingModeProvider.notifier).cycle(),
    );
  }
}
