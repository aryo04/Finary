/**
 * CORS & Response Utility
 * File: utils/response.ts
 */

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

/**
 * Membungkus response JSON dengan CORS headers
 */
export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
    status,
  });
}

/**
 * Response error standar dengan format JSON
 */
export function errorResponse(message: string, status = 500): Response {
  return jsonResponse({ error: message, is_transaction: false }, status);
}

/**
 * Menangani CORS Preflight (OPTIONS request)
 */
export function handleCors(req: Request): Response | null {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  return null;
}
