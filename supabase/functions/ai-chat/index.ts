/**
 * AI-CHAT Edge Function — Master Router & Dispatcher
 * File: index.ts
 *
 * Menerima request dari Flutter dan mengarahkan ke Handler yang tepat:
 * - Foto Struk Belanja        -> receipt_handler
 * - Teks Transaksi Belanja   -> transaction_handler
 * - Analisis / Tanya Saldo   -> financial_handler (dengan live Supabase database query)
 * - Sapaan / Tanya Panduan   -> general_handler
 */
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { handleCors, errorResponse } from "./utils/response.ts";
import { classifyIntent, ChatRequestBody } from "./utils/validation.ts";
import { handleReceipt } from "./handlers/receipt_handler.ts";
import { handleTransaction } from "./handlers/transaction_handler.ts";
import { handleFinancial } from "./handlers/financial_handler.ts";
import { handleGeneral } from "./handlers/general_handler.ts";

serve(async (req: Request) => {
  // 1. Handle CORS preflight
  const corsRes = handleCors(req);
  if (corsRes) return corsRes;

  // 2. Verifikasi Autentikasi Pengguna (JWT Bearer Token)
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return errorResponse("Header Authorization diperlukan untuk mengakses fitur AI.", 401);
  }

  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) {
    return errorResponse("Token autentikasi tidak ditemukan.", 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

  if (supabaseUrl && supabaseAnonKey) {
    try {
      const supabase = createClient(supabaseUrl, supabaseAnonKey, {
        global: { headers: { Authorization: authHeader } },
      });
      const { data: { user }, error: authError } = await supabase.auth.getUser(token);
      if (authError || !user) {
        return errorResponse("Sesi autentikasi tidak valid atau telah berakhir. Silakan login kembali.", 401);
      }
    } catch (e) {
      return errorResponse("Gagal memvalidasi sesi autentikasi.", 401);
    }
  }

  try {
    const body: ChatRequestBody = await req.json();

    // 3. Klasifikasi intent secara cerdas
    const intent = classifyIntent(body);

    // 4. Dispatch ke handler yang sesuai
    switch (intent) {
      case "receipt":
        return await handleReceipt(body);

      case "financial":
        return await handleFinancial(req, body);

      case "transaction":
        return await handleTransaction(body);

      case "general":
      default:
        return await handleGeneral(body);
    }
  } catch (error) {
    return errorResponse(error.message || "Terjadi kesalahan pada router server AI", 500);
  }
});
