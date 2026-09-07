/**
 * Schema & Types for Transaction Parsing
 * File: schemas/transaction_schema.ts
 */

export interface TransactionItem {
  name: string;
  qty: number;
  price: number;
  unit_price?: number;
}

export interface TransactionGroupSchema {
  category_name: string;
  type: "income" | "expense";
  total_amount: number;
  description: string;
  items: TransactionItem[];
  wallet_id?: string;
  wallet_name?: string;
}

export interface TransactionResponseSchema {
  is_transaction: boolean;
  is_receipt: boolean;
  type: "income" | "expense";
  amount: number;
  category_name: string;
  description: string;
  transaction_date?: string;
  wallet_id?: string;
  wallet_name?: string;
  items: TransactionItem[];
  groups?: TransactionGroupSchema[];
  reply_text: string;
}
