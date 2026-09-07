/**
 * Receipt Handler — Memproses foto struk via Vision AI
 * File: handlers/receipt_handler.ts
 */

import { ChatRequestBody, formatCategoryList } from "../utils/validation.ts";
import { jsonResponse, errorResponse } from "../utils/response.ts";
import { buildReceiptPrompt } from "../prompts/receipt_prompt.ts";
import { callOpenAI } from "../services/openai_service.ts";
import { ReceiptResponseSchema } from "../schemas/receipt_schema.ts";

export async function handleReceipt(body: ChatRequestBody): Promise<Response> {
  const { message, categories, image } = body;

  if (!image || image.trim() === "") {
    return errorResponse("Foto struk tidak ditemukan dalam request.", 400);
  }

  const categoryList = formatCategoryList(categories);
  const systemPrompt = buildReceiptPrompt(categoryList);

  const userContent = [
    {
      type: "text",
      text:
        message ||
        "Analisis foto struk ini dan ekstrak seluruh rincian belanja, harga satuan, subtotal, pajak, total biaya, metode pembayaran (QRIS/Debit/Tunai), nominal bayar, dan kembalian.",
    },
    {
      type: "image_url",
      image_url: {
        url: image.startsWith("data:") ? image : `data:image/jpeg;base64,${image}`,
        detail: "high",
      },
    },
  ];

  try {
    const result = await callOpenAI<ReceiptResponseSchema>({
      systemPrompt,
      userContent,
      model: "gpt-4o-mini",
      temperature: 0.1,
      maxTokens: 1000,
    });

    // Validasi & Normalisasi Matematis Anti-Salah Nilai Kasir
    if (result && result.is_transaction) {
      const itemsSum = Array.isArray(result.items)
        ? result.items.reduce((sum, item) => sum + (item.price ?? 0), 0)
        : 0;

      // Kasus 1: AI salah mengisi amount dengan paid_amount padahal ada kembalian
      if (
        typeof result.paid_amount === "number" &&
        typeof result.change_amount === "number" &&
        result.change_amount > 0
      ) {
        const netPaid = result.paid_amount - result.change_amount;
        if (netPaid > 0) {
          if (
            result.amount === result.paid_amount ||
            (result.subtotal && netPaid === result.subtotal) ||
            (itemsSum > 0 && Math.abs(netPaid - itemsSum) < 100)
          ) {
            result.amount = netPaid;
          }
        }
      }

      // Kasus 2: amount masih sama dengan paid_amount, cek subtotal + tax - discount
      if (
        typeof result.subtotal === "number" &&
        result.subtotal > 0 &&
        result.amount === result.paid_amount
      ) {
        const calculated =
          result.subtotal + (result.tax ?? 0) - (result.discount ?? 0);
        if (calculated > 0) {
          result.amount = calculated;
        }
      }

      // Kasus 3: Jika amount kosong / 0 tapi items / subtotal ada
      if (!result.amount || result.amount <= 0) {
        if (typeof result.subtotal === "number" && result.subtotal > 0) {
          result.amount = result.subtotal + (result.tax ?? 0) - (result.discount ?? 0);
        } else if (itemsSum > 0) {
          result.amount = itemsSum;
        }
      }
    }

    return jsonResponse(result);
  } catch (error) {
    return errorResponse(error.message || "Gagal menganalisis struk belanja", 500);
  }
}
