import 'package:cakeu/core/utils/currency_formatter.dart';
import 'package:cakeu/features/categories/data/models/category_model.dart';
import 'package:cakeu/features/chatbot/data/models/chat_message_model.dart';
import 'package:cakeu/features/chatbot/data/services/category_keyword_matcher.dart';

class PendingContext {
  final String description;
  final String categoryName;
  final String type;
  final DateTime? transactionDate;

  PendingContext({
    required this.description,
    required this.categoryName,
    required this.type,
    this.transactionDate,
  });
}

/// Mesin NLP Lokal & Rule-based Offline untuk Chatbot Finary
class LocalNlpEngine {
  PendingContext? _pendingContext;

  String naturalizeReplyText(
    String original,
    double? amount,
    String? category,
    String? description,
  ) {
    final lower = original.toLowerCase();

    // Ubah kalimat kaku bot seperti "Saya mendeteksi transaksi..."
    if (lower.contains('mendeteksi') ||
        lower.contains('pesan diproses') ||
        lower.contains('apakah ingin disimpan') ||
        lower.contains('apakah anda ingin menyimpan') ||
        lower.startsWith('saya mendeteksi')) {
      final formatted = amount != null ? ' (total **Rp${formatRupiah(amount)}**)' : '';
      final cat = (category != null && category.isNotEmpty) ? ' untuk **$category**' : '';
      return 'Sip, udah aku hitung dan rekap$cat$formatted! Cek rinciannya di bawah dan tap Simpan ya! ✨';
    }
    return original;
  }

