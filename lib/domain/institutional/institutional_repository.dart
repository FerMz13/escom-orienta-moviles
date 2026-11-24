import 'institutional_models.dart';

abstract interface class InstitutionalRepository {
  Future<List<InstitutionalResource>> getAll();
  Future<InstitutionalResource?> getById(String id);
  Future<List<InstitutionalResource>> getByCategory(String category);

  /// Búsqueda por nombre, descripción corta, alias y palabras clave, sin
  /// distinguir acentos ni mayúsculas.
  Future<List<InstitutionalResource>> search(String query);
}
