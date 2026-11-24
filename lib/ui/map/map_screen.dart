import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/map/map_repository.dart';
import '../../domain/map/map_image_catalog.dart';
import '../../domain/map/map_models.dart';
import '../../domain/navigation/normalized_map_point.dart';
import '../../domain/navigation/route_metrics.dart';
import '../../domain/navigation/route_models.dart';
import '../common/common_widgets.dart';
import '../providers.dart';
import '../theme/app_theme.dart';
import 'map_overlay_painter.dart';
import 'place_search_delegate.dart';

/// Origen por defecto cuando el usuario pide "Cómo llegar" sin elegir inicio.
const _defaultOriginPlaceId = 'entrada_principal';
const _mapAspectRatio = 1260 / 1600;

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key, this.initialPlaceId, this.routeToPlace = false});

  /// Lugar a destacar al abrir (p. ej. desde un trámite o una clase).
  final String? initialPlaceId;

  /// Si es `true`, se traza la ruta hacia [initialPlaceId].
  final bool routeToPlace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final map = ref.watch(loadedMapProvider);
    return Scaffold(
      body: AsyncValueView(
        value: map,
        onRetry: () => ref.invalidate(loadedMapProvider),
        data: (repository) => _MapView(
          repository: repository,
          initialPlaceId: initialPlaceId,
          routeToPlace: routeToPlace,
        ),
      ),
    );
  }
}

/// Origen de la ruta: un lugar o un punto tocado en el mapa.
class _Origin {
  const _Origin.place(MapPlace this.place)
      : point = null,
        floorId = null;
  const _Origin.point(NormalizedMapPoint this.point, String this.floorId) : place = null;

  final MapPlace? place;
  final NormalizedMapPoint? point;
  final String? floorId;

  String get label => place?.name ?? 'Punto en el mapa (${floorLabel(floorId!)})';

  RouteEndpoint get endpoint =>
      place != null ? PlaceEndpoint(place!) : ManualPointEndpoint(floorId: floorId!, point: point!);
}

class _MapView extends ConsumerStatefulWidget {
  const _MapView({required this.repository, this.initialPlaceId, this.routeToPlace = false});

  final MapRepository repository;
  final String? initialPlaceId;
  final bool routeToPlace;

  @override
  ConsumerState<_MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<_MapView> with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _animation =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
  Animation<Matrix4>? _matrixAnimation;

  late String _floorId = widget.repository.floors.first.id;
  MapResolutionLevel _resolution = MapResolutionLevel.low;
  Size _viewport = Size.zero;

  MapPlace? _selected;
  _Origin? _origin;
  MapPlace? _destination;
  RouteResult? _route;
  bool _routing = false;
  bool _avoidStairs = false;

