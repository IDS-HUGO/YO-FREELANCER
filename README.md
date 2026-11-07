# YO FREELANCER

Plataforma de servicios independientes, oficios y talento para México y América Latina. Desarrollada con Flutter, Supabase, arquitectura MVVM limpia con Riverpod, sistema de pagos en garantía (Escrow) con Stripe y motor de publicidad patrocinada.

---

## 📱 Características Principales

* **Doble Perfil Dinámico:** Experiencia personalizada para **Yoers** (proveedores de oficio y profesionistas) y **Clientes** (contratantes).
* **Pagos con Custodia en Garantía (Escrow):** Los fondos del cliente quedan protegidos en la plataforma hasta que se confirma la entrega satisfactoria del trabajo.
* **Comisión de Plataforma Configurable:** Retención transparente de la comisión de intermediación (10% por defecto) y acreditación a la cartera *YOER Cash*.
* **Motor Publicitario "Yoer Ads":** Herramienta integrada para que los Yoers contraten micro-campañas de alcance local y aparezcan en los primeros resultados y carrusel de recomendados.
* **Verificación de Identidad Biométrica (KYC):** Validación de credencial oficial y prueba de vida facial.
* **Radar de Tareas y Agenda:** Geolocalización de solicitudes exprés y gestión de calendario en tiempo real.
* **Modo Pruebas / Sandbox:** Entorno de pruebas con tarjetas de simulación precargadas para probar flujos de pago sin dinero real.

---

## 🛠️ Stack Tecnológico

* **Frontend:** Flutter 3 (Dart 3) para iOS y Android.
* **Manejo de Estado:** Riverpod & StateNotifier (MVVM).
* **Navegación:** GoRouter con guardias de autenticación y redirección reactiva.
* **Backend:** Supabase (PostgreSQL + RLS + Auth + Storage) con soporte desacoplado para backend propio Node/Express.
* **Pasarela de Pago:** Stripe Connect (Destination charges & split payments) y métodos locales (SPEI, OXXO).
* **Diseño UI/UX:** Sistema de diseño nativo basado en la paleta Guisante & Oliva con soporte para modo claro y oscuro.

---

## 🚀 Inicio Rápido

### Requisitos Previos
* Flutter SDK >= 3.16.0
* Cuenta y proyecto configurado en Supabase

### Instalación y Ejecución

```bash
# 1. Clonar el repositorio y entrar al proyecto
cd yofreelancer

# 2. Descargar dependencias
flutter pub get

# 3. Ejecutar en modo desarrollo / sandbox
flutter run
```

Para la guía detallada de configuración de base de datos, Stripe, comisiones y variables de entorno, consulta:
👉 **[GUIA_CONFIGURACION.md](GUIA_CONFIGURACION.md)**

---

## 🧪 Pruebas y Calidad de Código

El proyecto cuenta con suite de pruebas unitarias y análisis estático estricto:

```bash
# Ejecutar análisis estático (linter)
flutter analyze

# Ejecutar suite de pruebas unitarias
flutter test
```

---

## 📂 Estructura del Proyecto

```text
lib/
├── app/
│   ├── config/          # Configuración de backend, pagos, KYC y supabase
│   ├── di/              # Inyección de dependencias (GetIt)
│   └── router/          # Definición de rutas y navegación (GoRouter)
├── core/                # Utilidades transversales, red y cifrado
├── features/            # Módulos organizados por dominio (Clean Architecture)
│   ├── auth/            # Autenticación y verificación KYC
│   ├── bookings/        # Contrataciones y reservas
│   ├── client/          # Pantallas y vistas del cliente
│   ├── legal/           # Términos, condiciones y privacidad
│   ├── payments/        # Checkout, Sandbox y pasarela de cobro
│   ├── services/        # Catálogo de servicios y motor publicitario (Ads)
│   ├── wallet/          # Cartera digital YOER Cash y retiros
│   └── yoer/            # Pantallas de vitrina y gestión del Yoer
└── shared/              # Tema, widgets reutilizables y DTOs
```
