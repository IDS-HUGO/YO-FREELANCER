-- ============================================================
-- YO FREE-LANCER — Supabase Schema (completo, script único)
-- Ejecuta este SQL en el SQL Editor de tu proyecto Supabase
-- Supabase Dashboard → SQL Editor → New Query
--
-- Idempotente: se puede pegar y volver a correr completo las veces
-- que haga falta (proyecto nuevo o ya existente) sin romper datos
-- ni políticas existentes.
-- ============================================================

-- ──────────────────────────────────────────────────
-- EXTENSIONES
-- ──────────────────────────────────────────────────
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";
create extension if not exists "pg_trgm"; -- búsqueda de texto

-- ──────────────────────────────────────────────────
-- ENUMs
-- ──────────────────────────────────────────────────
do $$ begin
  create type user_type as enum ('YOER', 'CLIENT');
exception when duplicate_object then null; end $$;

do $$ begin
  create type user_status as enum ('DISPONIBLE', 'OCUPADO', 'NO_DISPONIBLE', 'WARNED');
exception when duplicate_object then null; end $$;

do $$ begin
  create type availability_status as enum ('AVAILABLE', 'NOT_AVAILABLE', 'IN_TASK', 'WARNED');
exception when duplicate_object then null; end $$;

do $$ begin
  create type service_category as enum (
    'CONSTRUCCION', 'LIMPIEZA', 'REPARACION', 'EDUCACION',
    'ARTE', 'MUSICA', 'DEPORTES', 'TECNOLOGIA', 'SALUD',
    'BELLEZA', 'TRANSPORTE', 'OTROS'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type service_type as enum ('A_DOMICILIO', 'LOCAL', 'REMOTO', 'HIBRIDO');
exception when duplicate_object then null; end $$;

do $$ begin
  create type price_type as enum ('POR_HORA', 'PRECIO_FIJO', 'NEGOCIABLE');
exception when duplicate_object then null; end $$;

do $$ begin
  create type booking_status as enum (
    'PENDIENTE', 'CONFIRMADA', 'EN_PROGRESO',
    'COMPLETADA', 'CANCELADA', 'RECHAZADA'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type payment_status as enum ('PENDIENTE', 'PAGADO', 'REEMBOLSADO', 'FALLIDO');
exception when duplicate_object then null; end $$;

do $$ begin
  create type payment_method_type as enum (
    'EFECTIVO', 'TARJETA_CREDITO', 'TARJETA_DEBITO',
    'TRANSFERENCIA', 'OXXO', 'PAYPAL', 'MERCADO_PAGO'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type transaction_type as enum ('PAGO', 'REEMBOLSO', 'COMISION');
exception when duplicate_object then null; end $$;

do $$ begin
  create type sanction_severity as enum ('WARNING', 'AMONESTACION', 'SUSPENSION', 'BAN');
exception when duplicate_object then null; end $$;

do $$ begin
  create type notification_type as enum (
    'BOOKING_SOLICITUD', 'BOOKING_CONFIRMADA', 'BOOKING_CANCELADA', 'BOOKING_COMPLETADA',
    'NUEVA_POSTULACION', 'POSTULACION_ACEPTADA', 'NUEVA_INSIGNIA', 'AMONESTACION',
    'APELACION_RESUELTA', 'PAGO_RECIBIDO', 'EVENTO_CERCANO', 'SISTEMA'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type task_mode as enum ('EXPRES', 'AGENDADO');
exception when duplicate_object then null; end $$;

do $$ begin
  create type task_service_mode as enum ('PRESENCIAL', 'EN_LINEA', 'HIBRIDA');
exception when duplicate_object then null; end $$;

do $$ begin
  create type task_request_status as enum ('ABIERTA', 'ASIGNADA', 'CANCELADA', 'COMPLETADA');
exception when duplicate_object then null; end $$;

do $$ begin
  create type application_target as enum ('TASK_REQUEST', 'URGENT_TASK');
exception when duplicate_object then null; end $$;

do $$ begin
  create type application_status as enum ('PENDIENTE', 'ACEPTADA', 'RECHAZADA');
exception when duplicate_object then null; end $$;

do $$ begin
  create type wallet_transaction_type as enum (
    'DEPOSITO', 'RETIRO', 'PAGO_RECIBIDO', 'REEMBOLSO', 'COMISION', 'BONO'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type wallet_transaction_status as enum ('PENDIENTE', 'COMPLETADA', 'RECHAZADA');
exception when duplicate_object then null; end $$;

do $$ begin
  create type appeal_status as enum ('PENDIENTE', 'APROBADA', 'RECHAZADA');
exception when duplicate_object then null; end $$;

do $$ begin
  create type volunteering_type as enum ('ANUAL', 'TEMPORADA', 'EMERGENCIA');
exception when duplicate_object then null; end $$;

do $$ begin
  create type participation_status as enum ('INTERESADO', 'CONFIRMADO');
exception when duplicate_object then null; end $$;

do $$ begin
  create type manager_type as enum ('SELF', 'MANAGED');
exception when duplicate_object then null; end $$;

do $$ begin
  create type certification_status as enum ('NINGUNA', 'SOLICITADA', 'APROBADA');
exception when duplicate_object then null; end $$;

do $$ begin
  create type support_request_status as enum ('PENDIENTE', 'ATENDIDA');
exception when duplicate_object then null; end $$;

-- ──────────────────────────────────────────────────
-- TABLA: profiles (extiende auth.users de Supabase)
-- ──────────────────────────────────────────────────
create table if not exists public.profiles (
  id              uuid references auth.users on delete cascade primary key,
  email           text unique not null,
  username        text unique not null,
  full_name       text not null,
  user_type       user_type not null default 'CLIENT',
  status          user_status not null default 'NO_DISPONIBLE',
  phone_number    text,
  profile_image_url text,
  cover_image_url text,
  age             integer,
  gender          text,
  bio             text,
  -- Localización
  latitude        double precision,
  longitude       double precision,
  address         text,
  city            text,
  state           text,
  country         text default 'MX',
  -- Métricas YOER
  rating          double precision default 0.0,
  total_reviews   integer default 0,
  completed_jobs  integer default 0,
  weekly_bonus    double precision default 0.0,
  ranking_position integer,
  -- Verificación facial de identidad (Tarea 2, ver docs/KYC.md). Aplica a
  -- YOER y Cliente por igual. 'pending' hasta que se complete la
  -- verificación; nunca se marca 'verified' por default.
  kyc_status      text not null default 'pending'
                    check (kyc_status in ('pending', 'verified', 'rejected', 'error')),
  -- Timestamps
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

-- Migración idempotente para bases ya creadas antes de introducir kyc_status.
--
-- Decisión de producto (ver docs/KYC.md §5, antes marcada como pendiente de
-- confirmar): los usuarios que YA existían antes de esta migración quedan
-- verificados automáticamente ("grandfathering") para no romper su acceso
-- de un día para otro — no rompas funcionalidad existente. El gate de KYC
-- solo aplica de verdad a cuentas creadas DESPUÉS de este despliegue.
--
-- El backfill (`update ... set kyc_status = 'verified'`) solo corre la
-- primera vez que se agrega la columna (dentro del `if not exists`), nunca
-- en ejecuciones posteriores del script — de lo contrario, re-ejecutar este
-- schema volvería a marcar como 'verified' a cualquier usuario nuevo que
-- siga legítimamente en 'pending' esperando verificar su identidad.
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'kyc_status'
  ) then
    alter table public.profiles add column kyc_status text not null default 'pending';
    update public.profiles set kyc_status = 'verified';
  end if;
end $$;

alter table public.profiles
  drop constraint if exists profiles_kyc_status_check;
alter table public.profiles
  add constraint profiles_kyc_status_check
  check (kyc_status in ('pending', 'verified', 'rejected', 'error'));

-- ──────────────────────────────────────────────────
-- TABLA: kyc_verifications (auditoría no biométrica de Tarea 2)
-- Solo guarda el resultado de la comparación (nunca las imágenes: el
-- microservicio de verificación facial las procesa en memoria y las
-- descarta de inmediato, ver kyc-service/README.md).
-- ──────────────────────────────────────────────────
create table if not exists public.kyc_verifications (
  id           uuid default uuid_generate_v4() primary key,
  user_id      uuid references public.profiles(id) on delete cascade not null,
  request_id   text not null,
  match        boolean not null,
  similarity   double precision,
  distance     double precision,
  model        text,
  threshold    double precision,
  created_at   timestamptz default now()
);

alter table public.kyc_verifications enable row level security;

drop policy if exists "Usuario ve sus propias verificaciones KYC" on public.kyc_verifications;
create policy "Usuario ve sus propias verificaciones KYC" on public.kyc_verifications
  for select using (auth.uid() = user_id);

-- Sin policy de insert/update/delete para 'authenticated': solo el backend
-- (service_role) escribe en esta tabla tras llamar al microservicio de KYC.

-- RLS para profiles
alter table public.profiles enable row level security;

drop policy if exists "Perfiles visibles para todos" on public.profiles;
create policy "Perfiles visibles para todos"
  on public.profiles for select using (true);

drop policy if exists "Usuario edita su propio perfil" on public.profiles;
create policy "Usuario edita su propio perfil"
  on public.profiles for update using (auth.uid() = id);

drop policy if exists "Usuario inserta su propio perfil" on public.profiles;
create policy "Usuario inserta su propio perfil"
  on public.profiles for insert with check (auth.uid() = id);

-- Trigger para crear perfil automáticamente al registrarse
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, username, full_name, user_type)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'full_name', 'Usuario'),
    coalesce((new.raw_user_meta_data->>'user_type')::public.user_type, 'CLIENT'::public.user_type)
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ──────────────────────────────────────────────────
-- TABLA: freelancer_profiles (extra para YOERs)
-- ──────────────────────────────────────────────────
create table if not exists public.freelancer_profiles (
  user_id       uuid references public.profiles(id) on delete cascade primary key,
  title         text,
  description   text,
  hourly_rate   double precision,
  skills        text[] default '{}',
  experience    text,
  portfolio     text[] default '{}',
  availability  availability_status default 'NOT_AVAILABLE',
  origin_location text,
  active_location text,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

alter table public.freelancer_profiles enable row level security;

drop policy if exists "Perfiles freelancer visibles" on public.freelancer_profiles;
create policy "Perfiles freelancer visibles"
  on public.freelancer_profiles for select using (true);

drop policy if exists "YOER edita su propio perfil freelancer" on public.freelancer_profiles;
create policy "YOER edita su propio perfil freelancer"
  on public.freelancer_profiles for all using (auth.uid() = user_id);

-- ──────────────────────────────────────────────────
-- TABLA: badge_catalog (catálogo de insignias)
-- ──────────────────────────────────────────────────
create table if not exists public.badge_catalog (
  code        text primary key,
  name        text not null,
  description text,
  icon        text,
  is_active   boolean default true
);

insert into public.badge_catalog (code, name, description, icon) values
  ('PRIMERA_TAREA',    'Mi primera tarea',   'Completaste tu primer trabajo en la plataforma', '🎉'),
  ('PUNTUALIDAD',      'Puntualidad',        'Reconocido por llegar siempre a tiempo', '⏰'),
  ('PROFESIONALISMO',  'Profesionalismo',    'Destacas por tu trato profesional', '🤝'),
  ('CALIDAD',          'Calidad',            'Tu trabajo es reconocido por su excelente calidad', '✨'),
  ('MAS_SOLICITADO',   'Más solicitado',     'El YOER más solicitado en su categoría', '🔥'),
  ('RECORD_DIARIO',    'Récord del día',     'Superaste el récord de tareas completadas en un día', '🏆')
on conflict (code) do nothing;

-- Tabla de solo lectura para el cliente: sin RLS habilitado, un rol con
-- grants por defecto en el schema public podría insertar/editar/borrar
-- catálogo de insignias libremente. La habilitamos con una policy de
-- select únicamente (nadie puede escribir salvo el rol de servicio).
alter table public.badge_catalog enable row level security;
drop policy if exists "Catálogo de insignias visible" on public.badge_catalog;
create policy "Catálogo de insignias visible"
  on public.badge_catalog for select using (true);

-- ──────────────────────────────────────────────────
-- TABLA: badges (insignias otorgadas a usuarios)
-- ──────────────────────────────────────────────────
create table if not exists public.badges (
  id          uuid default uuid_generate_v4() primary key,
  user_id     uuid references public.profiles(id) on delete cascade,
  badge_code  text references public.badge_catalog(code),
  name        text not null,
  description text,
  icon_url    text,
  earned_at   timestamptz default now()
);

alter table public.badges add column if not exists badge_code text references public.badge_catalog(code);

alter table public.badges enable row level security;
drop policy if exists "Badges visibles" on public.badges;
create policy "Badges visibles" on public.badges for select using (true);

-- ──────────────────────────────────────────────────
-- TABLA: sanctions (sanciones)
-- ──────────────────────────────────────────────────
create table if not exists public.sanctions (
  id          uuid default uuid_generate_v4() primary key,
  user_id     uuid references public.profiles(id) on delete cascade,
  reason      text not null,
  description text,
  severity    sanction_severity not null,
  is_active   boolean default true,
  created_at  timestamptz default now(),
  expires_at  timestamptz
);

alter table public.sanctions enable row level security;
drop policy if exists "Sanciones visibles por admin y propio usuario" on public.sanctions;
create policy "Sanciones visibles por admin y propio usuario"
  on public.sanctions for select
  using (auth.uid() = user_id);

-- ──────────────────────────────────────────────────
-- TABLA: categories
-- ──────────────────────────────────────────────────
create table if not exists public.categories (
  id          bigserial primary key,
  name        service_category not null unique,
  display_name text not null,
  description text,
  icon_url    text,
  is_active   boolean default true
);

-- Datos semilla de categorías
insert into public.categories (name, display_name, description) values
  ('CONSTRUCCION', 'Construcción',   'Albañilería, plomería, electricidad'),
  ('LIMPIEZA',     'Limpieza',       'Hogar, oficina, vehículos'),
  ('REPARACION',   'Reparación',     'Electrodomésticos, electrónica'),
  ('EDUCACION',    'Educación',      'Clases, tutorías, talleres'),
  ('ARTE',         'Arte',           'Diseño, fotografía, video'),
  ('MUSICA',       'Música',         'Clases, eventos, grabación'),
  ('DEPORTES',     'Deportes',       'Entrenamiento, coaching'),
  ('TECNOLOGIA',   'Tecnología',     'Desarrollo, redes, soporte'),
  ('SALUD',        'Salud',          'Masajes, terapias, nutrición'),
  ('BELLEZA',      'Belleza',        'Estética, peluquería, maquillaje'),
  ('TRANSPORTE',   'Transporte',     'Mudanza, mensajería, chofer'),
  ('OTROS',        'Otros',          'Servicios varios')
on conflict (name) do nothing;

-- Hardening (SECURITY_REPORT.md): esta tabla no tenía RLS habilitado, a
-- diferencia de todas las demás tablas del schema. Solo lectura pública;
-- la gestión de categorías queda reservada al service_role (sin policy de
-- insert/update/delete para 'authenticated').
alter table public.categories enable row level security;

drop policy if exists "Lectura pública de categorías" on public.categories;
create policy "Lectura pública de categorías" on public.categories
  for select using (is_active = true);

-- ──────────────────────────────────────────────────
-- TABLA: services
-- ──────────────────────────────────────────────────
create table if not exists public.services (
  id            uuid default uuid_generate_v4() primary key,
  yoer_id       uuid references public.profiles(id) on delete cascade not null,
  title         text not null,
  description   text not null,
  category      service_category not null,
  specialties   text[] default '{}',
  service_type  service_type not null default 'LOCAL',
  price_type    price_type not null default 'PRECIO_FIJO',
  price         double precision not null,
  currency      text default 'MXN',
  -- Localización
  latitude      double precision,
  longitude     double precision,
  address       text,
  city          text,
  -- Media
  images        text[] default '{}',
  videos        text[] default '{}',
  -- Métricas
  rating        double precision default 0.0,
  total_reviews integer default 0,
  views_count   integer default 0,
  -- Estado
  is_active     boolean default true,
  is_promoted   boolean default false,
  -- Certificación de oficio/portafolio
  certification_status certification_status not null default 'NINGUNA',
  certification_notes  text,
  -- Disponibilidad (JSON)
  availability  jsonb default '{"monday":false,"tuesday":false,"wednesday":false,"thursday":false,"friday":false,"saturday":false,"sunday":false}',
  requirements  text[] default '{}',
  included_items text[] default '{}',
  -- Timestamps
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

alter table public.services add column if not exists certification_status certification_status not null default 'NINGUNA';
alter table public.services add column if not exists certification_notes text;

create index if not exists idx_services_yoer_id   on public.services(yoer_id);
create index if not exists idx_services_category  on public.services(category);
create index if not exists idx_services_city      on public.services(city);
create index if not exists idx_services_is_active on public.services(is_active);
create index if not exists idx_services_rating    on public.services(rating desc);

alter table public.services enable row level security;

drop policy if exists "Servicios activos visibles para todos" on public.services;
create policy "Servicios activos visibles para todos"
  on public.services for select using (is_active = true or auth.uid() = yoer_id);

drop policy if exists "YOER gestiona sus servicios" on public.services;
create policy "YOER gestiona sus servicios"
  on public.services for all using (auth.uid() = yoer_id);

-- ──────────────────────────────────────────────────
-- TABLA: bookings
-- ──────────────────────────────────────────────────
create table if not exists public.bookings (
  id                   uuid default uuid_generate_v4() primary key,
  service_id           uuid references public.services(id) on delete restrict not null,
  yoer_id              uuid references public.profiles(id) on delete restrict not null,
  client_id            uuid references public.profiles(id) on delete restrict not null,
  -- Detalles
  service_name         text not null,
  status               booking_status default 'PENDIENTE',
  scheduled_date       bigint not null, -- unix ms
  scheduled_time       text not null,   -- HH:mm
  duration             integer not null, -- minutos
  -- Localización
  latitude             double precision,
  longitude            double precision,
  address              text not null,
  notes                text,
  -- Precio
  total_price          double precision not null,
  currency             text default 'MXN',
  payment_status       payment_status default 'PENDIENTE',
  payment_method       payment_method_type,
  -- Timestamps
  created_at           timestamptz default now(),
  updated_at           timestamptz default now(),
  completed_at         timestamptz,
  cancelled_at         timestamptz,
  cancellation_reason  text
);

create index if not exists idx_bookings_yoer_id   on public.bookings(yoer_id);
create index if not exists idx_bookings_client_id on public.bookings(client_id);
create index if not exists idx_bookings_status    on public.bookings(status);
create index if not exists idx_bookings_date      on public.bookings(scheduled_date);

alter table public.bookings enable row level security;

drop policy if exists "Reserva visible por yoer y cliente" on public.bookings;
create policy "Reserva visible por yoer y cliente"
  on public.bookings for select
  using (auth.uid() = yoer_id or auth.uid() = client_id);

drop policy if exists "Cliente crea reserva" on public.bookings;
create policy "Cliente crea reserva"
  on public.bookings for insert with check (auth.uid() = client_id);

drop policy if exists "Yoer/cliente actualiza reserva" on public.bookings;
create policy "Yoer/cliente actualiza reserva"
  on public.bookings for update
  using (auth.uid() = yoer_id or auth.uid() = client_id);

-- ──────────────────────────────────────────────────
-- TABLA: payments
-- ──────────────────────────────────────────────────
create table if not exists public.payments (
  id               uuid default uuid_generate_v4() primary key,
  booking_id       uuid references public.bookings(id) on delete restrict not null,
  user_id          uuid references public.profiles(id) on delete restrict not null,
  amount           double precision not null,
  currency         text default 'MXN',
  payment_method   payment_method_type not null,
  transaction_type transaction_type default 'PAGO',
  status           payment_status default 'PENDIENTE',
  transaction_id   text,
  description      text,
  metadata         jsonb default '{}',
  created_at       timestamptz default now(),
  processed_at     timestamptz,
  refunded_at      timestamptz
);

alter table public.payments enable row level security;

drop policy if exists "Pago visible por usuario" on public.payments;
create policy "Pago visible por usuario"
  on public.payments for select using (auth.uid() = user_id);

drop policy if exists "Usuario crea pago" on public.payments;
create policy "Usuario crea pago"
  on public.payments for insert with check (auth.uid() = user_id);

-- ──────────────────────────────────────────────────
-- TABLA: reviews
-- ──────────────────────────────────────────────────
create table if not exists public.reviews (
  id              uuid default uuid_generate_v4() primary key,
  service_id      uuid references public.services(id) on delete cascade,
  booking_id      uuid references public.bookings(id) on delete cascade,
  reviewer_id     uuid references public.profiles(id) on delete cascade,
  reviewed_id     uuid references public.profiles(id) on delete cascade,
  rating          integer not null check (rating >= 1 and rating <= 5),
  comment         text,
  images          text[] default '{}',
  created_at      timestamptz default now()
);

alter table public.reviews enable row level security;
drop policy if exists "Reseñas visibles" on public.reviews;
create policy "Reseñas visibles" on public.reviews for select using (true);

drop policy if exists "Usuario crea reseña" on public.reviews;
create policy "Usuario crea reseña" on public.reviews for insert
  with check (auth.uid() = reviewer_id);

-- Trigger para actualizar rating del servicio y del YOER
create or replace function public.update_ratings_after_review()
returns trigger as $$
declare
  avg_rating double precision;
  review_count integer;
begin
  -- Actualizar rating del servicio
  select avg(rating), count(*) into avg_rating, review_count
  from public.reviews where service_id = new.service_id;

  update public.services
  set rating = round(avg_rating::numeric, 1), total_reviews = review_count
  where id = new.service_id;

  -- Actualizar rating del YOER
  select avg(r.rating), count(*) into avg_rating, review_count
  from public.reviews r
  join public.services s on r.service_id = s.id
  where s.yoer_id = new.reviewed_id;

  update public.profiles
  set rating = round(avg_rating::numeric, 1), total_reviews = review_count
  where id = new.reviewed_id;

  return new;
end;
$$ language plpgsql;

drop trigger if exists after_review_insert on public.reviews;
create trigger after_review_insert
  after insert on public.reviews
  for each row execute procedure public.update_ratings_after_review();

-- ──────────────────────────────────────────────────
-- TABLA: payment_cards (tarjetas guardadas)
-- ──────────────────────────────────────────────────
create table if not exists public.payment_cards (
  id               uuid default uuid_generate_v4() primary key,
  user_id          uuid references public.profiles(id) on delete cascade,
  card_number      text not null, -- solo últimos 4 dígitos
  card_holder_name text not null,
  expiry_month     integer not null,
  expiry_year      integer not null,
  card_type        text not null, -- VISA, MASTERCARD, AMEX
  is_default       boolean default false,
  created_at       timestamptz default now()
);

alter table public.payment_cards enable row level security;
drop policy if exists "Usuario ve sus tarjetas" on public.payment_cards;
create policy "Usuario ve sus tarjetas"
  on public.payment_cards for all using (auth.uid() = user_id);

-- ──────────────────────────────────────────────────
-- TABLA: urgent_tasks (tareas urgentes / Radar)
-- ──────────────────────────────────────────────────
create table if not exists public.urgent_tasks (
  id              uuid default uuid_generate_v4() primary key,
  client_id       uuid references public.profiles(id) on delete cascade,
  title           text not null,
  description     text not null,
  category        service_category not null,
  latitude        double precision,
  longitude       double precision,
  address         text,
  max_price       double precision,
  is_active       boolean default true,
  applicants_count integer default 0,
  assigned_yoer_id uuid references public.profiles(id),
  created_at      timestamptz default now(),
  expires_at      timestamptz not null
);

alter table public.urgent_tasks add column if not exists assigned_yoer_id uuid references public.profiles(id);

alter table public.urgent_tasks enable row level security;
drop policy if exists "Tareas urgentes visibles" on public.urgent_tasks;
create policy "Tareas urgentes visibles" on public.urgent_tasks for select using (true);

drop policy if exists "Cliente gestiona sus tareas" on public.urgent_tasks;
create policy "Cliente gestiona sus tareas" on public.urgent_tasks for all
  using (auth.uid() = client_id);

-- ──────────────────────────────────────────────────
-- TABLA: notifications
-- ──────────────────────────────────────────────────
create table if not exists public.notifications (
  id          uuid default uuid_generate_v4() primary key,
  user_id     uuid references public.profiles(id) on delete cascade not null,
  type        notification_type not null,
  title       text not null,
  body        text,
  data        jsonb default '{}',
  is_read     boolean default false,
  created_at  timestamptz default now()
);

create index if not exists idx_notifications_user_id on public.notifications(user_id);
create index if not exists idx_notifications_unread    on public.notifications(user_id, is_read);

alter table public.notifications enable row level security;

drop policy if exists "Usuario ve sus notificaciones" on public.notifications;
create policy "Usuario ve sus notificaciones"
  on public.notifications for select using (auth.uid() = user_id);

drop policy if exists "Usuario actualiza sus notificaciones" on public.notifications;
create policy "Usuario actualiza sus notificaciones"
  on public.notifications for update using (auth.uid() = user_id);

-- Sin policy de insert: el cliente Flutter nunca inserta notificaciones
-- directamente, todas se generan vía triggers (security definer, que
-- ignoran RLS). Cualquier policy de insert para "autenticado" dejaría a
-- un usuario crear notificaciones falsas para cualquier otro usuario.
drop policy if exists "Autenticado crea notificaciones" on public.notifications;

-- ──────────────────────────────────────────────────
-- TABLA: task_requests (tareas Expres/Agendado creadas por el cliente)
-- ──────────────────────────────────────────────────
create table if not exists public.task_requests (
  id                   uuid default uuid_generate_v4() primary key,
  client_id            uuid references public.profiles(id) on delete cascade not null,
  title                text not null,
  description          text not null,
  category             service_category not null,
  mode                 task_mode not null default 'EXPRES',
  service_mode         task_service_mode not null default 'PRESENCIAL',
  estimated_hours      double precision,
  budget               double precision not null,
  currency             text default 'MXN',
  address              text,
  latitude             double precision,
  longitude            double precision,
  scheduled_dates      jsonb default '[]',
  status               task_request_status not null default 'ABIERTA',
  assigned_yoer_id     uuid references public.profiles(id),
  assigned_booking_id  uuid references public.bookings(id),
  created_at           timestamptz default now(),
  updated_at           timestamptz default now(),
  expires_at           timestamptz
);

create index if not exists idx_task_requests_client   on public.task_requests(client_id);
create index if not exists idx_task_requests_status   on public.task_requests(status);
create index if not exists idx_task_requests_category on public.task_requests(category);

alter table public.task_requests enable row level security;

drop policy if exists "Tareas visibles para todos" on public.task_requests;
create policy "Tareas visibles para todos"
  on public.task_requests for select using (true);

drop policy if exists "Cliente gestiona sus tareas" on public.task_requests;
create policy "Cliente gestiona sus tareas"
  on public.task_requests for all using (auth.uid() = client_id);

-- ──────────────────────────────────────────────────
-- TABLA: task_applications (postulaciones YOER a task_requests o urgent_tasks)
-- ──────────────────────────────────────────────────
create table if not exists public.task_applications (
  id              uuid default uuid_generate_v4() primary key,
  target_type     application_target not null,
  task_request_id uuid references public.task_requests(id) on delete cascade,
  urgent_task_id  uuid references public.urgent_tasks(id) on delete cascade,
  yoer_id         uuid references public.profiles(id) on delete cascade not null,
  proposal        text,
  proposed_price  double precision,
  status          application_status not null default 'PENDIENTE',
  created_at      timestamptz default now(),
  constraint task_applications_target_check check (
    (target_type = 'TASK_REQUEST' and task_request_id is not null and urgent_task_id is null) or
    (target_type = 'URGENT_TASK'  and urgent_task_id  is not null and task_request_id is null)
  )
);

create index if not exists idx_task_applications_yoer         on public.task_applications(yoer_id);
create index if not exists idx_task_applications_task_request on public.task_applications(task_request_id);
create index if not exists idx_task_applications_urgent_task  on public.task_applications(urgent_task_id);

-- Evita que un YOER se postule dos veces a la misma tarea
create unique index if not exists idx_task_applications_unique_request
  on public.task_applications(task_request_id, yoer_id) where target_type = 'TASK_REQUEST';
create unique index if not exists idx_task_applications_unique_urgent
  on public.task_applications(urgent_task_id, yoer_id) where target_type = 'URGENT_TASK';

alter table public.task_applications enable row level security;

-- IMPORTANTE: el YOER solo puede ver/crear/retirar su postulación, NUNCA
-- actualizarla (eso permitiría auto-aceptarse). Aceptar/rechazar es
-- exclusivo del dueño de la tarea (política de más abajo) o de la función
-- accept_task_application().
drop policy if exists "YOER gestiona sus postulaciones" on public.task_applications;
drop policy if exists "YOER ve sus postulaciones" on public.task_applications;
create policy "YOER ve sus postulaciones"
  on public.task_applications for select using (auth.uid() = yoer_id);

drop policy if exists "YOER crea sus postulaciones" on public.task_applications;
create policy "YOER crea sus postulaciones"
  on public.task_applications for insert with check (auth.uid() = yoer_id);

drop policy if exists "YOER retira su postulacion" on public.task_applications;
create policy "YOER retira su postulacion"
  on public.task_applications for delete using (auth.uid() = yoer_id AND status = 'PENDIENTE');

drop policy if exists "Dueño de tarea ve postulaciones recibidas" on public.task_applications;
create policy "Dueño de tarea ve postulaciones recibidas"
  on public.task_applications for select using (
    exists (select 1 from public.task_requests t where t.id = task_request_id and t.client_id = auth.uid())
    or exists (select 1 from public.urgent_tasks u where u.id = urgent_task_id and u.client_id = auth.uid())
  );

drop policy if exists "Dueño de tarea acepta o rechaza postulacion" on public.task_applications;
create policy "Dueño de tarea acepta o rechaza postulacion"
  on public.task_applications for update using (
    exists (select 1 from public.task_requests t where t.id = task_request_id and t.client_id = auth.uid())
    or exists (select 1 from public.urgent_tasks u where u.id = urgent_task_id and u.client_id = auth.uid())
  );

-- ──────────────────────────────────────────────────
-- TABLA: wallet_accounts + wallet_transactions (YOER Cash)
-- ──────────────────────────────────────────────────
create table if not exists public.wallet_accounts (
  user_id         uuid references public.profiles(id) on delete cascade primary key,
  balance         double precision default 0.0,
  pending_balance double precision default 0.0,
  updated_at      timestamptz default now()
);

alter table public.wallet_accounts enable row level security;

drop policy if exists "Usuario ve su wallet" on public.wallet_accounts;
create policy "Usuario ve su wallet"
  on public.wallet_accounts for select using (auth.uid() = user_id);

create table if not exists public.wallet_transactions (
  id           uuid default uuid_generate_v4() primary key,
  user_id      uuid references public.profiles(id) on delete cascade not null,
  type         wallet_transaction_type not null,
  amount       double precision not null,
  status       wallet_transaction_status not null default 'PENDIENTE',
  booking_id   uuid references public.bookings(id),
  description  text,
  created_at   timestamptz default now(),
  processed_at timestamptz
);

create index if not exists idx_wallet_transactions_user on public.wallet_transactions(user_id);

alter table public.wallet_transactions enable row level security;

drop policy if exists "Usuario ve sus transacciones" on public.wallet_transactions;
create policy "Usuario ve sus transacciones"
  on public.wallet_transactions for select using (auth.uid() = user_id);

-- El usuario solo puede solicitar retiros directamente; depósitos/comisiones/pagos
-- los crean los triggers de abajo (security definer, no pasan por esta policy).
drop policy if exists "Usuario solicita retiro" on public.wallet_transactions;
create policy "Usuario solicita retiro"
  on public.wallet_transactions for insert
  with check (auth.uid() = user_id and type = 'RETIRO');

-- Al solicitar un retiro, reserva el monto de inmediato (lo mueve de balance
-- a pending_balance) para que el saldo mostrado sea real y no se puedan
-- solicitar dos retiros por el mismo dinero. Si no hay saldo suficiente,
-- aborta el insert con una excepción.
create or replace function public.reserve_wallet_withdrawal()
returns trigger as $$
declare
  current_balance double precision;
begin
  if new.type = 'RETIRO' then
    select balance into current_balance from public.wallet_accounts where user_id = new.user_id;
    if current_balance is null or current_balance < new.amount then
      raise exception 'Saldo insuficiente para este retiro';
    end if;

    update public.wallet_accounts
    set balance = balance - new.amount,
        pending_balance = pending_balance + new.amount,
        updated_at = now()
    where user_id = new.user_id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_reserve_wallet_withdrawal on public.wallet_transactions;
create trigger trg_reserve_wallet_withdrawal
  before insert on public.wallet_transactions
  for each row execute procedure public.reserve_wallet_withdrawal();

-- Al resolver un retiro (COMPLETADA o RECHAZADA, hecho manualmente por el
-- equipo desde el dashboard con el rol de servicio): libera pending_balance,
-- y si fue rechazado regresa el monto al balance disponible.
create or replace function public.finalize_wallet_withdrawal()
returns trigger as $$
begin
  if new.type = 'RETIRO' and old.status = 'PENDIENTE' and new.status is distinct from 'PENDIENTE' then
    update public.wallet_accounts
    set pending_balance = greatest(pending_balance - new.amount, 0),
        balance = balance + (case when new.status = 'RECHAZADA' then new.amount else 0 end),
        updated_at = now()
    where user_id = new.user_id;

    insert into public.notifications (user_id, type, title, body, data)
    values (
      new.user_id,
      'SISTEMA',
      case when new.status = 'COMPLETADA' then 'Retiro procesado' else 'Retiro rechazado' end,
      '$' || round(new.amount::numeric, 2) || ' ' ||
        (case when new.status = 'COMPLETADA' then 'fue transferido.' else 'fue devuelto a tu saldo.' end),
      jsonb_build_object('transaction_id', new.id)
    );
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_finalize_wallet_withdrawal on public.wallet_transactions;
create trigger trg_finalize_wallet_withdrawal
  after update on public.wallet_transactions
  for each row execute procedure public.finalize_wallet_withdrawal();

-- Crea automáticamente la wallet al registrarse un perfil
create or replace function public.handle_new_wallet()
returns trigger as $$
begin
  insert into public.wallet_accounts (user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_profile_created_wallet on public.profiles;
create trigger on_profile_created_wallet
  after insert on public.profiles
  for each row execute procedure public.handle_new_wallet();

-- Wallets para perfiles que ya existían antes de tener esta tabla/trigger
insert into public.wallet_accounts (user_id)
select id from public.profiles
on conflict (user_id) do nothing;

-- ──────────────────────────────────────────────────
-- TABLA: sanction_appeals + support_requests
-- ──────────────────────────────────────────────────
create table if not exists public.sanction_appeals (
  id          uuid default uuid_generate_v4() primary key,
  sanction_id uuid references public.sanctions(id) on delete cascade not null,
  user_id     uuid references public.profiles(id) on delete cascade not null,
  message     text not null,
  status      appeal_status not null default 'PENDIENTE',
  created_at  timestamptz default now(),
  resolved_at timestamptz
);

alter table public.sanction_appeals enable row level security;

-- El usuario solo puede verla y crearla; resolverla (cambiar `status`) es
-- exclusivo de un admin/service_role (bypassa RLS) — de lo contrario podría
-- aprobar/rechazar su propia apelación.
drop policy if exists "Usuario ve y crea sus apelaciones" on public.sanction_appeals;
drop policy if exists "Usuario ve sus apelaciones" on public.sanction_appeals;
create policy "Usuario ve sus apelaciones"
  on public.sanction_appeals for select using (auth.uid() = user_id);

drop policy if exists "Usuario crea sus apelaciones" on public.sanction_appeals;
create policy "Usuario crea sus apelaciones"
  on public.sanction_appeals for insert with check (auth.uid() = user_id);

create table if not exists public.support_requests (
  id         uuid default uuid_generate_v4() primary key,
  user_id    uuid references public.profiles(id) on delete cascade not null,
  reason     text not null,
  message    text,
  status     support_request_status not null default 'PENDIENTE',
  created_at timestamptz default now()
);

alter table public.support_requests enable row level security;

-- Mismo criterio: el usuario no debe poder marcar su propio ticket como
-- "atendido".
drop policy if exists "Usuario ve y crea sus solicitudes de soporte" on public.support_requests;
drop policy if exists "Usuario ve sus solicitudes de soporte" on public.support_requests;
create policy "Usuario ve sus solicitudes de soporte"
  on public.support_requests for select using (auth.uid() = user_id);

drop policy if exists "Usuario crea solicitudes de soporte" on public.support_requests;
create policy "Usuario crea solicitudes de soporte"
  on public.support_requests for insert with check (auth.uid() = user_id);

-- ──────────────────────────────────────────────────
-- TABLA: volunteering_events + volunteering_participants
-- ──────────────────────────────────────────────────
create table if not exists public.volunteering_events (
  id                  uuid default uuid_generate_v4() primary key,
  title               text not null,
  description         text not null,
  type                volunteering_type not null,
  banner_image_url    text,
  address             text,
  latitude            double precision,
  longitude           double precision,
  requires_reputation double precision default 0,
  is_active           boolean default true,
  starts_at           timestamptz not null,
  ends_at             timestamptz,
  created_at          timestamptz default now()
);

alter table public.volunteering_events enable row level security;

drop policy if exists "Eventos de voluntariado visibles" on public.volunteering_events;
create policy "Eventos de voluntariado visibles"
  on public.volunteering_events for select using (true);

-- Sin policy de insert para usuarios normales: se siembran manualmente por ahora
-- (crear voluntariado propio queda para una actualización futura).

create table if not exists public.volunteering_participants (
  id         uuid default uuid_generate_v4() primary key,
  event_id   uuid references public.volunteering_events(id) on delete cascade not null,
  yoer_id    uuid references public.profiles(id) on delete cascade not null,
  status     participation_status not null default 'INTERESADO',
  applied_at timestamptz default now(),
  unique (event_id, yoer_id)
);

alter table public.volunteering_participants enable row level security;

drop policy if exists "Participaciones visibles" on public.volunteering_participants;
create policy "Participaciones visibles"
  on public.volunteering_participants for select using (true);

-- El YOER puede inscribirse o retirar su interés, pero confirmar su
-- participación ("CONFIRMADO") es criterio del equipo organizador, no algo
-- que el propio YOER deba poder marcarse (por eso no hay policy de update).
drop policy if exists "YOER gestiona su participacion" on public.volunteering_participants;
drop policy if exists "YOER se inscribe a voluntariado" on public.volunteering_participants;
create policy "YOER se inscribe a voluntariado"
  on public.volunteering_participants for insert with check (auth.uid() = yoer_id);

drop policy if exists "YOER retira su interes" on public.volunteering_participants;
create policy "YOER retira su interes"
  on public.volunteering_participants for delete using (auth.uid() = yoer_id);

-- ──────────────────────────────────────────────────
-- TABLA: community_events (Explorar → "eventos cerca del explorer")
-- ──────────────────────────────────────────────────
create table if not exists public.community_events (
  id          uuid default uuid_generate_v4() primary key,
  title       text not null,
  description text,
  category    service_category,
  address     text,
  latitude    double precision,
  longitude   double precision,
  image_url   text,
  starts_at   timestamptz not null,
  ends_at     timestamptz,
  is_active   boolean default true,
  created_at  timestamptz default now()
);

alter table public.community_events enable row level security;

drop policy if exists "Eventos comunitarios visibles" on public.community_events;
create policy "Eventos comunitarios visibles"
  on public.community_events for select using (true);

-- ──────────────────────────────────────────────────
-- TABLA: artist_profiles (modo Artista/Talento simplificado)
-- ──────────────────────────────────────────────────
create table if not exists public.artist_profiles (
  user_id                   uuid references public.profiles(id) on delete cascade primary key,
  stage_name                text,
  manager_type              manager_type default 'SELF',
  manager_name              text,
  manager_contact           text,
  is_verified               boolean default false,
  verification_requested_at timestamptz,
  created_at                timestamptz default now(),
  updated_at                timestamptz default now()
);

alter table public.artist_profiles enable row level security;

drop policy if exists "Perfil artista visible" on public.artist_profiles;
create policy "Perfil artista visible"
  on public.artist_profiles for select using (true);

drop policy if exists "YOER gestiona su perfil artista" on public.artist_profiles;
create policy "YOER gestiona su perfil artista"
  on public.artist_profiles for all using (auth.uid() = user_id);

-- Defensa en profundidad: is_verified solo lo puede cambiar el rol de servicio
-- (revisión manual del equipo), nunca el propio usuario vía la policy de arriba.
create or replace function public.protect_artist_verification()
returns trigger as $$
begin
  if TG_OP = 'INSERT' then
    new.is_verified := false;
  elsif new.is_verified is distinct from old.is_verified and auth.role() <> 'service_role' then
    new.is_verified := old.is_verified;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_protect_artist_verification on public.artist_profiles;
create trigger trg_protect_artist_verification
  before insert or update on public.artist_profiles
  for each row execute procedure public.protect_artist_verification();

-- ──────────────────────────────────────────────────
-- TRIGGERS de automatización cross-cutting
-- ──────────────────────────────────────────────────

-- Notifica al YOER cuando entra una nueva reserva, y a la contraparte en cambios de estado
create or replace function public.notify_booking_change()
returns trigger as $$
declare
  recipient uuid;
  ntype notification_type;
  ntitle text;
begin
  if TG_OP = 'INSERT' then
    recipient := new.yoer_id;
    ntype := 'BOOKING_SOLICITUD';
    ntitle := 'Nueva solicitud de reserva';
  elsif TG_OP = 'UPDATE' and new.status is distinct from old.status then
    if new.status = 'CONFIRMADA' then
      recipient := new.client_id; ntype := 'BOOKING_CONFIRMADA'; ntitle := 'Reserva confirmada';
    elsif new.status = 'CANCELADA' then
      recipient := case when auth.uid() = new.client_id then new.yoer_id else new.client_id end;
      ntype := 'BOOKING_CANCELADA'; ntitle := 'Reserva cancelada';
    elsif new.status = 'COMPLETADA' then
      recipient := new.client_id; ntype := 'BOOKING_COMPLETADA'; ntitle := 'Servicio completado';
    else
      return new;
    end if;
  else
    return new;
  end if;

  insert into public.notifications (user_id, type, title, body, data)
  values (recipient, ntype, ntitle, new.service_name, jsonb_build_object('booking_id', new.id));

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_notify_booking_change on public.bookings;
create trigger trg_notify_booking_change
  after insert or update on public.bookings
  for each row execute procedure public.notify_booking_change();

-- Insignia automática "primera tarea" al completar el primer booking como YOER
create or replace function public.award_first_task_badge()
returns trigger as $$
begin
  if new.status = 'COMPLETADA' and old.status is distinct from 'COMPLETADA' then
    if not exists (
      select 1 from public.badges where user_id = new.yoer_id and badge_code = 'PRIMERA_TAREA'
    ) then
      insert into public.badges (user_id, badge_code, name, description, icon_url)
      values (new.yoer_id, 'PRIMERA_TAREA', 'Mi primera tarea',
              'Completaste tu primer trabajo en la plataforma', '🎉');

      insert into public.notifications (user_id, type, title, body, data)
      values (new.yoer_id, 'NUEVA_INSIGNIA', '¡Nueva insignia desbloqueada!',
              'Mi primera tarea', jsonb_build_object('badge_code', 'PRIMERA_TAREA'));
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_award_first_task_badge on public.bookings;
create trigger trg_award_first_task_badge
  after update on public.bookings
  for each row execute procedure public.award_first_task_badge();

-- Abono automático a la wallet del YOER al completar un booking ya pagado.
-- Dos resguardos además del básico "cambió a COMPLETADA":
--   1. Exige que exista un pago real (PAGADO) en `payments` para ese booking,
--      no solo que `bookings.payment_status` diga PAGADO (ese campo lo puede
--      tocar cualquiera de las dos partes vía la policy de update de bookings).
--   2. No vuelve a abonar si el booking oscila COMPLETADA→otro→COMPLETADA de
--      nuevo (ej. corrección manual desde el dashboard).
create or replace function public.credit_wallet_on_completion()
returns trigger as $$
declare
  commission_rate constant double precision := 0.10;
  net_amount double precision;
  has_real_payment boolean;
  already_credited boolean;
begin
  if new.status = 'COMPLETADA' and old.status is distinct from 'COMPLETADA'
     and new.payment_status = 'PAGADO' then

    select exists(
      select 1 from public.payments where booking_id = new.id and status = 'PAGADO'
    ) into has_real_payment;

    select exists(
      select 1 from public.wallet_transactions
      where booking_id = new.id and type = 'PAGO_RECIBIDO'
    ) into already_credited;

    if not has_real_payment or already_credited then
      return new;
    end if;

    net_amount := new.total_price * (1 - commission_rate);

    insert into public.wallet_accounts (user_id, balance)
    values (new.yoer_id, net_amount)
    on conflict (user_id) do update
      set balance = public.wallet_accounts.balance + excluded.balance,
          updated_at = now();

    insert into public.wallet_transactions (user_id, type, amount, status, booking_id, description, processed_at)
    values (new.yoer_id, 'PAGO_RECIBIDO', net_amount, 'COMPLETADA', new.id,
            'Pago por: ' || new.service_name, now());

    insert into public.notifications (user_id, type, title, body, data)
    values (new.yoer_id, 'PAGO_RECIBIDO', 'Pago recibido',
            '$' || round(net_amount::numeric, 2) || ' abonado a tu wallet',
            jsonb_build_object('booking_id', new.id));
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_credit_wallet_on_completion on public.bookings;
create trigger trg_credit_wallet_on_completion
  after update on public.bookings
  for each row execute procedure public.credit_wallet_on_completion();

-- Cancelar un booking activo lo reenvía al Radar como tarea urgente (con "penalización" implícita)
create or replace function public.send_cancelled_booking_to_radar()
returns trigger as $$
begin
  if new.status = 'CANCELADA' and old.status in ('CONFIRMADA', 'EN_PROGRESO') then
    insert into public.urgent_tasks (
      client_id, title, description, category, latitude, longitude, address, max_price, expires_at
    )
    select
      new.client_id,
      'Reemplazo urgente: ' || new.service_name,
      'Tarea cancelada, se necesita un YOER de reemplazo lo antes posible.',
      s.category,
      new.latitude, new.longitude, new.address,
      new.total_price,
      now() + interval '24 hours'
    from public.services s where s.id = new.service_id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_send_cancelled_booking_to_radar on public.bookings;
create trigger trg_send_cancelled_booking_to_radar
  after update on public.bookings
  for each row execute procedure public.send_cancelled_booking_to_radar();

-- Notifica al dueño de una tarea cuando recibe postulaciones, y al YOER cuando es aceptado
create or replace function public.notify_task_application()
returns trigger as $$
declare
  owner uuid;
  task_title text;
begin
  if TG_OP = 'INSERT' then
    if new.target_type = 'TASK_REQUEST' then
      select client_id, title into owner, task_title from public.task_requests where id = new.task_request_id;
    else
      select client_id, title into owner, task_title from public.urgent_tasks where id = new.urgent_task_id;
    end if;

    insert into public.notifications (user_id, type, title, body, data)
    values (owner, 'NUEVA_POSTULACION', 'Nueva postulación',
            coalesce(task_title, 'Tu tarea'), jsonb_build_object('application_id', new.id));

  elsif TG_OP = 'UPDATE' and new.status is distinct from old.status and new.status = 'ACEPTADA' then
    insert into public.notifications (user_id, type, title, body, data)
    values (new.yoer_id, 'POSTULACION_ACEPTADA', '¡Postulación aceptada!',
            'Te asignaron la tarea', jsonb_build_object('application_id', new.id));
  end if;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_notify_task_application on public.task_applications;
create trigger trg_notify_task_application
  after insert or update on public.task_applications
  for each row execute procedure public.notify_task_application();

-- Mantiene applicants_count de urgent_tasks al día
create or replace function public.increment_urgent_task_applicants()
returns trigger as $$
begin
  if new.target_type = 'URGENT_TASK' then
    update public.urgent_tasks set applicants_count = applicants_count + 1 where id = new.urgent_task_id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_increment_urgent_task_applicants on public.task_applications;
create trigger trg_increment_urgent_task_applicants
  after insert on public.task_applications
  for each row execute procedure public.increment_urgent_task_applicants();

-- Notifica nueva amonestación y resolución de apelación
create or replace function public.notify_sanction()
returns trigger as $$
begin
  insert into public.notifications (user_id, type, title, body, data)
  values (new.user_id, 'AMONESTACION', 'Nueva amonestación', new.reason, jsonb_build_object('sanction_id', new.id));
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_notify_sanction on public.sanctions;
create trigger trg_notify_sanction
  after insert on public.sanctions
  for each row execute procedure public.notify_sanction();

create or replace function public.notify_appeal_resolved()
returns trigger as $$
begin
  if new.status is distinct from old.status and new.status in ('APROBADA', 'RECHAZADA') then
    insert into public.notifications (user_id, type, title, body, data)
    values (new.user_id, 'APELACION_RESUELTA',
            case when new.status = 'APROBADA' then 'Apelación aprobada' else 'Apelación rechazada' end,
            'Tu apelación fue revisada', jsonb_build_object('appeal_id', new.id));
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_notify_appeal_resolved on public.sanction_appeals;
create trigger trg_notify_appeal_resolved
  after update on public.sanction_appeals
  for each row execute procedure public.notify_appeal_resolved();

-- Acepta una postulación de forma atómica: marca la postulación como
-- ACEPTADA y asigna al YOER en la tarea correspondiente en una sola
-- transacción, verificando que quien llama sea el dueño de la tarea.
create or replace function public.accept_task_application(app_id uuid)
returns void as $$
declare
  app record;
  owner_id uuid;
begin
  select * into app from public.task_applications where id = app_id;
  if not found then
    raise exception 'Postulación no encontrada';
  end if;

  if app.target_type = 'TASK_REQUEST' then
    select client_id into owner_id from public.task_requests where id = app.task_request_id;
  else
    select client_id into owner_id from public.urgent_tasks where id = app.urgent_task_id;
  end if;

  if owner_id is distinct from auth.uid() then
    raise exception 'No tienes permiso para aceptar esta postulación';
  end if;

  update public.task_applications set status = 'ACEPTADA' where id = app_id;

  if app.target_type = 'TASK_REQUEST' then
    update public.task_requests
    set status = 'ASIGNADA', assigned_yoer_id = app.yoer_id, updated_at = now()
    where id = app.task_request_id;
  else
    update public.urgent_tasks
    set assigned_yoer_id = app.yoer_id, is_active = false
    where id = app.urgent_task_id;
  end if;
end;
$$ language plpgsql security definer;

-- ──────────────────────────────────────────────────
-- FUNCIONES UTILITARIAS: búsqueda cercana y ranking
-- ──────────────────────────────────────────────────

-- Buscar servicios cercanos (haversine simple)
create or replace function public.get_nearby_services(
  user_lat double precision,
  user_lng double precision,
  radius_km double precision default 50,
  lim integer default 20
)
returns table(id uuid, title text, distance_km double precision) as $$
begin
  return query
  select
    s.id,
    s.title,
    (6371 * acos(
      cos(radians(user_lat)) * cos(radians(s.latitude)) *
      cos(radians(s.longitude) - radians(user_lng)) +
      sin(radians(user_lat)) * sin(radians(s.latitude))
    )) as distance_km
  from public.services s
  where s.is_active = true
    and s.latitude is not null
    and s.longitude is not null
  having (6371 * acos(
    cos(radians(user_lat)) * cos(radians(s.latitude)) *
    cos(radians(s.longitude) - radians(user_lng)) +
    sin(radians(user_lat)) * sin(radians(s.latitude))
  )) <= radius_km
  order by distance_km asc
  limit lim;
end;
$$ language plpgsql;

-- Tareas urgentes cercanas (mismo patrón haversine)
create or replace function public.get_nearby_urgent_tasks(
  user_lat double precision,
  user_lng double precision,
  radius_km double precision default 50,
  lim integer default 20
)
returns table(id uuid, title text, distance_km double precision) as $$
begin
  return query
  select
    t.id,
    t.title,
    (6371 * acos(
      cos(radians(user_lat)) * cos(radians(t.latitude)) *
      cos(radians(t.longitude) - radians(user_lng)) +
      sin(radians(user_lat)) * sin(radians(t.latitude))
    )) as distance_km
  from public.urgent_tasks t
  where t.is_active = true
    and t.latitude is not null and t.longitude is not null
    and t.expires_at > now()
  having (6371 * acos(
    cos(radians(user_lat)) * cos(radians(t.latitude)) *
    cos(radians(t.longitude) - radians(user_lng)) +
    sin(radians(user_lat)) * sin(radians(t.latitude))
  )) <= radius_km
  order by distance_km asc
  limit lim;
end;
$$ language plpgsql;

-- Ranking de YOERs por categoría/métrica (rating | completed_jobs | price)
create or replace function public.get_yoer_ranking(
  filter_category service_category default null,
  metric text default 'rating',
  lim integer default 20
)
returns table(
  id uuid, full_name text, profile_image_url text, rating double precision,
  completed_jobs integer, city text, avg_price double precision
) as $$
begin
  return query
  select
    p.id, p.full_name, p.profile_image_url, p.rating, p.completed_jobs, p.city,
    coalesce(avg(s.price), 0) as avg_price
  from public.profiles p
  left join public.services s on s.yoer_id = p.id and s.is_active = true
    and (filter_category is null or s.category = filter_category)
  where p.user_type = 'YOER'
    and (filter_category is null or exists (
      select 1 from public.services s2 where s2.yoer_id = p.id and s2.category = filter_category
    ))
  group by p.id
  order by
    case when metric = 'completed_jobs' then p.completed_jobs end desc nulls last,
    case when metric = 'price' then coalesce(avg(s.price), 999999) end asc nulls last,
    p.rating desc
  limit lim;
end;
$$ language plpgsql;

-- ──────────────────────────────────────────────────
-- Storage: buckets públicos (idempotente, no requiere pasos manuales en el
-- Dashboard). "cover-images" también se usa para banners de eventos/voluntariado.
-- ──────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
values
  ('profile-images', 'profile-images', true),
  ('service-images', 'service-images', true),
  ('cover-images',   'cover-images',   true)
on conflict (id) do nothing;

-- Lectura pública de los tres buckets (además del acceso vía public URL)
drop policy if exists "Lectura pública de imágenes" on storage.objects;
create policy "Lectura pública de imágenes" on storage.objects
  for select using (bucket_id in ('profile-images', 'service-images', 'cover-images'));

-- profile-images: cada usuario solo escribe dentro de su propia carpeta ({user_id}/...)
drop policy if exists "Usuario sube su foto de perfil" on storage.objects;
create policy "Usuario sube su foto de perfil" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'profile-images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Usuario actualiza su foto de perfil" on storage.objects;
create policy "Usuario actualiza su foto de perfil" on storage.objects
  for update to authenticated
  using (bucket_id = 'profile-images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Usuario borra su foto de perfil" on storage.objects;
create policy "Usuario borra su foto de perfil" on storage.objects
  for delete to authenticated
  using (bucket_id = 'profile-images' and (storage.foldername(name))[1] = auth.uid()::text);

-- service-images: la ruta es "{service_id}/archivo.ext" (ver
-- ServiceRemoteDataSource.uploadServiceImage). Hardening (SECURITY_REPORT.md):
-- antes cualquier usuario autenticado podía escribir/borrar en cualquier ruta
-- del bucket; ahora se exige que el service_id de la carpeta pertenezca al
-- YOER autenticado.
drop policy if exists "Autenticados suben imágenes de servicio/portada" on storage.objects;
drop policy if exists "Yoer sube imágenes de sus servicios" on storage.objects;
create policy "Yoer sube imágenes de sus servicios" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'service-images' and exists (
      select 1 from public.services s
      where s.id::text = (storage.foldername(name))[1] and s.yoer_id = auth.uid()
    )
  );

drop policy if exists "Yoer actualiza imágenes de sus servicios" on storage.objects;
create policy "Yoer actualiza imágenes de sus servicios" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'service-images' and exists (
      select 1 from public.services s
      where s.id::text = (storage.foldername(name))[1] and s.yoer_id = auth.uid()
    )
  );

drop policy if exists "Autenticados gestionan imágenes de servicio/portada" on storage.objects;
drop policy if exists "Yoer borra imágenes de sus servicios" on storage.objects;
create policy "Yoer borra imágenes de sus servicios" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'service-images' and exists (
      select 1 from public.services s
      where s.id::text = (storage.foldername(name))[1] and s.yoer_id = auth.uid()
    )
  );

-- cover-images: hoy no existe código en la app que suba a este bucket (bucket
-- provisionado pero sin consumidor). Se define la misma convención que
-- profile-images ({user_id}/archivo.ext) como el patrón a seguir cuando se
-- implemente la subida de portada, para no dejar el bucket sin scoping por
-- dueño mientras tanto.
drop policy if exists "Usuario sube su portada" on storage.objects;
create policy "Usuario sube su portada" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'cover-images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Usuario actualiza su portada" on storage.objects;
create policy "Usuario actualiza su portada" on storage.objects
  for update to authenticated
  using (bucket_id = 'cover-images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Usuario borra su portada" on storage.objects;
create policy "Usuario borra su portada" on storage.objects
  for delete to authenticated
  using (bucket_id = 'cover-images' and (storage.foldername(name))[1] = auth.uid()::text);

-- ──────────────────────────────────────────────────
-- REALTIME: habilitar para las tablas que lo necesitan
-- ──────────────────────────────────────────────────
do $$ begin
  alter publication supabase_realtime add table public.bookings;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.reviews;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.urgent_tasks;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.task_applications;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.wallet_transactions;
exception when duplicate_object then null; end $$;



-- 1. Actualizar la función del trigger de nuevos usuarios
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, username, full_name, user_type)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Usuario'),
    COALESCE((NEW.raw_user_meta_data->>'user_type')::public.user_type, 'CLIENT'::public.user_type)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Re-vincular el trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 2. Actualizar la función del trigger de creación de wallets
CREATE OR REPLACE FUNCTION public.handle_new_wallet()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.wallet_accounts (user_id) VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Re-vincular el trigger de wallet
DROP TRIGGER IF EXISTS on_profile_created_wallet ON public.profiles;
CREATE TRIGGER on_profile_created_wallet
  AFTER INSERT ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_wallet();