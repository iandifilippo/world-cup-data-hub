import type { Confederacion } from "@/lib/types";

/**
 * Descripción del esquema tal como quedó en `supabase/migrations`. La consola
 * de datos la usa para dibujar el formulario de inserción y para armar el
 * INSERT, igual que hace el "Table editor" de Supabase con la metadata del
 * catálogo de Postgres.
 *
 * Las columnas `generated always as identity` no aparecen: las genera Postgres.
 */
export type TipoColumna =
  | "texto"
  | "entero"
  | "decimal"
  | "booleano"
  | "fecha"
  | "fecha_hora";

export interface Columna {
  nombre: string;
  /** Tipo de Postgres, tal cual, para mostrarlo junto al campo. */
  tipoSql: string;
  tipo: TipoColumna;
  requerido: boolean;
  /** Valores admitidos por un CHECK: se dibujan como desplegable. */
  opciones?: readonly string[];
  /** Longitud exacta obligatoria (por ejemplo char(3)). */
  largoExacto?: number;
  minimo?: number;
  maximo?: number;
  porDefecto?: string;
  ayuda?: string;
}

export interface Tabla {
  nombre: string;
  descripcion: string;
  /** Reglas de negocio del documento que afectan a esta tabla. */
  reglas?: string[];
  columnas: Columna[];
}

const CONFEDERACIONES: readonly Confederacion[] = [
  "CONMEBOL",
  "UEFA",
  "CONCACAF",
  "CAF",
  "AFC",
  "OFC",
];

const FASES_TIPICAS = [
  "Fase de Grupos",
  "Octavos de Final",
  "Cuartos de Final",
  "Semifinal",
  "Tercer Lugar",
  "Final",
] as const;

