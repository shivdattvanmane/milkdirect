-- ============================================================================
-- Migration SQL for MilkDirect (mk_ tables in Supabase)
-- ============================================================================

-- 1. Ensure columns exist on mk_profiles
alter table if exists mk_profiles add column if not exists alternate_phone text;
alter table if exists mk_profiles add column if not exists photo_url text;
alter table if exists mk_profiles add column if not exists is_blocked boolean not null default false;

-- 2. Enforce One Email = One Account / Role
create unique index if not exists mk_profiles_phone_unique 
  on mk_profiles (phone) 
  where phone is not null and phone != '';

-- 3. mk_supplier_profiles updates
alter table if exists mk_supplier_profiles add column if not exists shop_name text;
alter table if exists mk_supplier_profiles add column if not exists photo_url text;
alter table if exists mk_supplier_profiles add column if not exists cover_url text;
alter table if exists mk_supplier_profiles add column if not exists about text;
alter table if exists mk_supplier_profiles add column if not exists bank_account_no text;
alter table if exists mk_supplier_profiles add column if not exists bank_ifsc text;
alter table if exists mk_supplier_profiles add column if not exists fssai_no text;
alter table if exists mk_supplier_profiles add column if not exists documents jsonb not null default '[]'::jsonb;
alter table if exists mk_supplier_profiles add column if not exists rejection_reason text;
alter table if exists mk_supplier_profiles add column if not exists rating_avg numeric(3,2) not null default 5.0;
alter table if exists mk_supplier_profiles add column if not exists rating_count int not null default 0;
alter table if exists mk_supplier_profiles add column if not exists delivery_slots text[] not null default '{"morning_5_8","morning_8_10","evening_5_8"}'::text[];

-- 4. mk_products updates
alter table if exists mk_products add column if not exists fat_percent numeric(4,2);
alter table if exists mk_products add column if not exists snf_percent numeric(4,2);
alter table if exists mk_products add column if not exists source text not null default 'own_cattle';
alter table if exists mk_products add column if not exists processing text not null default 'raw';
alter table if exists mk_products add column if not exists min_order_l numeric(4,2) not null default 0.5;
alter table if exists mk_products add column if not exists delivery_charge numeric(6,2) not null default 0;
alter table if exists mk_products add column if not exists unavailable_until date;
alter table if exists mk_products add column if not exists photo_url text;

-- 5. mk_addresses updates
alter table if exists mk_addresses add column if not exists label text not null default 'Home';
alter table if exists mk_addresses add column if not exists landmark text;
alter table if exists mk_addresses add column if not exists contact_phone text;
alter table if exists mk_addresses add column if not exists is_default boolean not null default false;
alter table if exists mk_addresses add column if not exists latitude numeric(10,7);
alter table if exists mk_addresses add column if not exists longitude numeric(10,7);

-- 6. mk_subscriptions updates
alter table if exists mk_subscriptions add column if not exists frequency text not null default 'daily';
alter table if exists mk_subscriptions add column if not exists weekdays int[] not null default '{1,2,3,4,5,6,7}'::int[];
alter table if exists mk_subscriptions add column if not exists slot text not null default 'morning_5_8';
alter table if exists mk_subscriptions add column if not exists end_date date;
alter table if exists mk_subscriptions add column if not exists instructions text;
alter table if exists mk_subscriptions add column if not exists payment_mode text not null default 'cash';
alter table if exists mk_subscriptions add column if not exists delivery_charge numeric(6,2) not null default 0;

-- 7. mk_orders updates
alter table if exists mk_orders add column if not exists slot text not null default 'morning_5_8';
alter table if exists mk_orders add column if not exists delivery_charge numeric(6,2) not null default 0;
alter table if exists mk_orders add column if not exists instructions text;
alter table if exists mk_orders add column if not exists payment_mode text not null default 'cash';

-- 8. mk_complaints updates
alter table if exists mk_complaints add column if not exists issue_type text not null default 'quality';
alter table if exists mk_complaints add column if not exists photo_url text;
alter table if exists mk_complaints add column if not exists admin_notes text;

-- 9. Secure Role Column: Clients can NEVER insert or elevate role to 'admin'
revoke update on mk_profiles from authenticated;
grant update (name, phone, alternate_phone, photo_url, language) on mk_profiles to authenticated;

drop policy if exists mk_p_self_insert on mk_profiles;
create policy mk_p_self_insert on mk_profiles for insert 
  with check (id = auth.uid() and role in ('customer','supplier'));

drop policy if exists mk_p_self_update on mk_profiles;
create policy mk_p_self_update on mk_profiles for update 
  using (id = auth.uid()) 
  with check (id = auth.uid());

-- 10. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
