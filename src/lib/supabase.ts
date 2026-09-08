import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

/**
 * La plataforma es de solo lectura. Si las variables de entorno no están
 * configuradas, `getSupabase()` devuelve null y la capa de consultas
 * (`src/lib/queries.ts`) usa el dataset local incluido en el repositorio.
 * Así el despliegue en Vercel funciona incluso antes de conectar la base.
 */
let cliente: SupabaseClient | null = null;

export function supabaseConfigurado(): boolean {
  return Boolean(url && anonKey && url.startsWith("http"));
}

export function getSupabase(): SupabaseClient | null {
  if (!supabaseConfigurado()) return null;
  if (!cliente) {
    cliente = createClient(url as string, anonKey as string, {
      auth: { persistSession: false },
    });
  }
  return cliente;
}
