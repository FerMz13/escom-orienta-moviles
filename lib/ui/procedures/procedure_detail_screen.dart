import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/institutional/institutional_map_action_validator.dart';
import '../../domain/institutional/institutional_models.dart';
import '../../navigation/app_routes.dart';
import '../common/common_widgets.dart';
import '../providers.dart';

class ProcedureDetailScreen extends ConsumerWidget {
  const ProcedureDetailScreen({super.key, required this.resourceId});
  final String resourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resources = ref.watch(institutionalResourcesProvider);
    final resource = resources.value?.where((r) => r.id == resourceId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(resource?.name ?? 'Trámite')),
      body: AsyncValueView(
        value: resources,
        data: (_) => resource == null
            ? const EmptyState(icon: Icons.search_off, title: 'No se encontró el trámite')
            : _Detail(resource: resource),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.resource});
  final InstitutionalResource resource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final r = resource;
    final validation = ref.watch(mapActionValidatorProvider).value?.validate(r);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        if (r.shortDescription.isNotEmpty)
          Text(r.shortDescription, style: theme.textTheme.titleSmall),
        if (r.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(r.description),
        ],
        if (r.availability case final a?) ...[
          const SizedBox(height: 12),
          _InfoCard(
            icon: a.active == false ? Icons.event_busy : Icons.event_available,
            title: a.displayText,
            lines: a.notes,
          ),
        ],
        if (r.period case final p?) ...[
          const SizedBox(height: 12),
          _InfoCard(icon: Icons.date_range, title: p.description, lines: [?p.warning]),
        ],
        if (r.location case final location?) ...[
          const SectionTitle('Ubicación', icon: Icons.place_outlined),
          Text(location.displayName),
          const SizedBox(height: 8),
          switch (validation) {
            MapActionValidation.valid => Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () =>
                      context.go(AppRoutes.mapFor(placeId: location.mapLocationId, route: true)),
                  icon: const Icon(Icons.directions_walk),
                  label: const Text('Cómo llegar'),
                ),
              ),
            MapActionValidation.offCampus => Text(
                'Este trámite se realiza fuera de ESCOM.',
                style: theme.textTheme.bodySmall,
              ),
            _ => const SizedBox.shrink(),
          },
        ],
        if (r.schedule != null) ...[
          const SectionTitle('Horario', icon: Icons.schedule),
          Text(r.schedule!),
        ],
        if (r.cost != null) ...[
          const SectionTitle('Costo', icon: Icons.payments_outlined),
          Text(r.cost!),
        ],
        if (r.requirements.isNotEmpty) ...[
          const SectionTitle('Requisitos', icon: Icons.checklist),
          BulletList(r.requirements),
        ],
        if (r.documents.isNotEmpty) ...[
          const SectionTitle('Documentos', icon: Icons.folder_outlined),
          BulletList(r.documents),
        ],
        if (r.steps.isNotEmpty) ...[
          const SectionTitle('Pasos', icon: Icons.format_list_numbered),
          _Steps(r.steps),
        ],
        for (final channel in r.channels) _ChannelCard(channel),
        if (r.applicationProcess case final process?) ...[
          SectionTitle('Solicitud en ${process.platformName}', icon: Icons.laptop),
          _Steps(process.steps),
          BulletList(process.recommendations),
          if (process.platformUrl != null) _LinkButton('Abrir plataforma', process.platformUrl!),
        ],
        if (r.scholarshipTypes.isNotEmpty) ...[
          const SectionTitle('Modalidades', icon: Icons.school_outlined),
          for (final s in r.scholarshipTypes)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(s.name),
              subtitle: s.requirementsStatus == null ? null : Text(s.requirementsStatus!),
              children: [BulletList(s.requirements)],
            ),
        ],
        if (r.serviceRules.isNotEmpty) ...[
          const SectionTitle('Reglas del servicio', icon: Icons.rule),
          BulletList([for (final rule in r.serviceRules) rule.description]),
        ],
        if (r.subServices.isNotEmpty) ...[
          const SectionTitle('Servicios disponibles', icon: Icons.category_outlined),
          for (final s in r.subServices)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.name),
              subtitle: Text([
                if (s.description.isNotEmpty) s.description,
                ?s.capacity,
                ?s.rules,
              ].join('\n')),
            ),
        ],
        if (r.offerings.isNotEmpty) ...[
          const SectionTitle('Actividades y opciones', icon: Icons.event_note),
          for (final o in r.offerings) _OfferingTile(o),
        ],
        if (r.contact case final c?) ...[
          const SectionTitle('Contacto', icon: Icons.contact_phone_outlined),
          _ContactText(c),
        ],
        if (r.notes.isNotEmpty) ...[
          const SectionTitle('Notas', icon: Icons.info_outline),
          BulletList(r.notes),
        ],
        if (r.faqs.isNotEmpty) ...[
          const SectionTitle('Preguntas frecuentes', icon: Icons.help_outline),
          for (final f in r.faqs)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(f.question),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              childrenPadding: const EdgeInsets.only(bottom: 12),
              children: [Text(f.answer)],
            ),
        ],
        if (r.actions.isNotEmpty) ...[
          const SectionTitle('Enlaces', icon: Icons.link),
          for (final a in r.actions) _LinkButton(a.name, a.url),
        ],
        if (r.sources.isNotEmpty) ...[
          const SectionTitle('Fuentes oficiales', icon: Icons.verified_outlined),
          for (final s in r.sources)
            s.url == null ? Text(s.title) : _LinkButton(s.title, s.url!),
        ],
        if (r.lastReviewed != null) ...[
          const SizedBox(height: 16),
          Text('Información revisada: ${r.lastReviewed}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ],
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps(this.steps);
  final List<ResourceStep> steps;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final step in steps)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 14, child: Text('${step.order}', style: const TextStyle(fontSize: 13))),
              title: Text(step.title),
              subtitle: step.description.isEmpty ? null : Text(step.description),
            ),
        ],
      );
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard(this.channel);
  final ResourceChannel channel;

  @override
  Widget build(BuildContext context) {
    final c = channel;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: ExpansionTile(
          initiallyExpanded: c.recommended,
          shape: const Border(),
          leading: Icon(c.recommended ? Icons.star : Icons.alt_route),
          title: Text(c.name),
          subtitle: Text([
            if (c.recommended) 'Recomendado',
            ?c.estimatedTime?.displayText,
          ].join(' · ')),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            if (c.requirements.isNotEmpty) ...[
              const SectionTitle('Requisitos'),
              BulletList(c.requirements),
            ],
            if (c.documents.isNotEmpty) ...[
              const SectionTitle('Documentos'),
              BulletList([
                for (final d in c.documents) '${d.name}${d.required ? '' : ' (opcional)'}',
              ]),
            ],
            if (c.paymentDetails.isNotEmpty) ...[
              const SectionTitle('Pago'),
              BulletList(c.paymentDetails),
            ],
            if (c.steps.isNotEmpty) ...[
              const SectionTitle('Pasos'),
              _Steps(c.steps),
            ],
            if (c.tracking case final t? when t.available) ...[
              const SectionTitle('Seguimiento'),
              _Steps(t.steps),
              BulletList(t.notes),
            ],
            if (c.notes.isNotEmpty) BulletList(c.notes),
            if (c.url != null) _LinkButton('Abrir enlace oficial', c.url!),
          ],
        ),
      ),
    );
  }
}

