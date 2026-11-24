# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

ESCOM Orienta Móviles is a Flutter/Dart app for students of ESCOM-IPN: indoor building navigation with optimal routing, SAES schedule import from PDF, and an offline catalog of procedures/services/scholarships. It is a full port of an original Kotlin/Room Android app, deliberately **without any chatbot or AI module**. Source comments are in Spanish and frequently reference the original Kotlin files they were ported from (e.g. `PdfScheduleProcessor.kt`).

## Commands

```bash
flutter pub get                 # install dependencies
flutter run                     # run on connected device/emulator
flutter analyze                 # lint (flutter_lints; android/ ios/ build/ excluded)
flutter test                    # run all tests (~68 tests under test/)
flutter test test/domain/a_star_route_finder_test.dart   # run one file
flutter test --name "substring" # run tests whose name matches
flutter build apk               # build Android release

# Drift code generation — REQUIRED after editing any table/DAO (see below)
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch     # regenerate on save while developing
```

Android build requires **Android SDK Platform 37** (`compileSdk = 37`), JDK 17, and core library desugaring (needed by `flutter_local_notifications`).

## Critical conventions

- **UI imports `package:material_ui/material_ui.dart`, never `package:flutter/material.dart`.** `material_ui` is a pub.dev package that re-exports Flutter Material; all 14 UI files use it. Match this when adding files.
- **Drift uses committed code generation.** `*.g.dart` files (e.g. `app_database.g.dart`, DAO `.g.dart`) are checked in. After changing `lib/data/database/tables.dart`, any DAO, or `@DriftDatabase`, you must re-run `build_runner` or the build breaks. `schemaVersion` is 1 with no migrations yet — bump it and add a migration when changing the schema.
- Foreign keys are enabled per-connection via `PRAGMA foreign_keys = ON` in the migration `beforeOpen` (SQLite defaults them off); cascade delete of class sessions depends on it.

## Architecture

Clean Architecture in three layers under `lib/`, with `main.dart` as entry point (wraps the app in a Riverpod `ProviderScope`):

- **`domain/`** — pure Dart, no Flutter/data dependencies: entities, the A* algorithm, schedule conflict detection, text normalization. Testable in isolation.
- **`data/`** — repositories, Drift database/DAOs, the PDF pipeline, and asset JSON parsers. Implements domain interfaces.
- **`ui/`** — screens (home, map, schedule, procedures) and widgets. `ui/providers.dart` is the single Riverpod DI file.
- **`navigation/`** — `go_router` config.

**Dependency injection:** All repositories/services are Riverpod providers in [lib/ui/providers.dart](lib/ui/providers.dart). Tests override them via `ProviderScope(overrides: [...])`. Key seams for testing without Flutter: `MapRepository({AssetTextLoader? loader})` injects a fake asset loader instead of `rootBundle`; `AppDatabase([QueryExecutor? executor])` accepts `NativeDatabase.memory()`.

**Navigation:** Four bottom-tab branches via `StatefulShellRoute.indexedStack` (state preserved across tabs). Cross-screen navigation uses query params, e.g. the home "Cómo llegar" button routes to `/mapa?lugar=<placeId>&ruta=1`; the map route's `ValueKey(state.uri)` forces a rebuild so a new target applies even if the map tab was already open.

### Routing engine (map)
- Map data lives in `assets/maps/` as three JSON files per floor (`places_`, `navigation_`, `accesos_`) for floors `pb`, `p1`, `p2`. `MapRepository` loads and caches all floors once (`ensureLoaded()`).
- `AStarRouteFinder` ([lib/domain/navigation/a_star_route_finder.dart](lib/domain/navigation/a_star_route_finder.dart)) is pure Dart A* over a per-floor graph, with its own binary min-heap. The heuristic is Euclidean distance scaled by the graph's smallest `weight/length` ratio so it never overestimates (admissible) even when JSON weights don't match geometry. `accessibleOnly` drops edges touching stair nodes.
- `DefaultRouteCalculationService` ([lib/data/map/default_route_calculation_service.dart](lib/data/map/default_route_calculation_service.dart)) orchestrates: same-floor runs A* between candidate door nodes; multi-floor tries each stair connector present on all traversed floors and keeps the cheapest, optimizing each leg independently. A place connects to the graph via explicit access points (`accesos_<floor>.json`), else its `navigationNodeId`, else the nearest corridor node. Accessible routing across floors fails by design (no elevator/ramp data).

### Schedule PDF pipeline (`lib/data/schedule/pdf/`)
`PdfScheduleProcessor.process(bytes, fileName)` is the entry point and is fully offline. Pipeline: `SyncfusionPdfTextExtractor` → `ScheduleParser` → `ScheduleNormalizer` → dedup (`preferSessionsWithClassroom` keeps the room-bearing copy of duplicate sessions) → status classification (`complete` / `partialRooms` / `noRoomsPublished`). The active schedule fully replaces any previous one on import.

### Institutional catalog (`lib/data/institutional/`, `assets/institutional/`)
Offline, read from `manifest.json` + per-resource JSON under `academic/` and `services/`. `InstitutionalMapActionValidator` checks whether a resource's map link points to a real place id (constructed with the loaded `MapRepository`) so the UI can show "map" vs "external instance".

## Testing notes
Tests mirror the layer structure (`test/domain/`, `test/data/`, `test/widget_test.dart`). Domain and data tests run without a device by injecting the fake loader / in-memory database described above. The algorithm tests (A*, route service, conflict detector) are the regression safety net for the port — keep them green when touching routing or schedule logic.
