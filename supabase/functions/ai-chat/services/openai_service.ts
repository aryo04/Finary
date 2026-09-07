/**
 * OpenAI API Communication Service
 * File: services/openai_service.ts
 */

export interface OpenAICallParams {
  systemPrompt: string;
  userContent: string | Array<Record<string, unknown>>;
  history?: Array<{ role: string; content: string }>;
  model?: "gpt-4o-mini" | "gpt-4o";
  temperature?: number;
  maxTokens?: number;
}

export async function callOpenAI<T = Record<string, unknown>>(params: OpenAICallParams): Promise<T> {
  const apiKey = Deno.env.get("OPENAIAPI");
  if (!apiKey) {
    throw new Error("OPENAIAPI key belum dikonfigurasi di Supabase secrets");
  }

  const {
    systemPrompt,
    userContent,
    history = [],
    model = "gpt-4o-mini",
    temperature = 0.1,
    maxTokens = 800,
  } = params;

  // Bangun riwayat percakapan agar AI memiliki memori kontekstual yang bersambung
  const formattedHistory = history
    .filter((h) => h.content && h.content.trim() !== "")
    .map((h) => ({
      role: h.role === "assistant" ? "assistant" : "user",
      content: h.content,
    }));

  const messages = [
    { role: "system", content: systemPrompt },
    ...formattedHistory,
    { role: "user", content: userContent },
  ];

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      messages,
      temperature,
      max_tokens: maxTokens,
      response_format: { type: "json_object" },
    }),
  });

  const data = await response.json();

  if (data.error) {
    throw new Error(data.error.message || "OpenAI API Error");
  }

  const content = data.choices?.[0]?.message?.content;
  if (!content) {
    throw new Error("OpenAI mengembalikan respons kosong");
  }

  return JSON.parse(content) as T;
}
