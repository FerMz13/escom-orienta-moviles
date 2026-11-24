import 'dart:convert';

import '../../domain/institutional/institutional_models.dart';

/// Error de esquema en un recurso institucional.
class InstitutionalFormatException extends FormatException {
  const InstitutionalFormatException(super.message);
}

/// Parser del catálogo institucional, portado de `InstitutionalJsonParser.kt`.
///
/// Es tolerante con campos opcionales y nombres alternativos (`title`,
/// `summary`, `workflowSteps`…), pero rechaza recursos sin `id`/`name`, pasos
/// sin orden o listas con valores vacíos.
class InstitutionalJsonParser {
  const InstitutionalJsonParser();

  /// Devuelve las rutas relativas declaradas en `manifest.json`.
  List<String> parseManifest(String source) {
    final root = _Json.decode(source);
    final schemaVersion = root.intOrNull('schemaVersion') ?? root.intOrNull('version') ?? 0;
    _require(schemaVersion > 0, 'manifest.schemaVersion debe ser mayor que cero');
    final paths = root.strings('resources').map((p) => p.replaceAll('\\', '/')).toList();
    _require(
      paths.every((p) => p.isNotEmpty && !p.startsWith('/') && !p.contains('..')),
      'manifest contiene una ruta no válida',
    );
    return paths;
  }

  InstitutionalResource parseResource(String source) =>
      _parseResource(_Json.decode(source));

