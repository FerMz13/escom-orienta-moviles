import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/institutional/institutional_models.dart';
import '../../domain/text/text_normalization.dart';
import '../../navigation/app_routes.dart';
import '../common/common_widgets.dart';
import '../providers.dart';

/// Filtro por tipo; los apoyos (becas) se muestran aparte de los servicios.
enum _Filter {
  all('Todos', null),
  procedures('Trámites', ResourceType.procedure),
  services('Servicios', ResourceType.service),
  support('Becas y apoyos', ResourceType.support);

  const _Filter(this.label, this.type);
  final String label;
  final ResourceType? type;
}

IconData resourceIcon(InstitutionalResource r) => switch (r.archetype) {
      InstitutionalArchetype.procedure => Icons.assignment_outlined,
      InstitutionalArchetype.scholarship => Icons.school_outlined,
      InstitutionalArchetype.workshopActivity => Icons.sports_soccer_outlined,
      InstitutionalArchetype.facilityService => Icons.support_agent_outlined,
    };

class ProceduresScreen extends ConsumerStatefulWidget {
  const ProceduresScreen({super.key});

  @override
  ConsumerState<ProceduresScreen> createState() => _ProceduresScreenState();
}

class _ProceduresScreenState extends ConsumerState<ProceduresScreen> {
  final _query = TextEditingController();
  _Filter _filter = _Filter.all;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<InstitutionalResource> _visible(List<InstitutionalResource> all) {
    final needle = normalizeForSearch(_query.text);
    return [
      for (final r in all)
        if ((_filter.type == null || r.type == _filter.type) &&
            r.type != ResourceType.information &&
            (needle.isEmpty ||
                [r.name, r.shortDescription, r.category, ...r.aliases, ...r.keywords]
                    .any((t) => normalizeForSearch(t).contains(needle))))
          r,
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Widget build(BuildContext context) {
    final resources = ref.watch(institutionalResourcesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Trámites y servicios')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar: constancia, beca, biblioteca…',
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Borrar',
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(_query.clear),
                      ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final f in _Filter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(f.label),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncValueView(
              value: resources,
              onRetry: () => ref.invalidate(institutionalResourcesProvider),
              data: (all) {
                final visible = _visible(all);
                if (visible.isEmpty) {
                  return const EmptyState(icon: Icons.search_off, title: 'Sin resultados');
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final r = visible[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: Icon(resourceIcon(r), color: Theme.of(context).colorScheme.primary),
                        title: Text(r.name),
                        subtitle: r.shortDescription.isEmpty
                            ? null
                            : Text(r.shortDescription, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go(AppRoutes.procedure(r.id)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
