-- MilkDirect Full Schema for Supabase (prefixed with mk_ to coexist in shared projects like queuekissan).
-- Run in the Supabase SQL editor.

create extension if not exists pgcrypto;

-- 1. Profiles
create table if not exists mk_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  phone text,
  alternate_phone text,
  photo_url text,
  role text not null check (role in ('customer','supplier','admin')),
  language text not null default 'en' check (language in ('en','hi','mr')),
  is_blocked boolean not null default false,
  created_at timestamptz not null default now()
);

create unique index if not exists mk_profiles_phone_unique 
  on mk_profiles (phone) 
  where phone is not null and phone != '';

-- 2. Supplier Profiles
create table if not exists mk_supplier_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references mk_profiles(id) on delete cascade,
  shop_name text,
  photo_url text,
  cover_url text,
  about text,
  type text not null check (type in ('farmer','milkman')),
  village text not null,
  pincode text not null,
  upi_id text,
  bank_account_no text,
  bank_ifsc text,
  fssai_no text,
  documents jsonb not null default '[]'::jsonb,
  verification_status text not null default 'pending' check (verification_status in ('pending','verified','rejected')),
  rejection_reason text,
  rating_avg numeric(3,2) not null default 5.0,
  rating_count int not null default 0,
  delivery_slots text[] not null default '{"morning_5_8","morning_8_10","evening_5_8"}'::text[],
  created_at timestamptz not null default now()
);

-- 3. Products
create table if not exists mk_products (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid not null references mk_supplier_profiles(id) on delete cascade,
  milk_type text not null check (milk_type in ('cow','buffalo','other')),
  price_per_litre numeric(8,2) not null check (price_per_litre > 0),
  daily_quantity_l numeric(8,2) not null default 0,
  fat_percent numeric(4,2),
  snf_percent numeric(4,2),
  source text not null default 'own_cattle' check (source in ('own_cattle','collected')),
  processing text not null default 'raw' check (processing in ('raw','boiled','pasteurised')),
  min_order_l numeric(4,2) not null default 0.5,
  delivery_charge numeric(6,2) not null default 0,
  unavailable_until date,
  photo_url text,
  available boolean not null default true,
  created_at timestamptz not null default now()
);

-- 4. Customer Addresses
create table if not exists mk_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references mk_profiles(id) on delete cascade,
  label text not null default 'Home',
  line text not null,
  landmark text,
  pincode text not null,
  contact_phone text,
  is_default boolean not null default false,
  latitude numeric(10,7),
  longitude numeric(10,7),
  created_at timestamptz not null default now()
);

-- 5. Service Areas
create table if not exists mk_service_areas (
  supplier_id uuid not null references mk_supplier_profiles(id) on delete cascade,
  pincode text not null,
  primary key (supplier_id, pincode)
);

-- 6. Subscriptions
create table if not exists mk_subscriptions (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references mk_profiles(id) on delete cascade,
  supplier_id uuid not null references mk_supplier_profiles(id),
  product_id uuid not null references mk_products(id),
  quantity_l numeric(6,2) not null check (quantity_l > 0),
  frequency text not null default 'daily' check (frequency in ('daily','alternate','custom')),
  weekdays int[] not null default '{1,2,3,4,5,6,7}'::int[],
  slot text not null default 'morning_5_8' check (slot in ('morning_5_8','morning_8_10','evening_5_8')),
  start_date date not null,
  end_date date,
  status text not null default 'active' check (status in ('active','paused','cancelled')),
  skip_dates date[] not null default '{}',
  address text,
  instructions text,
  payment_mode text not null default 'cash' check (payment_mode in ('cash','upi','monthly')),
  delivery_charge numeric(6,2) not null default 0,
  created_at timestamptz not null default now()
);

-- 7. Orders
create table if not exists mk_orders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references mk_profiles(id) on delete cascade,
  supplier_id uuid not null references mk_supplier_profiles(id),
  product_id uuid not null references mk_products(id),
  subscription_id uuid references mk_subscriptions(id) on delete set null,
  delivery_date date not null,
  slot text not null default 'morning_5_8',
  quantity_l numeric(6,2) not null check (quantity_l > 0),
  delivered_quantity numeric(6,2),
  amount numeric(10,2) not null default 0,
  delivery_charge numeric(6,2) not null default 0,
  status text not null default 'pending' check (status in ('pending','delivered','missed','rescheduled')),
  address text,
  instructions text,
  payment_mode text not null default 'cash',
  created_at timestamptz not null default now(),
  unique (subscription_id, delivery_date)
);

-- 8. Payments
create table if not exists mk_payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references mk_orders(id) on delete cascade,
  amount numeric(10,2) not null,
  method text not null check (method in ('cash','upi','online')),
  status text not null default 'paid',
  created_at timestamptz not null default now()
);

