export type Confederacion =
  | "CONMEBOL"
  | "UEFA"
  | "CONCACAF"
  | "CAF"
  | "AFC"
  | "OFC";

export interface Equipo {
  equipo_id: number;
  nombre_equipo: string;
  codigo_pais: string;
  confederacion: Confederacion;
  bandera: string;
}

export interface Edicion {
  id_edicion: number;
  nombre_edicion: string;
  anio: number;
  sede: string;
  pais_sede: string;
  equipos: number;
  campeon: string;
  subcampeon: string;
  goleador: string;
  goles_goleador: number;
  asistencia_total: number;
  promedio_asistencia: number;
  partidos: number;
  decada: number;
}

export interface RankingFila {
  ciclo: 2022 | 2026;
  posicion: number;
  nombre_equipo: string;
  codigo_pais: string;
  confederacion: Confederacion;
  bandera: string;
  puntos: number;
  posicion_anterior: number | null;
  variacion: number | null;
  partidos_evaluados: number;
}

/** Resultado de la comparación entre ciclos (RN10). */
export interface ComparacionRanking {
  codigo_pais: string;
  nombre_equipo: string;
  bandera: string;
  confederacion: Confederacion;
  posicion_2022: number | null;
  posicion_2026: number | null;
  puntos_2022: number | null;
  puntos_2026: number | null;
  dif_posiciones: number | null;
  dif_puntos: number | null;
  participa_2026: boolean;
  comparable: boolean;
}

export interface Sede {
  id_sede: number;
  nombre_estadio: string;
  ciudad: string;
  pais: string;
  capacidad: number;
}

export type Fase =
  | "Fase de Grupos"
  | "Dieciseisavos de Final"
  | "Octavos de Final"
  | "Cuartos de Final"
  | "Semifinal"
  | "Tercer Lugar"
  | "Final";

export interface PartidoCalendario {
  id_partido: number;
  numero_partido: number;
  /** ISO corto: YYYY-MM-DD */
  fecha: string;
  /** HH:MM en hora local de la sede */
  hora: string;
  fase: Fase;
  grupo: string | null;
  equipo_local: string;
  codigo_local: string | null;
  bandera_local: string | null;
  equipo_visitante: string;
  codigo_visitante: string | null;
  bandera_visitante: string | null;
  nombre_estadio: string;
  ciudad: string;
  pais_sede: string;
  ranking_local: number | null;
  puntos_local: number | null;
  ranking_visitante: number | null;
  puntos_visitante: number | null;
  /** Null mientras el partido no se haya jugado o no se haya cargado. */
  goles_local: number | null;
  goles_visitante: number | null;
}

/** Partido de una edición histórica (RF05). */
export interface PartidoHistorico {
  id_partido: number;
  fecha: string;
  equipo_local: string;
  equipo_visitante: string;
  goles_local: number | null;
  goles_visitante: number | null;
  fase: string;
}

export interface MetricasGlobales {
  ediciones_historicas: number;
  partidos_historicos: number;
  selecciones_ranking_2026: number;
  partidos_programados_2026: number;
  anio_min: number;
  anio_max: number;
}

/** De dónde salieron los datos que está viendo el usuario. */
export type OrigenDatos = "supabase" | "local";

/** Partido histórico con marcador, sede y nota contextual. */
export interface PartidoHistoricoDetallado {
  id_partido: number;
  anio: number;
  /** ISO corto: YYYY-MM-DD */
  fecha: string;
  equipo_local: string;
  goles_local: number;
  goles_visitante: number;
  equipo_visitante: string;
  fase: string;
  nombre_estadio: string;
  ciudad: string;
  nota: string | null;
}