  InstitutionalResource _parseResource(_Json root) {
    final id = root.string('id').trim();
    final name = (root.string('name').isNotEmpty ? root.string('name') : root.string('title')).trim();
    _require(id.isNotEmpty, 'id está vacío');
    _require(name.isNotEmpty, 'name está vacío');

    final category = root.string('category').trim();
    final parsedArchetype = InstitutionalArchetype.tryParse(root.string('archetype'));
    final type = ResourceType.tryParse(root.string('type')) ??
        switch (parsedArchetype) {
          InstitutionalArchetype.procedure => ResourceType.procedure,
          InstitutionalArchetype.facilityService => ResourceType.service,
          InstitutionalArchetype.workshopActivity => ResourceType.service,
          InstitutionalArchetype.scholarship => ResourceType.support,
          null => throw InstitutionalFormatException('type no válido: ${root.string('type')}'),
        };

    final channelObjects = root.objects('channels');
    final channels = channelObjects.map(_parseChannel).toList();
    final recommendedChannel =
        channelObjects.where((c) => c.boolOr('recommended', false)).firstOrNull;

    final rawSteps = root.arrayOrNull('workflowSteps') ??
        root.arrayOrNull('steps') ??
        recommendedChannel?.arrayOrNull('steps');
    final steps = [
      for (final item in _Json.objectsOf(rawSteps))
        () {
          final description = (item.has('description')
                  ? item.string('description')
                  : item.string('detail'))
              .trim();
          final title = item.string('title').trim();
          final effectiveTitle = title.isEmpty ? description : title;
          return ResourceStep(
            order: item.intOrNull('order') ?? item.intOrNull('step') ?? 0,
            title: effectiveTitle,
            description: effectiveTitle == description ? '' : description,
          );
        }(),
    ];
    _validateSteps(steps);
    steps.sort((a, b) => a.order.compareTo(b.order));

    final locationObj = root.objectOrNull('location');
    final directLocationId = root.optional('locationId');
    ResourceLocation? location;
    if (locationObj != null) {
      final displayName = locationObj.string('displayName').trim();
      _require(displayName.isNotEmpty, 'location.displayName está vacío');
      location = ResourceLocation(
        mapLocationId: locationObj.optional('mapLocationId'),
        displayName: displayName,
      );
    } else if (directLocationId != null) {
      location = ResourceLocation(
        mapLocationId: directLocationId,
        displayName: _readableLabel(directLocationId),
      );
    }

    final offerings = root.objects('offerings').map(_parseOffering).toList();
    final offeringSchedules = <String>{for (final o in offerings) ...o.schedule};

    return InstitutionalResource(
      id: id,
      type: type,
      category: category,
      name: name,
      shortDescription: root.string('shortDescription').isNotEmpty
          ? root.string('shortDescription')
          : root.string('summary'),
      description: root.string('description'),
      aliases: root.strings('aliases'),
      keywords: root.strings('keywords'),
      audience: root.has('audience') ? root.strings('audience') : root.strings('targetAudience'),
      requirements: root.arrayOrNull('requirements') != null
          ? root.strings('requirements')
          : root.arrayOrNull('accessRequirements') != null
              ? root.strings('accessRequirements')
              : recommendedChannel?.strings('requirements') ?? const [],
      documents: _documentNames(root.arrayOrNull('documents')),
      steps: steps,
      location: location,
      offerings: offerings,
      schedule: root.displayText('schedule') ??
          recommendedChannel?.objectOrNull('estimatedTime')?.optional('displayText') ??
          (offeringSchedules.isEmpty ? null : offeringSchedules.join(' | ')),
      cost: root.displayText('cost'),
      notes: root.strings('notes'),
      sources: [
        for (final s in root.objects('sources'))
          () {
            final title = (s.has('title') ? s.string('title') : s.string('name')).trim();
            _require(title.isNotEmpty, 'sources.title está vacío');
            return ResourceSource(title: title, url: s.optional('url'));
          }(),
      ],
      lastReviewed: root.optional('lastReviewed') ?? root.optional('lastUpdated'),
      channels: channels,
      contact: root.objectOrNull('contact')?.let(_parseContact),
      actions: root.objects('actions').map(_parseAction).toList(),
      availability: root.objectOrNull('availability')?.let(
            (a) => ResourceAvailability(
              active: a.boolOrNull('activeCall'),
              displayText: a.string('displayText'),
              notes: a.strings('notes'),
            ),
          ),
      applicationProcess: root.objectOrNull('applicationProcess')?.let((p) {
        final platform = p.objectOrNull('platform');
        return ResourceApplicationProcess(
          platformName: platform?.string('name') ?? '',
          platformUrl: platform?.optional('url'),
          steps: _parseSteps(p.arrayOrNull('steps')),
          recommendations: p.strings('recommendations'),
        );
      }),
      scholarshipTypes: [
        for (final s in root.objects('scholarshipTypes'))
          () {
            final direct = s.strings('requirements');
            final legacy = [
              for (final r in s.objects('referenceRequirements')) r.string('description'),
            ];
            return ResourceScholarshipType(
              id: s.string('id'),
              name: s.string('name'),
              requirements: direct.isNotEmpty ? direct : legacy,
              requirementsStatus: s.optional('requirementsStatus'),
            );
          }(),
      ],
      resourceDocuments: _documents(root.arrayOrNull('documents')),
      archetype: parsedArchetype,
      period: root.objectOrNull('period')?.let(
            (p) => ResourcePeriod(
              type: p.has('type') ? p.string('type') : 'ACADEMIC_CALENDAR_WINDOW',
              description: p.string('description'),
              warning: p.optional('warning'),
            ),
          ),
      serviceRules: [
        for (final r in root.objects('serviceRules'))
          ResourceServiceRule(
            id: r.optional('id'),
            type: r.string('type'),
            description: r.string('description'),
            maxDurationMinutes: r.intOrNull('maxDurationMinutes'),
            minPeople: r.intOrNull('minPeople'),
            maxPeople: r.intOrNull('maxPeople'),
          ),
      ],
      subServices: [
        for (final s in root.objects('subServices'))
          ResourceSubService(
            id: s.string('id'),
            name: s.string('name'),
            description: s.string('description'),
            rules: s.optional('rules'),
            capacity: s.optional('capacity'),
            maxDurationMinutes: s.intOrNull('maxDurationMinutes'),
          ),
      ],
      faqs: [
        for (final f in root.objects('faqs'))
          ResourceFaq(question: f.string('question'), answer: f.string('answer')),
      ],
    );
  }

  ResourceOffering _parseOffering(_Json item) {
    final contacts = item.objects('contacts').map(_parseContact).toList();
    final directSchedule = _parseOfferingSchedule(item.arrayOrNull('schedule'));
    final contactSchedules = [for (final c in contacts) ?c.schedule];
    final instructor = item.optional('instructor');
    return ResourceOffering(
      id: item.string('id'),
      type: item.string('type'),
      name: item.string('name'),
      description: item.has('description')
          ? item.string('description')
          : item.string('shortDescription'),
      instructor: instructor == null
          ? null
          : [?item.optional('instructorRole'), instructor].join(' '),
      variants: item.strings('variants'),
      divisions: item.strings('divisions'),
      topics: item.strings('topics'),
      schedule: directSchedule.isNotEmpty ? directSchedule : contactSchedules,
      contacts: contacts,
      location: item.objectOrNull('location')?.let(
            (l) => ResourceLocation(
              mapLocationId: l.optional('mapLocationId'),
              displayName: l.string('displayName'),
            ),
          ),
      cost: item.displayText('cost'),
      confidential: item.boolOrNull('confidential'),
      documents: _documents(item.arrayOrNull('documents')),
      actions: item.objects('actions').map(_parseAction).toList(),
      searchTargets: item.strings('searchTargets'),
      url: item.optional('url'),
    );
  }

