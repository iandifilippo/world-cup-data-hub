"use client";

import { useEffect, useState, type ReactNode } from "react";

import { IconoAsistencia, IconoBalon, IconoTrofeo } from "@/components/Icons";
import { Panel } from "@/components/Piezas";
import { numero } from "@/lib/format";
import type { Edicion } from "@/lib/types";

const INTERVALO_MS = 12_000;

/**
 * RF11 — destaca de forma rotativa un hito histórico. Arranca siempre en
 * Brasil 1970 (la edición usada en los mockups) y va cambiando cada 12 s;
 * el usuario también puede pasar de una a otra con los controles.
 */
export function Destacado({ ediciones }: { ediciones: Edicion[] }) {
  const inicial = Math.max(
    0,
    ediciones.findIndex((e) => e.anio === 1970),
  );
  const [indice, setIndice] = useState(inicial);
  const [pausado, setPausado] = useState(false);

  useEffect(() => {
    if (pausado || ediciones.length < 2) return;
    const t = window.setInterval(() => {
      setIndice((i) => (i + 1) % ediciones.length);
    }, INTERVALO_MS);
    return () => window.clearInterval(t);
  }, [pausado, ediciones.length]);

  const e = ediciones[indice];
  if (!e) return null;

  return (
    <Panel
      titulo="Destacado histórico"
      accion={
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => setPausado((p) => !p)}
            className="rounded-md px-2 py-1 text-xs font-semibold text-gris-texto transition hover:bg-slate-100 hover:text-tinta"
          >
            {pausado ? "Reanudar" : "Pausar"}
          </button>
          <button
            type="button"
            onClick={() => setIndice((i) => (i + 1) % ediciones.length)}
            className="rounded-md px-2 py-1 text-xs font-semibold text-azul transition hover:bg-azul-suave"
          >
            Siguiente edición
          </button>
        </div>
      }
    >
      <div className="grid gap-5 p-5 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.6fr)]">
        <div className="flex items-center gap-4">
          <IconoTrofeo className="h-16 w-16 shrink-0 text-amber-400" />
          <div>
            <p className="text-xl font-bold tracking-tight">
              {e.pais_sede} {e.anio}
            </p>
            <dl className="mt-2 space-y-0.5 text-sm text-gris-texto">
              <div className="flex gap-2">
                <dt>Sede:</dt>
                <dd className="text-tinta">{e.sede}</dd>
              </div>
              <div className="flex gap-2">
                <dt>Campeón:</dt>
                <dd className="font-medium text-tinta">{e.campeon}</dd>
              </div>
              <div className="flex gap-2">
                <dt>Subcampeón:</dt>
                <dd className="text-tinta">{e.subcampeon}</dd>
              </div>
            </dl>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          <Dato
            icono={<IconoBalon className="h-5 w-5" />}
            etiqueta="Goleador"
            valor={e.goleador}
            pie={`${e.goles_goleador} goles`}
          />
          <Dato
            icono={<IconoAsistencia className="h-5 w-5" />}
            etiqueta="Asistencia total"
            valor={numero(e.asistencia_total)}
          />
          <Dato
            icono={<IconoAsistencia className="h-5 w-5" />}
            etiqueta="Promedio asistencia"
            valor={numero(e.promedio_asistencia)}
          />
          <Dato
            icono={<IconoBalon className="h-5 w-5" />}
            etiqueta="Partidos"
            valor={String(e.partidos)}
            pie={`${e.equipos} equipos`}
          />
        </div>
      </div>
    </Panel>
  );
}

function Dato({
  icono,
  etiqueta,
  valor,
  pie,
}: {
  icono: ReactNode;
  etiqueta: string;
  valor: string;
  pie?: string;
}) {
  return (
    <div className="rounded-lg border border-gris-borde p-3">
      <p className="text-[11px] font-semibold uppercase tracking-wide text-gris-texto">
        {etiqueta}
      </p>
      <div className="mt-2 flex items-center gap-2 text-azul">{icono}</div>
      <p className="cifras mt-1 text-sm font-semibold leading-tight">{valor}</p>
      {pie ? <p className="mt-0.5 text-xs text-gris-texto">{pie}</p> : null}
    </div>
  );
}
