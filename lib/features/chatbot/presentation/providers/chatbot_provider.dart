import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cakeu/core/utils/date_formatter.dart';
import 'package:cakeu/features/categories/data/models/category_model.dart';
import 'package:cakeu/features/chatbot/data/models/chat_message_model.dart';
import 'package:cakeu/features/chatbot/data/repositories/chatbot_repository.dart';
import 'package:cakeu/features/chatbot/data/services/category_keyword_matcher.dart';
import 'package:cakeu/features/chatbot/data/services/local_nlp_engine.dart';
import 'package:cakeu/features/transactions/data/models/transaction_model.dart';
import 'package:cakeu/features/transactions/data/repositories/transaction_repository.dart';

class ChatbotProvider extends ChangeNotifier {
  final ChatbotRepository _chatbotRepository;
  final TransactionRepository _transactionRepository;

  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Set<String> _savedMessageIds = {};

  static const String _prefSavedKeys = 'cakeu_saved_chat_msg_ids';

  ChatbotProvider(this._chatbotRepository, this._transactionRepository) {
    _loadSavedCache();
  }

  bool _hasLoadedHistory = false;

  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _loadSavedCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefSavedKeys) ?? [];
      _savedMessageIds.addAll(list);
    } catch (_) {}
  }

  Future<void> _persistSavedId(String messageId) async {
    try {
      _savedMessageIds.add(messageId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefSavedKeys, _savedMessageIds.toList());
    } catch (_) {}
  }

  Future<void> _persistSavedCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefSavedKeys, _savedMessageIds.toList());
    } catch (_) {}
  }

  /// Sinkronisasi otomatis saat transaksi dihapus di menu Riwayat Transaksi:
  /// Mengembalikan status kartu tiket chat agar tombol "Simpan Ulang" aktif kembali
  void syncTransactionDeleted(String transactionId) {
    bool updated = false;
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].transactionId == transactionId) {
        _savedMessageIds.remove(_messages[i].id);
        // Pertahankan transactionId pada message di memori session saat ini
        // agar chat_receipt_card dapat mendeteksi wasDeletedFromHistory
        // (menampilkan badge 'Dihapus • Simpan Ulang' dan tombol 'Simpan Ulang ke Transaksi')
        updated = true;
      }
    }
    if (updated) {
      _persistSavedCache();
      notifyListeners();
    }
  }

  void clearData() {
    _messages = [];
    _hasLoadedHistory = false;
    _errorMessage = null;
    _savedMessageIds.clear();
    notifyListeners();
  }

  Future<void> clearChatHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _chatbotRepository.clearChatHistory();
      _savedMessageIds.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefSavedKeys);
      _messages = [
        ChatMessageModel(
          id: 'welcome',
          userId: '',
          role: 'assistant',
          content:
              'Halo! 👋 Saya Finary AI Assistant.\n\nKamu bisa mencatat transaksi hanya dengan mengetik bahasa santai sehari-hari atau foto struk belanjaan.\n\nContoh:\n• "Beli kopi Kenangan 15rb"\n• "Gaji masuk 5 juta"\n• Foto struk belanja / restoran',
        ),
      ];
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory({bool forceRefresh = false}) async {
    if (_hasLoadedHistory && !forceRefresh) return;

    if (forceRefresh) {
      _messages = [];
      _hasLoadedHistory = false;
    }

    _isLoading = true;
    notifyListeners();

    await _loadSavedCache();

    try {
      final history = await _chatbotRepository.getChatHistory();
      if (history.isNotEmpty) {
        _messages = history.map((m) {
          final isLocallySaved = _savedMessageIds.contains(m.id) ||
              (m.transactionId != null && m.transactionId!.isNotEmpty);
          if (isLocallySaved && !m.isSaved) {
            return m.copyWith(isSaved: true);
          }
          return m;
        }).toList();
      } else {
        _messages = [
          ChatMessageModel(
            id: 'welcome',
            userId: '',
            role: 'assistant',
            content:
                'Halo! 👋 Saya Finary AI Assistant.\n\nKamu bisa mencatat transaksi hanya dengan mengetik bahasa santai sehari-hari atau foto struk belanjaan.\n\nContoh:\n• "Beli kopi Kenangan 15rb"\n• "Gaji masuk 5 juta"\n• Foto struk belanja / restoran',
          ),
        ];
      }
      _hasLoadedHistory = true;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage({
    required String text,
    required List<CategoryModel> categories,
    List<dynamic>? wallets,
    String? base64Image,
    DateTime? selectedDate,
  }) async {
    if (text.trim().isEmpty && base64Image == null) return;

    final isCustomDate = selectedDate != null && !AppDateFormatter.isSameDay(selectedDate, DateTime.now());
    final now = DateTime.now();
    final effectiveMsgDate = isCustomDate
        ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day, now.hour, now.minute, now.second)
        : now;

    final tempUserMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '',
      role: 'user',
      content: text.isEmpty ? 'Analisis foto struk belanjaan ini' : text,
      imageBase64: base64Image,
      createdAt: effectiveMsgDate,
    );

    _messages.add(tempUserMsg);
    _isLoading = true;
    notifyListeners();

    try {
      final savedUserMsg = await _chatbotRepository.saveMessage(
        role: 'user',
        content: tempUserMsg.content,
      );
      final userIdx = _messages.indexWhere((m) => m.id == tempUserMsg.id);
      if (userIdx != -1) {
        _messages[userIdx] = savedUserMsg.copyWith(
          imageBase64: base64Image,
          createdAt: isCustomDate ? effectiveMsgDate : null,
        );
      }

      final lowerText = text.toLowerCase();
      final isFinancialInquiry = base64Image == null && (
          lowerText.contains('rincikan') ||
          lowerText.contains('apa saja') ||
          lowerText.contains('apasaja') ||
          (lowerText.contains('pemasukan') && (lowerText.contains('pengeluaran') || lowerText.contains('bulan') || lowerText.contains('hari'))) ||
          (lowerText.contains('pengeluaran') && (lowerText.contains('pemasukan') || lowerText.contains('bulan') || lowerText.contains('hari'))) ||
          lowerText.contains('rekap') ||
          lowerText.contains('laporan') ||
          lowerText.contains('bagaimana jika bulan') ||
          lowerText.contains('gimana kalau bulan') ||
          lowerText.contains('kalo bulan') ||
          lowerText.contains('kalau bulan'));

      // Kirim hingga 8 riwayat pesan sebelumnya agar percakapan bisa bersambung alami (multi-turn memory)
      // Exclude pesan saat ini agar tidak terduplikasi di prompt AI
      final previousMessages = _messages
          .where((m) => m.id != tempUserMsg.id && m.id != savedUserMsg.id && m.id != 'welcome')
          .toList();

      final historyContext = previousMessages.reversed.take(8).toList().reversed.map((m) {
        String msgContent = m.content;
        if (m.isAssistant && m.extractedData != null && (m.extractedData!.isTransaction || m.extractedData!.isReceipt)) {
          final ed = m.extractedData!;
          final itemsSummary = ed.items?.map((i) => '${i.name} (${i.qty}x: Rp${i.price?.toInt() ?? 0})').join(', ') ?? '';
          final groupsSummary = ed.groups?.map((g) => '${g.categoryName} [${g.type}]: Rp${g.totalAmount.toInt()} (${g.items.map((i) => i.name).join(', ')})').join(' | ') ?? '';
          msgContent += ' [Data Draf Transaksi: Toko=${ed.description ?? '-'}, Total=Rp${ed.amount?.toInt() ?? 0}, Tipe=${ed.type ?? 'expense'}, Kategori=${ed.categoryName ?? '-'}, Subtotal=Rp${ed.subtotal?.toInt() ?? 0}, BayarTunai=Rp${ed.paidAmount?.toInt() ?? 0}, Kembali=Rp${ed.changeAmount?.toInt() ?? 0}, Status=${m.isSaved ? 'Sudah Disimpan' : 'Belum Disimpan'}${itemsSummary.isNotEmpty ? ', Items=$itemsSummary' : ''}${groupsSummary.isNotEmpty ? ', Groups=$groupsSummary' : ''}]';
        }
        return {
          'role': m.role,
          'content': msgContent,
        };
      }).toList();

      List<TransactionModel>? recentTxs;
      try {
        recentTxs = await _transactionRepository.getTransactions();
      } catch (_) {}

      final extracted = await _chatbotRepository.parseMessageWithAI(
        message: text.isEmpty ? 'Analisis dan ekstrak rincian struk belanja ini' : text,
        categories: categories,
        wallets: wallets,
        recentTransactions: recentTxs,
        base64Image: base64Image,
        historyContext: historyContext,
      );

      var finalExtracted = extracted;

      final detectedDate = LocalNlpEngine.extractRelativeDate(text);
      if (detectedDate != null) {
        finalExtracted = finalExtracted.copyWith(transactionDate: detectedDate);
      } else if (isCustomDate) {
        finalExtracted = finalExtracted.copyWith(transactionDate: selectedDate);
      } else if (extracted.transactionDate != null) {
        finalExtracted = finalExtracted.copyWith(transactionDate: extracted.transactionDate);
      } else {
        // Jika tidak ada tanggal khusus disebut user atau AI, gunakan waktu saat ini
        finalExtracted = finalExtracted.copyWith(transactionDate: DateTime.now());
      }

      // Smart Fallback: jika pertanyaan finansial tapi AI error / kosong / bilang 0 padahal di recentTxs ada transaksi
      if (isFinancialInquiry &&
          !finalExtracted.isTransaction &&
          (finalExtracted.replyText.isEmpty ||
           finalExtracted.replyText.toLowerCase().contains('gagal') ||
           (recentTxs != null && recentTxs.isNotEmpty && finalExtracted.replyText.toLowerCase().contains('belum ada transaksi')))) {
        final localReply = _buildLocalFinancialReply(text, recentTxs ?? [], wallets);
        finalExtracted = finalExtracted.copyWith(replyText: localReply);
      }

      final savedBotMsg = await _chatbotRepository.saveMessage(
        role: 'assistant',
        content: finalExtracted.replyText,
        extractedData: finalExtracted,
      );

      _messages.add(savedBotMsg.copyWith(
        createdAt: isCustomDate ? effectiveMsgDate : null,
      ));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _messages.add(
        ChatMessageModel(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          userId: '',
          role: 'assistant',
          content: 'Maaf, terjadi kesalahan saat memproses pesan: ${e.toString()}',
          createdAt: isCustomDate ? effectiveMsgDate : null,
        ),
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<TransactionModel>?> confirmAndSaveTransaction({
    required ChatMessageModel message,
    required List<CategoryModel> categories,
    String? walletId,
    List<dynamic>? wallets,
  }) async {
    final data = message.extractedData;
    if (data == null || !data.isTransaction || data.amount == null) {
      return null;
    }

    final index = _messages.indexWhere((m) => m.id == message.id);

    try {
      // Helper untuk mencocokkan ID kategori secara aman & akurat via CategoryKeywordMatcher
      String? getSafeCategoryId(String? catName, String type) {
        if (categories.isEmpty) return null;
        if (catName != null && catName.isNotEmpty) {
          final target = catName.toLowerCase().trim();

          // 1. Direct Exact Match
          final directMatch = categories.where((c) => c.name.toLowerCase() == target);
          if (directMatch.isNotEmpty) return directMatch.first.id;

          // 2. Partial Contains Match
          final partialMatch = categories.where((c) =>
              c.name.toLowerCase().contains(target) ||
              target.contains(c.name.toLowerCase()));
          if (partialMatch.isNotEmpty) return partialMatch.first.id;

          // 3. Centralized Keyword Matcher
          final detectedName = CategoryKeywordMatcher.detect(catName).toLowerCase();
          final keywordMatch = categories.where((c) =>
              c.name.toLowerCase() == detectedName ||
              c.name.toLowerCase().contains(detectedName) ||
              detectedName.contains(c.name.toLowerCase()));
          if (keywordMatch.isNotEmpty) return keywordMatch.first.id;
        }

        // Fallback: Cocokkan tipe yang sama (expense / income)
        final typeMatch = categories.where((c) => c.type == type);
        if (typeMatch.isNotEmpty) {
          final nonOther = typeMatch.where((c) => !c.name.toLowerCase().contains('lain'));
          if (nonOther.isNotEmpty) return nonOther.first.id;
          return typeMatch.first.id;
        }
        return categories.first.id;
      }

      final effectiveDate = data.transactionDate ?? DateTime.now();
      final effectiveWalletId = walletId ?? data.walletId;

      // 1. Multi-Kategori (Groups) — Simpan sekaligus dalam 1 batch network call
      if (data.groups != null && data.groups!.length > 1) {
        final batchItems = data.groups!.map((grp) {
          final categoryId = getSafeCategoryId(grp.categoryName, grp.type);

          String grpDesc = grp.description.isNotEmpty ? grp.description : grp.categoryName;
          if (grp.items.isNotEmpty) {
            final itemsStr = grp.items.map((i) => i.toString()).join(', ');
            if (!grpDesc.contains(grp.items.first.name)) {
              grpDesc = '$grpDesc ($itemsStr)';
            }
          }

          // Split payment: setiap group bisa punya dompet berbeda
          final grpWalletId = _resolveWalletId(grp.walletName, wallets) ?? grp.walletId ?? effectiveWalletId;

          return {
            'type': grp.type,
            'amount': grp.totalAmount,
            'category_id': categoryId,
            ...?grpWalletId == null ? null : {'wallet_id': grpWalletId},
            'description': grpDesc,
            'transaction_date': effectiveDate,
            'source': 'ai_chat',
          };
        }).toList();

        final savedTxs = await _transactionRepository.addTransactionsBatch(batchItems);
        final lastTxId = savedTxs.isNotEmpty ? savedTxs.last.id : '';

        // Simpan ke cache lokal & tandai tersimpan di UI
        await _persistSavedId(message.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            isSaved: true,
            transactionId: lastTxId,
          );
          notifyListeners();
        }

        if (lastTxId.isNotEmpty) {
          await _chatbotRepository.updateMessageTransactionId(message.id, lastTxId);
        }
        return savedTxs;
      }

      // 2. Single Transaction flow
      final categoryId = getSafeCategoryId(data.categoryName, data.type ?? 'expense');

      String fullDescription = data.description ?? 'Transaksi via AI Chat';
      if (data.items != null && data.items!.isNotEmpty) {
        final itemsStr = data.items!.map((i) => i.toString()).join(', ');
        if (!fullDescription.contains(data.items!.first.name)) {
          fullDescription = '$fullDescription ($itemsStr)';
        }
      }

      final savedTx = await _transactionRepository.addTransaction(
        type: data.type ?? 'expense',
        amount: data.amount!,
        categoryId: categoryId,
        walletId: effectiveWalletId,
        description: fullDescription,
        transactionDate: effectiveDate,
        source: 'ai_chat',
      );

      // Simpan ke cache lokal & tandai tersimpan di UI
      await _persistSavedId(message.id);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          isSaved: true,
          transactionId: savedTx.id,
        );
        notifyListeners();
      }

      await _chatbotRepository.updateMessageTransactionId(message.id, savedTx.id);
      return [savedTx];
    } catch (e) {
      _errorMessage = 'Gagal menyimpan transaksi: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // ====================================================================
  // CLIENT-SIDE FINANCIAL REPORT (100% database, 0% hallucination)
  // ====================================================================

  /// Resolve wallet_name dari AI ke wallet_id berdasarkan daftar dompet user
  String? _resolveWalletId(String? walletName, List<dynamic>? wallets) {
    if (walletName == null || walletName.isEmpty || wallets == null || wallets.isEmpty) return null;
    final target = walletName.toLowerCase();

    // 1. Exact name match
    for (final w in wallets) {
      final name = (w is Map<String, dynamic>) ? (w['name'] as String? ?? '') : (w.name as String? ?? '');
      if (name.toLowerCase() == target) {
        return (w is Map<String, dynamic>) ? w['id'] as String? : w.id as String?;
      }
    }

    // 2. Partial/contains match
    for (final w in wallets) {
      final name = (w is Map<String, dynamic>) ? (w['name'] as String? ?? '') : (w.name as String? ?? '');
      if (name.toLowerCase().contains(target) || target.contains(name.toLowerCase())) {
        return (w is Map<String, dynamic>) ? w['id'] as String? : w.id as String?;
      }
    }

    // 3. Type-based match (cash/bank/ewallet keywords)
    String? targetType;
    if (target.contains('tunai') || target.contains('cash') || target.contains('dompet')) {
      targetType = 'cash';
    } else if (target.contains('bank') || target.contains('rekening') || target.contains('qris') || target.contains('debit')) {
      targetType = 'bank';
    } else if (target.contains('e-wallet') || target.contains('ewallet') || target.contains('gopay') || target.contains('ovo') || target.contains('dana') || target.contains('shopeepay')) {
      targetType = 'ewallet';
    }

    if (targetType != null) {
      for (final w in wallets) {
        final wType = (w is Map<String, dynamic>) ? (w['type'] as String? ?? '') : (w.type as String? ?? '');
        if (wType.toLowerCase() == targetType) {
          return (w is Map<String, dynamic>) ? w['id'] as String? : w.id as String?;
        }
      }
    }

    return null;
  }

  /// Deteksi bulan-bulan & tahun dari teks input pengguna (bisa multi-bulan)
  List<({int month, int year})> _detectMonths(String text) {
    final lower = text.toLowerCase();
    final now = DateTime.now();
    const monthNames = {
      'januari': 1, 'februari': 2, 'maret': 3, 'april': 4,
      'mei': 5, 'juni': 6, 'juli': 7, 'agustus': 8,
      'september': 9, 'oktober': 10, 'november': 11, 'desember': 12,
    };

    // Deteksi tahun jika ada angka 4 digit
    final yearRegex = RegExp(r'(\d{4})');
    final yearMatch = yearRegex.firstMatch(text);
    final year = yearMatch != null ? int.parse(yearMatch.group(1)!) : now.year;

    final matched = <({int month, int year})>[];

    // Deteksi kombinasi "bulan lalu" & "bulan ini"
    if ((lower.contains('bulan lalu') || lower.contains('bln lalu')) &&
        (lower.contains('bulan ini') || lower.contains('bln ini') || lower.contains('sekarang'))) {
      final prev = DateTime(now.year, now.month - 1, 1);
      return [(month: prev.month, year: prev.year), (month: now.month, year: now.year)];
    }

    // Deteksi dari awal tahun s/d bulan sekarang ("awal tahun sampai sekarang", "awal bulan tahun ini sampe bulan sekarang")
    if (lower.contains('awal tahun') ||
        lower.contains('awal bulan tahun ini') ||
        lower.contains('dari awal tahun') ||
        (lower.contains('tahun ini') && (lower.contains('sekarang') || lower.contains('sampe') || lower.contains('sampai'))) ||
        (lower.contains('awal bulan') && (lower.contains('sekarang') || lower.contains('sampe') || lower.contains('sampai')))) {
      return List.generate(now.month, (i) => (month: i + 1, year: year));
    }

    // Deteksi nama-nama bulan spesifik
    for (final entry in monthNames.entries) {
      if (lower.contains(entry.key)) {
        matched.add((month: entry.value, year: year));
      }
    }

    if (matched.isNotEmpty) {
      // Urutkan kronologis
      matched.sort((a, b) => a.month.compareTo(b.month));
      return matched;
    }

    // "bulan lalu"
    if (lower.contains('bulan lalu') || lower.contains('bln lalu')) {
      final prev = DateTime(now.year, now.month - 1, 1);
      return [(month: prev.month, year: prev.year)];
    }

    // Default: bulan ini
    return [(month: now.month, year: now.year)];
  }

  String _formatRp(double amount) {
    final intVal = amount.toInt();
    final str = intVal.toString();
    final result = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) result.write('.');
      result.write(str[i]);
    }
    return result.toString();
  }

  String _buildLocalFinancialReply(
    String query,
    List<TransactionModel> allTxs,
    List<dynamic>? wallets,
  ) {
    const monthLabels = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];

    final detectedMonths = _detectMonths(query);

    // Filter transaksi non-transfer
    final validTxs = allTxs.where((t) => t.type != 'transfer').toList();

    // 1. Kasus Multi-Bulan (misal: "bulan agustus sama september", "juli, agustus, september")
    if (detectedMonths.length > 1) {
      final buf = StringBuffer();
      final monthNamesStr = detectedMonths.map((m) => monthLabels[m.month]).join(', ');
      buf.writeln('Berikut perbandingan pengeluaran dan pemasukanmu untuk bulan **$monthNamesStr** 📊\n');

      double grandIncome = 0;
      double grandExpense = 0;

      for (final m in detectedMonths) {
        final mLabel = monthLabels[m.month];
        final mYear = m.year;
        final mTxs = validTxs.where((t) => t.transactionDate.month == m.month && t.transactionDate.year == mYear).toList();

        final incTxs = mTxs.where((t) => t.type == 'income').toList();
        final expTxs = mTxs.where((t) => t.type == 'expense').toList();
        final mInc = incTxs.fold<double>(0, (s, t) => s + t.amount);
        final mExp = expTxs.fold<double>(0, (s, t) => s + t.amount);
        final mBal = mInc - mExp;

        grandIncome += mInc;
        grandExpense += mExp;

        buf.writeln('📅 **Bulan $mLabel $mYear**:');
        if (mTxs.isEmpty) {
          buf.writeln('  • *Belum ada catatan transaksi (Rp0)*\n');
        } else {
          buf.writeln('  • 💰 Pemasukan: **Rp${_formatRp(mInc)}** (${incTxs.length} transaksi)');
          buf.writeln('  • 🛒 Pengeluaran: **Rp${_formatRp(mExp)}** (${expTxs.length} transaksi)');
          final sign = mBal >= 0 ? '+' : '-';
          buf.writeln('  • 📈 Saldo Bersih: **${sign}Rp${_formatRp(mBal.abs())}**\n');
        }
      }

      final grandBal = grandIncome - grandExpense;
      final grandSign = grandBal >= 0 ? '+' : '-';
      buf.writeln('📌 **Total Seluruh Periode Tersebut**:');
      buf.writeln('• Total Pemasukan: **Rp${_formatRp(grandIncome)}**');
      buf.writeln('• Total Pengeluaran: **Rp${_formatRp(grandExpense)}**');
      buf.writeln('• Saldo Bersih: **${grandSign}Rp${_formatRp(grandBal.abs())}**');
      buf.writeln('\nAda yang ingin kamu tanyakan lebih detail tentang transaksi di atas? 😊✨');
      return buf.toString().trim();
    }

    // 2. Kasus Single Month / Hari Ini
    final target = detectedMonths.first;
    final month = target.month;
    final year = target.year;
    final monthLabel = monthLabels[month];

    final periodTxs = validTxs.where((t) {
      final d = t.transactionDate;
      return d.month == month && d.year == year;
    }).toList();

    final lower = query.toLowerCase();
    final isToday = lower.contains('hari ini');
    final todayDate = DateTime.now();

    List<TransactionModel> displayTxs;
    String periodText;
    if (isToday) {
      displayTxs = periodTxs.where((t) {
        final d = t.transactionDate;
        return d.year == todayDate.year && d.month == todayDate.month && d.day == todayDate.day;
      }).toList();
      periodText = 'hari ini (${todayDate.day} $monthLabel $year)';
    } else {
      displayTxs = periodTxs;
      periodText = 'bulan **$monthLabel $year**';
    }

    if (displayTxs.isEmpty) {
      // Periksa apakah user memiliki transaksi di bulan lain
      final otherMonthsMap = <String, ({double inc, double exp})>{};
      for (final t in validTxs) {
        final l = '${monthLabels[t.transactionDate.month]} ${t.transactionDate.year}';
        final prev = otherMonthsMap[l] ?? (inc: 0.0, exp: 0.0);
        if (t.type == 'income') {
          otherMonthsMap[l] = (inc: prev.inc + t.amount, exp: prev.exp);
        } else {
          otherMonthsMap[l] = (inc: prev.inc, exp: prev.exp + t.amount);
        }
      }

      if (otherMonthsMap.isNotEmpty) {
        final otherBuf = StringBuffer();
        otherBuf.writeln('Pada $periodText, kamu belum memiliki catatan pengeluaran maupun pemasukan yang tersimpan (Rp0).\n');
        otherBuf.writeln('Namun, kamu memiliki catatan transaksi aktif pada periode lain:');
        for (final entry in otherMonthsMap.entries) {
          otherBuf.writeln('• **Bulan ${entry.key}**: Pemasukan Rp${_formatRp(entry.value.inc)} | Pengeluaran Rp${_formatRp(entry.value.exp)}');
        }
        otherBuf.writeln('\nKamu bisa tanyakan rincian bulan tersebut, atau ketik transaksi baru untuk $periodText ya! 💪✨');
        return otherBuf.toString().trim();
      }

      return 'Pada $periodText, kamu belum memiliki catatan pengeluaran maupun pemasukan yang tersimpan (Rp0). '
          'Jika kamu ingin mulai mencatat, cukup ketik seperti *"beli makan 25rb"* atau *"gaji masuk 3jt"* dan aku langsung bantu catat! 💪✨';
    }

    // Hitung total income & expense
    final incTxs = displayTxs.where((t) => t.type == 'income').toList();
    final expTxs = displayTxs.where((t) => t.type == 'expense').toList();

    final totalIncome = incTxs.fold<double>(0, (s, t) => s + t.amount);
    final totalExpense = expTxs.fold<double>(0, (s, t) => s + t.amount);
    final netBalance = totalIncome - totalExpense;

    final buf = StringBuffer();
    buf.writeln('Ini dia rincian keuanganmu pada $periodText 📊\n');

    // --- Pemasukan ---
    buf.writeln('💰 **Total Pemasukan: Rp${_formatRp(totalIncome)}** (${incTxs.length} transaksi)');
    if (incTxs.isNotEmpty) {
      final incCats = <String, double>{};
      for (final t in incTxs) {
        final cat = t.category?.name ?? 'Pemasukan Lain';
        incCats[cat] = (incCats[cat] ?? 0) + t.amount;
      }
      for (final entry in incCats.entries) {
        buf.writeln('  • **${entry.key}**: Rp${_formatRp(entry.value)}');
      }
    }
    buf.writeln();

    // --- Pengeluaran ---
    buf.writeln('🛒 **Total Pengeluaran: Rp${_formatRp(totalExpense)}** (${expTxs.length} transaksi)');
    if (expTxs.isNotEmpty) {
      final expCats = <String, double>{};
      for (final t in expTxs) {
        final cat = t.category?.name ?? 'Lainnya';
        expCats[cat] = (expCats[cat] ?? 0) + t.amount;
      }
      final sorted = expCats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sorted) {
        final pct = totalExpense > 0 ? (entry.value / totalExpense * 100).round() : 0;
        buf.writeln('  • **${entry.key}**: Rp${_formatRp(entry.value)} ($pct%)');
      }
    }
    buf.writeln();

    // --- Saldo Bersih ---
    final sign = netBalance >= 0 ? '+' : '-';
    buf.writeln('📈 **Saldo Bersih Periode Ini**: ${sign}Rp${_formatRp(netBalance.abs())}');

    // --- Daftar transaksi ---
    if (displayTxs.length <= 15) {
      buf.writeln();
      buf.writeln('📋 **Daftar Transaksi:**');
      final sortedTxs = [...displayTxs]..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
      for (final t in sortedTxs) {
        final icon = t.type == 'income' ? '🟢' : '🔴';
        final cat = t.category?.name ?? '';
        final desc = t.description ?? '';
        final dateStr = '${t.transactionDate.day} $monthLabel';
        buf.writeln('  $icon $dateStr — **${desc.isNotEmpty ? desc : cat}** — Rp${_formatRp(t.amount)} ($cat)');
      }
    }

    buf.writeln();
    buf.writeln('Ada yang ingin kamu tanyakan lagi tentang keuanganmu? 😊✨');

    return buf.toString().trim();
  }
}