  ResourceContact _parseContact(_Json item) => ResourceContact(
        name: [?item.optional('title'), ?item.optional('name')].join(' '),
        role: item.optional('role'),
        phone: item.optional('phone'),
        extension: item.optional('extension'),
        email: item.optional('email'),
        shift: item.optional('shift')?.let(_readableShift),
        schedule: item.objectOrNull('schedule')?.let(_formatSchedule),
      );

  ResourceAction _parseAction(_Json item) => ResourceAction(
        id: item.string('id'),
        name: item.string('name'),
        type: item.string('type'),
        url: item.string('url'),
      );

  List<String> _parseOfferingSchedule(List<Object?>? array) => [
        for (final item in array ?? const <Object?>[])
          if (item is String && item.trim().isNotEmpty)
            item.trim()
          else if (item is Map<String, dynamic>)
            _formatSchedule(_Json(item)),
      ];

  String _formatSchedule(_Json item) {
    final displayText = item.optional('displayText');
    if (displayText != null) return displayText;
    final rawDays = item.strings('days');
    final day = item.has('day')
        ? _readableDay(item.string('day'))
        : rawDays.isNotEmpty
            ? _formatDaysList(rawDays)
            : '';
    final times = [?item.optional('start'), ?item.optional('end')].join(' a ');
    if (day.trim().isNotEmpty && times.trim().isNotEmpty) return '$day de $times hrs';
    return day.trim().isEmpty ? times : day;
  }

  String _formatDaysList(List<String> days) {
    final normalized = days.map(_readableDay).toList();
    const weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
    if (normalized.length == 5 && weekdays.every(normalized.contains)) {
      return 'Lunes a Viernes';
    }
    return normalized.join(', ');
  }

  static String _readableDay(String value) => switch (value.trim().toUpperCase()) {
        'LUNES' => 'Lunes',
        'MARTES' => 'Martes',
        'MIERCOLES' || 'MIÉRCOLES' => 'Miércoles',
        'JUEVES' => 'Jueves',
        'VIERNES' => 'Viernes',
        'SABADO' || 'SÁBADO' => 'Sábado',
        'DOMINGO' => 'Domingo',
        _ => _capitalize(value.toLowerCase()),
      };

  static String _readableShift(String value) => switch (value.trim().toUpperCase()) {
        'MATUTINO' => 'Turno matutino',
        'VESPERTINO' => 'Turno vespertino',
        'MIXTO' => 'Turno mixto',
        _ => _capitalize(value.toLowerCase()),
      };

  ResourceChannel _parseChannel(_Json item) {
    final id = item.string('id').trim();
    final name = item.string('name').trim();
    _require(id.isNotEmpty && name.isNotEmpty, 'channels requiere id y name');
    return ResourceChannel(
      id: id,
      type: item.string('type').trim(),
      name: name,
      recommended: item.boolOr('recommended', false),
      url: item.optional('url'),
      requirements: item.strings('requirements'),
      documents: _documents(item.arrayOrNull('requiredDocuments') ?? item.arrayOrNull('documents')),
      estimatedTime: item.objectOrNull('estimatedTime')?.let(
            (t) => ResourceEstimatedTime(
              type: t.string('type'),
              displayText: t.string('displayText'),
              official: t.boolOr('official', false),
              basis: t.optional('basis'),
            ),
          ),
      steps: _parseSteps(item.arrayOrNull('steps')),
      tracking: item.objectOrNull('tracking')?.let(
            (t) => ResourceTracking(
              available: t.boolOr('available', false),
              steps: _parseSteps(t.arrayOrNull('steps')),
              notes: t.strings('notes'),
            ),
          ),
      notes: item.strings('notes'),
      variant: item.optional('variant'),
      paymentDetails: item.objectOrNull('payment')?.let(_parsePayment) ?? const [],
    );
  }

  List<String> _parsePayment(_Json payment) => [
        if (payment.optional('displayText') case final v?) 'Importe: $v',
        if (payment.optional('method') case final v?) 'Método: ${_readableLabel(v)}',
        if (payment.optional('bank') case final v?) 'Banco: $v',
        if (payment.optional('beneficiary') case final v?) 'Beneficiario: $v',
        if (payment.optional('agreement') case final v?) 'Convenio: $v',
        if (payment.optional('displayClabe') case final v?) 'CLABE: $v',
        if (payment.optional('reference') case final v?) 'Referencia: $v',
        ?payment.objectOrNull('validity')?.optional('displayText'),
        ...payment.strings('notes'),
      ];

