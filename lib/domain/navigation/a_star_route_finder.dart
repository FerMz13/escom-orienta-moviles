import 'dart:math' as math;

import '../map/map_models.dart';

/// Camino encontrado en el grafo de un piso.
class GraphPath {
  const GraphPath(this.nodeIds, this.cost);

  final List<String> nodeIds;

  /// Suma de los pesos de las aristas recorridas.
  final double cost;
}

/// Búsqueda A* sobre el grafo de navegación de un piso.
///
/// La lista de adyacencia se construye una sola vez por instancia, así que
/// conviene reutilizar el mismo buscador para varias consultas del mismo grafo.
///
/// La heurística es la distancia euclidiana escalada por la menor razón
/// `peso / longitud` de las aristas del grafo; así nunca sobreestima el costo
/// real y el camino devuelto es siempre el de menor peso, aunque los pesos del
/// JSON no coincidan exactamente con la geometría.
class AStarRouteFinder {
  AStarRouteFinder(this.graph, {this.accessibleOnly = false}) {
    _buildAdjacency();
  }

  final MapNavigationGraph graph;

  /// Si es `true`, se descartan las aristas que tocan nodos de escalera.
  final bool accessibleOnly;

  final Map<String, List<_Neighbor>> _adjacency = {};
  double _heuristicScale = 1;

  /// Atajo equivalente a `AStarRouteFinder.findShortestPath` de Kotlin.
  static List<String> findShortestPath(
    MapNavigationGraph graph,
    String startNodeId,
    String destinationNodeId, {
    bool accessibleOnly = false,
  }) =>
      AStarRouteFinder(graph, accessibleOnly: accessibleOnly)
          .findPath(startNodeId, destinationNodeId)
          ?.nodeIds ??
      const [];

  void _buildAdjacency() {
    final nodes = graph.nodesById;
    var scale = double.infinity;
    for (final edge in graph.edges) {
      final from = nodes[edge.from];
      final to = nodes[edge.to];
      if (from == null || to == null || !(edge.weight > 0)) continue;
      if (accessibleOnly && (from.isStairs || to.isStairs)) continue;

      _adjacency.putIfAbsent(edge.from, () => []).add(_Neighbor(edge.to, edge.weight));
      _adjacency.putIfAbsent(edge.to, () => []).add(_Neighbor(edge.from, edge.weight));

      final length = _distance(from, to);
      if (length > 0) scale = math.min(scale, edge.weight / length);
    }
    _heuristicScale = scale.isFinite ? math.min(scale, 1.0) : 0;
  }

  /// Camino de menor costo entre dos nodos, o `null` si no existe.
  GraphPath? findPath(String startNodeId, String destinationNodeId) {
    final nodes = graph.nodesById;
    final start = nodes[startNodeId];
    final goal = nodes[destinationNodeId];
    if (start == null || goal == null) return null;
    if (startNodeId == destinationNodeId) return GraphPath([startNodeId], 0);

    double h(MapNavigationNode n) => _distance(n, goal) * _heuristicScale;

    final open = _MinHeap()..push(_Candidate(startNodeId, 0, h(start)));
    final costFromStart = <String, double>{startNodeId: 0};
    final previous = <String, String>{};
    final closed = <String>{};

    while (open.isNotEmpty) {
      final current = open.pop();
      if (!closed.add(current.nodeId)) continue;
      if (current.nodeId == destinationNodeId) {
        return GraphPath(
          _reconstruct(previous, destinationNodeId),
          current.cost,
        );
      }

      for (final neighbor in _adjacency[current.nodeId] ?? const <_Neighbor>[]) {
        if (closed.contains(neighbor.nodeId)) continue;
        final nextCost = current.cost + neighbor.weight;
        if (nextCost < (costFromStart[neighbor.nodeId] ?? double.infinity)) {
          costFromStart[neighbor.nodeId] = nextCost;
          previous[neighbor.nodeId] = current.nodeId;
          open.push(_Candidate(
            neighbor.nodeId,
            nextCost,
            nextCost + h(nodes[neighbor.nodeId]!),
          ));
        }
      }
    }
    return null;
  }

  static double _distance(MapNavigationNode a, MapNavigationNode b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static List<String> _reconstruct(Map<String, String> previous, String end) {
    final path = <String>[end];
    var current = end;
    while (previous.containsKey(current)) {
      current = previous[current]!;
      path.add(current);
    }
    return path.reversed.toList(growable: false);
  }
}

class _Neighbor {
  const _Neighbor(this.nodeId, this.weight);
  final String nodeId;
  final double weight;
}

class _Candidate {
  const _Candidate(this.nodeId, this.cost, this.estimatedTotal);
  final String nodeId;
  final double cost;
  final double estimatedTotal;

  /// Ordena por `f = g + h`, desempatando por menor `g`.
  bool operator <(_Candidate other) =>
      estimatedTotal < other.estimatedTotal ||
      (estimatedTotal == other.estimatedTotal && cost < other.cost);
}

/// Montículo binario mínimo (Dart core no incluye cola de prioridad).
class _MinHeap {
  final List<_Candidate> _items = [];

  bool get isNotEmpty => _items.isNotEmpty;

  void push(_Candidate item) {
    _items.add(item);
    var i = _items.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (!(_items[i] < _items[parent])) break;
      _swap(i, parent);
      i = parent;
    }
  }

  _Candidate pop() {
    final top = _items.first;
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = l + 1;
        var smallest = i;
        if (l < _items.length && _items[l] < _items[smallest]) smallest = l;
        if (r < _items.length && _items[r] < _items[smallest]) smallest = r;
        if (smallest == i) break;
        _swap(i, smallest);
        i = smallest;
      }
    }
    return top;
  }

  void _swap(int a, int b) {
    final t = _items[a];
    _items[a] = _items[b];
    _items[b] = t;
  }
}
