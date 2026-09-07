/**
 * Financial Calculation & Database Query Service
 * File: services/financial_service.ts
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { ChatRequestBody } from "../utils/validation.ts";

export interface SubPeriodInfo {
  label: string;
  name: string;
  startDate: string;
  endDate: string;
}

export interface DateRangeResult {
  periodLabel: string;
  startDate: string | null;
  endDate: string | null;
  subPeriods?: SubPeriodInfo[];
}

/**
 * Mendeteksi rentang waktu dari pertanyaan pengguna (hari ini, kemarin, minggu ini, bulan ini, bulan lalu, tahun ini, total saldo, perbandingan multi-bulan)
 */
export function determineDateRange(query: string): DateRangeResult {
  const q = query.toLowerCase();
  const now = new Date();

  // 0. Deteksi "Awal tahun / Awal bulan tahun ini sampai sekarang / Bulan sekarang"
  if (
    q.includes("awal tahun") ||
    q.includes("awal bulan tahun ini") ||
    q.includes("dari awal tahun") ||
    q.includes("sejak awal tahun") ||
    q.includes("sepanjang tahun ini") ||
    (q.includes("tahun ini") &&
      (q.includes("sekarang") ||
        q.includes("saat ini") ||
        q.includes("sampe") ||
        q.includes("sampai") ||
        q.includes("hingga"))) ||
    (q.includes("awal bulan") &&
      (q.includes("sekarang") || q.includes("sampe") || q.includes("sampai")))
  ) {
    const yearMatch = q.match(/\b(20\d\d)\b/);
    const year = yearMatch ? parseInt(yearMatch[1], 10) : now.getFullYear();

    const start = new Date(year, 0, 1, 0, 0, 0); // 1 Januari
    const currentMonth = now.getMonth();
    const end = new Date(year, currentMonth + 1, 0, 23, 59, 59, 999); // Akhir bulan berjalan

    const currentMonthName = now.toLocaleDateString("id-ID", { month: "long" });

    const monthNamesList = [
      "Januari", "Februari", "Maret", "April", "Mei", "Juni",
      "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ];

    const subPeriods: SubPeriodInfo[] = [];
    for (let m = 0; m <= currentMonth; m++) {
      const s = new Date(year, m, 1, 0, 0, 0);
      const e = new Date(year, m + 1, 0, 23, 59, 59, 999);
      subPeriods.push({
        label: `Bulan ${monthNamesList[m]} ${year}`,
        name: monthNamesList[m],
        startDate: s.toISOString(),
        endDate: e.toISOString(),
      });
    }

    return {
      periodLabel: `Awal Tahun (Januari ${year}) s/d Bulan Sekarang (${currentMonthName} ${year})`,
      startDate: start.toISOString(),
      endDate: end.toISOString(),
      subPeriods,
    };
  }

  // 1. Perbandingan: Bulan Lalu vs Bulan Ini
  if (
    (q.includes("bulan lalu") || q.includes("bln lalu")) &&
    (q.includes("bulan ini") || q.includes("bln ini") || q.includes("sekarang") || q.includes("saat ini"))
  ) {
    const startPrev = new Date(now.getFullYear(), now.getMonth() - 1, 1, 0, 0, 0);
    const endPrev = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999);
    const prevName = startPrev.toLocaleDateString("id-ID", { month: "long", year: "numeric" });

    const startThis = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);
    const endThis = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
    const thisName = startThis.toLocaleDateString("id-ID", { month: "long", year: "numeric" });

    return {
      periodLabel: `Perbandingan: Bulan Lalu (${prevName}) vs Bulan Ini (${thisName})`,
      startDate: startPrev.toISOString(),
      endDate: endThis.toISOString(),
      subPeriods: [
        {
          label: `Bulan Lalu (${prevName})`,
          name: prevName,
          startDate: startPrev.toISOString(),
          endDate: endPrev.toISOString(),
        },
        {
          label: `Bulan Ini (${thisName})`,
          name: thisName,
          startDate: startThis.toISOString(),
          endDate: endThis.toISOString(),
        },
      ],
    };
  }

  // 2. Perbandingan: Kemarin vs Hari Ini
  if (q.includes("kemarin") && (q.includes("hari ini") || q.includes("today"))) {
    const yesterday = new Date(now);
    yesterday.setDate(now.getDate() - 1);
    const startYest = new Date(yesterday.getFullYear(), yesterday.getMonth(), yesterday.getDate(), 0, 0, 0);
    const endYest = new Date(yesterday.getFullYear(), yesterday.getMonth(), yesterday.getDate(), 23, 59, 59, 999);

    const startToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
    const endToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

    return {
      periodLabel: "Perbandingan: Kemarin vs Hari Ini",
      startDate: startYest.toISOString(),
      endDate: endToday.toISOString(),
      subPeriods: [
        {
          label: "Kemarin",
          name: "Kemarin",
          startDate: startYest.toISOString(),
          endDate: endYest.toISOString(),
        },
        {
          label: "Hari Ini",
          name: "Hari Ini",
          startDate: startToday.toISOString(),
          endDate: endToday.toISOString(),
        },
      ],
    };
  }

  // 3. Deteksi Multi-Bulan / Bulan Spesifik (Januari s/d Desember)
  const monthNames = [
    { name: "januari", month: 0 },
    { name: "februari", month: 1 },
    { name: "maret", month: 2 },
    { name: "april", month: 3 },
    { name: "mei", month: 4 },
    { name: "juni", month: 5 },
    { name: "juli", month: 6 },
    { name: "agustus", month: 7 },
    { name: "september", month: 8 },
    { name: "oktober", month: 9 },
    { name: "november", month: 10 },
    { name: "desember", month: 11 },
  ];

  const matchedMonths: Array<{ name: string; month: number; index: number }> = [];
  for (const m of monthNames) {
    const idx = q.indexOf(m.name);
    if (idx !== -1) {
      matchedMonths.push({ name: m.name, month: m.month, index: idx });
    }
  }

  if (matchedMonths.length > 0) {
    const yearMatch = q.match(/\b(20\d\d)\b/);
    const year = yearMatch ? parseInt(yearMatch[1], 10) : now.getFullYear();

    // Urutkan secara kronologis berdasarkan bulan kalender
    matchedMonths.sort((a, b) => a.month - b.month);

    const subPeriods: SubPeriodInfo[] = matchedMonths.map((m) => {
      const start = new Date(year, m.month, 1, 0, 0, 0);
      const end = new Date(year, m.month + 1, 0, 23, 59, 59, 999);
      const monthCap = m.name.charAt(0).toUpperCase() + m.name.slice(1);
      return {
        label: `Bulan ${monthCap} ${year}`,
        name: monthCap,
        startDate: start.toISOString(),
        endDate: end.toISOString(),
      };
    });

    if (subPeriods.length === 1) {
      return {
        periodLabel: subPeriods[0].label,
        startDate: subPeriods[0].startDate,
        endDate: subPeriods[0].endDate,
        subPeriods,
      };
    } else {
      const overallStart = subPeriods[0].startDate;
      const overallEnd = subPeriods[subPeriods.length - 1].endDate;
      const labels = subPeriods.map((s) => s.name).join(", ");
      return {
        periodLabel: `Perbandingan Bulan: ${labels} ${year}`,
        startDate: overallStart,
        endDate: overallEnd,
        subPeriods,
      };
    }
  }

  // 4. Hari ini
  if (q.includes("hari ini") || q.includes("today")) {
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
    const end = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
    return {
      periodLabel: `Hari Ini (${start.toLocaleDateString("id-ID", { day: "numeric", month: "long", year: "numeric" })})`,
      startDate: start.toISOString(),
      endDate: end.toISOString(),
    };
  }

  // 5. Kemarin
  if (q.includes("kemarin") || q.includes("yesterday")) {
    const yesterday = new Date(now);
    yesterday.setDate(now.getDate() - 1);
    const start = new Date(yesterday.getFullYear(), yesterday.getMonth(), yesterday.getDate(), 0, 0, 0);
    const end = new Date(yesterday.getFullYear(), yesterday.getMonth(), yesterday.getDate(), 23, 59, 59, 999);
    return {
      periodLabel: `Kemarin (${start.toLocaleDateString("id-ID", { day: "numeric", month: "long", year: "numeric" })})`,
      startDate: start.toISOString(),
      endDate: end.toISOString(),
    };
  }

  // 6. Minggu ini (Senin s/d Minggu)
  if (q.includes("minggu ini") || q.includes("pekan ini") || q.includes("this week") || q.includes("7 hari")) {
    const day = now.getDay();
    const diffToMonday = (day === 0 ? -6 : 1) - day;
    const start = new Date(now);
    start.setDate(now.getDate() + diffToMonday);
    start.setHours(0, 0, 0, 0);

    const end = new Date(start);
    end.setDate(start.getDate() + 6);
    end.setHours(23, 59, 59, 999);

    return {
      periodLabel: `Minggu Ini (${start.toLocaleDateString("id-ID", { day: "numeric", month: "short" })} - ${end.toLocaleDateString("id-ID", { day: "numeric", month: "short", year: "numeric" })})`,
      startDate: start.toISOString(),
      endDate: end.toISOString(),
    };
  }

  // 7. Bulan lalu
  if (q.includes("bulan lalu") || q.includes("bln lalu") || q.includes("last month")) {
    const start = new Date(now.getFullYear(), now.getMonth() - 1, 1, 0, 0, 0);
    const end = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999);
    const monthName = start.toLocaleDateString("id-ID", { month: "long", year: "numeric" });
    return {
      periodLabel: `Bulan Lalu (${monthName})`,
      startDate: start.toISOString(),
      endDate: end.toISOString(),
    };
  }

  // 8. Tahun ini
  if (q.includes("tahun ini") || q.includes("this year")) {
    const start = new Date(now.getFullYear(), 0, 1, 0, 0, 0);
    const end = new Date(now.getFullYear(), 11, 31, 23, 59, 59, 999);
    return {
      periodLabel: `Tahun ${now.getFullYear()}`,
      startDate: start.toISOString(),
      endDate: end.toISOString(),
    };
  }

  // 9. Pertanyaan Saldo Sekarang / Duit Sekarang / Saldo Dompet / Asal Pemasukan / Perencanaan Survival -> All-Time
  if (
    q.includes("sekarang") ||
    q.includes("saat ini") ||
    q.includes("total duit") ||
    q.includes("duit saya") ||
    q.includes("uang saya") ||
    q.includes("dana saya") ||
    q.includes("sisa uang") ||
    q.includes("sisa saldo") ||
    q.includes("total saldo") ||
    q.includes("tabungan") ||
    q.includes("dompet") ||
    q.includes("rekening") ||
    q.includes("bertahan") ||
    q.includes("cukup") ||
    q.includes("budget") ||
    q.includes("anggaran") ||
    q.includes("dari apa") ||
    q.includes("dari mana") ||
    q.includes("sumber") ||
    q.includes("asal")
  ) {
    return {
      periodLabel: "Keseluruhan Waktu (Saldo Terkini & Riwayat Lengkap)",
      startDate: null,
      endDate: null,
    };
  }

  // Default: Bulan ini
  const start = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);
  const end = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
  const monthName = start.toLocaleDateString("id-ID", { month: "long", year: "numeric" });
  return {
    periodLabel: `Bulan Ini (${monthName})`,
    startDate: start.toISOString(),
    endDate: end.toISOString(),
  };
}

