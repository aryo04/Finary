import 'dart:convert';
import 'dart:typed_data';

class ReceiptItem {
  final String name;
  final int qty;
  final double? unitPrice;
  final double? price;

  ReceiptItem({
    required this.name,
    this.qty = 1,
    this.unitPrice,
    this.price,
  });

  factory ReceiptItem.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final qty = (json['qty'] is num) ? (json['qty'] as num).toInt() : 1;
      final price = (json['price'] is num) ? (json['price'] as num).toDouble() : null;
      final unitPrice = (json['unit_price'] is num)
          ? (json['unit_price'] as num).toDouble()
          : (price != null && qty > 1 ? price / qty : price);

      return ReceiptItem(
        name: json['name'] as String? ?? 'Barang',
        qty: qty,
        unitPrice: unitPrice,
        price: price,
      );
    } else if (json is String) {
      return ReceiptItem(name: json);
    }
    return ReceiptItem(name: json.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'qty': qty,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (price != null) 'price': price,
    };
  }

  @override
  String toString() {
    if (price != null) {
      return '$name ${qty > 1 ? "($qty x)" : ""}: Rp${price!.toInt()}';
    }
    return '$name ${qty > 1 ? "($qty x)" : ""}';
  }
}

class TransactionGroup {
  final String categoryName;
  final String type; // 'expense' or 'income'
  final double totalAmount;
  final List<ReceiptItem> items;
  final String description;
  final String? walletId;
  final String? walletName;

  TransactionGroup({
    required this.categoryName,
    this.type = 'expense',
    required this.totalAmount,
    required this.items,
    required this.description,
    this.walletId,
    this.walletName,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  factory TransactionGroup.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      List<ReceiptItem> parsedItems = [];
      if (json['items'] != null && json['items'] is List) {
        parsedItems = (json['items'] as List)
            .map((e) => ReceiptItem.fromJson(e))
            .toList();
      }
      return TransactionGroup(
        categoryName: json['category_name'] as String? ?? 'Belanja',
        type: json['type'] as String? ?? 'expense',
        totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : 0.0,
        items: parsedItems,
        description: json['description'] as String? ?? '',
        walletId: json['wallet_id'] as String?,
        walletName: json['wallet_name'] as String?,
      );
    }
    return TransactionGroup(
      categoryName: 'Belanja',
      totalAmount: 0.0,
      items: [],
      description: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_name': categoryName,
      'type': type,
      'total_amount': totalAmount,
      'items': items.map((e) => e.toJson()).toList(),
      'description': description,
      if (walletId != null) 'wallet_id': walletId,
      if (walletName != null) 'wallet_name': walletName,
    };
  }

  TransactionGroup copyWith({
    String? categoryName,
    String? type,
    double? totalAmount,
    List<ReceiptItem>? items,
    String? description,
    String? walletId,
    String? walletName,
  }) {
    return TransactionGroup(
      categoryName: categoryName ?? this.categoryName,
      type: type ?? this.type,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
      description: description ?? this.description,
      walletId: walletId ?? this.walletId,
      walletName: walletName ?? this.walletName,
    );
  }
}

class ExtractedTransaction {
  final bool isTransaction;
  final bool isReceipt; // Menandakan apakah ini dari foto struk belanja
  final String? type; // 'expense' or 'income'
  final double? amount;
  final double? subtotal;
  final double? discount;
  final double? tax;
  final double? paidAmount; // Uang yang dibayarkan / tunai
  final double? changeAmount; // Uang kembalian
  final String? paymentMethod; // Tunai, QRIS, Debit, dll
  final List<ReceiptItem>? items;
  final List<TransactionGroup>? groups; // Multi-kategori grouping
  final String? categoryName;
  final String? description;
  final String? walletId;
  final String? walletName;
  final DateTime? transactionDate; // Tanggal transaksi (bisa kemarin / spesifik)
  final String replyText;

