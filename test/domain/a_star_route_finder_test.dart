import 'package:escom_orienta_moviles/domain/map/map_models.dart';
import 'package:escom_orienta_moviles/domain/navigation/a_star_route_finder.dart';
import 'package:flutter_test/flutter_test.dart';

MapNavigationNode node(String id, double x, double y,
        [MapNavigationNodeType type = MapNavigationNodeType.path]) =>
    MapNavigationNode(id: id, x: x, y: y, type: type);

MapNavigationEdge edge(String from, String to, double weight) =>
    MapNavigationEdge(from: from, to: to, weight: weight);

MapNavigationGraph graph(
  List<MapNavigationNode> nodes,
  List<MapNavigationEdge> edges,
) =>
    MapNavigationGraph(
      floorId: 'PB',
      coordinateWidth: 1260,
      coordinateHeight: 1600,
      mapWidth: 1260,
      mapHeight: 1600,
      nodes: nodes,
      edges: edges,
    );

void main() {
  group('AStarRouteFinder', () {
    test('elige la ruta de menor peso', () {
      final g = graph(
        [node('A', 0, 0), node('B', 1, 0), node('C', 0, 2)],
        [edge('A', 'B', 1), edge('B', 'C', 1), edge('A', 'C', 5)],
      );
      expect(AStarRouteFinder.findShortestPath(g, 'A', 'C'), ['A', 'B', 'C']);
      expect(AStarRouteFinder(g).findPath('A', 'C')!.cost, 2);
    });

    test('devuelve vacío si los nodos están desconectados', () {
      final g = graph([node('A', 0, 0), node('B', 1, 0)], []);
      expect(AStarRouteFinder.findShortestPath(g, 'A', 'B'), isEmpty);
    });

    test('las aristas son bidireccionales', () {
      final g = graph(
        [node('A', 0, 0), node('B', 10, 0)],
        [edge('A', 'B', 10)],
      );
      expect(AStarRouteFinder.findShortestPath(g, 'B', 'A'), ['B', 'A']);
    });

    test('origen igual a destino', () {
      final g = graph([node('A', 0, 0)], []);
      expect(AStarRouteFinder(g).findPath('A', 'A')!.nodeIds, ['A']);
    });

    test('nodo inexistente devuelve null', () {
      final g = graph([node('A', 0, 0)], []);
      expect(AStarRouteFinder(g).findPath('A', 'Z'), isNull);
    });

    test('ignora aristas con peso no positivo o nodos desconocidos', () {
      final g = graph(
        [node('A', 0, 0), node('B', 1, 0), node('C', 2, 0)],
        [edge('A', 'C', 0), edge('A', 'X', 1), edge('A', 'B', 1), edge('B', 'C', 1)],
      );
      expect(AStarRouteFinder.findShortestPath(g, 'A', 'C'), ['A', 'B', 'C']);
    });

    test('sigue siendo óptimo si los pesos son menores que la geometría', () {
      // Con heurística euclidiana pura, A* llegaría por A-C (peso 100)
      // antes de explorar el desvío barato por B.
      final g = graph(
        [node('A', 0, 0), node('B', 0, 500), node('C', 100, 0)],
        [edge('A', 'C', 100), edge('A', 'B', 1), edge('B', 'C', 1)],
      );
      final path = AStarRouteFinder(g).findPath('A', 'C')!;
      expect(path.nodeIds, ['A', 'B', 'C']);
      expect(path.cost, 2);
    });

    test('modo accesible evita escaleras', () {
      final g = graph(
        [
          node('A', 0, 0),
          node('S', 5, 0, MapNavigationNodeType.stairs),
          node('B', 10, 0),
          node('C', 5, 10),
        ],
        [edge('A', 'S', 5), edge('S', 'B', 5), edge('A', 'C', 12), edge('C', 'B', 12)],
      );
      expect(AStarRouteFinder.findShortestPath(g, 'A', 'B'), ['A', 'S', 'B']);
      expect(
        AStarRouteFinder.findShortestPath(g, 'A', 'B', accessibleOnly: true),
        ['A', 'C', 'B'],
      );
    });
  });
}
