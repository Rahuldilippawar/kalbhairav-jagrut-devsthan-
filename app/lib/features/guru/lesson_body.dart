import 'package:flutter/material.dart';
import 'package:kjd_core/kjd_core.dart';

/// Lesson text with a little structure: `## ` lines are headings and
/// `- name – note` lines (two spaces of indent per generation) are drawn as
/// a family tree; every other line is a paragraph.
class LessonBody extends StatelessWidget {
  const LessonBody({super.key, required this.text, required this.fontSize, this.poem = false});
  final String text;
  final double fontSize;

  /// Stotra: centred, in the Devanagari serif.
  final bool poem;

  static final _node = RegExp(r'^( *)- (.*)$');

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      final node = _node.firstMatch(line);
      if (trimmed.isEmpty) {
        children.add(SizedBox(height: fontSize * .6));
      } else if (trimmed.startsWith('## ')) {
        children.add(_Heading(trimmed.substring(3), fontSize));
      } else if (node != null) {
        children.add(_TreeNode(level: node.group(1)!.length ~/ 2, text: node.group(2)!, fontSize: fontSize));
      } else {
        children.add(Text(
          trimmed,
          textAlign: poem ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.8,
            fontFamily: poem ? bannerFontFamily('tiroMarathi') : null,
            locale: poem ? bannerTextLocale : null,
          ),
        ));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, this.fontSize);
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: fontSize * .8, bottom: fontSize * .3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: KjdColors.goldLight,
            borderRadius: BorderRadius.circular(10),
            border: const Border(left: BorderSide(color: KjdColors.kumkum, width: 4)),
          ),
          child: Text(text,
              style: TextStyle(fontSize: fontSize + 1.5, fontWeight: FontWeight.w800, color: KjdColors.kumkumDark)),
        ),
      );
}

const _levelColors = [KjdColors.kumkum, KjdColors.saffron, KjdColors.gold, Color(0xFF6D4C41)];

class _TreeNode extends StatelessWidget {
  const _TreeNode({required this.level, required this.text, required this.fontSize});
  final int level;
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    // "name – note": the name in bold.
    final dash = text.indexOf(' – ');
    final name = dash < 0 ? text : text.substring(0, dash);
    final note = dash < 0 ? null : text.substring(dash + 3);
    final color = _levelColors[level % _levelColors.length];
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < level; i++)
          SizedBox(
            width: 18,
            child: Center(
              child: Container(width: 2, color: _levelColors[i % _levelColors.length].withValues(alpha: .35)),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(top: fontSize * .55, right: 8),
          child: Container(
            width: 10,
            height: 10,
            alignment: Alignment.topCenter,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: name, style: TextStyle(fontWeight: FontWeight.w800, color: level == 0 ? color : null)),
                if (note != null)
                  TextSpan(text: ' – $note', style: const TextStyle(color: KjdColors.inkMuted)),
              ]),
              style: TextStyle(fontSize: fontSize - 1, height: 1.5),
            ),
          ),
        ),
      ]),
    );
  }
}
