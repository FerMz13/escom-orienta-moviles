/// Modelos del catálogo institucional (trámites, servicios y apoyos).
///
/// Portados desde `domain/institutional/InstitutionalModels.kt`.
library;

/// Taxonomía institucional. Una ubicación o un enlace es una propiedad del
/// recurso, nunca un tipo.
enum ResourceType {
  procedure,
  service,
  support,
  information;

  static ResourceType? tryParse(String? value) {
    switch ((value ?? '').trim().toUpperCase()) {
      case 'PROCEDURE':
        return procedure;
      case 'SERVICE':
        return service;
      case 'SUPPORT':
        return support;
      case 'INFORMATION':
        return information;
      default:
        return null;
    }
  }
}

/// Arquetipo de presentación del recurso.
enum InstitutionalArchetype {
  /// Trámites administrativos (bajas, constancias, credencial, boleta).
  procedure,

  /// Servicios e instalaciones continuas (biblioteca, médico, orientación).
  facilityService,

  /// Actividades deportivas y talleres culturales.
  workshopActivity,

  /// Becas y apoyos estudiantiles.
  scholarship;

  static InstitutionalArchetype? tryParse(String? value) {
    switch ((value ?? '').trim().toUpperCase()) {
      case 'PROCEDURE':
        return procedure;
      case 'FACILITY_SERVICE':
        return facilityService;
      case 'WORKSHOP_ACTIVITY':
        return workshopActivity;
      case 'SCHOLARSHIP':
        return scholarship;
      default:
        return null;
    }
  }

  /// Arquetipo por defecto a partir del tipo y la categoría.
  static InstitutionalArchetype fromType(ResourceType type, String category) {
    switch (type) {
      case ResourceType.procedure:
        return procedure;
      case ResourceType.support:
        return scholarship;
      case ResourceType.service:
        final c = category.trim().toUpperCase();
        return c == 'CULTURA' || c == 'DEPORTE' ? workshopActivity : facilityService;
      case ResourceType.information:
        return facilityService;
    }
  }
}

enum InstitutionalResourceCapability {
  showSummary,
  showFullInformation,
  showRequirements,
  showSteps,
  showSchedule,
  showLocation,
  showRoute,
  openExternalLink,
}

class ResourceStep {
  const ResourceStep({required this.order, required this.title, this.description = ''});
  final int order;
  final String title;
  final String description;
}

class ResourceLocation {
  const ResourceLocation({this.mapLocationId, required this.displayName});

  /// ID de un lugar de `places_*.json`, o `null` si no está en el mapa.
  final String? mapLocationId;
  final String displayName;
}

class ResourceSource {
  const ResourceSource({required this.title, this.url});
  final String title;
  final String? url;
}

class ResourceDocument {
  const ResourceDocument({
    this.id,
    required this.name,
    this.required = false,
    this.description = '',
    this.type,
    this.url,
  });
  final String? id;
  final String name;
  final bool required;
  final String description;
  final String? type;
  final String? url;
}

class ResourceEstimatedTime {
  const ResourceEstimatedTime({
    required this.type,
    required this.displayText,
    this.official = false,
    this.basis,
  });
  final String type;
  final String displayText;
  final bool official;
  final String? basis;
}

class ResourceTracking {
  const ResourceTracking({required this.available, this.steps = const [], this.notes = const []});
  final bool available;
  final List<ResourceStep> steps;
  final List<String> notes;
}

class ResourceChannel {
  const ResourceChannel({
    required this.id,
    required this.type,
    required this.name,
    this.recommended = false,
    this.url,
    this.requirements = const [],
    this.documents = const [],
    this.estimatedTime,
    this.steps = const [],
    this.tracking,
    this.notes = const [],
    this.variant,
    this.paymentDetails = const [],
  });
  final String id;
  final String type;
  final String name;
  final bool recommended;
  final String? url;
  final List<String> requirements;
  final List<ResourceDocument> documents;
  final ResourceEstimatedTime? estimatedTime;
  final List<ResourceStep> steps;
  final ResourceTracking? tracking;
  final List<String> notes;
  final String? variant;
  final List<String> paymentDetails;
}

class ResourceAction {
  const ResourceAction({required this.id, required this.name, required this.type, required this.url});
  final String id;
  final String name;
  final String type;
  final String url;
}

class ResourceContact {
  const ResourceContact({
    required this.name,
    this.role,
    this.phone,
    this.extension,
    this.email,
    this.shift,
    this.schedule,
  });
  final String name;
  final String? role;
  final String? phone;
  final String? extension;
  final String? email;
  final String? shift;
  final String? schedule;
}

class ResourceOffering {
  const ResourceOffering({
    required this.id,
    required this.type,
    required this.name,
    this.description = '',
    this.instructor,
    this.variants = const [],
    this.divisions = const [],
    this.topics = const [],
    this.schedule = const [],
    this.contacts = const [],
    this.location,
    this.cost,
    this.confidential,
    this.documents = const [],
    this.actions = const [],
    this.searchTargets = const [],
    this.url,
  });
  final String id;
  final String type;
  final String name;
  final String description;
  final String? instructor;
  final List<String> variants;
  final List<String> divisions;
  final List<String> topics;
  final List<String> schedule;
  final List<ResourceContact> contacts;
  final ResourceLocation? location;
  final String? cost;
  final bool? confidential;
  final List<ResourceDocument> documents;
  final List<ResourceAction> actions;
  final List<String> searchTargets;
  final String? url;
}

class ResourceAvailability {
  const ResourceAvailability({this.active, required this.displayText, this.notes = const []});
  final bool? active;
  final String displayText;
  final List<String> notes;
}

