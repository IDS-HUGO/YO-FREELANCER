# AUDIT.md — YO FREE-LANCER

Auditoría técnica previa a las Tareas 1-3 (respaldo de Supabase, verificación facial, hardening de seguridad). Generada leyendo el código real del repo, no por inferencia.

## 1. Stack confirmado

- **Frontend**: Flutter (Dart). Sin frontend web/JS separado.
- **Backend**: 100% Supabase (Postgres + Auth + Storage + Realtime). No existe ningún servidor propio (Node/Express/Python) en el repo, ni siquiera parcial o abandonado.
- **Cliente Supabase**: `supabase_flutter: ^2.3.4`. Un único cliente (`Supabase.instance.client`), inicializado una vez en `main.dart`. No hay `createClient()` disperso.
- **Estado**: `flutter_riverpod ^2.5.1` (StateNotifier hand-written, no `riverpod_generator` pese a estar como dependencia). También está `provider: ^6.1.2` como dependencia, pero no se usa en paralelo de forma relevante — parece redundante.
- **DI**: `get_it ^9.2.1` en `lib/app/di/injection.dart`, solo para 4 features (`auth`, `services`, `bookings`, `payments`). `injectable` está en pubspec pero sin anotaciones — no se usa codegen.
- **Routing**: `go_router ^17.3.0`, instancia única vía `appRouterProvider`.
- **Networking crudo**: `dio` y `http` están en pubspec pero **no se usan** — todo pasa por el SDK de `supabase_flutter`.
- **Formularios**: `reactive_forms` y `form_field_validator` están en pubspec pero **no se usan** — los formularios son `Form`/`TextFormField` con validadores inline.
- **Imágenes**: `image_picker`, `image_cropper`, `photo_view`. **No hay `camera`, ni ninguna librería de detección facial/ML** (ni ML Kit, ni TFLite, ni face_recognition). Verificación facial se construiría desde cero.
- **Pagos**: `flutter_stripe` está declarado pero **no se usa en ningún archivo** (`grep -rn "Stripe" lib/` → 0 resultados). El feature de pagos es autoatestiguado por el cliente (ver riesgos).
- **Tests**: no existe carpeta `test/`. Cero cobertura pese a tener `mockito`/`flutter_test`/`build_runner` como dev deps.
- **CI**: no existe `.github/workflows` para este proyecto (solo hay un directorio `.github/modernize/java-upgrade/` de otra automatización no relacionada). `flutter analyze` es el único chequeo disponible y no corre automáticamente en ningún lado.

## 2. Puntos de llamada directa al SDK de Supabase

Solo 4 de ~14 features pasan por GetIt + una interfaz `Repository` (`AuthRepository` es la única con implementación real; `services`/`bookings`/`payments` tienen datasource registrado en GetIt pero sin interfaz repository). El resto (`notifications`, `sanctions`, `tasks/radar`, `community`, `badges`, `artist`, `volunteering`, `ranking`, `wallet`) instancian su `*RemoteDataSource` directamente con `Supabase.instance.client` dentro del provider de Riverpod, duplicando el wiring que ya hace GetIt para las otras 4.

Tablas/operaciones cubiertas (ver detalle completo en el historial de exploración): `profiles`, `services`, `bookings`, `payments`, `payment_cards` (nombre hardcodeado, no en `SupabaseConfig`), `notifications`, `sanctions`, `sanction_appeals`, `support_requests`, `urgent_tasks`, `task_requests`, `task_applications`, `wallet_accounts`, `wallet_transactions`, `badge_catalog`, `badges`, `community_events`, `volunteering_events`, `volunteering_participants`, `artist_profiles`. Storage: `profile-images`, `service-images` (no se encontró uso de `cover-images` en el código pese a existir el bucket).

## 3. Flujo de registro actual

`RegisterScreen` (`lib/features/auth/presentation/screens/register_screen.dart`) recoge: nombre completo, username, email, teléfono (opcional), password, confirmación, y tipo de usuario (YOER/CLIENT). **No sube foto, selfie ni identificación** — la foto de perfil se sube después, como acción separada desde `edit_profile_screen.dart`.

