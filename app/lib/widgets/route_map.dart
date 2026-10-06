import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:latlong2/latlong.dart';

import '../services/share_service.dart';
import 'common.dart';

/// OpenStreetMap tile URL. Null disables tiles (tests, offline).
final mapTileUrlProvider = Provider<String?>((_) => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');

/// Pavitra Payi Dindi route: numbered stops in day order joined by a line,
/// plus the final destination. Uses OpenStreetMap (no API key needed).
class RouteMap extends ConsumerWidget {
  const RouteMap({super.key, required this.stops, this.dindi});
  final List<EventScheduleItem> stops;
  final DindiDetails? dindi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final located = stops.where((s) => s.hasCoordinates).toList();
    final dest = dindi?.destinationLat != null && dindi?.destinationLng != null
        ? LatLng(dindi!.destinationLat!, dindi!.destinationLng!)
        : null;
    final points = [for (final s in located) LatLng(s.latitude!, s.longitude!), ?dest];
    if (points.length < 2) return const SizedBox.shrink();
    final tiles = ref.watch(mapTileUrlProvider);
    final directions = routeDirectionsUrl(stops, endLat: dindi?.destinationLat, endLng: dindi?.destinationLng);

    Widget pin(String label, Color color) => Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
          ),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
        );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 240,
          child: FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.fromLTRB(36, 36, 36, 56)),
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              if (tiles != null)
                TileLayer(urlTemplate: tiles, userAgentPackageName: 'org.kalbhairav.kjd_app')
              else
                const ColoredBox(color: KjdColors.goldLight),
              PolylineLayer(polylines: [
                Polyline(points: points, strokeWidth: 4, color: KjdColors.kumkum, pattern: StrokePattern.dashed(segments: const [10, 6])),
              ]),
              MarkerLayer(markers: [
                for (final (i, s) in located.indexed)
                  Marker(point: LatLng(s.latitude!, s.longitude!), width: 30, height: 30, child: pin('${s.dayNumber ?? i + 1}', KjdColors.kumkum)),
                if (dest != null) Marker(point: dest, width: 34, height: 34, child: pin('🚩', KjdColors.saffron)),
              ]),
              if (tiles != null) const SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
            ],
          ),
        ),
        if (directions != null)
          TextButton.icon(
            onPressed: () => openUrl(directions),
            icon: const Icon(Icons.directions_walk),
            label: Text('${context.l10n.route} – Google Maps'),
          ),
      ]),
    );
  }
}
