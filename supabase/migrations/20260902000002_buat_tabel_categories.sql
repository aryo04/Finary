-- ============================================================
-- Migration: 02. Tabel Kategori Transaksi (categories)
-- Deskripsi: Menyimpan kategori pengeluaran dan pemasukan
-- ============================================================

-- 1. Buat tabel categories
create table public.categories (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade,
  name text not null,
  type text not null check (type in ('expense', 'income')),
  icon text not null default 'category',
  color text not null default '#0D9488',
  is_default boolean not null default false,
  created_at timestamptz default now()
);

-- Komentar tabel & kolom
comment on table public.categories is 'Tabel kategori transaksi pengeluaran dan pemasukan';
comment on column public.categories.user_id is 'Pemilik kategori kustom (NULL jika kategori sistem global)';
comment on column public.categories.name is 'Nama kategori (contoh: Makan & Minum, Gaji)';
comment on column public.categories.type is 'Jenis transaksi: expense (pengeluaran) atau income (pemasukan)';
comment on column public.categories.is_default is 'Apakah kategori merupakan bawaan sistem';

-- 2. Aktifkan Row Level Security (RLS)
alter table public.categories enable row level security;

-- 3. Kebijakan RLS
create policy "Semua pengguna bisa lihat kategori sistem dan milik sendiri"
  on public.categories for select
  using (is_default = true or auth.uid() = user_id);

create policy "Pengguna bisa tambah kategori kustom"
  on public.categories for insert
  with check (auth.uid() = user_id and is_default = false);

create policy "Pengguna bisa ubah kategori kustom sendiri"
  on public.categories for update
  using (auth.uid() = user_id and is_default = false);

create policy "Pengguna bisa hapus kategori kustom sendiri"
  on public.categories for delete
  using (auth.uid() = user_id and is_default = false);

-- 4. Indeks
create index idx_categories_user on public.categories (user_id);
create index idx_categories_type on public.categories (type);

-- 5. Seed Data Kategori Bawaan Sistem
insert into public.categories (name, type, icon, color, is_default)
values
  -- Kategori Pengeluaran (Expense)
  ('Makan & Minum', 'expense', 'restaurant', '#F97316', true),
  ('Transportasi', 'expense', 'directions_car', '#3B82F6', true),
  ('Belanja', 'expense', 'shopping_bag', '#EC4899', true),
  ('Tagihan & Utilitas', 'expense', 'receipt_long', '#EAB308', true),
  ('Hiburan', 'expense', 'sports_esports', '#8B5CF6', true),
  ('Kesehatan', 'expense', 'medical_services', '#EF4444', true),
  ('Pendidikan', 'expense', 'school', '#10B981', true),
  ('Penyesuaian Saldo', 'expense', 'tune', '#6B7280', true),
  ('Lainnya', 'expense', 'category', '#6B7280', true),

  -- Kategori Pemasukan (Income)
  ('Saldo Awal', 'income', 'account_balance_wallet', '#0D9488', true),
  ('Gaji', 'income', 'account_balance_wallet', '#10B981', true),
  ('Freelance', 'income', 'work', '#06B6D4', true),
  ('Investasi', 'income', 'trending_up', '#6366F1', true),
  ('Bonus & Hadiah', 'income', 'card_giftcard', '#F59E0B', true),
  ('Penyesuaian Saldo', 'income', 'tune', '#6B7280', true),
  ('Pemasukan Lain', 'income', 'category', '#14B8A6', true);
