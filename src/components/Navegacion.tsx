"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ReactNode } from "react";

import { ConsolaDatos } from "@/components/ConsolaDatos";
import {
  IconoCalendario,
  IconoHistorial,
  IconoInicio,
  IconoRanking,
  IconoTrofeo,
} from "@/components/Icons";
import { SelectorPaleta } from "@/components/Paleta";

interface Modulo {
  href: string;
  nombre: string;
  icono: (props: { className?: string }) => ReactNode;
}

/** RF12 — los cuatro módulos accesibles desde cualquier pantalla. */
export const MODULOS: Modulo[] = [
  { href: "/", nombre: "Inicio", icono: IconoInicio },
  { href: "/historial", nombre: "Historial de Mundiales", icono: IconoHistorial },
  { href: "/ranking", nombre: "Ranking FIFA", icono: IconoRanking },
  { href: "/calendario", nombre: "Calendario 2026", icono: IconoCalendario },
];

function esActivo(pathname: string, href: string): boolean {
  if (href === "/") return pathname === "/";
  return pathname === href || pathname.startsWith(`${href}/`);
}

/**
 * Barra lateral de escritorio. Es `sticky` y mide exactamente el alto de la
 * ventana (`h-screen`), así que hace scroll por dentro y su pie siempre se ve.
 * En pantallas menores a `lg` se oculta y manda la barra superior.
 */
export function BarraLateral() {
  const pathname = usePathname();

  return (
    <aside className="barra-fina sticky top-0 hidden h-screen w-64 shrink-0 flex-col overflow-y-auto bg-navy-800 lg:flex">
      <Link
        href="/"
        className="flex items-center gap-3 px-6 py-6 text-white transition hover:opacity-90"
      >
        <IconoTrofeo className="h-8 w-8 shrink-0 text-acento" />
        <span className="text-[15px] font-semibold leading-tight tracking-wide">
          World Cup
          <br />
          Data Hub
        </span>
      </Link>

      <nav className="flex flex-col gap-1 px-3" aria-label="Módulos">
        {MODULOS.map((m) => {
          const activo = esActivo(pathname, m.href);
          const Icono = m.icono;
          return (
            <Link
              key={m.href}
              href={m.href}
              aria-current={activo ? "page" : undefined}
              className={[
                "flex items-center gap-3 rounded-lg border px-3 py-2.5 text-sm transition",
                activo
                  ? "border-azul bg-azul text-azul-contraste"
                  : "border-transparent text-navy-texto hover:bg-navy-700 hover:text-white",
              ].join(" ")}
            >
              <Icono className="h-5 w-5 shrink-0" />
              <span className="leading-snug">{m.nombre}</span>
            </Link>
          );
        })}
      </nav>

      {/* Pie: herramientas del proyecto (consola de datos y apariencia). */}
      <div className="mt-auto border-t border-white/10 p-3">
        <p className="px-1 pb-2 text-[10px] font-semibold uppercase tracking-wider text-navy-texto/70">
          Proyecto
        </p>
        <div className="flex flex-col gap-1.5">
          <ConsolaDatos variante="lateral" />
          <SelectorPaleta variante="lateral" />
        </div>
        <p className="mt-2.5 px-1 text-[11px] leading-relaxed text-navy-texto/80">
          Historia del Mundial, Ranking FIFA y calendario 2026 en un solo lugar.
        </p>
      </div>
    </aside>
  );
}

export function BarraSuperior() {
  const pathname = usePathname();

  return (
    <header className="sticky top-0 z-20 border-b border-gris-borde bg-superficie/95 backdrop-blur">
      <div className="flex items-center gap-4 px-5 py-3 sm:px-8">
        {/* En móvil sólo el trofeo; el nombre completo no cabe. */}
        <Link href="/" className="flex shrink-0 items-center gap-2 lg:hidden">
          <IconoTrofeo className="h-6 w-6 text-azul" />
          <span className="hidden whitespace-nowrap text-sm font-semibold sm:inline">
            World Cup Data Hub
          </span>
        </Link>
        <span className="hidden text-base font-semibold tracking-tight lg:block">
          World Cup Data Hub
        </span>

        <nav
          className="barra-fina -mb-3 ml-auto flex min-w-0 gap-1 overflow-x-auto pb-0"
          aria-label="Navegación principal"
        >
          {MODULOS.map((m) => {
            const activo = esActivo(pathname, m.href);
            return (
              <Link
                key={m.href}
                href={m.href}
                aria-current={activo ? "page" : undefined}
                className={[
                  "whitespace-nowrap border-b-2 px-3 py-2 text-sm transition",
                  activo
                    ? "border-azul font-semibold text-azul"
                    : "border-transparent text-gris-texto hover:text-tinta",
                ].join(" ")}
              >
                {m.nombre}
              </Link>
            );
          })}
        </nav>

        {/* Sin barra lateral, las herramientas viven aquí. */}
        <div className="flex shrink-0 items-center gap-1 border-l border-gris-borde pl-2 lg:hidden">
          <ConsolaDatos variante="compacto" />
          <SelectorPaleta variante="compacto" />
        </div>
      </div>
    </header>
  );
}
