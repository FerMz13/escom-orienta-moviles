import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../navigation/app_routes.dart';
import '../auth/auth_controller.dart';
import '../common/common_widgets.dart';
import '../providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    final alias = ref.watch(localSettingsProvider).value?.sanitizedUserAlias ?? 'Alumno';
    final greetingName = user == null ? alias : user.fullName.trim().split(RegExp(r'\s+')).first;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                Image.asset('assets/images/escom_logo.png', height: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ESCOM Orienta', style: theme.textTheme.titleLarge),
                      Text('¡Bienvenido, $greetingName!',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Ajustes',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push(AppRoutes.settings),
                ),
                IconButton(
                  tooltip: 'Mi perfil',
                  icon: const Icon(Icons.account_circle_outlined),
                  onPressed: () => context.push(AppRoutes.profile),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _NextClassCard(),
            const SectionTitle('Accesos rápidos', icon: Icons.bolt),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _QuickAccess(
                  icon: Icons.map,
                  title: 'Mapa de ESCOM',
                  subtitle: 'Busca salones y traza rutas',
                  onTap: () => context.go(AppRoutes.map),
                ),
                _QuickAccess(
                  icon: Icons.calendar_month,
                  title: 'Mi horario',
                  subtitle: 'Carga tu PDF del SAES',
                  onTap: () => context.go(AppRoutes.schedule),
                ),
                _QuickAccess(
                  icon: Icons.description,
                  title: 'Trámites',
                  subtitle: 'Constancias, bajas, credencial',
                  onTap: () => context.go(AppRoutes.procedures),
                ),
                _QuickAccess(
                  icon: Icons.local_library,
                  title: 'Biblioteca',
                  subtitle: 'Ver en el mapa',
                  onTap: () => context.go(AppRoutes.mapFor(placeId: 'biblioteca')),
                ),
              ],
            ),
            const SectionTitle('Lugares frecuentes', icon: Icons.place),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (id, label) in const [
                  ('gestion_escolar', 'Gestión Escolar'),
                  ('servicio_medico', 'Servicio médico'),
                  ('auditorio', 'Auditorio'),
                  ('entrada_principal', 'Entrada principal'),
                ])
                  ActionChip(
                    avatar: const Icon(Icons.place_outlined, size: 18),
                    label: Text(label),
                    onPressed: () => context.go(AppRoutes.mapFor(placeId: id)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Clase en curso o la siguiente del día.
class _NextClassCard extends ConsumerWidget {
  const _NextClassCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final schedule = ref.watch(activeScheduleProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: schedule.when(
          loading: () => const SizedBox(height: 72, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('No se pudo leer el horario: $e'),
          data: (schedule) {
            if (schedule == null || schedule.classes.isEmpty) {
              return _CardContent(
                label: 'SIN HORARIO',
                title: 'Agrega tus materias para ver aquí tu próxima clase.',
                actionLabel: 'Cargar horario',
                onAction: () => context.go(AppRoutes.schedule),
              );
            }
            final minutes = now.hour * 60 + now.minute;
            final today = [...schedule.classes.where((c) => c.dayOfWeek == now.weekday)]
              ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
            final current = today.where((c) => c.startMinutes <= minutes && c.endMinutes > minutes).firstOrNull;
            final next = today.where((c) => c.startMinutes > minutes).firstOrNull;
            final session = current ?? next;
            if (session == null) {
              return _CardContent(
                label: 'HOY',
                title: today.isEmpty ? 'No tienes clases hoy.' : 'Terminaste tus clases de hoy.',
                actionLabel: 'Ver horario',
                onAction: () => context.go(AppRoutes.schedule),
              );
            }
            final detail = [
              '${session.startTime} - ${session.endTime}',
              if (session.classroomName != null) 'Salón ${session.classroomName}',
              if (current != null) 'termina en ${session.endMinutes - minutes} min'
              else 'empieza en ${session.startMinutes - minutes} min',
            ].join(' · ');
            return _CardContent(
              label: current != null ? 'EN CURSO AHORA' : 'PRÓXIMA CLASE',
              title: session.subjectName,
              detail: detail,
              actionLabel: session.classroomName == null ? 'Ver horario' : 'Cómo llegar',
              onAction: () async {
                final classroom = session.classroomName;
                if (classroom == null) return context.go(AppRoutes.schedule);
                final place = await ref.read(placeForClassroomProvider(classroom).future);
                if (!context.mounted) return;
                if (place == null) {
                  showSnack(context, 'No se ubica el salón $classroom dentro del mapa de ESCOM.');
                } else {
                  context.go(AppRoutes.mapFor(placeId: place.id, route: true));
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.label,
    required this.title,
    this.detail,
    required this.actionLabel,
    required this.onAction,
  });

  final String label;
  final String title;
  final String? detail;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onColor = theme.colorScheme.onPrimaryContainer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: onColor, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(title, style: theme.textTheme.titleMedium?.copyWith(color: onColor)),
        if (detail != null) ...[
          const SizedBox(height: 4),
          Text(detail!, style: theme.textTheme.bodyMedium?.copyWith(color: onColor)),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ),
      ],
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const Spacer(),
              Text(title, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
