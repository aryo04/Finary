-- ============================================================
-- Migration: 03. Tabel Dompet & Rekening (wallets)
-- Deskripsi: Menyimpan dompet tunai, rekening bank, e-wallet pengguna
-- ============================================================

-- 1. Buat tabel wallets
create table public.wallets (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  name text not null,
  type text not null check (type in ('cash', 'bank', 'ewallet', 'other')),
  initial_balance numeric not null default 0 check (initial_balance >= 0),
  icon text not null default 'account_balance_wallet',
  color text not null default '#0D9488',
  is_default boolean not null default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Komentar tabel & kolom
comment on table public.wallets is 'Tabel dompet tunai, rekening bank, dan e-wallet pengguna';
comment on column public.wallets.user_id is 'Pemilik dompet';
comment on column public.wallets.name is 'Nama dompet, contoh: Dompet Tunai, Bank BCA, GoPay';
comment on column public.wallets.type is 'Jenis dompet: cash, bank, ewallet, other';
comment on column public.wallets.initial_balance is 'Saldo awal dompet';
comment on column public.wallets.is_default is 'Apakah dompet merupakan dompet utama default';

-- 2. Aktifkan Row Level Security (RLS)
alter table public.wallets enable row level security;

-- 3. Kebijakan RLS
create policy "Pengguna bisa lihat dompet sendiri"
  on public.wallets for select
  using (auth.uid() = user_id);

create policy "Pengguna bisa tambah dompet sendiri"
  on public.wallets for insert
  with check (auth.uid() = user_id);

create policy "Pengguna bisa ubah dompet sendiri"
  on public.wallets for update
  using (auth.uid() = user_id);

create policy "Pengguna bisa hapus dompet sendiri"
  on public.wallets for delete
  using (auth.uid() = user_id);

-- 4. Indeks
create index idx_wallets_user on public.wallets (user_id);
