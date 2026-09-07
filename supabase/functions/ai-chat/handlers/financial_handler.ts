/**
 * Financial Handler — Memproses pertanyaan analisis keuangan & budgeting dengan data real-time
 * File: handlers/financial_handler.ts
 */

import { ChatRequestBody } from "../utils/validation.ts";
import { jsonResponse, errorResponse } from "../utils/response.ts";
import { buildFinancialContext } from "../services/financial_service.ts";
import { buildFinancialPrompt } from "../prompts/financial_prompt.ts";
import { callOpenAI } from "../services/openai_service.ts";
import { FinancialInsightResponseSchema } from "../schemas/financial_schema.ts";

export async function handleFinancial(req: Request, body: ChatRequestBody): Promise<Response> {
  const { message, history } = body;

  if (!message || message.trim() === "") {
    return errorResponse("Pesan pertanyaan finansial tidak boleh kosong.", 400);
  }

  const authHeader = req.headers.get("Authorization") ?? "";

  // 1. Ambil data asli dari PostgreSQL database Supabase (dan fallback ke live client wallet balances)
  const financialContext = await buildFinancialContext(authHeader, message, body);

  // 2. Buat prompt cerdas yang menyertakan angka riil keuangan pengguna dari database
  const systemPrompt = buildFinancialPrompt(financialContext);

  try {
    const result = await callOpenAI<FinancialInsightResponseSchema>({
      systemPrompt,
      userContent: message,
      history,
      model: "gpt-4o-mini",
      temperature: 0.1,
      maxTokens: 800,
    });

    return jsonResponse(result);
  } catch (error) {
    return errorResponse(error.message || "Gagal memproses analisis keuangan", 500);
  }
}
