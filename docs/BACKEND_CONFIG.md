# 🔀 Backend configurable: Supabase o backend propio (Tarea 1)

Documenta el switch manual entre las dos fuentes de datos que puede usar la app para auth, perfil y "proyectos" (tabla `services`). **No hay failover automático, ni circuit breaker, ni detección de caídas en runtime** — el backend se elige una sola vez, al compilar la app.

## 1. Cómo funciona

```
UI (ViewModels)
    ↓
AuthRepository / ServiceRepository   (interfaces, el resto de la app no sabe cuál impl está activa)
    ↓
   elegido en tiempo de build por BackendModeConfig.current
    ├── BackendMode.supabase    → SupabaseAuthRepositoryImpl / SupabaseServiceRepositoryImpl
    └── BackendMode.ownBackend  → NodeAuthRepositoryImpl / NodeServiceRepositoryImpl
```

`lib/app/config/backend_mode.dart` define el enum `BackendMode` y lee `--dart-define=BACKEND_MODE=...` una sola vez al arrancar. `lib/app/di/injection.dart` registra la implementación correspondiente en GetIt según ese valor — sin wrapper, sin monitor de salud, sin lógica de "si falla uno, prueba el otro". Si el modo elegido no responde, la operación simplemente falla y se muestra el error al usuario, igual que cualquier llamada de red fallida.

## 2. Cómo elegir el modo

**Modo Supabase** (default, sin flags — es el comportamiento histórico de la app):

```bash
flutter run
```

**Modo backend propio**:

```bash
flutter run \
  --dart-define=BACKEND_MODE=own_backend \
  --dart-define=NODE_BACKEND_URL=https://tu-backend.example.com
```

En este modo, la app **no usa la anon key de Supabase para nada relacionado con auth/perfil/servicios** — el backend propio maneja su propia autenticación de punta a punta (registro, login, JWT propio, cambio/restablecimiento de contraseña). Ver el README del proyecto `yofreelancer-backend` (repo independiente, ver §4) para su configuración y despliegue.

## 3. Alcance (qué SÍ cambia con el switch y qué NO)

Solo **auth + perfil + "proyectos" (`services`)** respetan `BackendMode`. El resto de features (`bookings`, `payments`, `notifications`, `wallet`, `sanctions`, etc.) **siempre llaman a Supabase directamente**, sin importar el modo elegido — extender el switch a esas features es trabajo futuro, no incluido aquí. Esto significa que, en modo `own_backend`, la app sigue necesitando un proyecto Supabase configurado y corriendo para todo lo que no sea auth/perfil/servicios.

La verificación facial (KYC, ver `docs/KYC.md`) es completamente independiente de `BackendMode`: siempre se llama directo al microservicio de KYC (`yofreelancer-kyc-service`, otro proyecto separado) por su propia URL, sin importar qué backend esté activo.

## 4. Los dos backends son proyectos independientes

- **`yofreelancer-backend`** (Node/Express + Prisma/Postgres): repo Git propio, standalone, desplegable por separado. La app móvil solo lo consume por HTTP (`lib/features/auth/data/datasources/auth_node_datasource.dart`, `lib/features/services/data/datasources/service_node_datasource.dart`) — no hay ninguna otra relación de código.
- **`yofreelancer-kyc-service`** (FastAPI + DeepFace): repo Git propio, standalone, llamado directo desde la app (`lib/features/auth/data/datasources/kyc_remote_datasource.dart`).

Ninguno de los dos vive dentro de este repo. Ver el README de cada proyecto para instrucciones de arranque/despliegue.

## 5. Pruebas

- `test/app/config/backend_mode_test.dart` — la función pura `parseBackendMode()` y el default de `BackendModeConfig.current` sin `--dart-define`.
- `test/features/auth/auth_node_datasource_test.dart` y `test/features/services/service_node_datasource_test.dart` — confirman que, en modo backend propio, los datasources hablan correctamente el contrato HTTP esperado (usando un adaptador Dio falso, sin necesitar el backend real corriendo).
- El modo Supabase reutiliza `AuthRemoteDataSource`/`ServiceRemoteDataSource`, que ya eran el código de producción existente antes de esta tarea — no se agregó cobertura nueva ahí porque no cambió su comportamiento.
- Para probar el flujo completo con el backend propio real corriendo: `flutter test --dart-define=BACKEND_MODE=own_backend` (con `yofreelancer-backend` levantado en local) o correr la app con `flutter run --dart-define=BACKEND_MODE=own_backend`.
