-- Seed data for Local Transport Info (Supabase / Postgres)
-- Tables expected:
--   public.stops(stop_id text primary key, name_bn text, name_en text)
--   public.routes(route_id text primary key, route_no text, name_bn text, name_en text, total_km numeric, rate_per_km numeric)
--   public.fares(id bigserial primary key, route_id text, from_stop text, to_stop text, fare numeric)
--
-- If you don't yet have unique constraints, you can still run plain INSERTs,
-- but you may get duplicates. Recommended constraints:
--   stops:  primary key (stop_id)
--   routes: primary key (route_id)
--   fares:  unique (route_id, from_stop, to_stop)

begin;

-- Recommended (safe) constraints (run once; comment out if already exists)
-- ALTER TABLE public.stops  ADD CONSTRAINT stops_pkey  PRIMARY KEY (stop_id);
-- ALTER TABLE public.routes ADD CONSTRAINT routes_pkey PRIMARY KEY (route_id);
-- CREATE UNIQUE INDEX IF NOT EXISTS fares_route_from_to_ux ON public.fares(route_id, from_stop, to_stop);

-- STOPS
insert into public.stops (stop_id, name_bn, name_en) values
  ('kalshi','কালশী','Kalshi'),
  ('mirpur12','মিরপুর-১২','Mirpur-12'),
  ('mirpur10','মিরপুর-১০','Mirpur-10'),
  ('kazipara','কাজীপাড়া','Kazipara'),
  ('shewrapara','শেওড়াপাড়া','Shewrapara'),
  ('farmgate','ফার্মগেট','Farmgate'),
  ('shahbag','শাহবাগ','Shahbag'),
  ('paltan','পল্টন','Paltan'),
  ('gulistan','গুলিস্তান','Gulistan'),
  ('tiktuli','টিকাটুলি','Tikatuli'),
  ('saydabad','সায়দাবাদ','Saydabad'),
  ('jatrabari','যাত্রাবাড়ী','Jatrabari'),
  ('signboard','সাইনবোর্ড','Signboard'),
  ('kanchpur','কাঁচপুর ব্রিজ','Kanchpur Bridge')
on conflict (stop_id) do update set
  name_bn = excluded.name_bn,
  name_en = excluded.name_en;

-- ROUTES
insert into public.routes (route_id, route_no, name_bn, name_en, total_km, rate_per_km) values
  ('a101','A-101','কালশী → কাঁচপুর ব্রিজ','Kalshi → Kanchpur Bridge',28.8),
  ('a102','A-102','মিরপুর → সদরঘাট','Mirpur → Sadarghat',null),
  ('a103','A-103','উত্তরা → মতিঝিল','Uttara → Motijheel',null),
  ('a104','A-104','মিরপুর → গুলিস্তান','Mirpur → Gulistan',null),
  ('a105','A-105','গাবতলী → যাত্রাবাড়ী','Gabtoli → Jatrabari',null)
on conflict (route_id) do update set
  route_no = excluded.route_no,
  name_bn  = excluded.name_bn,
  name_en  = excluded.name_en,
  total_km = excluded.total_km,
  rate_per_km = excluded.rate_per_km;

-- FARES
insert into public.fares (route_id, from_stop, to_stop, fare) values
  ('a101','kalshi','mirpur12',10),
  ('a101','kalshi','mirpur10',12),
  ('a101','kalshi','kazipara',15),
  ('a101','kalshi','shewrapara',17),
  ('a101','kalshi','farmgate',28),
  ('a101','kalshi','shahbag',34),
  ('a101','kalshi','paltan',38),
  ('a101','kalshi','gulistan',41),
  ('a101','kalshi','tiktuli',44),
  ('a101','kalshi','saydabad',46),
  ('a101','kalshi','jatrabari',49),
  ('a101','kalshi','signboard',52),
  ('a101','kalshi','kanchpur',56)
on conflict (route_id, from_stop, to_stop) do update set
  fare = excluded.fare;

commit;

-- RLS quick policies (run in Supabase SQL Editor if you have RLS enabled)
-- alter table public.stops  enable row level security;
-- alter table public.routes enable row level security;
-- alter table public.fares  enable row level security;
--
-- drop policy if exists "public read stops"  on public.stops;
-- drop policy if exists "public read routes" on public.routes;
-- drop policy if exists "public read fares"  on public.fares;
--
-- create policy "public read stops"  on public.stops  for select to anon using (true);
-- create policy "public read routes" on public.routes for select to anon using (true);
-- create policy "public read fares"  on public.fares  for select to anon using (true);

-- Admins table (for admin login + fare edits)
-- Create Supabase auth users first, then add them here.
-- create table if not exists public.admins (
--   id bigserial primary key,
--   user_id uuid,
--   email text,
--   created_at timestamptz default now()
-- );
-- create unique index if not exists admins_user_id_ux on public.admins(user_id);
-- create unique index if not exists admins_email_ux on public.admins(email);

-- Example insert (email-only; easiest):
-- insert into public.admins (email) values ('admin@gmail.com');
-- Example insert (recommended if you have the UUID):
-- insert into public.admins (user_id, email)
-- values ('<AUTH_USER_UUID>', 'admin@gmail.com');

-- RLS for admins table
-- alter table public.admins enable row level security;
-- drop policy if exists "admins can read own row" on public.admins;
-- create policy "admins can read own row" on public.admins
--   for select to authenticated
--   using (
--     auth.uid() = user_id
--     or (auth.jwt() ->> 'email') = email
--   );

-- Optional: allow admins to insert/update fares
-- drop policy if exists "admins manage fares" on public.fares;
-- create policy "admins manage fares" on public.fares
--   for all to authenticated
--   using (
--     exists (
--       select 1 from public.admins
--       where user_id = auth.uid()
--          or email = (auth.jwt() ->> 'email')
--     )
--   )
--   with check (
--     exists (
--       select 1 from public.admins
--       where user_id = auth.uid()
--          or email = (auth.jwt() ->> 'email')
--     )
--   );
