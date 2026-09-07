-- ============================================================
-- Migration: 05. Tabel Transaksi Keuangan (transactions)
-- Deskripsi: Menyimpan riwayat pengeluaran dan pemasukan pengguna
-- ============================================================

-- 1. Buat tabel transactions
create table public.transactions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  category_id uuid references public.categories(id) on delete set null,
  wallet_id uuid references public.wallets(id) on delete set null,
  type text not null check (type in ('expense', 'income')),
  amount numeric not null check (amount > 0),
  description text,
  transaction_date timestamptz default now() not null,
  source text not null default 'manual' check (source in ('manual', 'ai_chat', 'receipt_scan', 'system', 'adjustment')),
  created_at timestamptz default now() not null
);

-- Komentar tabel & kolom
comment on table public.transactions is 'Tabel transaksi keuangan pengeluaran dan pemasukan pengguna';
comment on column public.transactions.user_id is 'Pemilik transaksi';
comment on column public.transactions.category_id is 'Kategori transaksi (relasi ke categories)';
comment on column public.transactions.wallet_id is 'Sumber dompet/rekening (relasi ke wallets)';
comment on column public.transactions.type is 'Jenis: expense (pengeluaran) atau income (pemasukan)';
comment on column public.transactions.amount is 'Nominal uang transaksi';
comment on column public.transactions.description is 'Deskripsi/catatan transaksi';
comment on column public.transactions.transaction_date is 'Tanggal terjadinya transaksi';
comment on column public.transactions.source is 'Asal pencatatan: manual, ai_chat, atau receipt_scan';

-- 2. Aktifkan Row Level Security (RLS)
alter table public.transactions enable row level security;

-- 3. Kebijakan RLS
create policy "Pengguna bisa lihat transaksi sendiri"
  on public.transactions for select
  using (auth.uid() = user_id);

create policy "Pengguna bisa tambah transaksi sendiri"
  on public.transactions for insert
  with check (auth.uid() = user_id);

create policy "Pengguna bisa ubah transaksi sendiri"
  on public.transactions for update
  using (auth.uid() = user_id);

create policy "Pengguna bisa hapus transaksi sendiri"
  on public.transactions for delete
  using (auth.uid() = user_id);

-- 4. Indeks Performa
create index idx_transactions_user_date on public.transactions (user_id, transaction_date desc);
create index idx_transactions_wallet on public.transactions (wallet_id);
create index idx_transactions_category on public.transactions (category_id);
create index idx_transactions_type on public.transactions (type);
create index if not exists idx_transactions_user_type_date on public.transactions (user_id, type, transaction_date desc);
create index if not exists idx_transactions_user_wallet_type on public.transactions (user_id, wallet_id, type);
