import 'package:material_ui/material_ui.dart';

import '../../domain/map/map_models.dart';
import '../../domain/text/text_normalization.dart';

String floorLabel(String floorId) => floorId == 'PB' ? 'Planta baja' : 'Piso $floorId';

/// Busca lugares en todos los pisos por nombre, código o alias, sin importar
/// acentos ni mayúsculas.
List<MapPlace> searchPlaces(List<MapPlace> places, String query) {
  final needle = normalizeForSearch(query);
  if (needle.isEmpty) return const [];
  final scored = <(int, MapPlace)>[];
  for (final place in places) {
    final name = normalizeForSearch(place.name);
    final code = place.roomNumber ?? '';
    final aliases = place.aliases.map(normalizeForSearch);
    final score = code == needle || name == needle
        ? 0
        : code.startsWith(needle) || name.startsWith(needle)
            ? 1
            : aliases.any((a) => a == needle)
                ? 2
                : name.contains(needle) || aliases.any((a) => a.contains(needle))
                    ? 3
                    : -1;
    if (score >= 0) scored.add((score, place));
  }
  scored.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2.name.compareTo(b.$2.name));
  return [for (final (_, place) in scored) place];
}

class PlaceSearchDelegate extends SearchDelegate<MapPlace?> {
  PlaceSearchDelegate(this.places) : super(searchFieldLabel: 'Salón, laboratorio, servicio…');

  final List<MapPlace> places;

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(tooltip: 'Borrar', icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(tooltip: 'Regresar', icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    if (query.trim().isEmpty) {
      return const ListTile(
        leading: Icon(Icons.info_outline),
        title: Text('Escribe un número de salón (p. ej. 2102) o el nombre de un lugar.'),
      );
    }
    final results = searchPlaces(places, query);
    if (results.isEmpty) {
      return const ListTile(leading: Icon(Icons.search_off), title: Text('Sin coincidencias'));
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final place = results[index];
        return ListTile(
          leading: const Icon(Icons.place_outlined),
          title: Text(place.name),
          subtitle: Text('${place.type.displayName} · ${floorLabel(place.floorId)} · ${place.building}'),
          onTap: () => close(context, place),
        );
      },
    );
  }
}
