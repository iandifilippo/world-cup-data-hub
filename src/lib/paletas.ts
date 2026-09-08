/**
 * Paletas disponibles. Cada `id` corresponde a un bloque de variables CSS en
 * `src/app/globals.css`; `muestra` son los tres colores que se dibujan en el
 * selector para reconocer la paleta sin tener que aplicarla.
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

export const CLAVE_PALETA = "wcdh:paleta";

export function esPaletaValida(id: string | null | undefined): boolean {
  return Boolean(id) && PALETAS.some((p) => p.id === id);
}

/**
 * Script que se inyecta en <head> y corre antes del primer pintado: aplica la
 * paleta guardada para que no se vea un parpadeo de la paleta por defecto.
 */
export const SCRIPT_PALETA = `(function(){try{var p=localStorage.getItem(${JSON.stringify(
  CLAVE_PALETA,
)});var v=${JSON.stringify(
  PALETAS.map((p) => p.id),
)};if(p&&v.indexOf(p)>-1){document.documentElement.setAttribute("data-paleta",p);}}catch(e){}})();`;
