import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get lang => Localizations.localeOf(this).languageCode;
  void toast(String msg) =>
      ScaffoldMessenger.of(this)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(msg)));
}

/// Renders an [AsyncValue] with consistent loading/error states.
class AsyncView<T> extends StatelessWidget {
  const AsyncView(this.value, {super.key, required this.data, this.loading, this.sliver = false});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final bool sliver;

  @override
  Widget build(BuildContext context) {
    final w = value.when(
      data: data,
      loading: () => loading ?? const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ErrorBox(message: '$e'),
    );
    return sliver && value is! AsyncData ? SliverToBoxAdapter(child: w) : w;
  }
}

class ErrorBox extends StatelessWidget {
  const ErrorBox({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: KjdColors.kumkum, size: 36),
          const SizedBox(height: 8),
          Text(context.l10n.error, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ]),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.message, this.icon = Icons.temple_hindu_outlined});
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(color: KjdColors.goldLight, shape: BoxShape.circle),
            child: Icon(icon, size: 44, color: KjdColors.saffron),
          ),
          const SizedBox(height: 14),
          Text(message ?? context.l10n.nothingHereYet,
              textAlign: TextAlign.center, style: const TextStyle(color: KjdColors.inkMuted, fontSize: 15, height: 1.5)),
        ]),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.icon});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final String? icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 8, 8),
        child: Row(children: [
          Container(
            width: 4,
            height: 20,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(gradient: KjdColors.heroGradient, borderRadius: BorderRadius.circular(4)),
          ),
          if (icon != null) Text('$icon ', style: const TextStyle(fontSize: 18)),
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ]),
      );
}

/// Network image with cache, placeholder and support for the bundled logo
/// via the `asset:logo` pseudo-URL used by demo content.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover, this.height, this.width, this.fallbackIcon = '🛕'});

  final String? url;
  final BoxFit fit;
  final double? height;
  final double? width;
  final String fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: height,
      width: width,
      decoration: const BoxDecoration(gradient: KjdColors.heroGradient),
      alignment: Alignment.center,
      child: Text(fallbackIcon, style: const TextStyle(fontSize: 40)),
    );
    final u = url;
    if (u == null || u.isEmpty) return fallback;
    if (u == 'asset:logo') {
      return Container(
        height: height,
        width: width,
        color: KjdColors.goldLight,
        padding: const EdgeInsets.all(8),
        child: const Image(image: TempleLogo.asset, fit: BoxFit.contain),
      );
    }
    return CachedNetworkImage(
      imageUrl: u,
      fit: fit,
      height: height,
      width: width,
      placeholder: (_, _) => Container(height: height, width: width, color: KjdColors.goldLight),
      errorWidget: (_, _, _) => fallback,
    );
  }
}

/// Small rounded pill used for statuses.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = KjdColors.saffron, this.filled = false});
  final String text;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                color: filled ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class LivePill extends StatelessWidget {
  const LivePill({super.key});
  @override
  Widget build(BuildContext context) => Pill('● ${context.l10n.liveNow}', color: KjdColors.live, filled: true);
}

/// Label/value row used on receipts, passes and detail pages.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 120,
              child: Text(label, style: const TextStyle(color: KjdColors.inkMuted))),
          Expanded(
            child: Text(value,
                style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
          ),
        ]),
      );
}

/// Shown at the top of the app when running without Firebase.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});
  @override
  Widget build(BuildContext context) => Material(
        color: KjdColors.goldLight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(children: [
            const Icon(Icons.science_outlined, size: 16, color: KjdColors.kumkumDark),
            const SizedBox(width: 6),
            Expanded(
              child: Text(context.l10n.demoMode,
                  style: const TextStyle(fontSize: 12, color: KjdColors.kumkumDark)),
            ),
          ]),
        ),
      );
}

String eventStatusLabel(BuildContext context, TempleEvent e, DateTime now) {
  if (e.isOngoing(now)) return context.l10n.ongoing;
  if (e.isUpcoming(now)) return context.l10n.upcoming;
  return context.l10n.completed;
}

String categoryIcon(List<EventCategory> cats, String id) =>
    cats.where((c) => c.id == id).map((c) => c.icon).firstOrNull ?? '🎉';
