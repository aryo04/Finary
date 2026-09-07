/**
 * Schema & Types for General Greetings & Conversation
 * File: schemas/general_schema.ts
 */

export interface GeneralChatResponseSchema {
  is_transaction: false;
  is_receipt: false;
  reply_text: string;
}
