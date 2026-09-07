-- ============================================================
-- Migration: 06. Tabel Riwayat Chatbot AI (chat_messages)
-- Deskripsi: Menyimpan riwayat percakapan pengguna dengan asisten AI
-- ============================================================

-- 1. Buat tabel chat_messages
create table public.chat_messages (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users on delete cascade not null,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  image_base64 text,
  raw_extracted_data jsonb,
  transaction_id uuid references public.transactions(id) on delete set null,
  created_at timestamptz default now() not null
);

-- Komentar tabel & kolom
comment on table public.chat_messages is 'Tabel riwayat percakapan chatbot AI Finary';
comment on column public.chat_messages.user_id is 'Pemilik pesan chat';
comment on column public.chat_messages.role is 'Peran pengirim: user atau assistant';
comment on column public.chat_messages.content is 'Isi teks pesan';
comment on column public.chat_messages.image_base64 is 'Foto struk belanja base64 (opsional)';
comment on column public.chat_messages.raw_extracted_data is 'Data hasil ekstraksi AI dalam format JSON';
comment on column public.chat_messages.transaction_id is 'Referensi ke transaksi tersimpan (opsional)';

-- 2. Aktifkan Row Level Security (RLS)
alter table public.chat_messages enable row level security;

-- 3. Kebijakan RLS
create policy "Pengguna bisa lihat pesan chat sendiri"
  on public.chat_messages for select
  using (auth.uid() = user_id);

create policy "Pengguna bisa kirim pesan chat"
  on public.chat_messages for insert
  with check (auth.uid() = user_id);

create policy "Pengguna bisa perbarui pesan chat sendiri"
  on public.chat_messages for update
  using (auth.uid() = user_id);

create policy "Pengguna bisa hapus pesan chat sendiri"
  on public.chat_messages for delete
  using (auth.uid() = user_id);

-- 4. Indeks
create index idx_chat_messages_user_created on public.chat_messages (user_id, created_at asc);
