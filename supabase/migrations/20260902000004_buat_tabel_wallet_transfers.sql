-- ============================================================
-- Migration: 04. Tabel Pindah Saldo (wallet_transfers)
-- Deskripsi: Menyimpan riwayat transfer saldo antar dompet pengguna
-- ============================================================

-- 1. Buat tabel wallet_transfers
create table public.wallet_transfers (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  from_wallet_id uuid references public.wallets(id) on delete cascade not null,
  to_wallet_id uuid references public.wallets(id) on delete cascade not null,
  amount numeric not null check (amount > 0),
  description text,
  transfer_date timestamptz default now() not null,
  created_at timestamptz default now() not null
);

-- Komentar tabel & kolom
comment on table public.wallet_transfers is 'Tabel riwayat pemindahan saldo antar dompet pengguna';
comment on column public.wallet_transfers.user_id is 'Pemilik transaksi transfer';
comment on column public.wallet_transfers.from_wallet_id is 'Dompet asal sumber dana';
comment on column public.wallet_transfers.to_wallet_id is 'Dompet tujuan penerima dana';
comment on column public.wallet_transfers.amount is 'Nominal saldo yang dipindahkan';
comment on column public.wallet_transfers.description is 'Catatan keterangan transfer (opsional)';

-- 2. Aktifkan Row Level Security (RLS)
alter table public.wallet_transfers enable row level security;

-- 3. Kebijakan RLS
create policy "Pengguna bisa lihat transfer sendiri"
  on public.wallet_transfers for select
  using (auth.uid() = user_id);

create policy "Pengguna bisa buat transfer sendiri"
  on public.wallet_transfers for insert
  with check (auth.uid() = user_id);

create policy "Pengguna bisa hapus transfer sendiri"
  on public.wallet_transfers for delete
  using (auth.uid() = user_id);

-- 4. Indeks
create index idx_wallet_transfers_user on public.wallet_transfers (user_id);
create index idx_wallet_transfers_from on public.wallet_transfers (from_wallet_id);
create index idx_wallet_transfers_to on public.wallet_transfers (to_wallet_id);
create index idx_wallet_transfers_date on public.wallet_transfers (transfer_date desc);
create index if not exists idx_wallet_transfers_user_date on public.wallet_transfers (user_id, transfer_date desc);
