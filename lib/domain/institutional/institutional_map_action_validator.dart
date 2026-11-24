import 'institutional_models.dart';

enum MapActionValidation {
  /// El `mapLocationId` existe en el mapa.
  valid,

  /// El `mapLocationId` no corresponde a ningún lugar del mapa.
  invalidLocationId,

  /// El trámite se realiza fuera del plantel (p. ej. en la DAE).
  offCampus,

  /// El recurso no tiene ubicación en el mapa.
  noMapLocation,
}

/// Comprueba si existe un lugar del mapa con ese ID.
typedef MapPlaceExists = bool Function(String placeId);

/// Una referencia a un lugar del mapa que no existe.
class InvalidMapReference {
  const InvalidMapReference({
    required this.resourceId,
    required this.mapLocationId,
    this.offeringId,
  });

  final String resourceId;
  final String mapLocationId;

  /// `null` si la referencia es la ubicación principal del recurso.
  final String? offeringId;

  @override
  String toString() =>
      '$resourceId${offeringId == null ? '' : '/$offeringId'} → $mapLocationId';
}

/// Valida que las ubicaciones del catálogo apunten a lugares reales del mapa.
class InstitutionalMapActionValidator {
  const InstitutionalMapActionValidator(this._placeExists);

  final MapPlaceExists _placeExists;

  MapActionValidation validate(InstitutionalResource resource) {
    final id = resource.location?.mapLocationId;
    if (id == null) {
      final displayName = resource.location?.displayName.toUpperCase() ?? '';
      return displayName.contains('DAE')
          ? MapActionValidation.offCampus
          : MapActionValidation.noMapLocation;
    }
    return _placeExists(id)
        ? MapActionValidation.valid
        : MapActionValidation.invalidLocationId;
  }

  bool isValid(String? locationId) =>
      locationId != null && _placeExists(locationId);

  /// Revisa la ubicación principal y la de cada oferta de todos los recursos.
  List<InvalidMapReference> audit(Iterable<InstitutionalResource> resources) => [
        for (final resource in resources) ...[
          if (resource.location?.mapLocationId case final id? when !_placeExists(id))
            InvalidMapReference(resourceId: resource.id, mapLocationId: id),
          for (final offering in resource.offerings)
            if (offering.location?.mapLocationId case final id? when !_placeExists(id))
              InvalidMapReference(
                resourceId: resource.id,
                mapLocationId: id,
                offeringId: offering.id,
              ),
        ],
      ];
}