  static String? detectPaymentMethodFromText(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('qris')) return 'E-Wallet';
    if (lower.contains('cash') || lower.contains('tunai')) return 'Dompet Tunai';
    if (lower.contains('gopay') || lower.contains('ovo') || lower.contains('dana') || lower.contains('shopeepay') || lower.contains('ewallet') || lower.contains('e-wallet')) return 'E-Wallet';
    if (lower.contains('transfer') || lower.contains('tf') || lower.contains('rekening') || lower.contains('bank') || lower.contains('debit') || lower.contains('bca') || lower.contains('mandiri') || lower.contains('bri')) return 'Rekening Bank';
    return null;
  }

  List<TransactionGroup> groupItemsByCategory(List<ReceiptItem> items) {
    final Map<String, List<ReceiptItem>> groupedMap = {};
    final Map<String, String> groupCategoryMap = {};
    final Map<String, String> groupTypeMap = {};
    final Map<String, String?> groupWalletMap = {};

    for (final item in items) {
      final lowerName = item.name.toLowerCase();
      final bool isItemIncome = lowerName.contains('dapat') ||
          lowerName.contains('dapet') ||
          lowerName.contains('gaji') ||
          lowerName.contains('kiriman') ||
          lowerName.contains('transfer masuk') ||
          lowerName.contains('uang masuk') ||
          lowerName.contains('bonus') ||
          lowerName.contains('cuan') ||
          lowerName.contains('rejeki') ||
          lowerName.contains('rezeki');

      final itemType = isItemIncome ? 'income' : 'expense';
      final cat = isItemIncome ? 'Pemasukan Lain' : detectItemCategory(item.name);
      final pm = detectPaymentMethodFromText(item.name);
      final key = pm != null ? '${cat}__${itemType}__$pm' : '${cat}__$itemType';

      groupedMap.putIfAbsent(key, () => []).add(item);
      groupCategoryMap[key] = cat;
      groupTypeMap[key] = itemType;
      if (pm != null) groupWalletMap[key] = pm;
    }

    return groupedMap.entries.map((e) {
      final key = e.key;
      final catName = groupCategoryMap[key] ?? 'Belanja';
      final itemType = groupTypeMap[key] ?? 'expense';
      final catItems = e.value;
      final totalGrp = catItems.fold<double>(0, (sum, i) => sum + (i.price ?? 0));
      return TransactionGroup(
        categoryName: catName,
        type: itemType,
        totalAmount: totalGrp,
        items: catItems,
        description: catItems.map((i) => i.name).join(', '),
        walletName: groupWalletMap[key],
      );
    }).toList();
  }

  String detectItemCategory(String itemName) {
    return CategoryKeywordMatcher.detect(itemName);
  }

  ExtractedTransaction? checkInstantGreeting(String text) {
    final lower = text.trim().toLowerCase();

    // 1. Sapaan singkat
    final greetingRegex = RegExp(
      r'^(halo|hai|hi|hello|hey|hei|pagi|siang|sore|malam|assalamualaikum)[\s\!\.\?]*$',
      caseSensitive: false,
    );
    if (greetingRegex.hasMatch(lower)) {
      return ExtractedTransaction(
        isTransaction: false,
        isReceipt: false,
        replyText:
            'Halo! Aku Finary AI, asisten keuangan pribadimu ✨. Ada transaksi atau struk belanja yang mau kita catat hari ini?',
      );
    }

    // 2. Ucapan terima kasih
    final thanksRegex = RegExp(
      r'^(terima kasih|makasih|thanks|thank you|matur nuwun|nuhun|tengkyu)[\s\!\.\?]*$',
      caseSensitive: false,
    );
    if (thanksRegex.hasMatch(lower)) {
      return ExtractedTransaction(
        isTransaction: false,
        isReceipt: false,
        replyText: 'Sama-sama! Senang bisa membantumu mengelola keuangan dengan rapi ✨',
      );
    }

    // 3. Pertanyaan identitas / kamu siapa
    if (lower == 'kamu siapa' || lower == 'siapa kamu' || lower == 'siapa anda' || lower == 'tentang kamu') {
      return ExtractedTransaction(
        isTransaction: false,
        isReceipt: false,
        replyText:
            'Aku Finary AI, asisten pintar untuk mencatat pengeluaran, pemasukan, scan struk belanja, dan menganalisis ringkasan keuanganmu 🚀',
      );
    }

    // 4. Panduan / bantuan / cara pakai
    if (lower == 'bisa apa' ||
        lower == 'kamu bisa apa' ||
        lower == 'bantu apa' ||
        lower == 'bisa bantu apa' ||
        lower == 'cara pakai' ||
        lower == 'panduan' ||
        lower == 'tolong bantu' ||
        lower == 'bantu saya') {
      return ExtractedTransaction(
        isTransaction: false,
        isReceipt: false,
        replyText:
            'Aku bisa membantumu:\n\n'
            '• 💬 **Catat Transaksi**: Ketik misalnya *"Beli kopi 25rb"* atau *"Gaji kantor 5jt"*\n'
            '• 📸 **Scan Struk**: Tap kamera untuk foto struk kasir dan hitung PPN otomatis\n'
            '• 📊 **Tanya Keuangan**: Tanya *"Pengeluaran bulan ini berapa?"* atau *"Pengeluaran minggu ini berapa?"*',
      );
    }

    return null;
  }

  static ({int hour, int minute}) extractTimeFromText(String text, DateTime now) {
    final lower = text.toLowerCase();
    final timeRegex = RegExp(
      r'(?:jam|pukul)\s*(\d{1,2})(?:[\.:](\d{2}))?\s*(pagi|siang|sore|malam)?',
      caseSensitive: false,
    );
    final match = timeRegex.firstMatch(lower);
    if (match != null) {
      int h = int.tryParse(match.group(1) ?? '') ?? now.hour;
      int m = int.tryParse(match.group(2) ?? '') ?? 0;
      final period = match.group(3)?.toLowerCase();
      if (period == 'malam' && h < 12) h += 12;
      if (period == 'sore' && h < 12 && h >= 1 && h <= 6) h += 12;
      if (period == 'siang' && h < 11 && h >= 1) h += 12;
      if (period == 'pagi' && h == 12) h = 0;
      if (h >= 0 && h <= 23 && m >= 0 && m <= 59) {
        return (hour: h, minute: m);
      }
    }
    return (hour: now.hour, minute: now.minute);
  }

  static DateTime? extractRelativeDate(String text) {
    final lower = text.toLowerCase();
    final now = DateTime.now();
    final time = extractTimeFromText(text, now);

    // 1. Relatif Hari
    if (lower.contains('kemarin lusa') || lower.contains('2 hari lalu') || lower.contains('dua hari lalu')) {
      final d = now.subtract(const Duration(days: 2));
      return DateTime(d.year, d.month, d.day, time.hour, time.minute);
    }
    if (lower.contains('3 hari lalu') || lower.contains('tiga hari lalu')) {
      final d = now.subtract(const Duration(days: 3));
      return DateTime(d.year, d.month, d.day, time.hour, time.minute);
    }
    if (lower.contains('4 hari lalu') || lower.contains('empat hari lalu')) {
      final d = now.subtract(const Duration(days: 4));
      return DateTime(d.year, d.month, d.day, time.hour, time.minute);
    }
    if (lower.contains('5 hari lalu') || lower.contains('lima hari lalu')) {
      final d = now.subtract(const Duration(days: 5));
      return DateTime(d.year, d.month, d.day, time.hour, time.minute);
    }
    if (lower.contains('6 hari lalu') || lower.contains('enam hari lalu')) {
      final d = now.subtract(const Duration(days: 6));
      return DateTime(d.year, d.month, d.day, time.hour, time.minute);
    }
    if (lower.contains('seminggu lalu') || lower.contains('1 minggu lalu') || lower.contains('7 hari lalu')) {
      final d = now.subtract(const Duration(days: 7));
      return DateTime(d.year, d.month, d.day, time.hour, time.minute);
    }
    if (lower.contains('kemarin') || lower.contains('yesterday')) {
      final d = now.subtract(const Duration(days: 1));
      return DateTime(d.year, d.month, d.day, time.hour, time.minute);
    }
    if (lower.contains('tadi') || lower.contains('hari ini') || lower.contains('barusan')) {
      return DateTime(now.year, now.month, now.day, time.hour, time.minute);
    }

    // 2. Format spesifik nama bulan: "pada tanggal 31 agustus", "31 agustus", "15 juli", "tgl 31 agu"
    final dateNamedMonthRegex = RegExp(
      r'(?:pada\s+)?(?:tanggal|tgl)?\s*(\d{1,2})\s*(?:bulan\s*)?(januari|februari|maret|april|mei|juni|juli|agustus|september|oktober|november|desember|jan|feb|mar|apr|jun|jul|agu|agt|sep|okt|nov|des)(?:\s*(\d{4}))?',
      caseSensitive: false,
    );
    final matchNamed = dateNamedMonthRegex.firstMatch(lower);
    if (matchNamed != null) {
      final day = int.tryParse(matchNamed.group(1) ?? '');
      if (day != null && day >= 1 && day <= 31) {
        final monthStr = matchNamed.group(2)?.toLowerCase();
        final yearStr = matchNamed.group(3);

        const monthMap = {
          'januari': 1, 'jan': 1,
          'februari': 2, 'feb': 2,
          'maret': 3, 'mar': 3,
          'april': 4, 'apr': 4,
          'mei': 5,
          'juni': 6, 'jun': 6,
          'juli': 7, 'jul': 7,
          'agustus': 8, 'agu': 8, 'agt': 8,
          'september': 9, 'sep': 9,
          'oktober': 10, 'okt': 10,
          'november': 11, 'nov': 11,
          'desember': 12, 'des': 12,
        };

        int month = monthMap[monthStr] ?? now.month;
        int year = int.tryParse(yearStr ?? '') ?? now.year;

        try {
          return DateTime(year, month, day, time.hour, time.minute);
        } catch (_) {}
      }
    }

    // 3. Format angka biasa: "tanggal 28", "tgl 1/9", "tanggal 15/8"
    final dateNumericRegex = RegExp(
      r'(?:pada\s+)?(?:tanggal|tgl)\s*(\d{1,2})(?:[\s/]+(\d{1,2}))?(?:\s*(\d{4}))?',
      caseSensitive: false,
    );
    final matchNum = dateNumericRegex.firstMatch(lower);
    if (matchNum != null) {
      final day = int.tryParse(matchNum.group(1) ?? '');
      if (day != null && day >= 1 && day <= 31) {
        final monthStr = matchNum.group(2);
        final yearStr = matchNum.group(3);

        int month = now.month;
        if (monthStr != null) {
          final parsedMonth = int.tryParse(monthStr);
          if (parsedMonth != null && parsedMonth >= 1 && parsedMonth <= 12) {
            month = parsedMonth;
          }
        }

        int year = int.tryParse(yearStr ?? '') ?? now.year;
        if (monthStr == null && day > now.day && month == now.month) {
          month = month == 1 ? 12 : month - 1;
          if (month == 12) year -= 1;
        }

        try {
          return DateTime(year, month, day, time.hour, time.minute);
        } catch (_) {}
      }
    }

    return null;
  }

  ExtractedTransaction parseText(String text, List<CategoryModel> categories) {
    final trimmed = text.trim();
    final lower = trimmed.toLowerCase();
    final detectedDate = extractRelativeDate(trimmed);

    // Cek sapaan instan lokal
    final instant = checkInstantGreeting(trimmed);
    if (instant != null) return instant;

    // ─── A1. Parsing Multi-item berdasarkan baris baru (\n) ───
    final lines = trimmed.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length > 1) {
      double totalMulti = 0;
      final List<ReceiptItem> parsedList = [];
      for (final line in lines) {
        final lineClean = line.trim().replaceAll(RegExp(r'^[\-\*•\d\.\)]+\s*'), '');
        final lineMatch = RegExp(
          r'^(.*?)\s+(?:rp\.?\s*)?(\d+[\.,]?\d*)\s*(rb|k|ribu|jt|juta)?$',
          caseSensitive: false,
        ).firstMatch(lineClean);

        if (lineMatch != null) {
          final itemName = lineMatch.group(1)?.trim() ?? '';
          final rawVal = lineMatch.group(2)?.replaceAll('.', '').replaceAll(',', '.') ?? '0';
          final unit = lineMatch.group(3)?.toLowerCase() ?? '';
          double baseVal = double.tryParse(rawVal) ?? 0;
          if (unit == 'rb' || unit == 'k' || unit == 'ribu') {
            baseVal *= 1000;
          } else if (unit == 'jt' || unit == 'juta') {
            baseVal *= 1000000;
          } else if (baseVal < 1000 && baseVal > 0) {
            baseVal *= 1000;
          }

          if (itemName.isNotEmpty && baseVal > 0) {
            totalMulti += baseVal;
            parsedList.add(ReceiptItem(name: cleanTransactionDescription(itemName), qty: 1, price: baseVal));
          }
        }
      }

      if (parsedList.length > 1 && totalMulti > 0) {
        _pendingContext = null;
        final formattedTotal = formatRupiah(totalMulti);
        final groups = groupItemsByCategory(parsedList);

        final replyText = groups.length > 1
            ? 'Sip, udah aku pilah ke ${groups.length} kategori (total **Rp$formattedTotal**)! Cek ringkasan di bawah dan tap Simpan Semua ya! ✨'
            : 'Sip, udah aku hitung dan rekap semuanya (total **Rp$formattedTotal**)! Cek daftar item di bawah dan tap Simpan ya! ✨';

        return ExtractedTransaction(
          isTransaction: true,
          isReceipt: false,
          type: 'expense',
          amount: totalMulti,
          items: parsedList,
          groups: groups,
          categoryName: groups.first.categoryName,
          description: parsedList.map((e) => e.name).join(', '),
          transactionDate: detectedDate,
          replyText: replyText,
        );
      }
    }

    // ─── A2. Parsing Multi-item dalam 1 baris teks (misal: "kopi 25rb ayam geprek 15rb martabak 33") ───
    final multiItemRegex = RegExp(
      r'([a-zA-Z\s]+?)\s+(\d+[\.,]?\d*)\s*(rb|k|ribu|jt|juta)?(?=\s+[a-zA-Z]|$)',
      caseSensitive: false,
    );
    final multiMatches = multiItemRegex.allMatches(trimmed).toList();
    if (multiMatches.length > 1) {
      double totalMulti = 0;
      final List<ReceiptItem> parsedList = [];
      for (final m in multiMatches) {
        final itemName = m.group(1)?.trim() ?? '';
        final rawVal = m.group(2)?.replaceAll('.', '').replaceAll(',', '.') ?? '0';
        final unit = m.group(3)?.toLowerCase() ?? '';
        double baseVal = double.tryParse(rawVal) ?? 0;
        if (unit == 'rb' || unit == 'k' || unit == 'ribu') {
          baseVal *= 1000;
        } else if (unit == 'jt' || unit == 'juta') {
          baseVal *= 1000000;
        } else if (baseVal < 1000 && baseVal > 0) {
          baseVal *= 1000;
        }

        if (itemName.isNotEmpty && baseVal > 0) {
          totalMulti += baseVal;
          parsedList.add(ReceiptItem(name: cleanTransactionDescription(itemName), qty: 1, price: baseVal));
        }
      }

      if (parsedList.length > 1 && totalMulti > 0) {
        _pendingContext = null;
        final formattedTotal = formatRupiah(totalMulti);
        final groups = groupItemsByCategory(parsedList);

        final replyText = groups.length > 1
            ? 'Sip, udah aku pilah ke ${groups.length} kategori (total **Rp$formattedTotal**)! Cek ringkasan di bawah dan tap Simpan Semua ya! ✨'
            : 'Sip, udah aku hitung dan rekap semuanya (total **Rp$formattedTotal**)! Cek daftar item di bawah dan tap Simpan ya! ✨';

        return ExtractedTransaction(
          isTransaction: true,
          isReceipt: false,
          type: 'expense',
          amount: totalMulti,
          items: parsedList,
          groups: groups,
          categoryName: groups.first.categoryName,
          description: parsedList.map((e) => e.name).join(', '),
          transactionDate: detectedDate,
          replyText: replyText,
        );
      }
    }

    // ─── B. Parsing Angka Tunggal / Nominal ───
    final regexNumber = RegExp(
      r'(?:rp\.?\s*)?(\d+[\.,]?\d*)\s*(rb|k|ribu|jt|juta)?',
      caseSensitive: false,
    );
    final match = regexNumber.firstMatch(lower);

    double? amount;
    if (match != null) {
      String rawNum = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      if (match.group(1)!.contains('.') || match.group(1)!.contains(',')) {
        rawNum = match.group(1)!.replaceAll(',', '.');
      }
      double base = double.tryParse(rawNum) ?? 0;
      String unit = match.group(2)?.toLowerCase() ?? '';

      if (unit == 'rb' || unit == 'k' || unit == 'ribu') {
        amount = base * 1000;
      } else if (unit == 'jt' || unit == 'juta') {
        amount = base * 1000000;
      } else {
        if (base > 0) {
          amount = base;
        }
      }
    }

    final isJustAmount = amount != null &&
        amount > 0 &&
        (lower.replaceAll(RegExp(r'[\d\s\.,k|rb|ribu|jt|juta|rp]'), '').trim().length <= 3);

    // ─── C. Handle Follow-up Context (Pernah sebut item, baru sebut nominal) ───
    if (isJustAmount && _pendingContext != null) {
      final prev = _pendingContext!;
      _pendingContext = null;
      final formattedAmount = formatRupiah(amount);

      return ExtractedTransaction(
        isTransaction: true,
        isReceipt: false,
        type: prev.type,
        amount: amount,
        categoryName: prev.categoryName,
        description: prev.description,
        transactionDate: prev.transactionDate ?? detectedDate,
        replyText:
            'Siap! Transaksi **${prev.description}** sebesar **Rp$formattedAmount** (${prev.categoryName}) sudah kusiapkan. Silakan klik **Simpan ke Transaksi** di bawah ya! ✨',
      );
    } else if (isJustAmount && _pendingContext == null) {
      final formattedAmount = formatRupiah(amount);
      _pendingContext = PendingContext(
        description: 'Transaksi',
        categoryName: 'Lainnya',
        type: 'expense',
        transactionDate: detectedDate,
      );
      return ExtractedTransaction(
        isTransaction: false,
        replyText:
            'Uang sebesar **Rp$formattedAmount** ini untuk transaksi apa ya? 📝\n\nKetik rincian atau nama keperluannya (contoh: **Makan siang**, **Bensin**, atau **Gaji**).',
      );
    }

    // ─── C. Kategori & Tipe Deteksi ───
    bool isIncome = lower.contains('gaji') ||
        lower.contains('dapat uang') ||
        lower.contains('dapet uang') ||
        lower.contains('dapat duit') ||
        lower.contains('dapet duit') ||
        lower.contains('duit masuk') ||
        lower.contains('uang masuk') ||
        lower.contains('ada duit') ||
        lower.contains('ada uang') ||
        lower.contains('dapat transferan') ||
        lower.contains('dapet transferan') ||
        lower.contains('transferan masuk') ||
        lower.contains('transfer masuk') ||
        lower.contains('terima uang') ||
        lower.contains('terima duit') ||
        lower.contains('nerima uang') ||
        lower.contains('nerima duit') ||
        lower.contains('dapat') ||
        lower.contains('dapet') ||
        lower.contains('kiriman') ||
        lower.contains('bonus') ||
        lower.contains('cuan') ||
        lower.contains('rejeki') ||
        lower.contains('rezeki') ||
        lower.contains('penjualan') ||
        lower.contains('bunga bank') ||
        lower.contains('bunga deposito') ||
        lower.contains('freelance') ||
        lower.contains('uang jajan') ||
        lower.contains('uang saku') ||
        lower.contains('cair');

    String type = isIncome ? 'income' : 'expense';
    String matchedCategory = isIncome ? 'Pemasukan Lain' : 'Belanja';
    if (isIncome) {
      if (lower.contains('gaji')) {
        matchedCategory = 'Gaji';
      } else if (lower.contains('kiriman') || lower.contains('uang jajan') || lower.contains('uang saku') || lower.contains('hadiah') || lower.contains('bonus')) {
        matchedCategory = 'Bonus & Hadiah';
      } else if (lower.contains('freelance') || lower.contains('proyek')) {
        matchedCategory = 'Freelance';
      } else if (lower.contains('investasi') || lower.contains('saham') || lower.contains('crypto') || lower.contains('cuan')) {
        matchedCategory = 'Investasi';
      }
    }
    bool hasSpendingIntent = false;

    if (lower.contains('kopi') ||
        lower.contains('esteh') ||
        lower.contains('es teh') ||
        lower.contains('teh') ||
        lower.contains('makan') ||
        lower.contains('sarapan') ||
        lower.contains('dinner') ||
        lower.contains('lunch') ||
        lower.contains('nasi') ||
        lower.contains('minum') ||
        lower.contains('resto') ||
        lower.contains('cafe') ||
        lower.contains('kafe') ||
        lower.contains('snack') ||
        lower.contains('jajan') ||
        lower.contains('mie') ||
        lower.contains('bakso') ||
        lower.contains('geprek') ||
        lower.contains('sate') ||
        lower.contains('ayam')) {
      matchedCategory = 'Makan & Minum';
      hasSpendingIntent = true;
    } else if (lower.contains('bensin') ||
        lower.contains('pertalite') ||
        lower.contains('pertamax') ||
        lower.contains('solar') ||
        lower.contains('ojol') ||
        lower.contains('grab') ||
        lower.contains('gojek') ||
        lower.contains('maxim') ||
        lower.contains('indrive') ||
        lower.contains('tol') ||
        lower.contains('parkir') ||
        lower.contains('service') ||
        lower.contains('servis') ||
        lower.contains('cuci motor') ||
        lower.contains('cuci mobil')) {
      matchedCategory = 'Transportasi';
      hasSpendingIntent = true;
    } else if (lower.contains('bunga bank') ||
        lower.contains('dividen') ||
        lower.contains('saham') ||
        lower.contains('kripto') ||
        lower.contains('crypto') ||
        lower.contains('reksadana')) {
      matchedCategory = 'Investasi';
      type = 'income';
      hasSpendingIntent = true;
    } else if (lower.contains('bonus') ||
        lower.contains('kado') ||
        lower.contains('hadiah') ||
        lower.contains('thr')) {
      matchedCategory = 'Bonus / Hadiah';
      hasSpendingIntent = true;
    } else if (lower.contains('belanja') ||
        lower.contains('baju') ||
        lower.contains('celana') ||
        lower.contains('sepatu') ||
        lower.contains('tas') ||
        lower.contains('skincare') ||
        lower.contains('makeup') ||
        lower.contains('shopee') ||
        lower.contains('tokopedia') ||
        lower.contains('indomaret') ||
        lower.contains('alfamart')) {
      matchedCategory = 'Belanja';
      hasSpendingIntent = true;
    } else if (lower.contains('listrik') ||
        lower.contains('air') ||
        lower.contains('pdam') ||
        lower.contains('pln') ||
        lower.contains('wifi') ||
        lower.contains('indihome') ||
        lower.contains('pulsa') ||
        lower.contains('kuota') ||
        lower.contains('sewa') ||
        lower.contains('kontrakan') ||
        lower.contains('kos') ||
        lower.contains('kost') ||
        lower.contains('cicilan')) {
      matchedCategory = 'Tagihan & Utilitas';
      hasSpendingIntent = true;
    } else if (lower.contains('obat') ||
        lower.contains('dokter') ||
        lower.contains('apotek') ||
        lower.contains('rumah sakit') ||
        lower.contains('klinik') ||
        lower.contains('vitamin')) {
      matchedCategory = 'Kesehatan';
      hasSpendingIntent = true;
    } else if (lower.contains('buku') ||
        lower.contains('kursus') ||
        lower.contains('spp') ||
        lower.contains('ukt') ||
        lower.contains('kuliah') ||
        lower.contains('les')) {
      matchedCategory = 'Pendidikan';
      hasSpendingIntent = true;
    } else if (lower.contains('nonton') ||
        lower.contains('bioskop') ||
        lower.contains('xxi') ||
        lower.contains('game') ||
        lower.contains('topup') ||
        lower.contains('diamond') ||
        lower.contains('netflix') ||
        lower.contains('spotify') ||
        lower.contains('wisata') ||
        lower.contains('liburan')) {
      matchedCategory = 'Hiburan';
      hasSpendingIntent = true;
    }

    // ─── D. Transaksi Lengkap (Ada Deskripsi & Nominal) ───
    if (amount != null && amount > 0 && (hasSpendingIntent || isIncome || lower.contains('beli') || lower.contains('bayar') || lower.contains('gaji') || lower.contains('dapat') || lower.contains('dapet') || lower.contains('habis') || lower.contains('masuk'))) {
      _pendingContext = null;
      final formattedAmount = formatRupiah(amount);

      String? detectedPaymentMethod;
      if (lower.contains('rek') || lower.contains('rekening') || lower.contains('bank') || lower.contains('transfer') || lower.contains('tf') || lower.contains('bca') || lower.contains('bri') || lower.contains('mandiri') || lower.contains('bni') || lower.contains('jago') || lower.contains('qris')) {
        detectedPaymentMethod = 'Rekening Bank';
      } else if (lower.contains('tunai') || lower.contains('cash') || lower.contains('uang tunai') || lower.contains('uang fisik')) {
        detectedPaymentMethod = 'Tunai';
      } else if (lower.contains('gopay') || lower.contains('ovo') || lower.contains('dana') || lower.contains('shopeepay') || lower.contains('spay') || lower.contains('linkaja')) {
        detectedPaymentMethod = 'E-Wallet';
      }

      return ExtractedTransaction(
        isTransaction: true,
        type: type,
        amount: amount,
        categoryName: matchedCategory,
        description: cleanTransactionDescription(trimmed),
        paymentMethod: detectedPaymentMethod,
        transactionDate: detectedDate,
        replyText:
            'Sip! Sudah kusiapkan pencatatan untuk **${cleanTransactionDescription(trimmed)}** sebesar **Rp$formattedAmount** kategori **$matchedCategory**. Cek tiket di bawah dan tap Simpan ya! ✅',
      );
    }

    // ─── E. Transaksi Parsial (Ada niat belanja/pemasukan, tapi belum ada nominal) ───
    if (hasSpendingIntent || lower.startsWith('beli') || lower.startsWith('bayar') || lower.startsWith('dapat') || lower.startsWith('gaji') || lower.contains('dapet')) {
      _pendingContext = PendingContext(
        description: trimmed,
        categoryName: matchedCategory,
        type: type,
        transactionDate: detectedDate,
      );

      return ExtractedTransaction(
        isTransaction: false,
        replyText:
            'Siap! Untuk **"$trimmed"** ($matchedCategory), berapa nominalnya ya? 💰\n\nKetik nominalnya aja, contoh: **25rb** atau **50.000**.',
      );
    }

    // ─── F. Natural Chit-Chat & Intents ───

    // 1. Sapaan / Salam
    final greetings = ['ha', 'hai', 'halo', 'haloo', 'hii', 'hello', 'helo', 'p', 'pagi', 'siang', 'sore', 'malam', 'assalamualaikum', 'samlikum', 'oy', 'oi', 'hey', 'hy'];
    if (greetings.contains(lower) || lower.startsWith('halo ') || lower.startsWith('hai ') || lower.startsWith('selamat ')) {
      _pendingContext = null;
      return ExtractedTransaction(
        isTransaction: false,
        replyText:
            'Halo! 👋 Senang bertemu denganmu.\nAda yang mau kita catat hari ini? Kamu bisa ketik santai seperti *"makan siang 25rb"* atau foto struk belanjaanmu ya! 📸',
      );
    }

    // 2. Niat Mencatat Umum
    if (lower.contains('mau catat') ||
        lower.contains('mau nyatet') ||
        lower.contains('mau dicatat') ||
        lower.contains('ada yang mau dicatat') ||
        lower.contains('ada yg mau dicatat') ||
        lower.contains('catat dong') ||
        lower.contains('bantu catat') ||
        lower.contains('ada transaksi')) {
      _pendingContext = null;
      return ExtractedTransaction(
        isTransaction: false,
        replyText:
            'Boleh banget! Mau catat transaksi apa nih? 📝\n\nTulis aja detailnya (misal: *"Beli bensin 30rb"* atau *"Gaji 5jt"*), atau kamu juga bisa langsung kirim foto struknya ya! 📸',
      );
    }

    // 3. Ucapan Terima Kasih & Pujian
    final gratitudes = ['makasih', 'terima kasih', 'makasii', 'tengkyu', 'thanks', 'thx', 'mantap', 'keren', 'oke', 'ok', 'sip', 'siap', 'yoi', 'sipp'];
    if (gratitudes.contains(lower) || lower.startsWith('makasih') || lower.startsWith('terima kasih')) {
      return ExtractedTransaction(
        isTransaction: false,
        replyText:
            'Sama-sama! Senang bisa membantu kelola keuanganmu. Jangan lupa kabari aku lagi kalau ada transaksi lainnya ya! 😊✨',
      );
    }

    // 4. Tanya Bantuan / Panduan / Fitur
    if (lower.contains('bisa apa') ||
        lower.contains('siapa kamu') ||
        lower.contains('kamu siapa') ||
        lower.contains('fitur') ||
        lower.contains('panduan') ||
        lower.contains('bantuan') ||
        lower.contains('help') ||
        lower.contains('cara pakai')) {
      return ExtractedTransaction(
        isTransaction: false,
        replyText:
            'Aku **Finary AI Assistant** 🤖✨\n\nAku siap bantu keuanganmu jadi lebih rapi:\n• 📝 **Catat Santai**: Ketik pengeluaran/pemasukan dengan bahasa sehari-hari.\n• 📸 **Scan Struk**: Foto struk belanja (Indomaret, resto, dll) dan AI langsung hitung rinciannya.\n• 🏷️ **Kategori Otomatis**: Transaksi langsung dikelompokkan secara pintar.\n\nYuk, coba ketik transaksimu sekarang!',
      );
    }

    // 5. Tips Keuangan
    if (lower.contains('tips') || lower.contains('hemat') || lower.contains('boros') || lower.contains('nabung') || lower.contains('uang habis')) {
      return ExtractedTransaction(
        isTransaction: false,
        replyText:
            '💡 **Tips Keuangan Cerdas dari Finary**:\n1. **Gunakan metode 50/30/20**: 50% untuk kebutuhan pokok, 30% keinginan, dan 20% tabungan/investasi.\n2. **Catat sekecil apapun pengeluaranmu**: Pengeluaran kecil seperti jajan kopi seringkali menjadi penyebab utama *bocor halus*.\n3. **Cek grafik pengeluaran di Dashboard** untuk evaluasi pos mana yang paling boros!\n\nSemangat mengelola keuanganmu! 💪',
      );
    }

    // 6. Default Fallback Ramah & Natural
    _pendingContext = null;
    return ExtractedTransaction(
      isTransaction: false,
      replyText:
          'Aku siap membantu mencatat keuanganmu! 😊\n\nKamu bisa ketik transaksimu lengkap dengan nominal, contoh:\n• *"Beli kopi 20rb"*\n• *"Makan siang 25 ribu"*\n• *"Gaji masuk 6.5jt"*\natau foto struk belanjaan kasir lewat tombol kamera di bawah 📸.',
    );
  }

  String formatRupiah(double amount) {
    return CurrencyFormatter.format(amount.toInt()).replaceAll('Rp', '');
  }

  String cleanTransactionDescription(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
