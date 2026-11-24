import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Origen de la imagen de avatar.
enum AvatarSource { camera, gallery }

/// Integración con hardware (RF3): captura de foto con la cámara o selección
/// desde la galería para el avatar del perfil.
///
/// La imagen elegida se copia al almacenamiento privado de la app para que
/// persista aunque el archivo temporal original se borre.
class AvatarImageService {
  AvatarImageService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pick(AvatarSource source) async {
    final picked = await _picker.pickImage(
      source: source == AvatarSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return _persist(picked);
  }

  Future<String> _persist(XFile picked) async {
    final dir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory(p.join(dir.path, 'avatars'));
    if (!await avatarsDir.exists()) await avatarsDir.create(recursive: true);
    final ext = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
    final dest = p.join(avatarsDir.path, 'avatar_${DateTime.now().millisecondsSinceEpoch}$ext');
    await File(picked.path).copy(dest);
    return dest;
  }
}