class ResourceApplicationProcess {
  const ResourceApplicationProcess({
    required this.platformName,
    this.platformUrl,
    this.steps = const [],
    this.recommendations = const [],
  });
  final String platformName;
  final String? platformUrl;
  final List<ResourceStep> steps;
  final List<String> recommendations;
}

class ResourceScholarshipType {
  const ResourceScholarshipType({
    required this.id,
    required this.name,
    this.requirements = const [],
    this.requirementsStatus,
  });
  final String id;
  final String name;
  final List<String> requirements;
  final String? requirementsStatus;
}

class ResourceFaq {
  const ResourceFaq({required this.question, required this.answer});
  final String question;
  final String answer;
}

class ResourcePeriod {
  const ResourcePeriod({
    this.type = 'ACADEMIC_CALENDAR_WINDOW',
    required this.description,
    this.warning,
  });
  final String type;
  final String description;
  final String? warning;
}

class ResourceServiceRule {
  const ResourceServiceRule({
    this.id,
    required this.type,
    required this.description,
    this.maxDurationMinutes,
    this.minPeople,
    this.maxPeople,
  });
  final String? id;
  final String type;
  final String description;
  final int? maxDurationMinutes;
  final int? minPeople;
  final int? maxPeople;
}

class ResourceSubService {
  const ResourceSubService({
    required this.id,
    required this.name,
    this.description = '',
    this.rules,
    this.capacity,
    this.maxDurationMinutes,
  });
  final String id;
  final String name;
  final String description;
  final String? rules;
  final String? capacity;
  final int? maxDurationMinutes;
}

/// Recurso del catálogo institucional.
class InstitutionalResource {
  InstitutionalResource({
    required this.id,
    required this.type,
    required this.category,
    required this.name,
    this.shortDescription = '',
    this.description = '',
    this.aliases = const [],
    this.keywords = const [],
    this.audience = const [],
    this.requirements = const [],
    this.documents = const [],
    this.steps = const [],
    this.location,
    this.schedule,
    this.cost,
    this.notes = const [],
    this.sources = const [],
    this.lastReviewed,
    this.channels = const [],
    this.offerings = const [],
    this.contact,
    this.actions = const [],
    this.availability,
    this.applicationProcess,
    this.scholarshipTypes = const [],
    this.resourceDocuments = const [],
    InstitutionalArchetype? archetype,
    this.period,
    this.serviceRules = const [],
    this.subServices = const [],
    this.faqs = const [],
  }) : archetype = archetype ?? InstitutionalArchetype.fromType(type, category);

  /// ID estable; nunca se muestra al usuario.
  final String id;
  final ResourceType type;
  final String category;
  final String name;
  final String shortDescription;
  final String description;
  final List<String> aliases;
  final List<String> keywords;
  final List<String> audience;
  final List<String> requirements;

  /// Documentos en texto legible (`nombre — descripción`).
  final List<String> documents;
  final List<ResourceStep> steps;
  final ResourceLocation? location;
  final String? schedule;
  final String? cost;
  final List<String> notes;
  final List<ResourceSource> sources;
  final String? lastReviewed;
  final List<ResourceChannel> channels;
  final List<ResourceOffering> offerings;
  final ResourceContact? contact;
  final List<ResourceAction> actions;
  final ResourceAvailability? availability;
  final ResourceApplicationProcess? applicationProcess;
  final List<ResourceScholarshipType> scholarshipTypes;

  /// Documentos estructurados (con URL, si la tienen).
  final List<ResourceDocument> resourceDocuments;
  final InstitutionalArchetype archetype;
  final ResourcePeriod? period;
  final List<ResourceServiceRule> serviceRules;
  final List<ResourceSubService> subServices;
  final List<ResourceFaq> faqs;

  /// Todos los `mapLocationId` del recurso (principal y de sus ofertas).
  Iterable<String> get mapLocationIds sync* {
    if (location?.mapLocationId case final id?) yield id;
    for (final offering in offerings) {
      if (offering.location?.mapLocationId case final id?) yield id;
    }
  }

  /// Capacidades derivadas solo de los datos canónicos del catálogo.
  Set<InstitutionalResourceCapability> get supportedCapabilities {
    final result = <InstitutionalResourceCapability>{
      InstitutionalResourceCapability.showSummary,
      InstitutionalResourceCapability.showFullInformation,
    };
    if (requirements.isNotEmpty ||
        documents.isNotEmpty ||
        channels.any((c) => c.requirements.isNotEmpty || c.documents.isNotEmpty) ||
        scholarshipTypes.any((s) => s.requirements.isNotEmpty)) {
      result.add(InstitutionalResourceCapability.showRequirements);
    }
    if (steps.isNotEmpty ||
        channels.any((c) => c.steps.isNotEmpty) ||
        (applicationProcess?.steps.isNotEmpty ?? false)) {
      result.add(InstitutionalResourceCapability.showSteps);
    }
    if ((schedule?.trim().isNotEmpty ?? false) ||
        offerings.any((o) => o.schedule.isNotEmpty)) {
      result.add(InstitutionalResourceCapability.showSchedule);
    }
    if (location?.mapLocationId != null) {
      result
        ..add(InstitutionalResourceCapability.showLocation)
        ..add(InstitutionalResourceCapability.showRoute);
    }
    if (actions.isNotEmpty ||
        channels.any((c) => c.url != null) ||
        resourceDocuments.any((d) => d.url != null) ||
        offerings.any((o) =>
            o.url != null ||
            o.actions.isNotEmpty ||
            o.documents.any((d) => d.url != null))) {
      result.add(InstitutionalResourceCapability.openExternalLink);
    }
    return result;
  }

  @override
  String toString() => 'InstitutionalResource($id)';
}
