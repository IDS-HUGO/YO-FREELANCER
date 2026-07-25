# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

YO FREE-LANCER — a Flutter app connecting freelancers ("YOERs") with clients in Mexico. Backend is entirely Supabase (Postgres + Auth + Storage + Realtime), no custom server. UI copy, error messages, and comments are in Spanish; keep new user-facing strings and comments consistent with that.

## Commands

```bash
flutter pub get                    # install dependencies
flutter run                        # run on connected device/emulator
flutter analyze                    # static analysis (uses analysis_options.yaml)
flutter test                       # run tests (no test/ directory exists yet)
flutter test test/some_test.dart   # run a single test file
dart run build_runner build --delete-conflicting-outputs   # regenerate *.g.dart / *.freezed.dart
```

There is no CI config, lint-staged, or Makefile in this repo — `flutter analyze` is the only automated check currently wired up.

## Backend setup

Supabase project credentials live in `lib/app/config/supabase_config.dart` (URL, anon key, table names, storage bucket names, Edge Function names, Realtime channel names). The full schema (tables, triggers, RLS policies) is in `supabase_schema.sql` at the repo root — check it before assuming a column/table exists or adding a new query. Storage buckets (`profile-images`, `service-images`, `cover-images`) must be created manually in the Supabase dashboard and marked public.

Auth uses Supabase's PKCE flow. On sign-up, a Postgres trigger auto-creates the row in `public.profiles`; the client never inserts into `profiles` directly on registration.

## Architecture

Layered MVVM, organized by feature under `lib/features/<feature>/`:

```
UI (Screens, presentation/screens/)
    ↓ watches/reads
ViewModel (Riverpod StateNotifier, presentation/viewmodels/)
    ↓ calls
Repository (domain/repositories/ interface + data/repositories/ impl)  — only some features have this layer
    ↓ calls
RemoteDataSource (data/datasources/, raw supabase_flutter calls)
    ↓
Supabase (Postgres + Auth + Storage + Realtime)
```

Not every feature has the full stack: `auth` has repository + datasource + domain entity; `services`, `bookings`, `payments` currently skip the repository interface and call their `*RemoteDataSource` directly from the ViewModel/DI. Follow whatever pattern the feature you're touching already uses rather than introducing a repository layer for features that don't have one, unless asked to.

Each feature's data flows through a **DTO** in `lib/shared/dto/` (e.g. `user_dto.dart`, `service_dto.dart`) that handles `fromJson`/`toJson` (snake_case ↔ camelCase) and a `toEntity()` conversion to the plain `domain/entities/*_entity.dart` class used everywhere else in the app. Entities are the type ViewModels and UI work with; DTOs never leak past the datasource/repository boundary.

### Dependency injection

`lib/app/di/injection.dart` uses **GetIt** as a service locator for the data layer only (SupabaseClient, RemoteDataSources, Repository impls) — registered as singletons in `configureDependencies()`, called once in `main()` before `runApp`. **Riverpod** providers (in each feature's `*_viewmodel.dart`) then wrap the GetIt-resolved repository/datasource for use in the widget tree. When adding a new feature's datasource, register it in `injection.dart` following the existing pattern, then expose it to widgets via a Riverpod provider in that feature's viewmodel file.

### Routing (`lib/app/router/app_router.dart`)

Single `GoRouter` instance created once via `appRouterProvider` (a `Provider`, read with `ref.read` — never `ref.watch` — so the router itself is never rebuilt). Auth-based redirects are handled by GoRouter's `redirect` callback, refreshed via a `ChangeNotifier` (`_RouterNotifier`) that listens to `authViewModelProvider` and calls `notifyListeners()` on change. When adding routes:
- Add the path constant to `lib/app/router/app_routes.dart` first.
- YOER-only and CLIENT-only routes go inside the respective `ShellRoute` (adds the `MainScaffold` bottom nav); shared routes (service detail, booking detail, payment) are top-level `GoRoute`s outside any shell.
- The `redirect` logic in `app_router.dart` enforces role separation (YOER vs CLIENT) — update it if a new route needs different access rules, in particular the `publicRoutes` list and the `loc.startsWith('/client')` / `/yoer` checks.

### State management

Riverpod `StateNotifier`/`StateNotifierProvider` per feature, not `riverpod_generator` codegen (despite it being a dependency) — state classes are hand-written with `copyWith`, matching `AuthState` in `auth_viewmodel.dart`. Follow that pattern (immutable state class + `copyWith` + `clearX` boolean flags for nulling optional fields) for new ViewModels rather than switching to generated notifiers.

### Theming

`lib/shared/theme/app_theme.dart` defines Material 3 light/dark themes; `main.dart` forces `ThemeMode.dark` regardless of system setting. Brand color is `#32B354` green; font is Space Grotesk via `google_fonts`.

## Known repo quirks

- Committed working tree changes may include edits to `lib/app/config/supabase_config.dart` — be careful not to accidentally revert someone's in-progress credential/config change when editing nearby files.
- `build/`, `.dart_tool/`, `android/.gradle`, `android/.kotlin` are generated Flutter/Gradle output present in the working tree; don't hand-edit anything under them.
