import type { SupabaseClient } from "@supabase/supabase-js";

import { getSupabase } from "@/lib/supabase";
import { EDICIONES } from "@/lib/data/ediciones";
import { RANKING } from "@/lib/data/ranking";
import { CALENDARIO_2026, SEDES } from "@/lib/data/calendario";
import { PARTIDOS_HISTORICOS } from "@/lib/data/partidosHistoricos";
import { EQUIPOS } from "@/lib/data/equipos";
import type {
  Edicion,
  Equipo,
  MetricasGlobales,
  OrigenDatos,
  PartidoCalendario,
  PartidoHistoricoDetallado,
  RankingFila,
  Sede,
} from "@/lib/types";

export interface Resultado<T> {
  datos: T;
  origen: OrigenDatos;
}

/**
 * Ejecuta una consulta contra Supabase y, si falla o no está configurado,
 * cae al dataset local. Nunca lanza: la página siempre renderiza algo.
 */
async function consultar<T>(
  construir: (sb: SupabaseClient) => PromiseLike<{ data: unknown; error: unknown }>,
  respaldo: T,
): Promise<Resultado<T>> {
  const sb = getSupabase();
  if (!sb) return { datos: respaldo, origen: "local" };
  try {
    const { data, error } = await construir(sb);
    if (error || !data || (Array.isArray(data) && data.length === 0)) {
      return { datos: respaldo, origen: "local" };
    }
    return { datos: data as T, origen: "supabase" };
  } catch {
    return { datos: respaldo, origen: "local" };
  }
}

/** RF02 — historial completo de ediciones, ordenado cronológicamente. */
export async function getEdiciones(): Promise<Resultado<Edicion[]>> {
  return consultar<Edicion[]>(
    (sb) => sb.from("v_ediciones").select("*").order("anio", { ascending: true }),
    EDICIONES,
  );
}

/** RF06 — ranking FIFA de ambos ciclos con variación. */
export async function getRanking(): Promise<Resultado<RankingFila[]>> {
  return consultar<RankingFila[]>(
    (sb) => sb.from("v_ranking").select("*").order("posicion", { ascending: true }),
    RANKING,
  );
}

/** RF08 — calendario del Mundial 2026. */
export async function getCalendario(): Promise<Resultado<PartidoCalendario[]>> {
  return consultar<PartidoCalendario[]>(
    (sb) =>
      sb.from("v_calendario_2026").select("*").order("numero_partido", { ascending: true }),
    CALENDARIO_2026,
  );
}

/** RF05 — partidos de las ediciones históricas (vista v_partidos_edicion). */
export async function getPartidosHistoricos(): Promise<
  Resultado<PartidoHistoricoDetallado[]>
> {
  return consultar<PartidoHistoricoDetallado[]>(
    (sb) =>
      sb
        .from("v_partidos_edicion")
        .select(
          "id_partido, anio, fecha, equipo_local, goles_local, goles_visitante," +
            " equipo_visitante, fase, nombre_estadio, ciudad, nota",
        )
        // El historial muestra partidos jugados: los del calendario 2026 que
        // todavía no tienen marcador cargado no entran aquí.
        .not("goles_local", "is", null)
        .order("fecha", { ascending: true }),
    PARTIDOS_HISTORICOS,
  );
}

export async function getEquipos(): Promise<Resultado<Equipo[]>> {
  return consultar<Equipo[]>(
    (sb) => sb.from("equipos").select("*").order("nombre_equipo", { ascending: true }),
    EQUIPOS,
  );
}

export function getSedes(): Sede[] {
  return SEDES;
}

/** RF01 — métricas globales de la pantalla de Inicio. */
export async function getMetricas(): Promise<Resultado<MetricasGlobales>> {
  const sb = getSupabase();
  const local: MetricasGlobales = {
    ediciones_historicas: EDICIONES.length,
    partidos_historicos: EDICIONES.reduce((t, e) => t + e.partidos, 0),
    selecciones_ranking_2026: RANKING.filter((r) => r.ciclo === 2026).length,
    // El total real del torneo (104), no cuántos partidos están cargados.
    partidos_programados_2026:
      EDICIONES.find((e) => e.anio === 2026)?.partidos ?? CALENDARIO_2026.length,
    anio_min: Math.min(...EDICIONES.map((e) => e.anio)),
    anio_max: Math.max(...EDICIONES.map((e) => e.anio)),
  };
  if (!sb) return { datos: local, origen: "local" };
  try {
    const { data, error } = await sb.from("v_metricas_globales").select("*").single();
    if (error || !data) return { datos: local, origen: "local" };
    return { datos: data as MetricasGlobales, origen: "supabase" };
  } catch {
    return { datos: local, origen: "local" };
  }
}