class _OfferingTile extends StatelessWidget {
  const _OfferingTile(this.offering);
  final ResourceOffering offering;

  @override
  Widget build(BuildContext context) {
    final o = offering;
    final placeId = o.location?.mapLocationId;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(o.name),
      subtitle: o.schedule.isEmpty ? null : Text(o.schedule.join('\n')),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [
        if (o.description.isNotEmpty) Text(o.description),
        if (o.instructor != null) Text('Imparte: ${o.instructor}'),
        if (o.cost != null) Text('Costo: ${o.cost}'),
        if (o.topics.isNotEmpty) BulletList(o.topics),
        for (final c in o.contacts) _ContactText(c),
        if (o.location != null) Text('Lugar: ${o.location!.displayName}'),
        if (placeId != null)
          TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => context.go(AppRoutes.mapFor(placeId: placeId, route: true)),
            icon: const Icon(Icons.place_outlined),
            label: const Text('Ver en el mapa'),
          ),
        for (final a in o.actions) _LinkButton(a.name, a.url),
        if (o.url != null) _LinkButton('Más información', o.url!),
      ],
    );
  }
}

class _ContactText extends StatelessWidget {
  const _ContactText(this.contact);
  final ResourceContact contact;

  @override
  Widget build(BuildContext context) {
    final c = contact;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text([
        c.name,
        ?c.role,
        if (c.phone != null) 'Tel. ${c.phone}${c.extension == null ? '' : ' ext. ${c.extension}'}',
        ?c.email,
        ?c.shift,
        ?c.schedule,
      ].where((s) => s.trim().isNotEmpty).join('\n')),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, this.lines = const []});
  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(title), for (final l in lines) Text(l, style: Theme.of(context).textTheme.bodySmall)],
                ),
              ),
            ],
          ),
        ),
      );
}

class _LinkButton extends StatelessWidget {
  const _LinkButton(this.label, this.url);
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () async {
            final uri = Uri.tryParse(url);
            final opened = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (!opened && context.mounted) showSnack(context, 'No se pudo abrir el enlace.');
          },
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(label, textAlign: TextAlign.start),
        ),
      );
}