/**
 * Membangun ringkasan keuangan teks untuk dimasukkan ke prompt OpenAI
 */
export async function buildFinancialContext(
  authHeader: string,
  query: string,
  body?: ChatRequestBody
): Promise<string> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

  let data: any = null;
  const range = determineDateRange(query);

  if (supabaseUrl && supabaseAnonKey && authHeader) {
    try {
      const supabase = createClient(supabaseUrl, supabaseAnonKey, {
        global: {
          headers: {
            Authorization: authHeader,
          },
        },
      });

      const res = await supabase.rpc("get_financial_summary", {
        p_start_date: range.startDate,
        p_end_date: range.endDate,
      });
      data = res.data;
    } catch (_) {}
  }

  let income = Number(data?.total_income ?? 0);
  let expense = Number(data?.total_expense ?? 0);
  let balance = Number(data?.net_balance ?? 0);
  let count = Number(data?.transaction_count ?? 0);
  let expenseCats = data?.expense_categories ?? [];
  let incomeCats = data?.income_categories ?? [];
  let recentTxs = data?.recent_transactions ?? [];

  const rawTxs = body?.recent_transactions ?? [];
  let filteredTxs: any[] = [];

  if (rawTxs.length > 0) {
    // Filter berdasarkan range tanggal jika ada
    filteredTxs = rawTxs.filter((tx) => {
      if (!tx.transaction_date) return true;
      const txTime = new Date(tx.transaction_date).getTime();
      if (range.startDate && txTime < new Date(range.startDate).getTime()) return false;
      if (range.endDate && txTime > new Date(range.endDate).getTime()) return false;
      return true;
    });

    // Hitung aggregasi jika database kosong / belum tersinkronisasi
    if (count === 0 && filteredTxs.length > 0) {
      count = filteredTxs.length;
      income = filteredTxs
        .filter((t) => t.type === "income")
        .reduce((sum, t) => sum + Number(t.amount ?? 0), 0);
      expense = filteredTxs
        .filter((t) => t.type === "expense")
        .reduce((sum, t) => sum + Number(t.amount ?? 0), 0);
      balance = income - expense;

      // Group expense categories
      const expCatMap = new Map<string, number>();
      filteredTxs.filter((t) => t.type === "expense").forEach((t) => {
        const cat = t.category_name || "Lainnya";
        expCatMap.set(cat, (expCatMap.get(cat) ?? 0) + Number(t.amount ?? 0));
      });
      expenseCats = Array.from(expCatMap.entries()).map(([name, total]) => ({
        category_name: name,
        total_amount: total,
        percentage: expense > 0 ? Math.round((total / expense) * 100) : 0,
      }));

      // Group income categories
      const incCatMap = new Map<string, number>();
      filteredTxs.filter((t) => t.type === "income").forEach((t) => {
        const cat = t.category_name || "Pemasukan Lain";
        incCatMap.set(cat, (incCatMap.get(cat) ?? 0) + Number(t.amount ?? 0));
      });
      incomeCats = Array.from(incCatMap.entries()).map(([name, total]) => ({
        category_name: name,
        total_amount: total,
        percentage: income > 0 ? Math.round((total / income) * 100) : 0,
      }));
    }

    if (
      recentTxs.length === 0 ||
      recentTxs.some((t: any) => (t.description ?? "").startsWith("ENC:") || (t.description ?? "").startsWith("VAULT:"))
    ) {
      recentTxs = filteredTxs.map((t) => ({
        id: t.id,
        type: t.type,
        amount: t.amount,
        category_name: t.category_name ?? "Lainnya",
        wallet_name: t.wallet_name ?? "Tunai",
        description: t.description ?? "",
        transaction_date: t.transaction_date ?? "",
      }));
    }
  }

  // Kalkulasi Breakdown Per-Periode / Per-Bulan jika ada subPeriods
  let subPeriodsText = "";
  const allAvailableTxs = filteredTxs.length > 0 ? filteredTxs : (recentTxs.length > 0 ? recentTxs : rawTxs);
  if (range.subPeriods && range.subPeriods.length > 1) {
    if (range.subPeriods.length <= 4) {
      const sections: string[] = [];
      for (const sub of range.subPeriods) {
        const subStart = new Date(sub.startDate).getTime();
        const subEnd = new Date(sub.endDate).getTime();
        const subTxs = allAvailableTxs.filter((t: any) => {
          if (!t.transaction_date) return false;
          const txTime = new Date(t.transaction_date).getTime();
          return txTime >= subStart && txTime <= subEnd;
        });

        const subInc = subTxs
          .filter((t: any) => t.type === "income")
          .reduce((sum: number, t: any) => sum + Number(t.amount ?? 0), 0);
        const subExp = subTxs
          .filter((t: any) => t.type === "expense")
          .reduce((sum: number, t: any) => sum + Number(t.amount ?? 0), 0);
        const subBal = subInc - subExp;

        const expMap = new Map<string, number>();
        subTxs
          .filter((t: any) => t.type === "expense")
          .forEach((t: any) => {
            const cat = t.category_name || "Lainnya";
            expMap.set(cat, (expMap.get(cat) ?? 0) + Number(t.amount ?? 0));
          });
        const expCatList = Array.from(expMap.entries()).map(
          ([c, a]) => `${c}: Rp${a.toLocaleString("id-ID")}`
        );

        const incMap = new Map<string, number>();
        subTxs
          .filter((t: any) => t.type === "income")
          .forEach((t: any) => {
            const cat = t.category_name || "Pemasukan";
            incMap.set(cat, (incMap.get(cat) ?? 0) + Number(t.amount ?? 0));
          });
        const incCatList = Array.from(incMap.entries()).map(
          ([c, a]) => `${c}: Rp${a.toLocaleString("id-ID")}`
        );

        sections.push(
          `📅 [${sub.label}]:\n` +
          `- Total Pemasukan: Rp${subInc.toLocaleString("id-ID")} (${subTxs.filter((t: any) => t.type === "income").length} transaksi)\n` +
          (incCatList.length > 0 ? `  Sumber: ${incCatList.join(", ")}\n` : "") +
          `- Total Pengeluaran: Rp${subExp.toLocaleString("id-ID")} (${subTxs.filter((t: any) => t.type === "expense").length} transaksi)\n` +
          (expCatList.length > 0 ? `  Pos Kategori: ${expCatList.join(", ")}\n` : "") +
          `- Saldo Bersih: Rp${subBal.toLocaleString("id-ID")}\n` +
          (subTxs.length === 0 ? `- Status: Belum ada catatan transaksi pada bulan/periode ini (Rp0).\n` : "")
        );
      }
      subPeriodsText = `=== RINCIAN PER PERIODE YANG DITANYAKAN ===\n${sections.join("\n")}\n\n`;
    } else {
      // Untuk rentang banyak bulan (> 4 bulan, misal Januari s/d September)
      const emptySubPeriods: string[] = [];
      const activeSubSections: string[] = [];

      for (const sub of range.subPeriods) {
        const subStart = new Date(sub.startDate).getTime();
        const subEnd = new Date(sub.endDate).getTime();
        const subTxs = allAvailableTxs.filter((t: any) => {
          if (!t.transaction_date) return false;
          const txTime = new Date(t.transaction_date).getTime();
          return txTime >= subStart && txTime <= subEnd;
        });

        if (subTxs.length === 0) {
          emptySubPeriods.push(sub.name);
          continue;
        }

        const subInc = subTxs
          .filter((t: any) => t.type === "income")
          .reduce((sum: number, t: any) => sum + Number(t.amount ?? 0), 0);
        const subExp = subTxs
          .filter((t: any) => t.type === "expense")
          .reduce((sum: number, t: any) => sum + Number(t.amount ?? 0), 0);
        const subBal = subInc - subExp;

        const expMap = new Map<string, number>();
        subTxs
          .filter((t: any) => t.type === "expense")
          .forEach((t: any) => {
            const cat = t.category_name || "Lainnya";
            expMap.set(cat, (expMap.get(cat) ?? 0) + Number(t.amount ?? 0));
          });
        const expCatList = Array.from(expMap.entries()).map(
          ([c, a]) => `${c}: Rp${a.toLocaleString("id-ID")}`
        );

        const incMap = new Map<string, number>();
        subTxs
          .filter((t: any) => t.type === "income")
          .forEach((t: any) => {
            const cat = t.category_name || "Pemasukan";
            incMap.set(cat, (incMap.get(cat) ?? 0) + Number(t.amount ?? 0));
          });
        const incCatList = Array.from(incMap.entries()).map(
          ([c, a]) => `${c}: Rp${a.toLocaleString("id-ID")}`
        );

        activeSubSections.push(
          `📅 [${sub.label}]:\n` +
          `- Total Pemasukan: Rp${subInc.toLocaleString("id-ID")} (${subTxs.filter((t: any) => t.type === "income").length} transaksi)\n` +
          (incCatList.length > 0 ? `  Sumber: ${incCatList.join(", ")}\n` : "") +
          `- Total Pengeluaran: Rp${subExp.toLocaleString("id-ID")} (${subTxs.filter((t: any) => t.type === "expense").length} transaksi)\n` +
          (expCatList.length > 0 ? `  Pos Kategori: ${expCatList.join(", ")}\n` : "") +
          `- Saldo Bersih: Rp${subBal.toLocaleString("id-ID")}\n`
        );
      }

      const sections: string[] = [];
      if (emptySubPeriods.length > 0) {
        if (emptySubPeriods.length === 1) {
          sections.push(`📅 [Bulan ${emptySubPeriods[0]}]: Belum ada catatan transaksi (Rp0).`);
        } else {
          sections.push(`📅 [Bulan ${emptySubPeriods[0]} s/d ${emptySubPeriods[emptySubPeriods.length - 1]}]: Belum ada catatan transaksi (Rp0).`);
        }
      }
      sections.push(...activeSubSections);
      subPeriodsText = `=== RINCIAN PER PERIODE YANG DITANYAKAN ===\n${sections.join("\n\n")}\n\n`;
    }
  }

  // Jika periode yang ditanyakan Rp0 tapi pengguna memiliki transaksi aktif di periode lain
  let otherPeriodsNote = "";
  if (count === 0 && rawTxs.length > 0) {
    const activeMonths = new Map<string, { inc: number; exp: number; count: number }>();
    for (const t of rawTxs) {
      if (!t.transaction_date) continue;
      const d = new Date(t.transaction_date);
      const label = d.toLocaleDateString("id-ID", { month: "long", year: "numeric" });
      const current = activeMonths.get(label) ?? { inc: 0, exp: 0, count: 0 };
      if (t.type === "income") current.inc += Number(t.amount ?? 0);
      if (t.type === "expense") current.exp += Number(t.amount ?? 0);
      current.count += 1;
      activeMonths.set(label, current);
    }

    if (activeMonths.size > 0) {
      const activeList = Array.from(activeMonths.entries()).map(([monthName, stats]) => {
        return `• Bulan ${monthName}: Pemasukan Rp${stats.inc.toLocaleString("id-ID")}, Pengeluaran Rp${stats.exp.toLocaleString("id-ID")} (${stats.count} transaksi)`;
      });
      otherPeriodsNote = `\n=== INFORMASI TRANSAKSI AKTIF DI PERIODE LAIN ===\n` +
        `Catatan Sistem: Pada ${range.periodLabel} belum ada catatan transaksi (Rp0).\n` +
        `Namun sistem mendeteksi transaksi aktif pada periode berikut:\n` +
        activeList.join("\n") +
        `\nInstruksi Tambahan: Jelaskan dengan ramah bahwa pada ${range.periodLabel} belum ada transaksi (Rp0), lalu informasikan juga data transaksi aktif di periode lain di atas agar pengguna mendapatkan gambaran yang akurat dan tidak bingung!\n\n`;
    }
  }

  let wallets = data?.wallets ?? [];
  if ((!wallets || wallets.length === 0) && body?.wallets && body.wallets.length > 0) {
    wallets = body.wallets.map((w) => ({
      name: w.name,
      type: w.type,
      current_balance: w.current_balance ?? w.initial_balance ?? 0,
    }));
  } else if (body?.wallets && body.wallets.length > 0) {
    const bodyWalletSum = body.wallets.reduce(
      (sum, w) => sum + Number(w.current_balance ?? w.initial_balance ?? 0),
      0
    );
    const dataWalletSum = wallets.reduce(
      (sum, w: any) => sum + Number(w.current_balance ?? 0),
      0
    );
    if (bodyWalletSum > 0 && dataWalletSum === 0) {
      wallets = body.wallets.map((w) => ({
        name: w.name,
        type: w.type,
        current_balance: w.current_balance ?? w.initial_balance ?? 0,
      }));
    }
  }

  // Hitung total saldo riil dari seluruh dompet & rekening
  let walletSum = 0;
  if (Array.isArray(wallets) && wallets.length > 0) {
    walletSum = wallets.reduce(
      (sum, w: any) => sum + Number(w.current_balance ?? w.initial_balance ?? 0),
      0
    );
  }

  // JANGAN PERNAH default ke `balance` (arus kas transaksi) jika saldo dompet positif.
  // Arus kas transaksi (Pemasukan - Pengeluaran) bisa minus jika pengguna belum catat transaksi pemasukan,
  // tetapi uang asli di dompet/rekening pengguna tetap bernilai positif (dari saldo awal kartu dompet).
  let totalWealth = 0;
  if (walletSum > 0) {
    totalWealth = walletSum;
  } else if (data?.total_wealth !== undefined && data?.total_wealth !== null && Number(data.total_wealth) > 0) {
    totalWealth = Number(data.total_wealth);
  } else if (Array.isArray(wallets) && wallets.length > 0) {
    totalWealth = walletSum;
  } else {
    totalWealth = Math.max(0, balance);
  }

  let walletText = "Belum ada data dompet.";
  if (Array.isArray(wallets) && wallets.length > 0) {
    walletText = wallets
      .map(
        (w: any) =>
          `- ${w.name} (${w.type}): Rp${Number(w.current_balance ?? 0).toLocaleString("id-ID")}`
      )
      .join("\n");
  }

  let expenseCatText = "Belum ada pengeluaran.";
  if (Array.isArray(expenseCats) && expenseCats.length > 0) {
    expenseCatText = expenseCats
      .map(
        (c: any) =>
          `- ${c.category_name}: Rp${Number(c.total_amount).toLocaleString("id-ID")} (${c.percentage}%)`
      )
      .join("\n");
  }

  let incomeCatText = "Belum ada rincian sumber pemasukan.";
  if (Array.isArray(incomeCats) && incomeCats.length > 0) {
    incomeCatText = incomeCats
      .map(
        (c: any) =>
          `- ${c.category_name}: Rp${Number(c.total_amount).toLocaleString("id-ID")} (${c.percentage}%)`
      )
      .join("\n");
  }

  let recentTxText = "Belum ada daftar transaksi.";
  if (Array.isArray(recentTxs) && recentTxs.length > 0) {
    recentTxText = recentTxs
      .map((tx: any) => {
        let desc = tx.description ?? "";
        if (typeof desc === "string" && (desc.startsWith("ENC:") || desc.startsWith("VAULT:"))) {
          desc = "[Catatan Terenkripsi Brankas]";
        }
        return `• [${tx.transaction_date ?? ''}] ${tx.type === "income" ? "[PEMASUKAN]" : "[PENGELUARAN]"} Rp${Number(tx.amount).toLocaleString("id-ID")} | Kategori: ${tx.category_name} | Dompet: ${tx.wallet_name ?? 'Tunai'} | Ket: "${desc}"`;
      })
      .join("\n");
  }

  return `=== DATA KEUANGAN ASLI PENGGUNA (${range.periodLabel}) ===
- Total Saldo Riil Saat Ini (Semua Dompet & Rekening): Rp${totalWealth.toLocaleString("id-ID")}
- Total Pemasukan Tercatat Periode Ini: Rp${income.toLocaleString("id-ID")}
- Total Pengeluaran Tercatat Periode Ini: Rp${expense.toLocaleString("id-ID")}
- Selisih Transaksi Periode Ini: Rp${balance.toLocaleString("id-ID")}
- Total Transaksi Tercatat: ${count} transaksi

${subPeriodsText}${otherPeriodsNote}=== RINCIAN SALDO PER DOMPET & REKENING ===
${walletText}

=== RINCIAN SUMBER PEMASUKAN ===
${incomeCatText}

=== RINCIAN POS PENGELUARAN ===
${expenseCatText}

=== DAFTAR TRANSAKSI ASLI TERAKHIR (HISTORI NYATA) ===
${recentTxText}`;
}
