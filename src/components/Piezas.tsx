import type { ReactNode } from "react";

import { IconoBuscar } from "@/components/Icons";
import { fechaCorta, numero } from "@/lib/format";

export function TarjetaMetrica({
  icono,
  etiqueta,
  valor,
  pie,
}: {
  icono: ReactNode;
  etiqueta: string;
  valor: number | string;
  pie?: string;
}) {
  return (
    <div className="tarjeta flex items-start gap-4 p-4 sm:p-5">
      <span className="grid h-11 w-11 shrink-0 place-items-center rounded-lg bg-azul-suave text-azul">
        {icono}
      </span>
      <div className="min-w-0">
        <p className="text-[11px] font-semibold uppercase tracking-wide text-gris-texto">
          {etiqueta}
        </p>
        <p className="cifras mt-1 text-3xl font-bold leading-none tracking-tight">
          {typeof valor === "number" ? numero(valor) : valor}
        </p>
        {pie ? <p className="mt-1.5 text-xs text-gris-texto">{pie}</p> : null}
      </div>
    </div>
  );
}

export function Encabezado({
  titulo,
  descripcion,
}: {
  titulo: string;
  descripcion: string;
}) {
  return (
    <div className="mb-6">
      <h1 className="text-2xl font-bold tracking-tight sm:text-[28px]">{titulo}</h1>
      <p className="mt-1 text-sm text-gris-texto">{descripcion}</p>
    </div>
  );
}

export function Panel({
  titulo,
  accion,
  children,
  className = "",
}: {
  titulo?: string;
  accion?: ReactNode;
  children: ReactNode;
  className?: string;
}) {
  return (
    <section className={`tarjeta ${className}`}>
      {titulo ? (
        <div className="flex items-center justify-between gap-4 border-b border-gris-borde px-5 py-3.5">
          <h2 className="text-[13px] font-semibold uppercase tracking-wide text-gris-texto">
            {titulo}
          </h2>
          {accion}
        </div>
      ) : null}
      {children}
    </section>
  );
}

export function Variacion({ valor }: { valor: number | null }) {
  if (valor === null) return <span className="text-gris-texto">—</span>;
  if (valor === 0) return <span className="text-gris-texto">—</span>;
  const sube = valor > 0;
  return (
    <span
      className={`cifras inline-flex items-center gap-1 font-semibold ${
        sube ? "text-sube" : "text-baja"
      }`}
    >
      <span aria-hidden="true">{sube ? "↑" : "↓"}</span>
      <span className="sr-only">{sube ? "Sube" : "Baja"}</span>
      {Math.abs(valor)}
    </span>
  );
}

export function Bandera({
  emoji,
  nombre,
  className = "",
}: {
  emoji: string | null;
  nombre: string;
  className?: string;
}) {
  if (!emoji) {
    return (
      <span
        aria-hidden="true"
        className={`inline-grid h-5 w-7 place-items-center rounded-sm bg-gris-borde text-[10px] text-gris-texto ${className}`}
      >
        ?
      </span>
    );
  }
  return (
    <span role="img" aria-label={`Bandera de ${nombre}`} className={`text-lg leading-none ${className}`}>
      {emoji}
    </span>
  );
}

/**
 * Marcador de un partido. Mientras no haya goles cargados muestra el «vs» de
 * siempre, así sirve igual para un partido jugado y para uno sin resultado.
 */
export function Marcador({
  p,
  className = "",
}: {
  p: { goles_local: number | null; goles_visitante: number | null };
  className?: string;
}) {
  if (p.goles_local === null || p.goles_visitante === null) {
    return <span className={`text-xs text-gris-texto ${className}`}>vs</span>;
  }
  return (
    <span
      className={`cifras rounded-md bg-gris-suave px-2 py-0.5 text-sm font-bold tabular-nums ${className}`}
    >
      {p.goles_local}
      <span className="mx-1 font-normal text-gris-texto">-</span>
      {p.goles_visitante}
    </span>
  );
}

export function Insignia({
  children,
  tono = "neutro",
}: {
  children: ReactNode;
  tono?: "neutro" | "azul" | "verde";
}) {
  const tonos = {
    neutro: "bg-gris-suave text-gris-texto ring-1 ring-inset ring-gris-borde",
    azul: "bg-azul-suave text-azul",
    verde: "bg-exito-fondo text-exito-texto",
  } as const;
  return (
    <span
      className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-[11px] font-semibold ${tonos[tono]}`}
    >
      {children}
    </span>
  );
}

export function Vacio({ mensaje, accion }: { mensaje: string; accion?: string }) {
  return (
    <div className="px-5 py-14 text-center">
      <p className="text-sm font-medium text-tinta">{mensaje}</p>
      {accion ? <p className="mt-1 text-sm text-gris-texto">{accion}</p> : null}
    </div>
  );
}

export function AvisoOrigen({ origen }: { origen: "supabase" | "local" }) {
  if (origen === "supabase") return null;
  return (
    <p className="mb-4 rounded-lg border border-aviso-borde bg-aviso-fondo px-3.5 py-2 text-xs text-aviso-texto">
      Mostrando el dataset local incluido en el repositorio. Para leer desde
      Supabase, define <code className="font-mono">NEXT_PUBLIC_SUPABASE_URL</code> y{" "}
      <code className="font-mono">NEXT_PUBLIC_SUPABASE_ANON_KEY</code>.
    </p>
  );
}

/**
 * Fila de una lista de datos (`<dl>`): etiqueta a la izquierda, valor a la
 * derecha. La usan el destacado, el detalle del historial y el comparador del
 * ranking, así que las tres pantallas se ven igual sin repetir el markup.
 */
export function Renglon({
  etiqueta,
  valor,
  fuerte,
}: {
  etiqueta: string;
  valor: ReactNode;
  fuerte?: boolean;
}) {
  return (
    <div className="flex items-center justify-between gap-4 px-4 py-2.5">
      <dt className="text-gris-texto">{etiqueta}</dt>
      <dd className={`cifras text-right ${fuerte ? "font-semibold" : "font-medium"}`}>
        {valor}
      </dd>
    </div>
  );
}

/**
 * Fecha marcada con `<time>`. El texto visible es la versión corta en español
 * ("11 JUN 2026"); el atributo `dateTime` lleva el ISO (2026-06-11), que es el
 * formato que entienden el navegador y los lectores de pantalla.
 */
export function Fecha({ iso, className = "" }: { iso: string; className?: string }) {
  return (
    <time dateTime={iso} className={className}>
      {fechaCorta(iso)}
    </time>
  );
}

/** Campo de búsqueda con la lupa dentro. Se repite en las tres pantallas. */
export function CampoBusqueda({
  id,
  etiqueta,
  placeholder,
  valor,
  onCambio,
}: {
  id: string;
  etiqueta: string;
  placeholder: string;
  valor: string;
  onCambio: (valor: string) => void;
}) {
  return (
    <div>
      <label className="etiqueta-campo" htmlFor={id}>
        {etiqueta}
      </label>
      <div className="relative">
        <input
          id={id}
          className="campo pr-10"
          type="search"
          placeholder={placeholder}
          value={valor}
          onChange={(e) => onCambio(e.target.value)}
        />
        <IconoBuscar className="pointer-events-none absolute right-3 top-2.5 h-4 w-4 text-gris-texto" />
      </div>
    </div>
  );
}
