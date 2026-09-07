/**
 * Schema & Types for Receipt OCR & Breakdown
 * File: schemas/receipt_schema.ts
 */

import { TransactionItem } from "./transaction_schema.ts";

export interface ReceiptResponseSchema {
  is_transaction: boolean;
  is_receipt: boolean;
  type?: "expense" | "income";
  amount?: number;
  subtotal?: number;
  discount?: number;
  tax?: number;
  payment_method?: string; // QRIS, Debit BCA, Tunai, ShopeePay, dsb.
  paid_amount?: number;
  change_amount?: number;
  items?: TransactionItem[];
  category_name?: string;
  description?: string;
  reply_text: string;
}
