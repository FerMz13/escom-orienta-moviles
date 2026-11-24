import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/device/avatar_image_service.dart';
import '../../data/device/location_service.dart';
import '../../domain/auth/auth_models.dart';
import '../../navigation/app_routes.dart';
import '../auth/auth_controller.dart';
import '../common/common_widgets.dart';
import '../providers.dart';

/// Gestión de perfil (RF1): datos del usuario, avatar (cámara/galería, RF3),
/// cambio de contraseña, ubicación GPS (RF3), prueba de notificación y cierre
/// de sesión seguro.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: user == null
          ? const EmptyState(icon: Icons.person_off, title: 'Sin sesión activa')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      _Avatar(user: user),
                      const SizedBox(height: 12),
                      Text(user.fullName, style: theme.textTheme.titleLarge),
                      Text(user.email,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _changeAvatar(context, ref),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Cambiar foto'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionTitle('Cuenta', icon: Icons.manage_accounts),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('Editar nombre'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _editName(context, ref, user),
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.lock_reset),
                        title: const Text('Cambiar contraseña'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _changePassword(context, ref),
                      ),
                    ],
                  ),
                ),
                const SectionTitle('Dispositivo', icon: Icons.devices),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.my_location),
                        title: const Text('Mi ubicación (GPS)'),
                        subtitle: const Text('Muestra tus coordenadas actuales'),
                        onTap: () => _showLocation(context, ref),
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.notifications_active_outlined),
                        title: const Text('Probar notificación'),
                        onTap: () async {
                          await ref.read(notificationServiceProvider).requestPermissions();
                          await ref.read(notificationServiceProvider).showTest();
                          if (context.mounted) showSnack(context, 'Notificación enviada.');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () => _logout(context, ref),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ),
    );
  }

  Future<void> _changeAvatar(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<AvatarSource?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, AvatarSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, AvatarSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final path = await ref.read(avatarImageServiceProvider).pick(source);
      if (path == null) return;
      final result = await ref.read(authControllerProvider.notifier).updateProfile(avatarPath: path);
      if (!context.mounted) return;
      if (result case AuthFailure(:final message)) showSnack(context, message);
    } catch (e) {
      if (context.mounted) showSnack(context, 'No se pudo cambiar la foto: $e');
    }
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, UserAccount user) async {
    final controller = TextEditingController(text: user.fullName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre completo'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (newName == null) return;
    final result = await ref.read(authControllerProvider.notifier).updateProfile(fullName: newName);
    if (!context.mounted) return;
    if (result case AuthFailure(:final message)) showSnack(context, message);
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña actual'),
                validator: (v) => (v ?? '').isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                validator: AuthValidators.password,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final result = await ref.read(authControllerProvider.notifier).changePassword(
          currentPassword: current.text,
          newPassword: next.text,
        );
    if (!context.mounted) return;
    showSnack(context, switch (result) {
      AuthFailure(:final message) => message,
      _ => 'Contraseña actualizada.',
    });
  }

  Future<void> _showLocation(BuildContext context, WidgetRef ref) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final result = await ref.read(locationServiceProvider).currentPosition();
    if (!context.mounted) return;
    Navigator.pop(context); // cierra el spinner
    final message = switch (result) {
      LocationSuccess(:final latitude, :final longitude, :final accuracyMeters) =>
        'Lat: ${latitude.toStringAsFixed(5)}\nLon: ${longitude.toStringAsFixed(5)}\n'
            'Precisión: ±${accuracyMeters.toStringAsFixed(0)} m',
      LocationDenied(:final message) => message,
    };
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubicación actual'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir de tu cuenta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.login);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});
  final UserAccount user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = user.avatarPath;
    final hasImage = path != null && File(path).existsSync();
    return CircleAvatar(
      radius: 48,
      backgroundColor: theme.colorScheme.primaryContainer,
      foregroundImage: hasImage ? FileImage(File(path)) : null,
      child: hasImage
          ? null
          : Text(user.initials,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
    );
  }
}
