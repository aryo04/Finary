-- ============================================================
-- Migration: 01. Tabel Profil Pengguna (profiles)
-- Deskripsi: Menyimpan identitas publik pengguna (nama, avatar)
-- ============================================================

-- 1. Buat tabel profiles
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text,
  avatar_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Komentar tabel & kolom
comment on table public.profiles is 'Tabel data profil pengguna Finary';
comment on column public.profiles.id is 'ID pengguna, terhubung langsung ke auth.users';
comment on column public.profiles.full_name is 'Nama lengkap tampilan pengguna';
comment on column public.profiles.avatar_url is 'URL foto profil pengguna';

-- 2. Aktifkan Row Level Security (RLS)
alter table public.profiles enable row level security;

-- 3. Kebijakan RLS
create policy "Pengguna bisa lihat profil sendiri"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Pengguna bisa buat profil sendiri"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Pengguna bisa ubah profil sendiri"
  on public.profiles for update
  using (auth.uid() = id);
