/**
 * Schema & Types for Financial Queries & Insights
 * File: schemas/financial_schema.ts
 */

export interface FinancialInsightResponseSchema {
  is_transaction: false;
  is_insight: true;
  reply_text: string;
  suggested_actions?: string[];
}