  MapRepository get _repo => widget.repository;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransformChanged);
    _animation.addListener(() {
      if (_matrixAnimation != null) _transform.value = _matrixAnimation!.value;
    });
    final initial = widget.initialPlaceId == null ? null : _repo.placeById(widget.initialPlaceId!);
    if (initial != null) {
      _floorId = initial.floorId;
      _selected = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusPlace(initial);
        if (widget.routeToPlace) _routeTo(initial);
      });
    }
  }

  @override
  void dispose() {
    _transform
      ..removeListener(_onTransformChanged)
      ..dispose();
    _animation.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final level = MapImageCatalog.resolutionFor(
      _transform.value.getMaxScaleOnAxis(),
      current: _resolution,
    );
    if (level != _resolution) setState(() => _resolution = level);
  }

  // --- Interacción con el mapa ---

  Size get _mapSize {
    final width = _viewport.width;
    final height = _viewport.height;
    return width / height > _mapAspectRatio
        ? Size(height * _mapAspectRatio, height)
        : Size(width, width / _mapAspectRatio);
  }

  MapPlace? _placeAt(NormalizedMapPoint point) {
    MapPlace? best;
    var bestArea = double.infinity;
    for (final place in _repo.placesOnFloor(_floorId)) {
      for (final b in place.bounds) {
        if (!b.contains(point.x, point.y)) continue;
        final area = (b.right - b.left) * (b.bottom - b.top);
        if (area < bestArea) {
          bestArea = area;
          best = place;
        }
      }
    }
    return best;
  }

  void _onTap(NormalizedMapPoint point) => setState(() => _selected = _placeAt(point));

  void _onLongPress(NormalizedMapPoint point) {
    setState(() {
      _origin = _Origin.point(point, _floorId);
      _selected = null;
    });
    showSnack(context, 'Inicio fijado en este punto.');
    _recalculate();
  }

  /// Centra y acerca el mapa sobre un lugar.
  void _focusPlace(MapPlace place, {double scale = 2.6}) {
    final center = place.centerPoint;
    if (center == null || _viewport == Size.zero) return;
    final mapSize = _mapSize;
    final offset = Offset((_viewport.width - mapSize.width) / 2, (_viewport.height - mapSize.height) / 2);
    final px = offset.dx + center.x * mapSize.width;
    final py = offset.dy + center.y * mapSize.height;
    final target = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, _viewport.width / 2 - scale * px)
      ..setEntry(1, 3, _viewport.height / 2 - scale * py);
    _matrixAnimation = Matrix4Tween(begin: _transform.value, end: target)
        .animate(CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic));
    _animation.forward(from: 0);
  }

  void _resetZoom() {
    _matrixAnimation = Matrix4Tween(begin: _transform.value, end: Matrix4.identity())
        .animate(CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic));
    _animation.forward(from: 0);
  }

  void _showFloor(String floorId) {
    if (floorId == _floorId) return;
    setState(() {
      _floorId = floorId;
      if (_selected?.floorId != floorId) _selected = null;
    });
  }

  Future<void> _search() async {
    final place = await showSearch<MapPlace?>(context: context, delegate: PlaceSearchDelegate(_repo.allPlaces));
    if (place == null || !mounted) return;
    setState(() {
      _floorId = place.floorId;
      _selected = place;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusPlace(place));
  }

  // --- Rutas ---

  void _routeTo(MapPlace destination) {
    setState(() {
      _destination = destination;
      _origin ??= switch (_repo.placeById(_defaultOriginPlaceId)) {
        final entrance? when entrance.id != destination.id => _Origin.place(entrance),
        _ => null,
      };
    });
    if (_origin == null) {
      showSnack(context, 'Elige un inicio con el buscador o manteniendo presionado el mapa.');
    }
    _recalculate();
  }

  void _setOrigin(MapPlace place) {
    setState(() => _origin = _Origin.place(place));
    _recalculate();
  }

  Future<void> _recalculate() async {
    final origin = _origin, destination = _destination;
    if (origin == null || destination == null) {
      setState(() => _route = null);
      return;
    }
    setState(() => _routing = true);
    final result = await ref.read(routeServiceProvider).calculateRoute(
          origin.endpoint,
          PlaceEndpoint(destination),
          accessibleOnly: _avoidStairs,
        );
    if (!mounted) return;
    setState(() {
      _routing = false;
      _route = result;
      if (result.success) _floorId = result.segments.first.floorId;
    });
  }

  void _clearRoute() => setState(() {
        _origin = null;
        _destination = null;
        _route = null;
      });

  void _swapRoute() {
    final origin = _origin?.place, destination = _destination;
    if (origin == null || destination == null) return;
    setState(() {
      _origin = _Origin.place(destination);
      _destination = origin;
    });
    _recalculate();
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final floors = _repo.floors;
    final floor = floors.firstWhere((f) => f.id == _floorId);
    final hasRoutePanel = _origin != null || _destination != null;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(
              children: [
                Expanded(child: Text('Mapa de ESCOM', style: Theme.of(context).textTheme.titleLarge)),
                IconButton(tooltip: 'Buscar lugar', icon: const Icon(Icons.search), onPressed: _search),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final f in floors)
                  ButtonSegment(
                    value: f.id,
                    label: Text(f.id == 'PB' ? 'PB' : 'Piso ${f.id}'),
                    icon: _route?.segments.any((s) => s.floorId == f.id) ?? false
                        ? const Icon(Icons.route, size: 16)
                        : null,
                  ),
              ],
              selected: {_floorId},
              onSelectionChanged: (s) => _showFloor(s.single),
            ),
          ),
          if (hasRoutePanel) _routeHeader(),
          Expanded(child: _mapCanvas(floor)),
          if (_route != null || _routing)
            _routeSummary()
          else if (_selected != null)
            _placePanel(_selected!),
        ],
      ),
    );
  }

  Widget _mapCanvas(MapFloor floor) => LayoutBuilder(builder: (context, constraints) {
        _viewport = constraints.biggest;
        final mapSize = _mapSize;
        final colors = Theme.of(context).colorScheme;
        return Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: colors.surfaceContainerLowest,
                child: InteractiveViewer(
                  transformationController: _transform,
                  minScale: 1,
                  maxScale: 8,
                  boundaryMargin: const EdgeInsets.all(48),
                  child: SizedBox.fromSize(
                    size: _viewport,
                    child: Center(
                      child: SizedBox.fromSize(
                        size: mapSize,
                        child: GestureDetector(
                          onTapUp: (d) => _onTap(_normalize(d.localPosition, mapSize)),
                          onLongPressStart: (d) => _onLongPress(_normalize(d.localPosition, mapSize)),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                floor.imageAssetPath(_resolution),
                                fit: BoxFit.fill,
                                gaplessPlayback: true,
                                // Limita la memoria: PB "_a" mide 5040 × 6400 px.
                                cacheWidth: 1260 * (_resolution.index + 1),
                                errorBuilder: (_, _, _) => const Center(child: Text('Imagen no disponible')),
                              ),
                              CustomPaint(
                                painter: MapOverlayPainter(
                                  floorId: _floorId,
                                  transform: _transform,
                                  selectedPlace: _selected,
                                  destinationPlace: _destination,
                                  route: _route,
                                  manualOrigin: _origin?.floorId == _floorId ? _origin?.point : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: FloatingActionButton.small(
                heroTag: 'reset_zoom',
                tooltip: 'Ver piso completo',
                onPressed: _resetZoom,
                child: const Icon(Icons.zoom_out_map),
              ),
            ),
            if (_selected == null && _route == null)
              Positioned(
                left: 12,
                bottom: 12,
                right: 72,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'Toca un lugar para ver su información. Mantén presionado para fijar un inicio.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
          ],
        );
      });

  static NormalizedMapPoint _normalize(Offset local, Size size) => NormalizedMapPoint(
        (local.dx / size.width).clamp(0.0, 1.0),
        (local.dy / size.height).clamp(0.0, 1.0),
      );

  Widget _routeHeader() {
    final theme = Theme.of(context);
    Widget endpoint(IconData icon, Color color, String text) => Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        );
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  endpoint(Icons.trip_origin, EscomColors.routeOrigin,
                      _origin?.label ?? 'Elige un inicio (busca o mantén presionado)'),
                  const SizedBox(height: 6),
                  endpoint(Icons.place, EscomColors.routeDestination, _destination?.name ?? 'Elige un destino'),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Invertir',
              onPressed: _origin?.place != null && _destination != null ? _swapRoute : null,
              icon: const Icon(Icons.swap_vert),
            ),
            IconButton(
              tooltip: 'Quitar ruta',
              onPressed: _clearRoute,
              icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placePanel(MapPlace place) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text(place.name, style: theme.textTheme.titleMedium)),
                IconButton(
                  tooltip: 'Cerrar',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _selected = null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              '${place.type.displayName} · ${floorLabel(place.floorId)} · ${place.building}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (place.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(place.description, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            if (place.access == 'PERSONAL' || place.access == 'RESTRINGIDO') ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.lock_outline, size: 16, color: EscomColors.warning),
                const SizedBox(width: 6),
                Text('Acceso ${place.access == 'PERSONAL' ? 'solo para personal' : 'restringido'}',
                    style: theme.textTheme.bodySmall),
              ]),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _setOrigin(place),
                    icon: const Icon(Icons.trip_origin),
                    label: const Text('Salir de aquí'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _routeTo(place),
                    icon: const Icon(Icons.directions_walk),
                    label: const Text('Cómo llegar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeSummary() {
    final theme = Theme.of(context);
    final route = _route;
    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_routing)
              const LinearProgressIndicator()
            else if (route != null && !route.success)
              Row(children: [
                const Icon(Icons.error_outline, color: EscomColors.routeDestination),
                const SizedBox(width: 8),
                Expanded(child: Text(route.errorMessage ?? 'No se encontró ruta')),
              ])
            else if (route != null) ...[
              Builder(builder: (context) {
                final metrics = RouteMetricsCalculator.estimate(route);
                return Text('${metrics.minutes} min · ${metrics.meters} m',
                    style: theme.textTheme.titleMedium);
              }),
              const SizedBox(height: 4),
              ..._routeSteps(route),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Evitar escaleras'),
              value: _avoidStairs,
              onChanged: (value) {
                setState(() => _avoidStairs = value);
                _recalculate();
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _routeSteps(RouteResult route) {
    if (!route.isMultiFloor) {
      return [Text('Ruta en ${floorLabel(route.segments.single.floorId).toLowerCase()}.')];
    }
    return [
      for (final t in route.transitions)
        TextButton.icon(
          style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
          onPressed: () => _showFloor(t.toFloorId),
          icon: Icon(
            _levelOf(t.toFloorId) > _levelOf(t.fromFloorId) ? Icons.north_east : Icons.south_east,
            size: 18,
          ),
          label: Text(
            '${_levelOf(t.toFloorId) > _levelOf(t.fromFloorId) ? 'Sube' : 'Baja'} por la escalera '
            '(E) a ${floorLabel(t.toFloorId).toLowerCase()}',
          ),
        ),
    ];
  }

  int _levelOf(String floorId) => _repo.floors.indexWhere((f) => f.id == floorId);
}
