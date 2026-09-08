"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ReactNode } from "react";

import {
  IconoCalendario,
  IconoHistorial,
  IconoInicio,
  IconoRanking,
  IconoTrofeo,
} from "@/components/Icons";

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

export function BarraLateral() {
  const pathname = usePathname();

  return (
    <aside className="hidden w-64 shrink-0 flex-col bg-navy-800 lg:flex">
      <Link
        href="/"
        className="flex items-center gap-3 px-6 py-7 text-white transition hover:opacity-90"
      >
        <IconoTrofeo className="h-8 w-8 shrink-0 text-amber-300" />
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
                "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm transition",
                activo
                  ? "bg-azul text-white"
                  : "text-slate-300 hover:bg-navy-700 hover:text-white",
              ].join(" ")}
            >
              <Icono className="h-5 w-5 shrink-0" />
              <span className="leading-snug">{m.nombre}</span>
            </Link>
          );
        })}
      </nav>

      <p className="mt-auto m-4 rounded-lg bg-navy-700/70 p-4 text-xs leading-relaxed text-slate-300">
        Toda la historia del Mundial, el Ranking FIFA y el calendario 2026 en un
        solo lugar.
      </p>
    </aside>
  );
}

export function BarraSuperior() {
  const pathname = usePathname();

  return (
    <header className="sticky top-0 z-20 border-b border-gris-borde bg-white/95 backdrop-blur">
      <div className="flex items-center gap-6 px-5 py-3 sm:px-8">
        <Link href="/" className="flex items-center gap-2 lg:hidden">
          <IconoTrofeo className="h-6 w-6 text-azul" />
          <span className="text-sm font-semibold">World Cup Data Hub</span>
        </Link>
        <span className="hidden text-base font-semibold tracking-tight lg:block">
          World Cup Data Hub
        </span>

        <nav
          className="-mb-3 ml-auto flex gap-1 overflow-x-auto pb-0"
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
      </div>
    </header>
  );
}
