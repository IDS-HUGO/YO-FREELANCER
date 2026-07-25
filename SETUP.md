# SETUP — Puesta en marcha completa

Checklist para que **todo** el roadmap (auth, servicios, reservas, pagos, notificaciones,
agenda, radar, wallet, insignias, ranking, voluntariado, modo artista) funcione de punta a
punta sobre el proyecto Supabase ya conectado en `lib/app/config/supabase_config.dart`.

> `supabase_schema.sql` es ahora un único script con todo el esquema (antes estaba
> partido en `supabase_schema.sql` + `supabase_migration_v2.sql`). Es idempotente
> (usa `create table if not exists`, `drop policy if exists` + `create policy`,
> `create or replace function`, etc.) — puedes volver a pegarlo y correrlo completo
> las veces que haga falta, en un proyecto nuevo o en uno que ya tenía datos, sin
> romper nada existente.

## 1. Correr el script SQL

Supabase Dashboard → **SQL Editor → New Query** → pega el contenido completo de
`supabase_schema.sql` y ejecútalo.

Eso es todo — el script ya crea los tres buckets de Storage (`profile-images`,
`service-images`, `cover-images`) como públicos vía `insert into storage.buckets`,
más sus políticas de RLS (lectura pública, escritura solo para el dueño en
`profile-images`, escritura para cualquier usuario autenticado en los otros dos).
No hace falta crear nada a mano en el Dashboard.

## 2. Realtime

La migración v2 ya agrega `notifications`, `task_applications` y `wallet_transactions`
a la publicación `supabase_realtime` por SQL. No hay que tocar nada en el dashboard,
pero si el proyecto tiene Realtime desactivado a nivel de proyecto, actívalo en
**Database → Replication**.

## 3. Qué automatiza el backend ahora (sin tocar la app)

Todo esto corre solo, vía triggers de Postgres, en cuanto se completa la migración v2:

| Evento | Efecto automático |
|---|---|
| Se crea un booking | Notificación al YOER |
| Booking pasa a CONFIRMADA / CANCELADA / COMPLETADA | Notificación a la contraparte |
| Booking se cancela estando CONFIRMADA/EN_PROGRESO | Se crea una `urgent_task` (aparece en Radar) |
| Booking se completa y ya está PAGADO | Se abona el 90% a `wallet_accounts` del YOER (10% comisión) + transacción + notificación |
| YOER completa su primer booking | Insignia "Mi primera tarea" + notificación |
| Se crea/actualiza una `task_application` | Notificación al dueño de la tarea o al YOER aceptado |
| Se crea una sanción / se resuelve una apelación | Notificación al usuario |
| Se crea un perfil nuevo | Se crea automáticamente su `wallet_account` en 0 |

## 4. Datos semilla opcionales (para probar Radar/Explorar con contenido)

`badge_catalog` ya viene sembrado por la migración. Si quieres ver algo en Eventos y
Voluntariado antes de construir un panel de administración, inserta filas de prueba:

```sql
insert into public.community_events (title, description, category, address, starts_at)
values ('Feria de talento local', 'Exhibición de oficios y arte en la plaza central',
        'ARTE', 'Plaza Central', now() + interval '3 days');

insert into public.volunteering_events (title, description, type, starts_at)
values ('YOER Primavera: Sembrando Futuro', 'Jornada anual de reforestación comunitaria',
        'ANUAL', now() + interval '10 days');
```

## 5. Cosas que se dejaron fuera a propósito (ver plan aprobado)

- **Pagos reales (Stripe)**: `flutter_stripe` está en `pubspec.yaml` pero no se conecta.
  El flujo actual en `payments` simula el cobro (marca `PAGADO` de inmediato para métodos
  no-efectivo). Conectar Stripe de verdad requiere llave secreta + Edge Function, es un
  proyecto aparte con sus propias credenciales.
- **Verificación automática de modo Artista**: `artist_profiles.is_verified` solo lo puede
  cambiar el rol `service_role` (revisión manual desde el SQL Editor o un panel admin futuro),
  nunca el propio usuario.
- **Cliente Empresa, Grupos/Foros, préstamos de Wallet, voluntariado de desastres con
  crowdsourcing completo**: los propios docs los marcan como "actualización" futura.

## 6. Verificar que corrió bien

En el SQL Editor:

```sql
select table_name from information_schema.tables
where table_schema = 'public'
order by table_name;
```

Deberías ver, entre otras: `notifications`, `task_requests`, `task_applications`,
`wallet_accounts`, `wallet_transactions`, `badge_catalog`, `sanction_appeals`,
`support_requests`, `volunteering_events`, `volunteering_participants`,
`community_events`, `artist_profiles`.