-- 9. Reviews
create table if not exists mk_reviews (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references mk_profiles(id) on delete cascade,
  supplier_id uuid not null references mk_supplier_profiles(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  unique (customer_id, supplier_id)
);

-- 10. Complaints
create table if not exists mk_complaints (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references mk_orders(id) on delete cascade,
  customer_id uuid not null references mk_profiles(id) on delete cascade,
  issue_type text not null default 'quality' check (issue_type in ('missed','late','quantity','quality','other')),
  issue text not null,
  photo_url text,
  admin_notes text,
  resolution_status text not null default 'open' check (resolution_status in ('open','resolved')),
  created_at timestamptz not null default now()
);

-- ---------- Helper Functions ----------
create or replace function mk_is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from mk_profiles where id = auth.uid() and role = 'admin');
$$;

create or replace function mk_my_supplier_id() returns uuid
language sql stable security definer set search_path = public as $$
  select id from mk_supplier_profiles where user_id = auth.uid();
$$;

-- Admin-only verification (suppliers cannot verify themselves)
create or replace function mk_set_supplier_verification(p_supplier uuid, p_status text, p_reason text default null) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not mk_is_admin() then raise exception 'admin only'; end if;
  if p_status not in ('verified','rejected','pending') then raise exception 'bad status'; end if;
  update mk_supplier_profiles set verification_status = p_status, rejection_reason = p_reason where id = p_supplier;
end $$;

-- Creates the day's orders from active subscriptions (idempotent, honours skip dates and weekdays)
create or replace function mk_generate_orders_for_date(d date) returns void
language sql security definer set search_path = public as $$
  insert into mk_orders (customer_id, supplier_id, product_id, subscription_id, delivery_date, slot, quantity_l, amount, delivery_charge, address, instructions, payment_mode)
  select 
    s.customer_id, 
    s.supplier_id, 
    s.product_id, 
    s.id, 
    d, 
    s.slot,
    s.quantity_l, 
    (s.quantity_l * p.price_per_litre) + coalesce(s.delivery_charge, 0),
    coalesce(s.delivery_charge, 0),
    s.address,
    s.instructions,
    s.payment_mode
  from mk_subscriptions s 
  join mk_products p on p.id = s.product_id
  where s.status = 'active' 
    and s.start_date <= d 
    and (s.end_date is null or s.end_date >= d)
    and not (d = any (s.skip_dates))
    and (
      s.frequency = 'daily' or
      (s.frequency = 'alternate' and ((d - s.start_date) % 2 = 0)) or
      (s.frequency = 'custom' and (extract(isodow from d)::int = any(s.weekdays)))
    )
  on conflict (subscription_id, delivery_date) do nothing;
$$;

-- Price and supplier always come from the product, never from the client
create or replace function mk_set_order_amount() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  select supplier_id, (new.quantity_l * price_per_litre) + coalesce(delivery_charge, 0)
  into new.supplier_id, new.amount
  from mk_products where id = new.product_id;
  return new;
end $$;

drop trigger if exists mk_trg_order_amount on mk_orders;
create trigger mk_trg_order_amount before insert on mk_orders for each row execute function mk_set_order_amount();

-- Trigger to recalculate supplier rating average
create or replace function mk_update_supplier_rating() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update mk_supplier_profiles 
  set rating_avg = coalesce((select avg(rating)::numeric(3,2) from mk_reviews where supplier_id = coalesce(new.supplier_id, old.supplier_id)), 5.0),
      rating_count = coalesce((select count(*) from mk_reviews where supplier_id = coalesce(new.supplier_id, old.supplier_id)), 0)
  where id = coalesce(new.supplier_id, old.supplier_id);
  return new;
end $$;

drop trigger if exists mk_trg_supplier_rating on mk_reviews;
create trigger mk_trg_supplier_rating after insert or update or delete on mk_reviews for each row execute function mk_update_supplier_rating();

-- ---------- Column-Level Permissions ----------
revoke update on mk_profiles from authenticated;
grant update (name, phone, alternate_phone, photo_url, language) on mk_profiles to authenticated;
revoke insert, update on mk_supplier_profiles from authenticated;
grant insert (user_id, shop_name, photo_url, cover_url, about, type, village, pincode, upi_id, bank_account_no, bank_ifsc, fssai_no, documents, delivery_slots) on mk_supplier_profiles to authenticated;
grant update (shop_name, photo_url, cover_url, about, village, pincode, upi_id, bank_account_no, bank_ifsc, fssai_no, documents, delivery_slots) on mk_supplier_profiles to authenticated;

-- ---------- RLS ----------
alter table mk_profiles enable row level security;
alter table mk_supplier_profiles enable row level security;
alter table mk_products enable row level security;
alter table mk_addresses enable row level security;
alter table mk_service_areas enable row level security;
alter table mk_subscriptions enable row level security;
alter table mk_orders enable row level security;
alter table mk_payments enable row level security;
alter table mk_reviews enable row level security;
alter table mk_complaints enable row level security;

-- mk_profiles
drop policy if exists mk_p_self_select on mk_profiles;
create policy mk_p_self_select on mk_profiles for select using (id = auth.uid() or mk_is_admin());

