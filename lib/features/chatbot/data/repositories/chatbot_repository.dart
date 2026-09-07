import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cakeu/core/services/supabase_service.dart';
import 'package:cakeu/features/categories/data/models/category_model.dart';
import 'package:cakeu/features/transactions/data/models/transaction_model.dart';
import 'package:cakeu/features/chatbot/data/models/chat_message_model.dart';
import 'package:cakeu/features/chatbot/data/services/local_nlp_engine.dart';

class ChatbotRepository {
  SupabaseClient get _client => SupabaseService.client;
  final LocalNlpEngine _nlpEngine = LocalNlpEngine();

  Future<List<ChatMessageModel>> getChatHistory({int limit = 300}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // Ambil N pesan TERBARU dengan order created_at DESCENDING
    // agar chat terbaru tidak terpotong saat total riwayat melebihi limit.
    final response = await _client
        .from('chat_messages')
        .select('id, user_id, role, content, raw_extracted_data, transaction_id, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    final list = (response as List<dynamic>)
        .map((json) => ChatMessageModel.fromJson(json as Map<String, dynamic>))
        .toList();

    // Balik urutannya agar tampil secara kronologis (dari yang terlama ke terbaru)
    return list.reversed.toList();
  }

  Future<void> clearChatHistory() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('chat_messages')
        .delete()
        .eq('user_id', user.id);
  }

  Future<ChatMessageModel> saveMessage({
    required String role,
    required String content,
    ExtractedTransaction? extractedData,
    String? transactionId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User belum login');

    final response = await _client
        .from('chat_messages')
        .insert({
          'user_id': user.id,
          'role': role,
          'content': content,
          if (extractedData != null) 'raw_extracted_data': extractedData.toJson(),
          ...?transactionId == null ? null : {'transaction_id': transactionId},
        })
        .select()
        .single();

    return ChatMessageModel.fromJson(response);
  }

  Future<void> updateMessageTransactionId(
    String messageId,
    String transactionId,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client
          .from('chat_messages')
          .update({'transaction_id': transactionId})
          .eq('id', messageId)
          .eq('user_id', user.id);
    } catch (_) {}
  }

