-- ============================================================
-- Migration: 08. RPC Ringkasan Finansial & Multi-Dompet (get_financial_summary)
-- Deskripsi: Fungsi kalkulasi Single Source of Truth untuk Dashboard,
--            Laporan Keuangan, dan Analisis AI Chatbot.
-- ============================================================

create or replace function public.get_financial_summary(
  p_start_date timestamptz default null,
  p_end_date timestamptz default null,
  p_wallet_id uuid default null
)
returns jsonb
language plpgsql
security invoker
as $$
declare
  v_user_id uuid := auth.uid();
  v_default_wallet_id uuid;
  v_total_income numeric := 0;
  v_total_expense numeric := 0;
  v_net_balance numeric := 0;
  v_transaction_count int := 0;
  v_expense_categories jsonb := '[]'::jsonb;
  v_income_categories jsonb := '[]'::jsonb;
  v_recent_transactions jsonb := '[]'::jsonb;
  v_wallets jsonb := '[]'::jsonb;
  v_total_wealth numeric := 0;
begin
  -- 1. Verifikasi Autentikasi Pengguna
  if v_user_id is null then
    raise exception 'Pengguna belum terautentikasi';
  end if;

  -- Pastikan dompet default tersedia jika user baru pertama kali query
  perform public.seed_default_wallets_for_user(v_user_id);

  select id into v_default_wallet_id
  from public.wallets
  where user_id = v_user_id and is_default = true
  limit 1;

  -- 2. Hitung Total Pemasukan & Pengeluaran Riil (Filter Tanggal & Dompet)
  select
    coalesce(sum(case when type = 'income' then amount else 0 end), 0),
    coalesce(sum(case when type = 'expense' then amount else 0 end), 0),
    count(id)
  into
    v_total_income,
    v_total_expense,
    v_transaction_count
  from public.transactions
  where user_id = v_user_id
    and (p_start_date is null or transaction_date >= p_start_date)
    and (p_end_date is null or transaction_date <= p_end_date)
    and (
      p_wallet_id is null or 
      wallet_id = p_wallet_id or 
      (wallet_id is null and p_wallet_id = v_default_wallet_id)
    );

  v_net_balance := v_total_income - v_total_expense;

  -- 3. Hitung Rincian Saldo Terkini per Dompet (Initial + Income - Expense + Transfer_In - Transfer_Out)
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', w.id,
        'name', w.name,
        'type', w.type,
        'icon', w.icon,
        'color', w.color,
        'is_default', w.is_default,
        'initial_balance', w.initial_balance,
        'current_balance', (
          w.initial_balance + 
          coalesce(t_income.total, 0) - 
          coalesce(t_expense.total, 0) +
          coalesce(t_trf_in.total, 0) -
          coalesce(t_trf_out.total, 0)
        )
      ) order by w.is_default desc, w.created_at asc
    ),
    '[]'::jsonb
  )
  into v_wallets
  from public.wallets w
  left join (
    select coalesce(wallet_id, v_default_wallet_id) as w_id, sum(amount) as total
    from public.transactions
    where user_id = v_user_id and type = 'income'
    group by coalesce(wallet_id, v_default_wallet_id)
  ) t_income on t_income.w_id = w.id
  left join (
    select coalesce(wallet_id, v_default_wallet_id) as w_id, sum(amount) as total
    from public.transactions
    where user_id = v_user_id and type = 'expense'
    group by coalesce(wallet_id, v_default_wallet_id)
  ) t_expense on t_expense.w_id = w.id
  left join (
    select to_wallet_id as w_id, sum(amount) as total
    from public.wallet_transfers
    where user_id = v_user_id
    group by to_wallet_id
  ) t_trf_in on t_trf_in.w_id = w.id
  left join (
    select from_wallet_id as w_id, sum(amount) as total
    from public.wallet_transfers
    where user_id = v_user_id
    group by from_wallet_id
  ) t_trf_out on t_trf_out.w_id = w.id
  where w.user_id = v_user_id;

  -- 4. Hitung Total Kekayaan Bersih (Total Net Worth dari Seluruh Dompet)
  select coalesce(
    sum(
      w.initial_balance + 
      coalesce(t_income.total, 0) - 
      coalesce(t_expense.total, 0)
    ), 0
  )
  into v_total_wealth
  from public.wallets w
  left join (
    select coalesce(wallet_id, v_default_wallet_id) as w_id, sum(amount) as total
    from public.transactions
    where user_id = v_user_id and type = 'income'
    group by coalesce(wallet_id, v_default_wallet_id)
  ) t_income on t_income.w_id = w.id
  left join (
    select coalesce(wallet_id, v_default_wallet_id) as w_id, sum(amount) as total
    from public.transactions
    where user_id = v_user_id and type = 'expense'
    group by coalesce(wallet_id, v_default_wallet_id)
  ) t_expense on t_expense.w_id = w.id
  where w.user_id = v_user_id;

  -- 5. Rincian Pos Pengeluaran per Kategori (Expense Distribution)
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'category_id', c.id,
        'category_name', coalesce(c.name, 'Lainnya'),
        'category_color', coalesce(c.color, '#0D9488'),
        'category_icon', coalesce(c.icon, 'category'),
        'total_amount', t.subtotal,
        'percentage', case 
          when v_total_expense > 0 then round((t.subtotal / v_total_expense * 100)::numeric, 1)
          else 0 
        end
      ) order by t.subtotal desc
    ),
    '[]'::jsonb
  )
  into v_expense_categories
  from (
    select category_id, sum(amount) as subtotal
    from public.transactions
    where user_id = v_user_id 
      and type = 'expense'
      and (p_start_date is null or transaction_date >= p_start_date)
      and (p_end_date is null or transaction_date <= p_end_date)
      and (
        p_wallet_id is null or 
        wallet_id = p_wallet_id or 
        (wallet_id is null and p_wallet_id = v_default_wallet_id)
      )
    group by category_id
  ) t
  left join public.categories c on c.id = t.category_id;

  -- 6. Rincian Sumber Pemasukan per Kategori (Income Distribution)
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'category_id', c.id,
        'category_name', coalesce(c.name, 'Pemasukan Lain'),
        'category_color', coalesce(c.color, '#10B981'),
        'category_icon', coalesce(c.icon, 'attach_money'),
        'total_amount', t.subtotal,
        'percentage', case 
          when v_total_income > 0 then round((t.subtotal / v_total_income * 100)::numeric, 1)
          else 0 
        end
      ) order by t.subtotal desc
    ),
    '[]'::jsonb
  )
  into v_income_categories
  from (
    select category_id, sum(amount) as subtotal
    from public.transactions
    where user_id = v_user_id 
      and type = 'income'
      and (p_start_date is null or transaction_date >= p_start_date)
      and (p_end_date is null or transaction_date <= p_end_date)
      and (
        p_wallet_id is null or 
        wallet_id = p_wallet_id or 
        (wallet_id is null and p_wallet_id = v_default_wallet_id)
      )
    group by category_id
  ) t
  left join public.categories c on c.id = t.category_id;

  -- 7. Riwayat 5 Transaksi Terakhir
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', tx.id,
        'type', tx.type,
        'amount', tx.amount,
        'description', tx.description,
        'transaction_date', tx.transaction_date,
        'category_name', c.name,
        'category_color', c.color,
        'category_icon', c.icon,
        'wallet_name', w.name,
        'wallet_color', w.color,
        'wallet_icon', w.icon
      ) order by tx.transaction_date desc
    ),
    '[]'::jsonb
  )
  into v_recent_transactions
  from (
    select *
    from public.transactions
    where user_id = v_user_id
    order by transaction_date desc
    limit 5
  ) tx
  left join public.categories c on c.id = tx.category_id
  left join public.wallets w on w.id = coalesce(tx.wallet_id, v_default_wallet_id);

  -- 8. Return JSON Response Terstruktur
  return jsonb_build_object(
    'total_income', v_total_income,
    'total_expense', v_total_expense,
    'net_balance', v_net_balance,
    'total_wealth', v_total_wealth,
    'transaction_count', v_transaction_count,
    'wallets', v_wallets,
    'expense_categories', v_expense_categories,
    'income_categories', v_income_categories,
    'recent_transactions', v_recent_transactions
  );
end;
$$;
