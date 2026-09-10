/**
 * Lista de paletas. Cada `id` tiene su bloque de variables CSS en
 * `src/app/globals.css`; `muestra` son los tres colores que el selector dibuja
 * para reconocer la paleta de un vistazo.
 */
export interface Paleta {
  id: string;
  nombre: string;
  descripcion: string;
  muestra: [string, string, string];
}

export const PALETAS: Paleta[] = [
  {
    id: "clasico",
    nombre: "Clásico",
    descripcion: "Azul FIFA sobre fondo claro",
    muestra: ["#0B1D36", "#2563EB", "#F1F5F9"],
  },
  {
    id: "contraste",
    nombre: "Alto contraste",
    descripcion: "Azul y naranja, pensada para daltonismo",
    muestra: ["#0F172A", "#00629B", "#C2410C"],
  },
  {
    id: "esmeralda",
    nombre: "Esmeralda",
    descripcion: "Verde césped sobre fondo claro",
    muestra: ["#063528", "#059669", "#F0F7F3"],
  },
  {
    id: "atardecer",
    nombre: "Atardecer",
    descripcion: "Violeta y rosa sobre fondo claro",
    muestra: ["#2C1050", "#7C3AED", "#F6F3FB"],
  },
  {
    id: "noche",
    nombre: "Noche",
    descripcion: "Modo oscuro de alto contraste",
    muestra: ["#05070D", "#3B82F6", "#131B26"],
  },
];

export const PALETA_POR_DEFECTO = "clasico";

/** Clave de localStorage donde se recuerda la paleta elegida. */
export const CLAVE_PALETA = "wcdh:paleta";

export function esPaletaValida(id: string | null | undefined): id is string {
  return Boolean(id) && PALETAS.some((p) => p.id === id);
}
