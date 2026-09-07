/**
 * Validation & Intent Classifier Utility
 * File: utils/validation.ts
 */

export interface WalletInfo {
  id: string;
  name: string;
  type: string;
  is_default?: boolean;
  current_balance?: number;
  initial_balance?: number;
}

export interface TransactionInfo {
  id?: string;
  type: string; // 'income' | 'expense'
  amount: number;
  category_name?: string;
  wallet_name?: string;
  description?: string;
  transaction_date?: string;
}

export interface ChatRequestBody {
  message?: string;
  categories?: Array<{ name: string; type: string }>;
  wallets?: Array<WalletInfo>;
  recent_transactions?: Array<TransactionInfo>;
  image?: string; // base64 string
  history?: Array<{ role: string; content: string }>;
  summary?: Record<string, unknown>;
}

export type ChatIntent = "receipt" | "transaction" | "financial" | "general";

/**
 * Mendeteksi niat/intent pengguna dari request secara cerdas dan akurat
 */
export function classifyIntent(body: ChatRequestBody): ChatIntent {
  // 1. Jika ada gambar / base64 struk -> receipt intent
  if (body.image && body.image.trim() !== "") {
    return "receipt";
  }

  const msg = (body.message ?? "").toLowerCase().trim();
  if (!msg) return "general";

  // 2. Sapaan murni pendek / ucapan terima kasih
  const pureGreetingRegex = /^(halo|hai|hi|hello|hey|hei|pagi|siang|sore|malam|assalamualaikum)[\s\!\.\?]*$/i;
  const pureThanksRegex = /^(terima kasih|makasih|thanks|thank you|ok|oke|sip|siap)[\s\!\.\?]*$/i;
  const pureIdentityRegex = /^(kamu siapa|siapa kamu|siapa anda|fitur apa|apa yang bisa kamu lakukan|bisa bantu apa|bisa apa)[\s\!\.\?]*$/i;

  if (pureGreetingRegex.test(msg) || pureThanksRegex.test(msg) || pureIdentityRegex.test(msg)) {
    return "general";
  }

  // 3. Deteksi TRANSAKSI BARU (Mencatat pengeluaran/pemasukan baru)
  const hasMoneyAmount =
    /\d+\s*(rb|ribu|k|jt|juta|rp)?/i.test(msg) &&
    (msg.includes("rb") ||
      msg.includes("k") ||
      msg.includes("ribu") ||
      msg.includes("jt") ||
      msg.includes("juta") ||
      msg.includes("rp") ||
      /\d{4,}/.test(msg));

  // Cek apakah ada bullet list / daftar poin transaksi (misal: "- parkir 2rb", "• bensin 13rb")
  const isBulletListWithAmount =
    /[-•*]\s*.+\b\d+\s*(rb|k|ribu|jt|juta|rp)?/i.test(msg);

  // Cek apakah pengguna sedang MENANYAKAN pertanyaan finansial / laporan
  const isFinancialQuestion =
    msg.includes("?") ||
    msg.includes("berapa") ||
    msg.includes("apa saja") ||
    msg.includes("apa aja") ||
    msg.includes("mana saja") ||
    msg.includes("mana aja") ||
    msg.includes("bagaimana") ||
    msg.includes("gimana") ||
    msg.includes("apakah") ||
    msg.includes("kenapa") ||
    msg.includes("mengapa") ||
    msg.includes("kok") ||
    msg.includes("laporan") ||
    msg.includes("rekap") ||
    msg.includes("ringkasan") ||
    msg.includes("evaluasi") ||
    msg.includes("lihat pengeluaran") ||
    msg.includes("cek pengeluaran") ||
    msg.includes("lihat pemasukan") ||
    msg.includes("cek pemasukan") ||
    msg.includes("total pengeluaran") ||
    msg.includes("total pemasukan") ||
    msg.includes("total saldo") ||
    msg.includes("sisa saldo") ||
    msg.includes("sisa uang");

  // 3. Deteksi KOREKSI TRANSAKSI / STRUK (misal: "Totalnya anda salah, harusnya 32rb", "koreksi total jadi 32rb")
  const isCorrection =
    (msg.includes("salah") ||
      msg.includes("keliru") ||
      msg.includes("koreksi") ||
      msg.includes("bukan") ||
      msg.includes("harusnya") ||
      msg.includes("ralat") ||
      msg.includes("ganti jadi") ||
      msg.includes("ubah jadi") ||
      msg.includes("jadinya")) &&
    (hasMoneyAmount || msg.includes("total") || msg.includes("struk") || msg.includes("harga"));

  if (isCorrection) {
    return "transaction";
  }

  // 4. Deteksi TRANSAKSI BARU (Mencatat pengeluaran/pemasukan baru)
  const transactionKeywords = [
    "beli", "bayar", "jajan", "makan", "minum", "order", "pesan", "checkout",
    "top up", "topup", "sewa", "cicil", "gaji", "gajian",
    "dapat uang", "dapet uang", "dapat duit", "dapet duit", "dapat", "dapet",
    "kiriman", "dapat kiriman", "dapet kiriman", "terima uang", "nerima uang",
    "terima duit", "nerima duit", "terima", "nerima",
    "duit masuk", "uang masuk", "ada duit", "ada uang",
    "tf masuk", "transfer masuk", "transfer ke", "tf ke", "transferan", "dapat transferan", "dapet transferan",
    "catat", "input", "tambah", "kemarin beli", "tadi beli",
    "ada pengeluaran", "pengeluaran yaitu", "pengeluaran:", "pengeluaran uang",
    "ada pemasukan", "pemasukan yaitu", "pemasukan:", "pemasukan",
    "potongan", "parkir", "bensin", "pulsa", "listrik", "ongkir", "sabun",
    "cuan", "rejeki", "rezeki", "bonus", "uang jajan", "uang saku", "nemu duit", "nemu uang",
    "jual", "penjualan", "laku"
  ];
  const hasTransactionKeyword = transactionKeywords.some((k) => msg.includes(k));

  // Jika pesan menyebutkan pengeluaran/pemasukan dengan nominal, atau berupa daftar belanja,
  // DAN bukan sedang bertanya laporan/evaluasi -> MAKA INI ADALAH TRANSAKSI BARU!
  const isProvidingExpenseOrIncomeData =
    !isFinancialQuestion &&
    hasMoneyAmount &&
    (hasTransactionKeyword ||
      isBulletListWithAmount ||
      msg.includes("pengeluaran") ||
      msg.includes("pemasukan") ||
      msg.includes("belanja") ||
      msg.includes("tunai") ||
      msg.includes("cash") ||
      msg.includes("rek") ||
      msg.includes("bca") ||
      msg.includes("dapet") ||
      msg.includes("dapat") ||
      msg.includes("kemarin") ||
      msg.includes("tadi"));

  if (
    isProvidingExpenseOrIncomeData ||
    (hasTransactionKeyword && hasMoneyAmount) ||
    msg.startsWith("catat ") ||
    msg.startsWith("input ") ||
    msg.startsWith("tambah ") ||
    msg.startsWith("beli ") ||
    msg.startsWith("bayar ")
  ) {
    return "transaction";
  }

  // 5. Deteksi PERTANYAAN FINANSIAL, BUDGETING, PERENCANAAN, & KONSULTASI (FINANCIAL INTENT)
  const financialKeywords = [
    "apa yang harus", "apa yg harus", "harus apa", "harus gimana", "harus bagaimana",
    "lakukan untuk", "bertahan", "cukup ga", "cukup tidak", "cukupkah", "cukup",
    "budget", "anggaran", "saran", "tips", "rekomendasi", "evaluasi",
    "gimana cara", "bagaimana cara", "jangan make misal", "harus dengan dana",
    "duit saya", "uang saya", "saldo saya", "dana saya", "duitku", "uangku", "saldoku",
    "total saldo", "sisa uang", "sisa saldo", "kekayaan",
    "di dompet ada", "di bank ada", "di rekening ada", "boros", "hemat",
    "rekap", "laporan", "riwayat", "histori", "mutasi",
    "dihapus", "terhapus", "diedit", "batal", "dibatalkan", "salah catat",
    "minus", "mines", "defisit", "surplus", "arus kas", "edit saldo", "ngedit saldo", "saldo card",
    "bagaimana jika", "bagaimana kalau", "gimana kalau", "gimana jika",
    "kalo bulan", "kalau bulan", "bulan lalu", "tahun lalu", "tahun ini",
    "awal tahun", "awal bulan", "akhir bulan", "bulan sekarang",
    "sampe sekarang", "sampai sekarang", "hingga sekarang", "sejak awal", "sepanjang tahun",
    "januari", "februari", "maret", "april", "mei", "juni",
    "juli", "agustus", "september", "oktober", "november", "desember"
  ];

  const isFinancialAdvisoryOrInquiry = financialKeywords.some((k) => msg.includes(k));

  if (isFinancialAdvisoryOrInquiry) {
    return "financial";
  }

  // 6. Cek Multi-Turn History (Percakapan Bersambung Pertanyaan):
  const isQuestionOrFollowup =
    msg.includes("bagaimana") ||
    msg.includes("gimana") ||
    msg.includes("kalo") ||
    msg.includes("kalau") ||
    msg.includes("kenapa") ||
    msg.includes("mengapa") ||
    msg.includes("berapa") ||
    msg.includes("lalu") ||
    msg.includes("terus") ||
    msg.includes("apa") ||
    msg.includes("kok");

  if (body.history && body.history.length > 0) {
    const lastMsg = body.history[body.history.length - 1];
    const prevContent = (lastMsg?.content ?? "").toLowerCase();
    const prevWasFinancial =
      prevContent.includes("pengeluaran") ||
      prevContent.includes("pemasukan") ||
      prevContent.includes("transaksi") ||
      prevContent.includes("saldo") ||
      prevContent.includes("rp") ||
      prevContent.includes("bulan") ||
      prevContent.includes("dompet");

    if (prevWasFinancial && isQuestionOrFollowup) {
      return "financial";
    }
  }

  if (isQuestionOrFollowup && (msg.includes("tahun") || msg.includes("bulan") || msg.includes("hari") || msg.includes("sekarang"))) {
    return "financial";
  }

  return "general";
}

/**
 * Format string daftar kategori untuk dimasukkan ke system prompt
 */
export function formatCategoryList(categories?: Array<{ name: string; type: string }>): string {
  if (categories && Array.isArray(categories) && categories.length > 0) {
    return categories.map((c) => `${c.name} (${c.type})`).join(", ");
  }
  return "Makan & Minum (expense), Transportasi (expense), Belanja (expense), Tagihan & Utilitas (expense), Hiburan (expense), Kesehatan (expense), Pendidikan (expense), Gaji (income), Freelance (income), Investasi (income), Bonus & Hadiah (income), Lainnya (expense), Pemasukan Lain (income)";
}

/**
 * Format string daftar dompet pengguna
 */
export function formatWalletList(wallets?: Array<WalletInfo>): string {
  if (wallets && Array.isArray(wallets) && wallets.length > 0) {
    return wallets.map((w) => `"${w.name}" (ID: ${w.id}, Tipe: ${w.type}${w.is_default ? ', Utama' : ''})`).join(", ");
  }
  return '"Dompet Tunai" (Tipe: cash), "Rekening Bank" (Tipe: bank), "E-Wallet" (Tipe: ewallet)';
}
