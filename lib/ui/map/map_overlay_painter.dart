import 'package:material_ui/material_ui.dart';

import '../../domain/map/map_models.dart';
import '../../domain/navigation/normalized_map_point.dart';
import '../../domain/navigation/route_models.dart';
import '../theme/app_theme.dart';

/// Dibuja sobre la imagen del piso: lugar seleccionado, ruta y marcadores.
///
/// Repinta cuando cambia el zoom para mantener el grosor de línea constante
/// en pantalla.
class MapOverlayPainter extends CustomPainter {
  MapOverlayPainter({
    required this.floorId,
    required this.transform,
    this.selectedPlace,
    this.destinationPlace,
    this.route,
    this.manualOrigin,
  }) : super(repaint: transform);

  final String floorId;
  final TransformationController transform;
  final MapPlace? selectedPlace;
  final MapPlace? destinationPlace;
  final RouteResult? route;

  /// Punto de origen elegido tocando el mapa, si está en este piso.
  final NormalizedMapPoint? manualOrigin;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = transform.value.getMaxScaleOnAxis().clamp(1.0, 50.0);
    Offset at(NormalizedMapPoint p) => Offset(p.x * size.width, p.y * size.height);

    void drawBounds(MapPlace place, Color color) {
      if (place.floorId != floorId) return;
      final fill = Paint()..color = color.withValues(alpha: 0.22);
      final stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 / scale;
      for (final b in place.bounds) {
        final rect = Rect.fromLTRB(
            b.left * size.width, b.top * size.height, b.right * size.width, b.bottom * size.height);
        final rounded = RRect.fromRectAndRadius(rect, Radius.circular(3 / scale));
        canvas
          ..drawRRect(rounded, fill)
          ..drawRRect(rounded, stroke);
      }
    }

    if (destinationPlace case final destination?) drawBounds(destination, EscomColors.routeDestination);
    if (selectedPlace case final selected? when selected.id != destinationPlace?.id) {
      drawBounds(selected, EscomColors.blue);
    }

    final route = this.route;
    if (route != null && route.success) {
      final segment = route.segments.where((s) => s.floorId == floorId).firstOrNull;
      if (segment != null && segment.points.length > 1) {
        final path = Path()..moveTo(at(segment.points.first).dx, at(segment.points.first).dy);
        for (final p in segment.points.skip(1)) {
          path.lineTo(at(p).dx, at(p).dy);
        }
        canvas
          ..drawPath(
            path,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 9 / scale
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round,
          )
          ..drawPath(
            path,
            Paint()
              ..color = EscomColors.route
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5 / scale
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round,
          );
      }

      // Escaleras usadas en este piso.
      for (final t in route.transitions) {
        if (t.fromFloorId == floorId) _marker(canvas, at(t.point), scale, EscomColors.warning, 'E');
      }
      for (final t in route.transitions) {
        if (t.toFloorId == floorId) {
          final arrival = route.segments.where((s) => s.floorId == floorId).firstOrNull?.points.firstOrNull;
          if (arrival != null) _marker(canvas, at(arrival), scale, EscomColors.warning, 'E');
        }
      }

      final first = route.segments.first;
      if (first.floorId == floorId && first.points.isNotEmpty) {
        _marker(canvas, at(first.points.first), scale, EscomColors.routeOrigin, 'A');
      }
      final last = route.segments.last;
      if (last.floorId == floorId && last.points.isNotEmpty) {
        _marker(canvas, at(last.points.last), scale, EscomColors.routeDestination, 'B');
      }
    } else if (manualOrigin case final origin?) {
      _marker(canvas, at(origin), scale, EscomColors.routeOrigin, 'A');
    }
  }

  void _marker(Canvas canvas, Offset center, double scale, Color color, String label) {
    final radius = 11 / scale;
    canvas
      ..drawCircle(center, radius + 2.5 / scale, Paint()..color = Colors.white)
      ..drawCircle(center, radius, Paint()..color = color);
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: Colors.white, fontSize: 12 / scale, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(MapOverlayPainter old) =>
      old.floorId != floorId ||
      old.selectedPlace != selectedPlace ||
      old.destinationPlace != destinationPlace ||
      old.route != route ||
      old.manualOrigin != manualOrigin;
}