drop policy if exists mk_p_self_insert on mk_profiles;
create policy mk_p_self_insert on mk_profiles for insert with check (id = auth.uid() and role in ('customer','supplier'));

drop policy if exists mk_p_self_update on mk_profiles;
create policy mk_p_self_update on mk_profiles for update using (id = auth.uid());

drop policy if exists mk_p_supplier_public on mk_profiles;
create policy mk_p_supplier_public on mk_profiles for select using (
  exists (select 1 from mk_supplier_profiles sp where sp.user_id = mk_profiles.id and sp.verification_status = 'verified'));

drop policy if exists mk_p_customer_of_supplier on mk_profiles;
create policy mk_p_customer_of_supplier on mk_profiles for select using (
  exists (select 1 from mk_orders o where o.customer_id = mk_profiles.id and o.supplier_id = mk_my_supplier_id()));

-- mk_supplier_profiles
drop policy if exists mk_sp_select on mk_supplier_profiles;
create policy mk_sp_select on mk_supplier_profiles for select using (
  verification_status = 'verified' or user_id = auth.uid() or mk_is_admin());

drop policy if exists mk_sp_insert on mk_supplier_profiles;
create policy mk_sp_insert on mk_supplier_profiles for insert with check (user_id = auth.uid());

drop policy if exists mk_sp_update on mk_supplier_profiles;
create policy mk_sp_update on mk_supplier_profiles for update using (user_id = auth.uid());

-- mk_products
drop policy if exists mk_pr_select on mk_products;
create policy mk_pr_select on mk_products for select using (
  supplier_id = mk_my_supplier_id() or mk_is_admin() or
  exists (select 1 from mk_supplier_profiles sp where sp.id = mk_products.supplier_id and sp.verification_status = 'verified'));

drop policy if exists mk_pr_write on mk_products;
create policy mk_pr_write on mk_products for all using (supplier_id = mk_my_supplier_id()) with check (supplier_id = mk_my_supplier_id());

-- mk_addresses
drop policy if exists mk_ad_own on mk_addresses;
create policy mk_ad_own on mk_addresses for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- mk_service_areas
drop policy if exists mk_sa_select on mk_service_areas;
create policy mk_sa_select on mk_service_areas for select using (true);

drop policy if exists mk_sa_write on mk_service_areas;
create policy mk_sa_write on mk_service_areas for all using (supplier_id = mk_my_supplier_id()) with check (supplier_id = mk_my_supplier_id());

-- mk_subscriptions
drop policy if exists mk_sub_customer on mk_subscriptions;
create policy mk_sub_customer on mk_subscriptions for all using (customer_id = auth.uid()) with check (customer_id = auth.uid());

drop policy if exists mk_sub_supplier on mk_subscriptions;
create policy mk_sub_supplier on mk_subscriptions for select using (supplier_id = mk_my_supplier_id() or mk_is_admin());

-- mk_orders
drop policy if exists mk_o_customer_select on mk_orders;
create policy mk_o_customer_select on mk_orders for select using (customer_id = auth.uid());

drop policy if exists mk_o_customer_insert on mk_orders;
create policy mk_o_customer_insert on mk_orders for insert with check (customer_id = auth.uid() and subscription_id is null);

drop policy if exists mk_o_supplier_select on mk_orders;
create policy mk_o_supplier_select on mk_orders for select using (supplier_id = mk_my_supplier_id() or mk_is_admin());

drop policy if exists mk_o_supplier_update on mk_orders;
create policy mk_o_supplier_update on mk_orders for update using (supplier_id = mk_my_supplier_id()) with check (supplier_id = mk_my_supplier_id());

-- mk_payments
drop policy if exists mk_pay_select on mk_payments;
create policy mk_pay_select on mk_payments for select using (
  exists (select 1 from mk_orders o where o.id = mk_payments.order_id and (o.customer_id = auth.uid() or o.supplier_id = mk_my_supplier_id())) or mk_is_admin());

drop policy if exists mk_pay_insert on mk_payments;
create policy mk_pay_insert on mk_payments for insert with check (
  exists (select 1 from mk_orders o where o.id = mk_payments.order_id and o.supplier_id = mk_my_supplier_id()));

-- mk_reviews
drop policy if exists mk_rv_select on mk_reviews;
create policy mk_rv_select on mk_reviews for select using (true);

drop policy if exists mk_rv_write on mk_reviews;
create policy mk_rv_write on mk_reviews for all using (customer_id = auth.uid()) with check (customer_id = auth.uid());

-- mk_complaints
drop policy if exists mk_c_customer on mk_complaints;
create policy mk_c_customer on mk_complaints for select using (customer_id = auth.uid());

drop policy if exists mk_c_insert on mk_complaints;
create policy mk_c_insert on mk_complaints for insert with check (
  customer_id = auth.uid() and exists (select 1 from mk_orders o where o.id = order_id and o.customer_id = auth.uid()));

drop policy if exists mk_c_admin on mk_complaints;
create policy mk_c_admin on mk_complaints for all using (mk_is_admin()) with check (mk_is_admin());

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