  ExtractedTransaction({
    required this.isTransaction,
    this.isReceipt = false,
    this.type,
    this.amount,
    this.subtotal,
    this.discount,
    this.tax,
    this.paidAmount,
    this.changeAmount,
    this.paymentMethod,
    this.items,
    this.groups,
    this.categoryName,
    this.description,
    this.walletId,
    this.walletName,
    this.transactionDate,
    required this.replyText,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  factory ExtractedTransaction.fromJson(Map<String, dynamic> json) {
    List<ReceiptItem>? parsedItems;
    if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((e) => ReceiptItem.fromJson(e))
          .toList();
    }

    List<TransactionGroup>? parsedGroups;
    if (json['groups'] != null && json['groups'] is List) {
      parsedGroups = (json['groups'] as List)
          .map((e) => TransactionGroup.fromJson(e))
          .toList();
    }

    double? rawAmount = (json['amount'] is num) ? (json['amount'] as num).toDouble() : null;
    final isReceiptVal = json['is_receipt'] as bool? ?? false;
    final subtotalVal = (json['subtotal'] is num) ? (json['subtotal'] as num).toDouble() : null;
    final discountVal = (json['discount'] is num) ? (json['discount'] as num).toDouble() : null;
    final taxVal = (json['tax'] is num) ? (json['tax'] as num).toDouble() : null;
    final paidAmountVal = (json['paid_amount'] is num) ? (json['paid_amount'] as num).toDouble() : null;
    final changeAmountVal = (json['change_amount'] is num) ? (json['change_amount'] as num).toDouble() : null;

    // Normalisasi defensif struk kasir: koreksi jika amount keliru mengambil uang tunai diserahkan
    if (isReceiptVal && paidAmountVal != null && changeAmountVal != null && changeAmountVal > 0) {
      final netPaid = paidAmountVal - changeAmountVal;
      if (rawAmount == paidAmountVal || (subtotalVal != null && netPaid == subtotalVal)) {
        rawAmount = netPaid;
      }
    } else if (isReceiptVal && subtotalVal != null && subtotalVal > 0 && rawAmount == paidAmountVal) {
      final calculated = subtotalVal + (taxVal ?? 0) - (discountVal ?? 0);
      if (calculated > 0) {
        rawAmount = calculated;
      }
    }

    // Hitung otomatis amount jika kosong namun items / groups ada
    if ((rawAmount == null || rawAmount <= 0) && parsedGroups != null && parsedGroups.isNotEmpty) {
      rawAmount = parsedGroups.fold<double>(0.0, (sum, g) => sum + g.totalAmount);
    }
    if ((rawAmount == null || rawAmount <= 0) && parsedItems != null && parsedItems.isNotEmpty) {
      rawAmount = parsedItems.fold<double>(0.0, (sum, i) => sum + (i.price ?? 0.0));
    }

    DateTime? txDate;
    if (json['transaction_date'] != null) {
      try {
        txDate = DateTime.parse(json['transaction_date'] as String).toLocal();
      } catch (_) {}
    }

    final hasValidAmount = rawAmount != null && rawAmount > 0;
    final rawIsTx = json['is_transaction'] as bool? ?? false;
    final isTx = rawIsTx || (hasValidAmount && ((parsedGroups != null && parsedGroups.isNotEmpty) || (parsedItems != null && parsedItems.isNotEmpty)));

    return ExtractedTransaction(
      isTransaction: isTx && hasValidAmount,
      isReceipt: isReceiptVal,
      type: json['type'] as String?,
      amount: hasValidAmount ? rawAmount : null,
      subtotal: subtotalVal,
      discount: discountVal,
      tax: taxVal,
      paidAmount: paidAmountVal,
      changeAmount: changeAmountVal,
      paymentMethod: json['payment_method'] as String?,
      items: parsedItems,
      groups: parsedGroups,
      categoryName: json['category_name'] as String?,
      description: json['description'] as String?,
      walletId: json['wallet_id'] as String?,
      walletName: json['wallet_name'] as String?,
      transactionDate: txDate,
      replyText: json['reply_text'] as String? ?? '',
    );
  }

  ExtractedTransaction copyWith({
    bool? isTransaction,
    bool? isReceipt,
    String? type,
    double? amount,
    double? subtotal,
    double? discount,
    double? tax,
    double? paidAmount,
    double? changeAmount,
    String? paymentMethod,
    List<ReceiptItem>? items,
    List<TransactionGroup>? groups,
    String? categoryName,
    String? description,
    String? walletId,
    String? walletName,
    DateTime? transactionDate,
    String? replyText,
  }) {
    return ExtractedTransaction(
      isTransaction: isTransaction ?? this.isTransaction,
      isReceipt: isReceipt ?? this.isReceipt,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      paidAmount: paidAmount ?? this.paidAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      items: items ?? this.items,
      groups: groups ?? this.groups,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      walletId: walletId ?? this.walletId,
      walletName: walletName ?? this.walletName,
      transactionDate: transactionDate ?? this.transactionDate,
      replyText: replyText ?? this.replyText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_transaction': isTransaction,
      'is_receipt': isReceipt,
      'type': type,
      'amount': amount,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      'payment_method': paymentMethod,
      'items': items?.map((i) => i.toJson()).toList(),
      'groups': groups?.map((g) => g.toJson()).toList(),
      'category_name': categoryName,
      'description': description,
      'wallet_id': walletId,
      'wallet_name': walletName,
      'transaction_date': transactionDate?.toUtc().toIso8601String(),
      'reply_text': replyText,
    };
  }
}

class ChatMessageModel {
  final String id;
  final String userId;
  final String role; // 'user' or 'assistant'
  final String content;
  final String? imageBase64; // Foto struk yang bisa dilihat lagi
  final ExtractedTransaction? extractedData;
  final String? transactionId;
  final bool isSaved;
  final DateTime createdAt;
  Uint8List? _cachedImageBytes;

  ChatMessageModel({
    required this.id,
    required this.userId,
    required this.role,
    required this.content,
    this.imageBase64,
    this.extractedData,
    this.transactionId,
    this.isSaved = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Uint8List? get imageBytes {
    if (_cachedImageBytes != null) return _cachedImageBytes;
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      try {
        _cachedImageBytes = base64Decode(imageBase64!);
      } catch (_) {}
    }
    return _cachedImageBytes;
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  ChatMessageModel copyWith({
    String? id,
    String? userId,
    String? role,
    String? content,
    String? imageBase64,
    ExtractedTransaction? extractedData,
    String? transactionId,
    bool? isSaved,
    DateTime? createdAt,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      content: content ?? this.content,
      imageBase64: imageBase64 ?? this.imageBase64,
      extractedData: extractedData ?? this.extractedData,
      transactionId: transactionId ?? this.transactionId,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    ExtractedTransaction? extracted;
    if (json['raw_extracted_data'] != null &&
        json['raw_extracted_data'] is Map<String, dynamic>) {
      extracted = ExtractedTransaction.fromJson(
          json['raw_extracted_data'] as Map<String, dynamic>);
    }

    return ChatMessageModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      imageBase64: json['image_base64'] as String?,
      extractedData: extracted,
      transactionId: json['transaction_id'] as String?,
      isSaved: json['transaction_id'] != null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'role': role,
      'content': content,
      if (imageBase64 != null) 'image_base64': imageBase64,
      if (extractedData != null) 'raw_extracted_data': extractedData!.toJson(),
      if (transactionId != null) 'transaction_id': transactionId,
    };
  }
}
