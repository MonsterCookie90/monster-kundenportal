-- Monster Kundenportal: run only in a dedicated portal database/project.
-- Do not run against an existing licensing schema without review.
create extension if not exists pgcrypto;
create table if not exists public.companies(id uuid primary key default gen_random_uuid(),code text unique not null check(code ~ '^[A-Z0-9_-]{3,32}$'),name text not null,created_at timestamptz not null default now());
create table if not exists public.profiles(id uuid primary key references auth.users(id) on delete cascade,company_id uuid not null references public.companies(id),display_name text not null,role text not null check(role in ('owner','admin','office','worker')),created_at timestamptz not null default now());
create or replace function public.my_company() returns uuid language sql stable security definer set search_path=public as $$ select company_id from public.profiles where id=auth.uid() $$;
create or replace function public.my_role() returns text language sql stable security definer set search_path=public as $$ select role from public.profiles where id=auth.uid() $$;
revoke all on function public.my_company() from public;revoke all on function public.my_role() from public;
grant execute on function public.my_company() to authenticated;grant execute on function public.my_role() to authenticated;
create table if not exists public.employees(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id),profile_id uuid references public.profiles(id),name text not null,role text,active boolean not null default true);
create table if not exists public.customers(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id),name text not null,contact_email text,phone text,address text);
create table if not exists public.vehicles(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id),label text not null,registration text);
create table if not exists public.work_orders(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id),number text not null,title text not null,customer_id uuid references public.customers(id),assigned_profile_id uuid references public.profiles(id),status text not null default 'open',planned_at timestamptz,created_at timestamptz not null default now(),unique(company_id,number));
create table if not exists public.shifts(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id),profile_id uuid not null references public.profiles(id),title text not null,starts_at timestamptz not null,ends_at timestamptz not null check(ends_at>starts_at));
create table if not exists public.activities(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id),name text not null,aw numeric(10,2) not null default 0 check(aw>=0),price_per_aw numeric(12,2) not null default 0 check(price_per_aw>=0));
create table if not exists public.inventory_items(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id),name text not null,quantity numeric(12,3) not null default 0,unit text not null default 'Stk');
create table if not exists public.work_reports(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id),order_id uuid not null references public.work_orders(id),author_profile_id uuid not null references public.profiles(id),status text not null default 'draft',started_at timestamptz,ended_at timestamptz,notes text,created_at timestamptz not null default now());
create table if not exists public.work_photos(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id),order_id uuid not null references public.work_orders(id),file_path text not null,created_at timestamptz not null default now());
-- Restrict all tables to their company. Workers additionally see only assigned orders/shifts/reports.
do $$ declare t text; begin foreach t in array array['companies','profiles','employees','customers','vehicles','work_orders','shifts','activities','inventory_items','work_reports','work_photos'] loop execute format('alter table public.%I enable row level security',t);end loop;end $$;
create policy company_read on public.companies for select to authenticated using(id=public.my_company());
create policy profile_read on public.profiles for select to authenticated using(company_id=public.my_company() and (id=auth.uid() or public.my_role() in ('owner','admin','office')));
create policy employees_read on public.employees for select to authenticated using(company_id=public.my_company() and (profile_id=auth.uid() or public.my_role() in ('owner','admin','office')));
create policy customers_read on public.customers for select to authenticated using(company_id=public.my_company() and public.my_role() in ('owner','admin','office'));
create policy vehicles_read on public.vehicles for select to authenticated using(company_id=public.my_company() and public.my_role() in ('owner','admin','office'));
create policy orders_read on public.work_orders for select to authenticated using(company_id=public.my_company() and (assigned_profile_id=auth.uid() or public.my_role() in ('owner','admin','office')));
create policy shifts_read on public.shifts for select to authenticated using(company_id=public.my_company() and (profile_id=auth.uid() or public.my_role() in ('owner','admin','office')));
create policy activities_read on public.activities for select to authenticated using(company_id=public.my_company());
create policy inventory_read on public.inventory_items for select to authenticated using(company_id=public.my_company() and public.my_role() in ('owner','admin','office'));
create policy reports_read on public.work_reports for select to authenticated using(company_id=public.my_company() and (author_profile_id=auth.uid() or public.my_role() in ('owner','admin','office')));
create policy photos_read on public.work_photos for select to authenticated using(company_id=public.my_company() and (public.my_role() in ('owner','admin','office') or exists(select 1 from public.work_orders o where o.id=order_id and o.assigned_profile_id=auth.uid())));
-- No client-side INSERT/UPDATE/DELETE policies yet. Mutations must be implemented and audited before activation.
-- Provision first company and owner from a trusted server-side administrative workflow, never the browser.
create index if not exists idx_profiles_company on public.profiles(company_id);
create index if not exists idx_orders_company_assigned on public.work_orders(company_id,assigned_profile_id);
create index if not exists idx_shifts_company_profile on public.shifts(company_id,profile_id);
