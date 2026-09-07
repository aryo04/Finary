// Ambient declarations for Supabase Edge Functions (Deno runtime)
// This provides editor type recognition for VS Code / TypeScript LSP even when Deno extension is not active.

declare module "https://esm.sh/@supabase/supabase-js@2" {
  export function createClient<T = any>(
    supabaseUrl: string,
    supabaseKey: string,
    options?: any
  ): any;
  export type SupabaseClient<T = any> = any;
  const defaultExport: any;
  export default defaultExport;
}

declare module "https://deno.land/std@0.168.0/http/server.ts" {
  export function serve(
    handler: (req: Request) => Response | Promise<Response>,
    options?: { port?: number; onListen?: (params: { port: number; hostname: string }) => void }
  ): void;
}

declare namespace Deno {
  export const env: {
    get(key: string): string | undefined;
    set(key: string, value: string): void;
    delete(key: string): void;
    toObject(): Record<string, string>;
  };
}
