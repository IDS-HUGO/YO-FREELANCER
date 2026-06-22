-- ============================================================
-- YO FREE-LANCER — Supabase Schema
-- Ejecuta este SQL en el SQL Editor de tu proyecto Supabase
-- Supabase Dashboard → SQL Editor → New Query
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
create type user_type as enum ('YOER', 'CLIENT');
create type user_status as enum ('DISPONIBLE', 'OCUPADO', 'NO_DISPONIBLE', 'WARNED');
create type availability_status as enum ('AVAILABLE', 'NOT_AVAILABLE', 'IN_TASK', 'WARNED');
create type service_category as enum (
  'CONSTRUCCION', 'LIMPIEZA', 'REPARACION', 'EDUCACION',
  'ARTE', 'MUSICA', 'DEPORTES', 'TECNOLOGIA', 'SALUD',
  'BELLEZA', 'TRANSPORTE', 'OTROS'
);
create type service_type as enum ('A_DOMICILIO', 'LOCAL', 'REMOTO', 'HIBRIDO');
create type price_type as enum ('POR_HORA', 'PRECIO_FIJO', 'NEGOCIABLE');
create type booking_status as enum (
  'PENDIENTE', 'CONFIRMADA', 'EN_PROGRESO',
  'COMPLETADA', 'CANCELADA', 'RECHAZADA'
);
create type payment_status as enum ('PENDIENTE', 'PAGADO', 'REEMBOLSADO', 'FALLIDO');
create type payment_method_type as enum (
  'EFECTIVO', 'TARJETA_CREDITO', 'TARJETA_DEBITO',
  'TRANSFERENCIA', 'OXXO', 'PAYPAL', 'MERCADO_PAGO'
);
create type transaction_type as enum ('PAGO', 'REEMBOLSO', 'COMISION');
create type sanction_severity as enum ('WARNING', 'AMONESTACION', 'SUSPENSION', 'BAN');

-- ──────────────────────────────────────────────────
-- TABLA: profiles (extiende auth.users de Supabase)
-- ──────────────────────────────────────────────────
create table public.profiles (
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
  -- Timestamps
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

-- RLS para profiles
alter table public.profiles enable row level security;

create policy "Perfiles visibles para todos"
  on public.profiles for select using (true);

create policy "Usuario edita su propio perfil"
  on public.profiles for update using (auth.uid() = id);

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
    coalesce((new.raw_user_meta_data->>'user_type')::user_type, 'CLIENT')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ──────────────────────────────────────────────────
-- TABLA: freelancer_profiles (extra para YOERs)
-- ──────────────────────────────────────────────────
create table public.freelancer_profiles (
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

create policy "Perfiles freelancer visibles"
  on public.freelancer_profiles for select using (true);

create policy "YOER edita su propio perfil freelancer"
  on public.freelancer_profiles for all using (auth.uid() = user_id);

-- ──────────────────────────────────────────────────
-- TABLA: badges (insignias)
-- ──────────────────────────────────────────────────
create table public.badges (
  id          uuid default uuid_generate_v4() primary key,
  user_id     uuid references public.profiles(id) on delete cascade,
  name        text not null,
  description text,
  icon_url    text,
  earned_at   timestamptz default now()
);

alter table public.badges enable row level security;
create policy "Badges visibles" on public.badges for select using (true);

-- ──────────────────────────────────────────────────
-- TABLA: sanctions (sanciones)
-- ──────────────────────────────────────────────────
create table public.sanctions (
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
create policy "Sanciones visibles por admin y propio usuario"
  on public.sanctions for select
  using (auth.uid() = user_id);

-- ──────────────────────────────────────────────────
-- TABLA: categories
-- ──────────────────────────────────────────────────
create table public.categories (
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
  ('OTROS',        'Otros',          'Servicios varios');

-- ──────────────────────────────────────────────────
-- TABLA: services
-- ──────────────────────────────────────────────────
create table public.services (
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
  -- Disponibilidad (JSON)
  availability  jsonb default '{"monday":false,"tuesday":false,"wednesday":false,"thursday":false,"friday":false,"saturday":false,"sunday":false}',
  requirements  text[] default '{}',
  included_items text[] default '{}',
  -- Timestamps
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

create index idx_services_yoer_id   on public.services(yoer_id);
create index idx_services_category  on public.services(category);
create index idx_services_city      on public.services(city);
create index idx_services_is_active on public.services(is_active);
create index idx_services_rating    on public.services(rating desc);

alter table public.services enable row level security;

create policy "Servicios activos visibles para todos"
  on public.services for select using (is_active = true or auth.uid() = yoer_id);

create policy "YOER gestiona sus servicios"
  on public.services for all using (auth.uid() = yoer_id);

-- ──────────────────────────────────────────────────
-- TABLA: bookings
-- ──────────────────────────────────────────────────
create table public.bookings (
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

create index idx_bookings_yoer_id   on public.bookings(yoer_id);
create index idx_bookings_client_id on public.bookings(client_id);
create index idx_bookings_status    on public.bookings(status);
create index idx_bookings_date      on public.bookings(scheduled_date);

alter table public.bookings enable row level security;

create policy "Reserva visible por yoer y cliente"
  on public.bookings for select
  using (auth.uid() = yoer_id or auth.uid() = client_id);

create policy "Cliente crea reserva"
  on public.bookings for insert with check (auth.uid() = client_id);

create policy "Yoer/cliente actualiza reserva"
  on public.bookings for update
  using (auth.uid() = yoer_id or auth.uid() = client_id);

-- ──────────────────────────────────────────────────
-- TABLA: payments
-- ──────────────────────────────────────────────────
create table public.payments (
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

create policy "Pago visible por usuario"
  on public.payments for select using (auth.uid() = user_id);

create policy "Usuario crea pago"
  on public.payments for insert with check (auth.uid() = user_id);

-- ──────────────────────────────────────────────────
-- TABLA: reviews
-- ──────────────────────────────────────────────────
create table public.reviews (
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
create policy "Reseñas visibles" on public.reviews for select using (true);
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

create trigger after_review_insert
  after insert on public.reviews
  for each row execute procedure public.update_ratings_after_review();

-- ──────────────────────────────────────────────────
-- TABLA: payment_cards (tarjetas guardadas)
-- ──────────────────────────────────────────────────
create table public.payment_cards (
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
create policy "Usuario ve sus tarjetas"
  on public.payment_cards for all using (auth.uid() = user_id);

-- ──────────────────────────────────────────────────
-- TABLA: urgent_tasks (tareas urgentes)
-- ──────────────────────────────────────────────────
create table public.urgent_tasks (
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
  created_at      timestamptz default now(),
  expires_at      timestamptz not null
);

alter table public.urgent_tasks enable row level security;
create policy "Tareas urgentes visibles" on public.urgent_tasks for select using (true);
create policy "Cliente gestiona sus tareas" on public.urgent_tasks for all
  using (auth.uid() = client_id);

-- ──────────────────────────────────────────────────
-- FUNCIONES UTILITARIAS
-- ──────────────────────────────────────────────────

-- Buscar servicios cercanos (requiere pg_sphere o usando haversine simple)
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

-- Función para Storage (imágenes públicas)
-- Ejecutar en Supabase Dashboard → Storage → New bucket:
--   "profile-images" (público)
--   "service-images" (público)
--   "cover-images"   (público)

-- ──────────────────────────────────────────────────
-- REALTIME: habilitar para bookings y reviews
-- ──────────────────────────────────────────────────
alter publication supabase_realtime add table public.bookings;
alter publication supabase_realtime add table public.reviews;
alter publication supabase_realtime add table public.urgent_tasks;