export const TABLAS: Tabla[] = [
  {
    nombre: "equipos",
    descripcion: "Catálogo de selecciones nacionales miembro de la FIFA.",
    columnas: [
      { nombre: "nombre_equipo", tipoSql: "text", tipo: "texto", requerido: true },
      {
        nombre: "codigo_pais",
        tipoSql: "char(3)",
        tipo: "texto",
        requerido: true,
        largoExacto: 3,
        ayuda: "Código FIFA de tres letras, por ejemplo COL.",
      },
      {
        nombre: "confederacion",
        tipoSql: "text",
        tipo: "texto",
        requerido: true,
        opciones: CONFEDERACIONES,
      },
      {
        nombre: "bandera",
        tipoSql: "text",
        tipo: "texto",
        requerido: false,
        ayuda: "Emoji de la bandera.",
      },
    ],
  },
  {
    nombre: "sedes",
    descripcion: "Estadios que han servido de sede en las distintas ediciones.",
    columnas: [
      { nombre: "nombre_estadio", tipoSql: "text", tipo: "texto", requerido: true },
      { nombre: "ciudad", tipoSql: "text", tipo: "texto", requerido: true },
      { nombre: "pais", tipoSql: "text", tipo: "texto", requerido: true },
      {
        nombre: "capacidad",
        tipoSql: "integer",
        tipo: "entero",
        requerido: false,
        minimo: 1,
      },
    ],
  },
  {
    nombre: "ediciones",
    descripcion: "Cada Copa del Mundo como tal, por ejemplo «Qatar 2022».",
    reglas: [
      "RN01 — una edición finalizada debe tener campeón y subcampeón.",
      "RN01b — campeón y subcampeón no pueden ser la misma selección.",
    ],
    columnas: [
      {
        nombre: "nombre_edicion",
        tipoSql: "text",
        tipo: "texto",
        requerido: true,
        ayuda: "Único. Por ejemplo: Qatar 2022.",
      },
      {
        nombre: "anio",
        tipoSql: "integer",
        tipo: "entero",
        requerido: true,
        minimo: 1930,
        maximo: 2100,
      },
      { nombre: "sede", tipoSql: "text", tipo: "texto", requerido: true },
      { nombre: "pais_sede", tipoSql: "text", tipo: "texto", requerido: true },
      {
        nombre: "equipos",
        tipoSql: "integer",
        tipo: "entero",
        requerido: true,
        minimo: 1,
      },
      { nombre: "campeon", tipoSql: "text", tipo: "texto", requerido: false },
      { nombre: "subcampeon", tipoSql: "text", tipo: "texto", requerido: false },
      { nombre: "goleador", tipoSql: "text", tipo: "texto", requerido: false },
      {
        nombre: "goles_goleador",
        tipoSql: "integer",
        tipo: "entero",
        requerido: false,
        minimo: 0,
      },
      {
        nombre: "asistencia_total",
        tipoSql: "bigint",
        tipo: "entero",
        requerido: false,
        minimo: 0,
      },
      {
        nombre: "promedio_asistencia",
        tipoSql: "integer",
        tipo: "entero",
        requerido: false,
        minimo: 0,
      },
      {
        nombre: "partidos",
        tipoSql: "integer",
        tipo: "entero",
        requerido: true,
        minimo: 0,
      },
      { nombre: "fecha_inicio", tipoSql: "date", tipo: "fecha", requerido: false },
      {
        nombre: "finalizada",
        tipoSql: "boolean",
        tipo: "booleano",
        requerido: false,
        porDefecto: "true",
      },
    ],
  },
  {
    nombre: "fases",
    descripcion: "Fases dentro de un torneo: grupos, octavos, final…",
    columnas: [
      {
        nombre: "id_edicion",
        tipoSql: "integer → ediciones",
        tipo: "entero",
        requerido: true,
        minimo: 1,
      },
      {
        nombre: "nombre_fase",
        tipoSql: "text",
        tipo: "texto",
        requerido: true,
        opciones: FASES_TIPICAS,
      },
      {
        nombre: "orden",
        tipoSql: "smallint",
        tipo: "entero",
        requerido: false,
        porDefecto: "0",
      },
    ],
  },
  {
    nombre: "partidos",
    descripcion: "Cada partido jugado o programado del torneo.",
    columnas: [
      {
        nombre: "numero_partido",
        tipoSql: "integer",
        tipo: "entero",
        requerido: true,
        minimo: 1,
      },
      {
        nombre: "fecha_hora",
        tipoSql: "timestamptz",
        tipo: "fecha_hora",
        requerido: true,
      },
      {
        nombre: "id_sede",
        tipoSql: "integer → sedes",
        tipo: "entero",
        requerido: true,
        minimo: 1,
      },
      {
        nombre: "id_fase",
        tipoSql: "integer → fases",
        tipo: "entero",
        requerido: true,
        minimo: 1,
      },
      {
        nombre: "grupo",
        tipoSql: "char(1)",
        tipo: "texto",
        requerido: false,
        largoExacto: 1,
        ayuda: "Solo para la fase de grupos: A, B, C…",
      },
      {
        nombre: "etiqueta_local",
        tipoSql: "text",
        tipo: "texto",
        requerido: false,
        ayuda: "Para llaves sin sorteo resuelto: «1.º Grupo A».",
      },
      { nombre: "etiqueta_visitante", tipoSql: "text", tipo: "texto", requerido: false },
    ],
  },
  {
    nombre: "partido_equipo",
    descripcion: "Qué equipos jugaron cada partido y cuántos goles anotaron.",
    reglas: [
      "RN03 — un partido tiene exactamente un local y un visitante.",
      "RN07 — los goles nunca pueden ser negativos.",
    ],
    columnas: [
      {
        nombre: "id_partido",
        tipoSql: "integer → partidos",
        tipo: "entero",
        requerido: true,
        minimo: 1,
      },
      {
        nombre: "equipo_id",
        tipoSql: "integer → equipos",
        tipo: "entero",
        requerido: true,
        minimo: 1,
      },
      {
        nombre: "tipo",
        tipoSql: "text",
        tipo: "texto",
        requerido: true,
        opciones: ["local", "visitante"],
      },
      {
        nombre: "goles",
        tipoSql: "integer",
        tipo: "entero",
        requerido: false,
        minimo: 0,
      },
    ],
  },
  {
    nombre: "ranking_fifa",
    descripcion: "Ranking FIFA por ciclo, con puntaje y partidos evaluados.",
    reglas: ["RN09 — los ciclos 2022 y 2026 nunca se mezclan ni se promedian."],
    columnas: [
      {
        nombre: "ciclo",
        tipoSql: "integer",
        tipo: "entero",
        requerido: true,
        opciones: ["2022", "2026"],
      },
      {
        nombre: "equipo_id",
        tipoSql: "integer → equipos",
        tipo: "entero",
        requerido: true,
        minimo: 1,
      },
      {
        nombre: "posicion",
        tipoSql: "integer",
        tipo: "entero",
        requerido: true,
        minimo: 1,
        ayuda: "Única dentro del ciclo.",
      },
      {
        nombre: "puntos",
        tipoSql: "numeric(7,2)",
        tipo: "decimal",
        requerido: true,
        minimo: 0,
      },
      {
        nombre: "partidos_evaluados",
        tipoSql: "integer",
        tipo: "entero",
        requerido: false,
        minimo: 0,
        porDefecto: "0",
      },
    ],
  },
  {
    nombre: "jugadores",
    descripcion: "Registro de futbolistas convocados.",
    columnas: [
      { nombre: "nombre_completo", tipoSql: "text", tipo: "texto", requerido: true },
      {
        nombre: "fecha_nacimiento",
        tipoSql: "date",
        tipo: "fecha",
        requerido: false,
      },
      {
        nombre: "posicion",
        tipoSql: "text",
        tipo: "texto",
        requerido: false,
        opciones: ["Portero", "Defensa", "Centrocampista", "Delantero"],
      },
      {
        nombre: "equipo_id",
        tipoSql: "integer → equipos",
        tipo: "entero",
        requerido: false,
        minimo: 1,
      },
    ],
  },
  {
    nombre: "edicion_equipo",
    descripcion: "Qué selecciones clasificaron a cada edición y a qué grupo.",
    reglas: ["RN04 — un equipo no puede repetirse en el mismo grupo de una edición."],
    columnas: [
      {
        nombre: "id_edicion",
        tipoSql: "integer → ediciones",
        tipo: "entero",
        requerido: true,
        minimo: 1,
      },
      {
        nombre: "equipo_id",
        tipoSql: "integer → equipos",
        tipo: "entero",
        requerido: true,
        minimo: 1,
      },
      {
        nombre: "grupo_inicial",
        tipoSql: "char(1)",
        tipo: "texto",
        requerido: false,
        largoExacto: 1,
      },
    ],
  },
  {
    nombre: "edicion_sede",
    descripcion: "Qué estadios se usaron en cada edición.",
    reglas: ["RN08 — una edición se juega en una o más sedes."],
    columnas: [
      {
        nombre: "id_edicion",
        tipoSql: "integer → ediciones",
        tipo: "entero",
        requerido: true,
        minimo: 1,
      },
      {
        nombre: "id_sede",
        tipoSql: "integer → sedes",
        tipo: "entero",
        requerido: true,
        minimo: 1,
      },
    ],
  },
];

