# YO FREE-LANCER — Flutter App

Plataforma freelance para México. Flutter + Supabase + MVVM + Riverpod.

---

## 🚀 Setup en 5 pasos

### 1. Crear proyecto en Supabase
1. Ve a [supabase.com](https://supabase.com) → New project
2. Copia tu **Project URL** y **anon key** (Settings → API)

### 2. Ejecutar el schema SQL
1. En Supabase → **SQL Editor → New Query**
2. Pega el contenido de `supabase_schema.sql` y ejecuta

### 3. Crear Storage Buckets
En Supabase → **Storage → New Bucket**, crea estos 3 (marca como Public):
- `profile-images`
- `service-images`
- `cover-images`

### 4. Configurar credenciales
Edita `lib/app/config/supabase_config.dart`:

```dart
static const String supabaseUrl     = 'https://TU_PROYECTO.supabase.co';
static const String supabaseAnonKey = 'TU_ANON_KEY_AQUI';
```

### 5. Instalar y correr
```bash
flutter pub get
flutter run
```

---

## 🔀🪪 Proyectos relacionados (backend propio + verificación facial)

Estos dos servicios son **proyectos separados, en sus propios repos Git** — no viven dentro de este repo, se despliegan por su cuenta:

- **`yofreelancer-backend`** — backend Node/Express + Prisma/Postgres, standalone, con su propia autenticación. Alternativa a Supabase para auth/perfil/"proyectos" (servicios), elegida en tiempo de build (ver `docs/BACKEND_CONFIG.md`). Ver el `README.md` de ese repo para levantarlo.
- **`yofreelancer-kyc-service`** — microservicio Python (FastAPI + DeepFace) que compara la selfie con la identificación oficial en el registro (ver `docs/KYC.md`). La app lo llama directo, nunca a través del backend Node. Ver el `README.md` de ese repo para levantarlo.

El registro de usuarios queda gateado por KYC (`docs/KYC.md`) sin importar qué backend esté activo — `yofreelancer-kyc-service` debe estar corriendo para poder completar el registro.

```bash
# Modo Supabase (default) + KYC
flutter run --dart-define=KYC_SERVICE_URL=http://localhost:8000

# Modo backend propio + KYC
flutter run \
  --dart-define=BACKEND_MODE=own_backend \
  --dart-define=NODE_BACKEND_URL=http://localhost:4000 \
  --dart-define=KYC_SERVICE_URL=http://localhost:8000
```

---

## 📁 Estructura del proyecto

```
lib/
├── main.dart                         # Entrada principal
├── app/
│   ├── config/
│   │   └── supabase_config.dart      # URLs y credenciales Supabase
│   ├── di/
│   │   └── injection.dart            # Inyección de dependencias (GetIt)
│   └── router/
│       └── app_router.dart           # GoRouter con guards de auth
├── shared/
│   ├── theme/
│   │   └── app_theme.dart            # Material3 dark/light theme
│   ├── widgets/
│   │   └── main_scaffold.dart        # BottomNav + widgets reutilizables
│   └── dto/
│       ├── user_dto.dart             # DTO ↔ Entity User
│       └── service_dto.dart          # DTO ↔ Entity Service/Booking/Payment
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/          # Supabase auth calls
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/user_entity.dart
│   │   │   └── repositories/auth_repository.dart
│   │   └── presentation/
│   │       ├── viewmodels/auth_viewmodel.dart
│   │       └── screens/              # Splash, Welcome, Login, Register
│   ├── services/
│   │   ├── data/datasources/         # CRUD servicios en Supabase
│   │   ├── domain/entities/          # ServiceEntity + enums
│   │   └── presentation/
│   │       ├── viewmodels/service_viewmodel.dart
│   │       └── screens/              # ServiceDetail, CreateService
│   ├── bookings/
│   │   ├── data/datasources/         # Reservas + Realtime
│   │   └── presentation/
│   │       ├── viewmodels/
│   │       └── screens/booking_detail_screen.dart
│   ├── payments/
│   │   ├── data/datasources/         # Pagos + Tarjetas
│   │   └── presentation/
│   │       └── screens/payment_screen.dart
│   ├── yoer/presentation/screens/    # YoerHome, Vitrina, Profile
│   └── client/presentation/screens/  # ClientHome, Bookings, Profile
```

---

## 🏗️ Arquitectura

```
UI (Screens)
    ↓
ViewModel (Riverpod StateNotifier)
    ↓
DataSource (Supabase calls)
    ↓
Supabase (PostgreSQL + Auth + Storage + Realtime)
```

**Patrones usados:**
- **MVVM** — ViewModel separa lógica de UI
- **Repository pattern** — abstracción de fuente de datos
- **DTO pattern** — mapeo JSON ↔ Domain Entity
- **Dependency Injection** — GetIt + Riverpod providers

---

## 🔑 Autenticación

Supabase maneja auth con PKCE flow. Al registrarse:
1. Supabase crea el usuario en `auth.users`
2. Un trigger SQL crea automáticamente el perfil en `public.profiles`
3. El token se almacena de forma segura en `flutter_secure_storage`

---

## 📊 Base de datos (tablas principales)

| Tabla | Descripción |
|-------|-------------|
| `profiles` | Usuarios (extiende auth.users) |
| `freelancer_profiles` | Datos extra de YOERs |
| `services` | Servicios publicados |
| `bookings` | Reservas con Realtime |
| `payments` | Historial de pagos |
| `payment_cards` | Tarjetas guardadas |
| `reviews` | Reseñas con trigger de rating |
| `badges` | Insignias de YOERs |
| `sanctions` | Sanciones |
| `urgent_tasks` | Tareas urgentes |
| `categories` | Catálogo de categorías |
| `kyc_verifications` | Auditoría (no biométrica) de verificaciones faciales |

---

## 🎨 Tema

El app usa **Material Design 3** con paleta personalizada:

| Color | Uso |
|-------|-----|
| `#32B354` | Brand green (primario) |
| `#121513` | Background dark |
| `#1E231F` | Surface dark |
| `#27302A` | Card dark |
| `#E9F2EB` | Texto primario dark |
| `#8EA990` | Texto secundario dark |

Tipografía: **Space Grotesk** (Google Fonts)

---

## 🔌 Dependencias clave

| Package | Uso |
|---------|-----|
| `supabase_flutter` | Backend completo |
| `flutter_riverpod` | State management MVVM |
| `go_router` | Navegación declarativa |
| `get_it` | Inyección de dependencias |
| `google_fonts` | Space Grotesk |
| `cached_network_image` | Caché de imágenes |
| `image_picker` | Selección de fotos |
| `geolocator` | Ubicación |
| `intl` | Formato de fechas |
| `uuid` | Generación de IDs |

---

## 🧪 Credenciales de prueba

Después de ejecutar el schema, puedes registrar usuarios desde la app.
O crear uno manualmente en Supabase → Authentication → Users.

---

## 📱 Plataformas soportadas

- ✅ Android (API 21+)
- ✅ iOS (13+)

---

## ⚙️ Permisos requeridos

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>Para subir foto de perfil</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Para encontrar servicios cercanos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Para seleccionar imágenes</string>
```

---

## 🚧 TODO / Próximas features

- [ ] Chat en tiempo real (Supabase Realtime)
- [ ] Mapa con servicios cercanos (flutter_map)
- [ ] Notificaciones push (Supabase Edge Functions)
- [ ] Pago con Stripe (flutter_stripe)
- [ ] Ranking semanal de YOERs
- [ ] Tareas urgentes con radar
- [ ] Sistema de reseñas completo
- [ ] Panel de ganancias con gráficas (fl_chart)

---

## 📚 Documentación adicional

- `AUDIT.md` — auditoría de arquitectura y riesgos previa a las Tareas 1-3
- `SECURITY_REPORT.md` — hardening de seguridad: qué se corrigió y qué queda pendiente
- `docs/BACKEND_CONFIG.md` — cómo elegir Supabase o backend propio, y por qué es un switch manual sin failover automático
- `docs/KYC.md` — diseño y limitaciones de la verificación facial

---

## 📄 Licencia

Proyecto académico — Universidad Politécnica de Chiapas (UPCh)
