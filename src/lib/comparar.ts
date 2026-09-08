import type { ComparacionRanking, PartidoCalendario, RankingFila } from "@/lib/types";

/**
 * RN10 — la comparación entre ciclos solo es válida si la selección tiene
 * registro en AMBOS ciclos. Si falta uno, `comparable` queda en false y las
 * diferencias en null: nunca se inventa un valor.
 */
export function compararSeleccion(
  ranking: RankingFila[],
  codigo: string,
  calendario: PartidoCalendario[],
): ComparacionRanking | null {
  const r2022 = ranking.find((r) => r.ciclo === 2022 && r.codigo_pais === codigo);
  const r2026 = ranking.find((r) => r.ciclo === 2026 && r.codigo_pais === codigo);
  const base = r2026 ?? r2022;
  if (!base) return null;

  const comparable = Boolean(r2022 && r2026);
  const participa2026 = calendario.some(
    (p) => p.codigo_local === codigo || p.codigo_visitante === codigo,
  );

  return {
    codigo_pais: base.codigo_pais,
    nombre_equipo: base.nombre_equipo,
    bandera: base.bandera,
    confederacion: base.confederacion,
    posicion_2022: r2022?.posicion ?? null,
    posicion_2026: r2026?.posicion ?? null,
    puntos_2022: r2022?.puntos ?? null,
    puntos_2026: r2026?.puntos ?? null,
    dif_posiciones:
      comparable && r2022 && r2026 ? r2022.posicion - r2026.posicion : null,
    dif_puntos:
      comparable && r2022 && r2026
        ? Math.round((r2026.puntos - r2022.puntos) * 10) / 10
        : null,
    participa_2026: participa2026,
    comparable,
  };
}
