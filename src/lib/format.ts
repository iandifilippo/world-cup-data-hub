const MESES = [
  "ENE",
  "FEB",
  "MAR",
  "ABR",
  "MAY",
  "JUN",
  "JUL",
  "AGO",
  "SEP",
  "OCT",
  "NOV",
  "DIC",
];

const MESES_LARGOS = [
  "Enero",
  "Febrero",
  "Marzo",
  "Abril",
  "Mayo",
  "Junio",
  "Julio",
  "Agosto",
  "Septiembre",
  "Octubre",
  "Noviembre",
  "Diciembre",
];

/** 3404252 → "3.404.252" (formato colombiano, sin depender del locale del navegador). */
export function numero(n: number | null | undefined): string {
  if (n === null || n === undefined || Number.isNaN(n)) return "—";
  const [entero, decimal] = Math.abs(n).toString().split(".");
  const conPuntos = entero.replace(/\B(?=(\d{3})+(?!\d))/g, ".");
  const signo = n < 0 ? "-" : "";
  return decimal ? `${signo}${conPuntos},${decimal}` : `${signo}${conPuntos}`;
}

/** 1678.9 → "1678,9" */
export function puntos(n: number | null | undefined): string {
  if (n === null || n === undefined || Number.isNaN(n)) return "—";
  return n.toFixed(1).replace(".", ",");
}

/** "2026-06-11" → "11 JUN 2026" (sin construir Date, para evitar corrimientos de zona). */
export function fechaCorta(iso: string): string {
  const [a, m, d] = iso.split("-");
  const mes = MESES[Number(m) - 1] ?? m;
  return `${d} ${mes} ${a}`;
}

/** "2026-06" → "Junio 2026" */
export function mesLargo(iso: string): string {
  const [a, m] = iso.split("-");
  return `${MESES_LARGOS[Number(m) - 1] ?? m} ${a}`;
}

export function claveMes(iso: string): string {
  return iso.slice(0, 7);
}

/** Quita tildes y pasa a minúsculas: permite buscar "mexico" y encontrar "México". */
export function normalizar(texto: string): string {
  return texto
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim();
}

export function decadaEtiqueta(decada: number): string {
  return `${decada}s`;
}