  List<ResourceStep> _parseSteps(List<Object?>? array) {
    final steps = [
      for (final step in _Json.objectsOf(array))
        () {
          final description = step.string('description').trim();
          final title = step.string('title').trim();
          final effectiveTitle = title.isEmpty ? description : title;
          return ResourceStep(
            order: step.intOrNull('order') ?? 0,
            title: effectiveTitle,
            description: effectiveTitle == description ? '' : description,
          );
        }(),
    ];
    _validateSteps(steps);
    return steps..sort((a, b) => a.order.compareTo(b.order));
  }

  static void _validateSteps(List<ResourceStep> steps) {
    _require(
      steps.every((s) => s.order > 0 && s.title.isNotEmpty),
      'steps requiere order > 0 y title',
    );
    _require(
      steps.map((s) => s.order).toSet().length == steps.length,
      'steps contiene órdenes duplicados',
    );
  }

  static List<String> _documentNames(List<Object?>? array) => [
        for (final value in array ?? const <Object?>[])
          () {
            final text = switch (value) {
              String s => s.trim(),
              Map<String, dynamic> m => () {
                  final name = _Json(m).string('name').trim();
                  final description = _Json(m).string('description').trim();
                  return description.isEmpty ? name : '$name — $description';
                }(),
              _ => '',
            };
            _require(text.isNotEmpty, 'documents contiene un valor inválido');
            return text;
          }(),
      ];

  static List<ResourceDocument> _documents(List<Object?>? array) => [
        for (final value in array ?? const <Object?>[])
          switch (value) {
            String s => ResourceDocument(name: s),
            Map<String, dynamic> m => () {
                final doc = _Json(m);
                final name = doc.string('name').trim();
                _require(name.isNotEmpty, 'document requiere name');
                return ResourceDocument(
                  id: doc.optional('id'),
                  name: name,
                  required: doc.boolOr('required', false),
                  description: doc.string('description'),
                  type: doc.optional('type'),
                  url: doc.optional('url'),
                );
              }(),
            _ => throw const InstitutionalFormatException('document inválido'),
          },
      ];

  static String _readableLabel(String value) =>
      _capitalize(value.toLowerCase().replaceAll('_', ' '));

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  static void _require(bool condition, String message) {
    if (!condition) throw InstitutionalFormatException(message);
  }
}

/// Acceso tipado y tolerante a un objeto JSON.
class _Json {
  const _Json(this._map);

  factory _Json.decode(String source) {
    final value = jsonDecode(source);
    if (value is! Map<String, dynamic>) {
      throw const InstitutionalFormatException('La raíz debe ser un objeto JSON');
    }
    return _Json(value);
  }

  final Map<String, dynamic> _map;

  bool has(String key) => _map[key] != null;

  /// Cadena o `''` si falta o es `null`. Los números se convierten a texto.
  String string(String key) => switch (_map[key]) {
        String s => s,
        null => '',
        final other => other.toString(),
      };

  /// Cadena recortada, o `null` si falta, es `null` o queda vacía.
  String? optional(String key) {
    final value = string(key).trim();
    return value.isEmpty ? null : value;
  }

  int? intOrNull(String key) => switch (_map[key]) {
        num n => n.toInt(),
        String s => int.tryParse(s.trim()),
        _ => null,
      };

  bool? boolOrNull(String key) => switch (_map[key]) {
        bool b => b,
        _ => null,
      };

  bool boolOr(String key, bool fallback) => boolOrNull(key) ?? fallback;

  List<Object?>? arrayOrNull(String key) => switch (_map[key]) {
        List<Object?> l => l,
        _ => null,
      };

  _Json? objectOrNull(String key) => switch (_map[key]) {
        Map<String, dynamic> m => _Json(m),
        _ => null,
      };

  List<_Json> objects(String key) => objectsOf(arrayOrNull(key));

  static List<_Json> objectsOf(List<Object?>? array) => [
        for (final item in array ?? const <Object?>[])
          if (item is Map<String, dynamic>)
            _Json(item)
          else
            throw const InstitutionalFormatException('Se esperaba un objeto en la lista'),
      ];

  /// Lista de cadenas no vacías (recortadas).
  List<String> strings(String key) => [
        for (final item in arrayOrNull(key) ?? const <Object?>[])
          if (item is String && item.trim().isNotEmpty)
            item.trim()
          else
            throw InstitutionalFormatException('"$key" contiene un valor vacío o inválido'),
      ];

  /// Texto de un campo que puede ser cadena u objeto con `displayText`.
  String? displayText(String key) => switch (_map[key]) {
        null => null,
        String s => s.trim().isEmpty ? null : s.trim(),
        Map<String, dynamic> m => _Json(m).optional('displayText'),
        final other => other.toString(),
      };
}

extension<T extends Object> on T {
  R let<R>(R Function(T) transform) => transform(this);
}
