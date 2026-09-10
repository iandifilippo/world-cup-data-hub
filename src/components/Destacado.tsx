"use client";

import { useState, type ReactNode } from "react";

import {
  IconoAsistencia,
  IconoBalon,
  IconoEstadio,
  IconoTrofeo,
} from "@/components/Icons";
import { Panel, Renglon } from "@/components/Piezas";
import { numero } from "@/lib/format";
import type { Edicion } from "@/lib/types";

/** Edición que se muestra al abrir la página. */
const ANIO_INICIAL = 1970;

/**
 * RF11 — destacado histórico. Muestra una edición a la vez; el desplegable de
 * abajo permite saltar a cualquiera de las 23.
 */
export function Destacado({ ediciones }: { ediciones: Edicion[] }) {
  const [anio, setAnio] = useState(ANIO_INICIAL);

  // Si la edición inicial no existe en los datos, se cae a la primera.
  const edicion = ediciones.find((e) => e.anio === anio) ?? ediciones[0];
  if (!edicion) return null;

  return (
    <Panel titulo="Destacado histórico">
      <div className="grid gap-5 p-5 lg:grid-cols-[minmax(0,260px)_minmax(0,1fr)]">
        {/* Identidad de la edición: trofeo, año y ficha básica. */}
        <div>
          <div className="flex items-center gap-4">
            <IconoTrofeo className="h-14 w-14 shrink-0 text-acento" />
            <div className="min-w-0">
              <p className="text-xl font-bold leading-tight tracking-tight">
                {edicion.pais_sede} {edicion.anio}
              </p>
              <p className="mt-1 flex items-center gap-1.5 text-xs text-gris-texto">
                <IconoEstadio className="h-3.5 w-3.5 shrink-0" />
                <span className="truncate">{edicion.sede}</span>
              </p>
            </div>
          </div>

          <dl className="mt-4 divide-y divide-gris-borde rounded-lg border border-gris-borde text-sm">
            <Renglon etiqueta="Campeón" valor={edicion.campeon} fuerte />
            <Renglon etiqueta="Subcampeón" valor={edicion.subcampeon} />
            <Renglon etiqueta="Equipos" valor={edicion.equipos} />
          </dl>
        </div>

        {/* Cifras del torneo. Como en el mockup, van en una fila de tarjetas
            que pasa a dos columnas cuando no cabe. */}
        <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
          <Dato
            icono={<IconoBalon className="h-4 w-4" />}
            etiqueta="Goleador"
            valor={edicion.goleador}
            pie={`${edicion.goles_goleador} goles`}
          />
          <Dato
            icono={<IconoAsistencia className="h-4 w-4" />}
            etiqueta="Asistencia total"
            valor={numero(edicion.asistencia_total)}
          />
          <Dato
            icono={<IconoAsistencia className="h-4 w-4" />}
            etiqueta="Promedio asistencia"
            valor={numero(edicion.promedio_asistencia)}
          />
          <Dato
            icono={<IconoBalon className="h-4 w-4" />}
            etiqueta="Partidos"
            valor={String(edicion.partidos)}
            pie={`${edicion.equipos} equipos`}
          />
        </div>
      </div>

      <div className="flex flex-wrap items-center gap-3 border-t border-gris-borde px-5 py-3">
        <label className="text-xs text-gris-texto" htmlFor="destacado-edicion">
          Ver otra edición
        </label>
        <select
          id="destacado-edicion"
          className="campo max-w-xs flex-1"
          value={edicion.anio}
          onChange={(evento) => setAnio(Number(evento.target.value))}
        >
          {ediciones.map((e) => (
            <option key={e.id_edicion} value={e.anio}>
              {e.pais_sede} {e.anio}
            </option>
          ))}
        </select>
      </div>
    </Panel>
  );
}

/** Una cifra del torneo con su icono. */
function Dato({
  icono,
  etiqueta,
  valor,
  pie,
}: {
  icono: ReactNode;
  etiqueta: string;
  valor: string | number;
  pie?: string;
}) {
  return (
    <div className="rounded-lg border border-gris-borde p-3">
      <p className="flex items-start gap-1.5 text-[11px] font-semibold uppercase leading-tight tracking-wide text-gris-texto">
        <span className="mt-px shrink-0 text-azul">{icono}</span>
        <span>{etiqueta}</span>
      </p>
      <p className="cifras mt-1.5 text-sm font-semibold leading-tight">{valor}</p>
      {pie ? <p className="mt-0.5 text-xs text-gris-texto">{pie}</p> : null}
    </div>
  );
}
