/**
 * General Handler — Memproses sapaan & percakapan santai dengan memori bersambung
 * File: handlers/general_handler.ts
 */

import { ChatRequestBody } from "../utils/validation.ts";
import { jsonResponse, errorResponse } from "../utils/response.ts";
import { buildGeneralPrompt } from "../prompts/general_prompt.ts";
import { callOpenAI } from "../services/openai_service.ts";
import { GeneralChatResponseSchema } from "../schemas/general_schema.ts";

export async function handleGeneral(body: ChatRequestBody): Promise<Response> {
  const { message, history } = body;

  const systemPrompt = buildGeneralPrompt();
  const userContent = message && message.trim() !== "" ? message : "Halo Finary AI!";

  try {
    const result = await callOpenAI<GeneralChatResponseSchema>({
      systemPrompt,
      userContent,
      history,
      model: "gpt-4o-mini",
      temperature: 0.6,
      maxTokens: 500,
    });

    return jsonResponse({
      is_transaction: false,
      is_receipt: false,
      reply_text: result.reply_text || "Halo! Ada yang bisa aku bantu untuk mencatat keuanganmu hari ini? ✨",
    });
  } catch (error) {
    return errorResponse(error.message || "Gagal memproses percakapan santai", 500);
  }
}
