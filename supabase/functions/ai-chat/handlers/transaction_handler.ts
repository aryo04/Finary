/**
 * Transaction Handler — Memproses chat teks transaksi dengan memori percakapan & multi-dompet
 * File: handlers/transaction_handler.ts
 */

import { ChatRequestBody, formatCategoryList, formatWalletList } from "../utils/validation.ts";
import { jsonResponse, errorResponse } from "../utils/response.ts";
import { buildTransactionPrompt } from "../prompts/transaction_prompt.ts";
import { callOpenAI } from "../services/openai_service.ts";
import { normalizeTransactionResponse } from "../services/transaction_service.ts";
import { TransactionResponseSchema } from "../schemas/transaction_schema.ts";

export async function handleTransaction(body: ChatRequestBody): Promise<Response> {
  const { message, categories, wallets, history } = body;

  if (!message || message.trim() === "") {
    return errorResponse("Pesan teks transaksi tidak boleh kosong.", 400);
  }

  const categoryList = formatCategoryList(categories);
  const walletList = formatWalletList(wallets);
  const systemPrompt = buildTransactionPrompt(categoryList, walletList);

  try {
    const rawResult = await callOpenAI<Partial<TransactionResponseSchema>>({
      systemPrompt,
      userContent: message,
      history,
      model: "gpt-4o-mini",
      temperature: 0.1,
      maxTokens: 800,
    });

    const normalized = normalizeTransactionResponse(rawResult);
    return jsonResponse(normalized);
  } catch (error) {
    return errorResponse(error.message || "Gagal memproses transaksi chat", 500);
  }
}