/** Escapa un literal de texto para SQL: 'O''Neill'. */
function literalTexto(valor: string): string {
  return `'${valor.replace(/'/g, "''")}'`;
}

/** Convierte el valor del formulario al literal SQL que le corresponde. */
export function literalSql(columna: Columna, valor: string): string {
  const v = valor.trim();
  if (v === "") return "null";
  switch (columna.tipo) {
    case "entero":
    case "decimal":
      return v;
    case "booleano":
      return v === "true" ? "true" : "false";
    default:
      return literalTexto(v);
  }
}

/** Convierte el valor del formulario al tipo que espera supabase-js. */
export function valorJs(columna: Columna, valor: string): unknown {
  const v = valor.trim();
  if (v === "") return null;
  switch (columna.tipo) {
    case "entero":
    case "decimal":
      return Number(v);
    case "booleano":
      return v === "true";
    default:
      return v;
  }
}

export interface ErrorCampo {
  columna: string;
  mensaje: string;
}

/** Valida el formulario con las mismas restricciones que tiene la tabla. */
export function validar(tabla: Tabla, valores: Record<string, string>): ErrorCampo[] {
  const errores: ErrorCampo[] = [];

  for (const c of tabla.columnas) {
    const v = (valores[c.nombre] ?? "").trim();

    if (v === "") {
      if (c.requerido && c.porDefecto === undefined) {
        errores.push({ columna: c.nombre, mensaje: "Este campo es obligatorio." });
      }
      continue;
    }

    if (c.largoExacto && v.length !== c.largoExacto) {
      errores.push({
        columna: c.nombre,
        mensaje: `Debe tener exactamente ${c.largoExacto} carácter(es).`,
      });
      continue;
    }

    if (c.tipo === "entero" || c.tipo === "decimal") {
      const n = Number(v);
      if (!Number.isFinite(n)) {
        errores.push({ columna: c.nombre, mensaje: "Debe ser un número." });
        continue;
      }
      if (c.tipo === "entero" && !Number.isInteger(n)) {
        errores.push({ columna: c.nombre, mensaje: "Debe ser un número entero." });
        continue;
      }
      if (c.minimo !== undefined && n < c.minimo) {
        errores.push({ columna: c.nombre, mensaje: `No puede ser menor que ${c.minimo}.` });
        continue;
      }
      if (c.maximo !== undefined && n > c.maximo) {
        errores.push({ columna: c.nombre, mensaje: `No puede ser mayor que ${c.maximo}.` });
      }
    }
  }

  // RN01b, comprobada aquí para no esperar al rechazo de Postgres.
  if (tabla.nombre === "ediciones") {
    const campeon = (valores.campeon ?? "").trim();
    const subcampeon = (valores.subcampeon ?? "").trim();
    if (campeon && campeon === subcampeon) {
      errores.push({
        columna: "subcampeon",
        mensaje: "RN01b — el subcampeón no puede ser el mismo campeón.",
      });
    }
    const finalizada = (valores.finalizada ?? "true").trim() !== "false";
    if (finalizada && (!campeon || !subcampeon)) {
      errores.push({
        columna: campeon ? "subcampeon" : "campeon",
        mensaje: "RN01 — una edición finalizada necesita campeón y subcampeón.",
      });
    }
  }

  return errores;
}

/** Arma el INSERT completo con los valores que haya escrito el usuario. */
export function construirInsert(
  tabla: Tabla,
  valores: Record<string, string>,
): string {
  const usadas = tabla.columnas.filter(
    (c) => (valores[c.nombre] ?? "").trim() !== "",
  );
  if (usadas.length === 0) {
    return `-- Completa al menos un campo de "${tabla.nombre}" para ver el INSERT.`;
  }

  const columnas = usadas.map((c) => c.nombre).join(", ");
  const literales = usadas
    .map((c) => literalSql(c, valores[c.nombre] ?? ""))
    .join(", ");

  return `insert into ${tabla.nombre} (${columnas})\nvalues (${literales});`;
}
