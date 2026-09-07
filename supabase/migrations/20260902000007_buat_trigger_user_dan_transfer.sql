-- ============================================================
-- Migration: 07. Trigger User Baru & Prosedur Pindah Saldo
-- Deskripsi: Otomasi inisialisasi user baru (profil, dompet) & RPC transfer dana
-- ============================================================

-- 1. Fungsi Helper untuk Inisialisasi 3 Dompet Bawaan bagi Pengguna Baru
create or replace function public.seed_default_wallets_for_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not exists (select 1 from public.wallets where user_id = p_user_id) then
    -- 1. Dompet Tunai (Default / Cash)
    insert into public.wallets (user_id, name, type, icon, color, is_default, initial_balance)
    values (p_user_id, 'Dompet Tunai', 'cash', 'payments', '#10B981', true, 0);

    -- 2. Rekening Bank (Bank)
    insert into public.wallets (user_id, name, type, icon, color, is_default, initial_balance)
    values (p_user_id, 'Rekening Bank', 'bank', 'account_balance', '#2563EB', false, 0);

    -- 3. E-Wallet (Digital)
    insert into public.wallets (user_id, name, type, icon, color, is_default, initial_balance)
    values (p_user_id, 'E-Wallet', 'ewallet', 'smartphone', '#8B5CF6', false, 0);
  end if;
end;
$$;

-- 2. Fungsi Trigger saat Pengguna Baru Mendaftar di auth.users
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- 1. Buat profil pengguna
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url'
  );

  -- 2. Buat 3 dompet default otomatis
  perform public.seed_default_wallets_for_user(new.id);

  return new;
end;
$$;

-- Pasang trigger pada tabel auth.users
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3. Prosedur RPC untuk Transfer Saldo Antar Dompet (Murni Pindah Saldo)
create or replace function public.transfer_wallet_funds(
  p_from_wallet_id uuid,
  p_to_wallet_id uuid,
  p_amount numeric,
  p_description text default null,
  p_date timestamptz default now()
)
returns jsonb
language plpgsql
security invoker
as $$
declare
  v_user_id uuid := auth.uid();
  v_from_wallet public.wallets%rowtype;
  v_to_wallet public.wallets%rowtype;
begin
  if v_user_id is null then
    raise exception 'Pengguna belum terautentikasi';
  end if;

  if p_amount <= 0 then
    raise exception 'Nominal transfer harus lebih dari 0';
  end if;

  if p_from_wallet_id = p_to_wallet_id then
    raise exception 'Dompet asal dan tujuan tidak boleh sama';
  end if;

  select * into v_from_wallet from public.wallets where id = p_from_wallet_id and user_id = v_user_id;
  select * into v_to_wallet from public.wallets where id = p_to_wallet_id and user_id = v_user_id;

  if v_from_wallet.id is null or v_to_wallet.id is null then
    raise exception 'Dompet asal atau tujuan tidak ditemukan';
  end if;

  -- Catat ke tabel wallet_transfers (tidak mengubah total pemasukan / pengeluaran riil)
  insert into public.wallet_transfers (
    user_id,
    from_wallet_id,
    to_wallet_id,
    amount,
    description,
    transfer_date
  ) values (
    v_user_id,
    p_from_wallet_id,
    p_to_wallet_id,
    p_amount,
    p_description,
    coalesce(p_date, now())
  );

  return jsonb_build_object(
    'success', true,
    'message', 'Berhasil memindahkan saldo sebesar Rp' || p_amount::text,
    'from_wallet', v_from_wallet.name,
    'to_wallet', v_to_wallet.name
  );
end;
$$;