Flujo: `RegisterScreen` → `AuthViewModel.register()` → `AuthRepositoryImpl` → `AuthRemoteDataSource.signUp()` → `_client.auth.signUp(...)` con metadata (`username`, `full_name`, `user_type`, `phone_number`) → espera fija de 500ms → lee el perfil (creado por trigger). `signIn()` sí reintenta hasta 3 veces con backoff por si el trigger tarda; `signUp()` no.

Trigger `handle_new_user()` (SECURITY DEFINER, `supabase_schema.sql:186-205`) crea la fila en `public.profiles` desde `raw_user_meta_data` tras el INSERT en `auth.users`. RLS de `profiles`: SELECT público, INSERT/UPDATE solo `auth.uid() = id`.

Validación de password: solo longitud ≥ 6 en cliente, sin regla de complejidad, y sin verificación server-side adicional.

## 4. Riesgos ya detectados (antes de tocar nada)

| Riesgo | Nivel | Detalle |
|---|---|---|
| `categories` sin RLS habilitado | Medio | Única tabla del schema sin `enable row level security`, inconsistente con el resto |
| Políticas de storage `service-images`/`cover-images` sin scoping por dueño | Alto | Cualquier usuario autenticado puede subir/borrar objetos en cualquier ruta de esos buckets; la propiedad solo se respeta en la UI, no en la base de datos (el propio schema lo reconoce en un comentario, línea 1418) |
| Sin validación de tipo/tamaño de archivo antes de subir imágenes | Medio-Alto | `uploadProfileImage`/`uploadServiceImage` suben lo que sea sin whitelist de extensión/MIME ni límite de tamaño |
| Feature de pagos autoatestiguado | Alto | El cliente inserta directamente una fila en `payments` con `status: 'PAGADO'` y actualiza `bookings.payment_status` sin ninguna pasarela real ni verificación externa; `flutter_stripe` está declarado pero no integrado |
| Cero pruebas automatizadas y sin CI | Medio | Cualquier regresión en auth/RLS/pagos se detecta solo manualmente |
| Inconsistencia arquitectónica (repository layer parcial) | Bajo | No es un riesgo de seguridad, pero complica mantenimiento y aumenta probabilidad de bugs futuros |
| Dependencias declaradas pero sin uso (`dio`, `http`, `reactive_forms`, `form_field_validator`, `flutter_stripe`, `provider`) | Bajo | Superficie de auditoría/paquete innecesaria |
| `freelancer_profiles` tabla muerta (con RLS, sin código que la use) | Bajo | Feature incompleta/abandonada en el schema |
| Sin verificación de identidad en registro | — | Esperado hoy (no es un bug), es el objetivo de la Tarea 2 |
| Anon key hardcodeada en `supabase_config.dart` | Bajo (esperado) | Es el patrón correcto para la anon key protegida por RLS; no hay `service_role` key expuesta en ningún lado del cliente. Sí falta una estrategia de `.env`/secrets para cuando se añada backend propio (Tarea 1) |

Ninguna `service_role` key ni secreto de pago está expuesta en el código actual.

## 5. Qué falta para las tareas siguientes

- **Tarea 1** necesita decidir arquitectura (ver propuesta de opciones aparte) — hoy no existe ningún backend propio ni capa adapter; todo el código llama Supabase directo o casi directo.
- **Tarea 2** parte de cero: no hay librería de cámara/ML en el proyecto ni endpoint de verificación. Se necesita elegir proveedor/enfoque (ver propuesta de opciones aparte).
- **Tarea 3** tiene objetivos concretos ya identificados arriba (RLS de `categories`, storage policies de `service-images`/`cover-images`, validación de uploads, rate limiting en login, headers, etc.) que se pueden abordar de forma incremental sin depender de decisiones de arquitectura de las Tareas 1 y 2.
