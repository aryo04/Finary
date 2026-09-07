class WalletTransferModel {
  final String id;
  final String userId;
  final String fromWalletId;
  final String toWalletId;
  final double amount;
  final String? description;
  final DateTime transferDate;
  final DateTime createdAt;
  final String? fromWalletName;
  final String? toWalletName;

  WalletTransferModel({
    required this.id,
    required this.userId,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    this.description,
    required this.transferDate,
    required this.createdAt,
    this.fromWalletName,
    this.toWalletName,
  });

  factory WalletTransferModel.fromJson(Map<String, dynamic> json) {
    return WalletTransferModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      fromWalletId: json['from_wallet_id'] as String? ?? '',
      toWalletId: json['to_wallet_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String?,
      transferDate: json['transfer_date'] != null
          ? DateTime.parse(json['transfer_date'] as String).toLocal()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      fromWalletName: json['from_wallet']?['name'] as String?,
      toWalletName: json['to_wallet']?['name'] as String?,
    );
  }
}