  Future<ExtractedTransaction> parseMessageWithAI({
    required String message,
    required List<CategoryModel> categories,
    List<dynamic>? wallets,
    List<TransactionModel>? recentTransactions,
    String? base64Image,
    List<Map<String, String>>? historyContext,
  }) async {
    // 0. Sapaan instan lokal (0 milidetik - tanpa loading / network lag)
    if (base64Image == null) {
      final instant = _nlpEngine.checkInstantGreeting(message);
      if (instant != null) return instant;
    }

    final formattedWallets = wallets?.map((w) {
      if (w is Map<String, dynamic>) return w;
      return {
        'id': w.id,
        'name': w.name,
        'type': w.type,
        'is_default': w.isDefault,
        'current_balance': w.currentBalance,
        'initial_balance': w.initialBalance,
      };
    }).toList();

    final formattedTransactions = recentTransactions?.take(50).map((t) {
      return {
        'id': t.id,
        'type': t.type,
        'amount': t.amount,
        'category_name': t.category?.name ?? 'Lainnya',
        'wallet_name': t.wallet?.name ?? 'Tunai',
        'description': t.description ?? '',
        'transaction_date': t.transactionDate.toIso8601String(),
      };
    }).toList();

    // 1. Jika ada gambar/struk, kirim ke Supabase Edge Function AI Vision
    if (base64Image != null) {
      try {
        final response = await _client.functions.invoke(
          'ai-chat',
          body: {
            'message': message,
            'categories': categories
                .map((c) => {'name': c.name, 'type': c.type})
                .toList(),
            ...?formattedWallets == null ? null : {'wallets': formattedWallets},
            ...?formattedTransactions == null ? null : {'recent_transactions': formattedTransactions},
            'image': base64Image,
            ...?historyContext == null ? null : {'history': historyContext},
          },
        );

        if (response.status == 200 && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          final result = ExtractedTransaction.fromJson(data);
          if (result.isTransaction && (result.amount ?? 0) > 0) {
            final reply =
                result.replyText.isNotEmpty &&
                    !result.replyText.toLowerCase().contains('pesan diproses')
                ? result.replyText
                : 'Struk belanja berhasil dianalisis! Total sebesar **Rp${result.amount!.toInt()}**. Silakan periksa rincian di bawah dan tap Simpan.';
            return ExtractedTransaction(
              isTransaction: true,
              isReceipt: true,
              type: result.type ?? 'expense',
              amount: result.amount,
              subtotal: result.subtotal,
              discount: result.discount,
              tax: result.tax,
              paidAmount: result.paidAmount,
              changeAmount: result.changeAmount,
              paymentMethod: result.paymentMethod,
              items: result.items,
              groups: null, // Struk adalah 1 kesatuan transaksi, jangan dipecah ke multi-grup!
              categoryName: result.categoryName ?? 'Makan & Minum',
              description: result.description ?? 'Belanja via Scan Struk',
              walletId: result.walletId,
              walletName: result.walletName,
              transactionDate: result.transactionDate,
              replyText: reply,
            );
          }
        }
        return ExtractedTransaction(
          isTransaction: false,
          isReceipt: false,
          replyText: 'Maaf, struk tidak terbaca dengan jelas. Pastikan foto struk terlihat tegak, fokus, dan tidak terpotong, lalu coba lagi ya! 📸',
        );
      } catch (e) {
        return ExtractedTransaction(
          isTransaction: false,
          isReceipt: false,
          replyText: 'Gagal menganalisis struk: Pastikan Edge Function Supabase dan OPENAIAPI sudah terpasang dengan benar.',
        );
      }
    }

    // 2. Coba kirim teks ke Edge Function jika tersedia
    try {
      final response = await _client.functions.invoke(
        'ai-chat',
        body: {
          'message': message,
          'categories': categories
              .map((c) => {'name': c.name, 'type': c.type})
              .toList(),
          ...?formattedWallets == null ? null : {'wallets': formattedWallets},
          ...?formattedTransactions == null ? null : {'recent_transactions': formattedTransactions},
          ...?historyContext == null ? null : {'history': historyContext},
        },
      );

      if (response.status == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final result = ExtractedTransaction.fromJson(data);

        // Jika respons valid, bukan 'pesan diproses', dan punya makna yang jelas
        if (result.replyText.isNotEmpty &&
            !result.replyText.toLowerCase().contains('pesan diproses') &&
            (result.isTransaction || result.replyText.length > 10)) {
          // Cek jika ada banyak items, lakukan auto-group per kategori
          List<TransactionGroup>? groups = result.groups;
          if ((groups == null || groups.isEmpty) &&
              result.items != null &&
              result.items!.length > 1) {
            groups = _nlpEngine.groupItemsByCategory(result.items!);
          }

          final totalAmount =
              result.amount ??
              (groups != null && groups.isNotEmpty
                  ? groups.fold<double>(0.0, (sum, g) => sum + g.totalAmount)
                  : result.items?.fold<double>(
                      0.0,
                      (sum, i) => sum + (i.price ?? 0.0),
                    ));

          final isTx =
              (totalAmount != null && totalAmount > 0) || result.isTransaction;

          // Naturalize kata-kata kaku seperti "Saya mendeteksi..."
          String naturalReply = _nlpEngine.naturalizeReplyText(
            result.replyText,
            totalAmount,
            result.categoryName,
            result.description,
          );

          if (groups != null && groups.length > 1) {
            final formattedTotal = _nlpEngine.formatRupiah(totalAmount ?? 0);
            naturalReply =
                'Sip, udah aku pilah ke ${groups.length} kategori (total **Rp$formattedTotal**)! Cek ringkasan di bawah dan tap Simpan Semua ya! ✨';
          }

          final detectedDate = result.transactionDate ?? LocalNlpEngine.extractRelativeDate(message);

          return ExtractedTransaction(
            isTransaction: isTx,
            isReceipt: false, // Text message bukan struk kasir fisik!
            type: result.type ?? 'expense',
            amount: totalAmount,
            subtotal: null,
            discount: null,
            tax: null,
            paidAmount: null,
            changeAmount: null,
            paymentMethod: result.paymentMethod,
            items: result.items,
            groups: groups,
            categoryName: result.categoryName ?? 'Makan & Minum',
            description: result.description ?? message,
            walletId: result.walletId,
            walletName: result.walletName,
            transactionDate: detectedDate,
            replyText: naturalReply,
          );
        }
      }
    } catch (_) {
      // Lanjut ke Natural NLP engine lokal jika function error/offline
    }

    // 3. Natural NLP & Conversational AI Engine Lokal
    return _nlpEngine.parseText(message, categories);
  }
}
