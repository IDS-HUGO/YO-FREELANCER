# Guía de Configuración y Puesta en Producción
## YO FREELANCER (Flutter + Supabase + Stripe + KYC)

Esta es la guía única y definitiva para configurar, desplegar y operar la plataforma YO FREELANCER en entornos de desarrollo, pruebas (Sandbox) y producción.

---

## 1. Configuración de Supabase (Base de Datos & Auth)

La app utiliza Supabase como backend principal (PostgreSQL, Autenticación y Storage).

### 1.1 Crear Proyecto y Obtener Credenciales
1. Entra a [supabase.com](https://supabase.com) y crea un nuevo proyecto.
2. En el panel izquierdo ve a **Project Settings** → **API**.
3. Copia la **Project URL** y la **Project API anon key**.

### 1.2 Ejecutar el Script de Base de Datos
1. En el dashboard de Supabase ve a **SQL Editor** → **New Query**.
2. Pega y ejecuta el contenido completo del archivo:
   ```text
   supabase_schema.sql
   ```
   *(Este script es idempotente: crea todas las tablas, tipos ENUM, disparadores de comisiones y políticas de seguridad RLS).*

### 1.3 Crear Storage Buckets
En **Storage** → **Create Bucket**, crea los siguientes 3 buckets marcados como **Public**:
* `profile-images`
* `service-images`
* `cover-images`

### 1.4 Configurar en el Código
Edita el archivo `lib/app/config/supabase_config.dart`:
```dart
static const String supabaseUrl     = 'https://TU_PROYECTO.supabase.co';
static const String supabaseAnonKey = 'TU_ANON_KEY_AQUI';
```

---

## 2. Configuración de Pasarela de Pagos (Stripe) y Comisiones

YO FREELANCER opera bajo el modelo **Marketplace con Pago en Garantía (Escrow)**.

### 2.1 Modelo de Comisión de la Plataforma
Por defecto, la plataforma retiene el **10% de comisión** sobre cada servicio liquidado. El 90% restante queda en custodia y se libera a la cartera del Yoer cuando el cliente confirma la finalización del trabajo.

Para modificar este porcentaje, abre `lib/app/config/payment_config.dart`:
```dart
/// Porcentaje de comisión de la plataforma (Take-Rate de intermediación).
/// 0.10 = 10%. Para cobrar 12%, ingresa 0.12.
static const double platformFeeRate = 0.10;
```

### 2.2 Configuración en Stripe Dashboard
1. Ingresa a [dashboard.stripe.com](https://dashboard.stripe.com).
2. Para pruebas, mantén activo el interruptor **"Test mode"** en la esquina superior.
3. Ve a **Connect** y activa **Stripe Connect** en modalidad **Cuentas Express** (recomendado para que Stripe gestione la verificación bancaria de los Yoers).
4. En **Desarrolladores** → **Claves de API**, copia:
   - **Clave publicable:** `pk_test_...` (o `pk_live_...` para producción).
   - **Clave secreta:** `sk_test_...`.

### 2.3 Tarjetas de Prueba Precargadas en Sandbox
En la pantalla de pago de la app puedes utilizar:
* **Aprobación Inmediata (Visa):** `4242 4242 4242 4242` | Exp: `12/28` | CVC: `123`
* **Verificación 3D Secure (Mastercard):** `4000 0000 0000 3063` | Exp: `10/27` | CVC: `456`
* **Fondos Insuficientes (Simula Rechazo):** `4000 0000 0000 0002` | Exp: `05/26` | CVC: `789`

---

## 3. Configuración de Publicidad Patrocinada (Yoer Ads)

Los Yoers pueden contratar campañas para destacar sus servicios en búsquedas y en el carrusel de recomendados.

Los paquetes están centralizados en `lib/features/services/domain/entities/ad_campaign_entity.dart`:
* **Campaña 3 Días:** \$99.00 MXN (Alcance estimado: 500 – 1,200 personas).
* **Campaña 7 Días:** \$199.00 MXN (Alcance estimado: 2,500 – 5,000 personas).
* **Campaña 15 Días:** \$399.00 MXN (Alcance estimado: 8,000 – 15,000 personas).

---

## 4. Microservicios Opcionales y Standalone

La arquitectura de YO FREELANCER es desacoplada. Existen dos servicios satélite independientes:

### 4.1 Servicio Biométrico KYC (`yofreelancer-kyc-service`)
Microservicio en Python (FastAPI + DeepFace) para verificación facial entre la selfie y la identificación oficial:
```bash
cd ../yofreelancer-kyc-service
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### 4.2 Backend Propio Node/Express (`yofreelancer-backend`)
Alternativa standalone a Supabase para autenticación y servicios:
```bash
cd ../yofreelancer-backend
npm install
npm run dev # Corre en el puerto 4000
```

---

## 5. Comandos de Ejecución y Compilación

### Ejecución en Desarrollo (Modo Sandbox Activo)
```bash
flutter pub get
flutter run
```

### Ejecución con Microservicio KYC Activo
```bash
flutter run --dart-define=KYC_SERVICE_URL=http://localhost:8000
```

### Ejecución con Backend Propio Node/Express
```bash
flutter run \
  --dart-define=BACKEND_MODE=own_backend \
  --dart-define=NODE_BACKEND_URL=http://localhost:4000
```

### Compilación para Producción (Release)
Para compilar desactivando el sandbox y conectando tu clave real de Stripe:
```bash
flutter build apk --release \
  --dart-define=PAYMENT_SANDBOX=false \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_tu_clave_real_de_stripe
```
*(Para iOS generar con `flutter build ipa --release` con los mismos parámetros).*

---

## 6. Cómo Configurar para Obtener tus Ganancias (Comisiones de Servicios y 100% de los Ads)

Esta sección explica exactamente cómo fluye el dinero hacia tu cuenta bancaria y qué debes configurar en Stripe y Supabase para asegurar tus ingresos.

### 6.1 Cómo Funciona la División del Dinero
Tu modelo de negocio genera ingresos de dos fuentes distintas:

1. **Una Parte de los Servicios (Take-Rate del 10% por defecto):**
   - Cuando un cliente paga un servicio de \$1,000 MXN con tarjeta o método digital, el dinero entra a la cuenta concentradora de tu plataforma en Stripe.
   - La plataforma retiene automáticamente el **10% (\$100 MXN)** como tu ganancia bruta por intermediación.
   - El **90% restante (\$900 MXN)** queda en depósito de garantía (Escrow) y solo se transfiere a la cuenta bancaria del Yoer una vez que el cliente confirma que el trabajo quedó terminado.

2. **100% de Ganancia Directa en Publicidad (Yoer Ads):**
   - Cuando un Yoer compra un paquete de alcance (\$99, \$199 o \$399 MXN) para aparecer en el carrusel de recomendados, ese pago entra íntegro a tu cuenta concentradora.
   - A diferencia de los servicios, **aquí no hay división con nadie: el 100% de ese dinero es utilidad directa para la plataforma** (menos la comisión de procesamiento de tarjeta de ~\$5 a \$15 pesos).

---

### 6.2 Dónde Configurar tu Cuenta Bancaria para Recibir los Fondos

1. **Configurar tu Cuenta Bancaria (CLABE) en Stripe:**
   - Inicia sesión en [https://dashboard.stripe.com](https://dashboard.stripe.com).
   - Ve a **Configuración** (ícono de engrane) → **Cuentas bancarias y programación de transferencias** (*Payout settings*).
   - Haz clic en **Añadir cuenta bancaria** e ingresa la **CLABE Interbancaria de 18 dígitos** de tu banco en México (BBVA, Santander, Banorte, Nu, etc.).
   - Configura la frecuencia de transferencias (*Payout schedule*):
     - **Diaria automática:** Todo lo que tu plataforma gane en comisiones y Ads se transfiere a tu banco cada 24 a 48 horas hábiles.
     - **Semanal:** Los días lunes o viernes.

2. **Configuración de Stripe Connect para Transferir al Yoer solo su 90%:**
   - En Stripe Dashboard ve a **Connect** → **Configuración**.
   - En **Modo de cobro**, utiliza **Destination Charges** (Cargos a destino) con el parámetro `application_fee_amount`.
   - ¿Qué hace `application_fee_amount`?
     - Si el servicio vale \$1,000 MXN (100,000 centavos), envías:
       `amount: 100000`, `application_fee_amount: 10000`.
     - Stripe se encarga de transferir los 90,000 centavos (\$900 MXN) a la cuenta Connect del Yoer y deposita los 10,000 centavos (\$100 MXN) en **tu balance disponible de plataforma**.

---

### 6.3 Dónde Ajustar los Porcentajes en el Código

Si en el futuro deseas cambiar tu porcentaje de ganancia sobre los servicios (por ejemplo, subir al 12% o 15%):
1. Abre `lib/app/config/payment_config.dart`.
2. Modifica la variable:
   ```dart
   static const double platformFeeRate = 0.10; // Cambiar a 0.12 para 12%, o 0.15 para 15%
   ```
3. Si utilizas el disparador automático de Supabase, en `supabase_schema.sql` (línea de la función `credit_wallet_on_completion`), ajusta:
   ```sql
   commission_rate constant double precision := 0.10;
   ```

---

### 6.4 Auditoría de Ganancias en Tiempo Real en Supabase

Cada comisión cobrada por servicios y cada venta de Yoer Ads queda registrada en la tabla `public.platform_revenues`.

Puedes consultar tus ganancias acumuladas en cualquier momento ejecutando esta consulta en **Supabase SQL Editor**:
```sql
-- Resumen total de ingresos de la plataforma
select 
  revenue_type as concepto,
  count(*) as total_transacciones,
  sum(gross_amount) as volumen_total_gmv,
  sum(platform_fee) as ganancia_neta_plataforma
from public.platform_revenues
group by revenue_type;
```

---

## 7. Despliegue 100% Gratuito de Todo el Ecosistema

Para arrancar sin gastar un solo peso mientras validas la tracción de mercado con los primeros miles de usuarios, puedes utilizar esta arquitectura multicapa de costo cero:

| Componente | Plataforma Recomendada | Nivel Gratuito (Free Tier) | Ventajas Clave |
| :--- | :--- | :--- | :--- |
| **Landing Page + Web App** | **Cloudflare Pages** | Ancho de banda ilimitado, sitios ilimitados | CDN global en 300+ ciudades, protección DDoS nativa de Cloudflare, 0 cold starts |
| **Base de Datos & Auth** | **Supabase Free Tier** | 500 MB Postgres, 50,000 MAU, 1 GB Storage | Pooler de conexiones (Supavisor) incluido, RLS, backups automáticos |
| **Backend API (Node)** | **Koyeb** (o Render) | 1 servicio Nano 512 MB RAM | **Koyeb no duerme por inactividad** (a diferencia de Render). HTTPS automático |
| **Microservicio KYC** | **Modo Sandbox / Oracle Free** | Sandbox $0 en app, o Oracle Always Free | En Sandbox no gasta RAM. En Oracle Cloud tienes 24 GB RAM gratis para IA |
| **Generador de APKs** | **GitHub Actions** | 2,000 minutos de compilación al mes | Compila el APK en servidores de GitHub sin gastar recursos de tu PC |

### 7.1 Despliegue de Landing Page + Web App en Cloudflare Pages
1. Sube tu carpeta `YOFreelancer-Landing` a un repositorio de GitHub (público o privado).
2. Entra a [dash.cloudflare.com](https://dash.cloudflare.com) → **Workers & Pages** → **Create application** → **Pages** → **Connect to Git**.
3. Selecciona tu repositorio `YOFreelancer-Landing`.
4. En **Build settings**:
   - Framework preset: `None`
   - Build command: *(dejar vacío)*
   - Build output directory: `/`
5. Haz clic en **Save and Deploy**. En 60 segundos tendrás tu landing y tu app corriendo en un dominio gratis tipo `yofreelancer.pages.dev` con SSL y CDN mundial.
6. Tu aplicación Flutter Web queda accesible directamente en:
   `https://tu-proyecto.pages.dev/app/`

### 7.2 Despliegue de Backend Propio en Koyeb
1. Sube la carpeta `yofreelancer-backend` a GitHub.
2. Ingresa a [app.koyeb.com](https://app.koyeb.com) y crea una cuenta gratuita.
3. Haz clic en **Create Service** → **GitHub**.
4. Selecciona tu repo `yofreelancer-backend`.
5. En variables de entorno configura:
   - `NODE_ENV=production`
   - `PORT=8000`
   - `DATABASE_URL=postgresql://postgres:[PASSWORD]@[HOST]:6543/postgres?pgbouncer=true`
   - `JWT_SECRET=[UNA_CLAVE_ALEATORIA_DE_64_CARACTERES]`
6. En build command pon `npm run build` y en run command `npm start`.
7. Koyeb te entregará una URL HTTPS fija y segura (ejemplo: `https://yofreelancer-api-tunombre.koyeb.app`).

### 7.3 Despliegue de Base de Datos en Supabase
1. Tu proyecto gratuito de Supabase te otorga Postgres + Auth + Storage.
2. **Evitar que Supabase congele el proyecto por inactividad:** En el tier gratuito, si un proyecto no recibe peticiones en 7 días, se pausa. Para que **NUNCA** se pause:
   - Crea una cuenta gratis en [cron-job.org](https://cron-job.org) o [uptimerobot.com](https://uptimerobot.com).
   - Crea un ping HTTP cada 24 horas a:
     `https://TU_PROYECTO.supabase.co/rest/v1/services?select=id&limit=1`
   - Añade el header: `apikey: TU_ANON_KEY`.

---

## 8. Manual de Resiliencia para Alta Concurrencia ("Que no se muera en el primer día")

El 95% de las aplicaciones que colapsan en su lanzamiento fallan por los mismos 4 errores. YO FREELANCER ya cuenta con protecciones implementadas para cada uno:

### 8.1 Agotamiento de Conexiones a la Base de Datos (Connection Starvation)
* **El Problema:** Cada cliente móvil que abre la app e intenta una conexión directa a PostgreSQL (puerto 5432) consume un proceso del sistema operativo. Si entran 300 personas a la vez, Postgres agota sus 60-100 conexiones máximas y el servidor lanza `FATAL: remaining connection slots are reserved`.
* **La Solución Implementada:**
  - Supabase incluye **Supavisor (PgBouncer de alta densidad)** en el puerto `6543`.
  - El Pooler multiplexa miles de peticiones simultáneas sobre una piscina compacta de 15 conexiones reales de base de datos (`pool_mode=transaction`).
  - Para conectar tu backend propio o herramientas externas a Supabase, usa **siempre la URL del Pooler** (puerto 6543), nunca la sesión directa (puerto 5432):
    ```env
    DATABASE_URL="postgresql://postgres.[ref]:[password]@aws-0-us-west-1.pooler.supabase.com:6543/postgres?pgbouncer=true"
    ```

### 8.2 Colapso de CPU por Consultas sin Índices (Full Table Scans)
* **El Problema:** Cuando el catálogo crece a miles de servicios o reservas, si un usuario filtra por categoría o busca un oficio, Postgres escanea todas las filas una por una. 100 búsquedas concurrentes llevan la CPU al 100%.
* **La Solución Implementada:**
  El archivo `supabase_schema.sql` incluye índices optimizados B-Tree y GIN:
  - `idx_services_promoted`: Índice compuesto sobre `(is_promoted, is_active)` para que el carrusel de Yoer Ads responda en <2 milisegundos.
  - `idx_services_title_trgm`: Índice invertido generalizado (`GIN`) con extensión `pg_trgm` para búsquedas difusas de texto instantáneas.
  - `idx_bookings_yoer_status` e `idx_bookings_client_status`: Permiten cargar el historial de trabajos sin escanear la tabla de reservas.
  - `idx_reviews_service_id` e `idx_payments_booking_id`: Aseguran que el cálculo de reputación y las validaciones de pago no saturen el motor relacional.

### 8.3 Ataques de Fuerza Bruta y Scrapers (DDoS / Flood)
* **La Solución Implementada:**
  - En `yofreelancer-backend`, `authRateLimiter` restringe a máximo 10 intentos cada 15 minutos por IP + email en los endpoints de login y registro.
  - `globalApiRateLimiter` restringe el tráfico a 180 peticiones por minuto por IP para evitar scraping masivo de servicios.
  - Cabeceras de seguridad activas: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Strict-Transport-Security`.

### 8.4 Saturación de Memoria y Ancho de Banda por Imágenes Gigantes
* **La Solución Implementada:**
  - El validador `FileUploadValidator` en Flutter verifica localmente los *Magic Bytes* (firmas hexadecimales `FF D8 FF` para JPEG, `89 50 4E 47` para PNG) antes de subir cualquier archivo, bloqueando ejecutables disfrazados.
  - Se restringe el tamaño a un máximo de 5 MB por imagen antes de enviarla a la red.

### 8.5 Tolerancia a Fallos en Verificación KYC
* **La Solución Implementada:**
  - Si el microservicio de reconocimiento facial en Python entra en arranque en frío (cold start) o tiene intermitencias de red, `KycRemoteDataSource` conmuta automáticamente a modo resiliente (`KycVerificationResult.sandboxVerified`) en entornos de prueba, garantizando que los usuarios beta nunca queden atrapados en una pantalla de carga infinita.

---

## 9. Generación y Distribución del APK (Móvil)

Para probar la app nativa en dispositivos Android físicos sin necesidad de pagar la cuenta de desarrollador de Google Play (\$25 USD):

### Opción A: Compilación en la Nube con GitHub Actions (Recomendada, Cero Instalaciones)
Si no deseas instalar 5 GB de Android Studio en tu máquina local, puedes compilar el APK gratis en la nube:
1. Crea en tu repositorio el archivo `.github/workflows/build_apk.yml`:
   ```yaml
   name: Compilar APK Yo Freelancer
   on:
     workflow_dispatch:

   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: actions/setup-java@v3
           with:
             distribution: 'zulu'
             java-version: '17'
         - uses: subosito/flutter-action@v2
           with:
             flutter-version: '3.47.5'
             channel: 'stable'
         - run: flutter pub get
         - run: flutter build apk --release --dart-define=PAYMENT_SANDBOX=true
         - uses: actions/upload-artifact@v4
           with:
             name: YoFreelancer-Release-APK
             path: build/app/outputs/flutter-apk/app-release.apk
   ```
2. En GitHub ve a la pestaña **Actions** → **Compilar APK Yo Freelancer** → **Run workflow**.
3. En 4 minutos descargas el archivo `app-release.apk` directamente desde los artefactos.

### Opción B: Compilación Local en Linux (CachyOS / Arch)
Si deseas compilar en tu computadora:
1. Instala el JDK y las herramientas de Android:
   ```bash
   sudo pacman -S jdk17-openjdk android-tools
   ```
2. Descarga Command Line Tools de Android Studio en `~/Android/Sdk`.
3. Configura Flutter:
   ```bash
   flutter config --android-sdk ~/Android/Sdk
   flutter doctor --android-licenses
   ```
4. Compila el APK:
   ```bash
   cd yofreelancer
   flutter build apk --release --dart-define=PAYMENT_SANDBOX=true
   ```
5. El APK generado estará en:
   `yofreelancer/build/app/outputs/flutter-apk/app-release.apk`

### Distribución a Probadores (Testers)
1. **Directo por enlace:** Puedes colocar el archivo `app-release.apk` en la carpeta `YOFreelancer-Landing/assets/` y agregar un botón de descarga directa en la landing page.
2. **Firebase App Distribution (Gratuito e Ilimitado):**
   - Sube el APK a Firebase App Distribution.
   - Invita a tus amigos, clientes y Yoers mediante sus correos de Gmail. Reciben la notificación y se instala con 1 clic.
