/**
 * Transaction Business Service & Normalizer
 * File: services/transaction_service.ts
 */

import { TransactionResponseSchema, TransactionItem } from "../schemas/transaction_schema.ts";

export function normalizeTransactionResponse(raw: Partial<TransactionResponseSchema>): TransactionResponseSchema {
  let items: TransactionItem[] = Array.isArray(raw.items) ? raw.items : [];
  if (items.length === 0 && Array.isArray(raw.groups) && raw.groups.length > 0) {
    items = raw.groups.flatMap((g) => (Array.isArray(g.items) ? g.items : []));
  }

  // Hitung total dari items atau groups jika amount kosong
  let totalAmount = typeof raw.amount === "number" && raw.amount > 0 ? raw.amount : 0;
  if (totalAmount === 0 && items.length > 0) {
    totalAmount = items.reduce((sum, item) => sum + (item.price ?? 0), 0);
  }
  if (totalAmount === 0 && Array.isArray(raw.groups) && raw.groups.length > 0) {
    totalAmount = raw.groups.reduce((sum, g) => sum + (g.total_amount ?? 0), 0);
  }

  const hasOnlyIncomeGroups =
    Array.isArray(raw.groups) &&
    raw.groups.length > 0 &&
    raw.groups.every((g) => g.type === "income");
  const inferredType =
    raw.type === "income" || hasOnlyIncomeGroups ? "income" : "expense";

  return {
    is_transaction: raw.is_transaction ?? totalAmount > 0,
    is_receipt: false,
    type: inferredType,
    amount: totalAmount,
    category_name:
      raw.category_name ||
      (raw.groups?.[0]?.category_name ??
        (inferredType === "income" ? "Pemasukan Lain" : "Belanja")),
    description: raw.description || (raw.groups?.[0]?.description ?? "Catatan transaksi"),
    transaction_date: raw.transaction_date,
    wallet_id: raw.wallet_id,
    wallet_name: raw.wallet_name,
    items,
    groups: raw.groups,
    reply_text: raw.reply_text || "Rincian transaksi sudah disiapkan! Silakan periksa dan tap Simpan ke Transaksi ya! ✨",
  };
}
