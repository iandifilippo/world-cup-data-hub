"use client";

import { useEffect, useState, type ReactNode } from "react";

import {
  IconoAnterior,
  IconoAsistencia,
  IconoBalon,
  IconoEstadio,
  IconoPausa,
  IconoReproducir,
  IconoSiguiente,
  IconoTrofeo,
} from "@/components/Icons";
import { Panel } from "@/components/Piezas";
import { numero } from "@/lib/format";
import type { Edicion } from "@/lib/types";

const INTERVALO_MS = 12_000;

/**
 * RF11 — destaca un hito histórico. La rotación automática está apagada de
 * salida: antes el panel cambiaba solo cada 12 s y había que pausarlo a mano
 * para poder leerlo. Ahora se navega con los controles y quien quiera el
 * carrusel lo enciende con el botón de reproducir.
 */
export function Destacado({ ediciones }: { ediciones: Edicion[] }) {
  const inicial = Math.max(
    0,
    ediciones.findIndex((e) => e.anio === 1970),
  );
  const [indice, setIndice] = useState(inicial);
  const [rotando, setRotando] = useState(false);

  useEffect(() => {
    if (!rotando || ediciones.length < 2) return;
    const t = window.setInterval(() => {
      setIndice((i) => (i + 1) % ediciones.length);
    }, INTERVALO_MS);
    return () => window.clearInterval(t);
  }, [rotando, ediciones.length]);

  const e = ediciones[indice];
  if (!e) return null;

  const mover = (paso: number) =>
    setIndice((i) => (i + paso + ediciones.length) % ediciones.length);

  return (
    <Panel
      titulo="Destacado histórico"
      accion={
        <div className="flex items-center gap-0.5">
          <button
            type="button"
            onClick={() => mover(-1)}
            aria-label="Edición anterior"
            className="btn-icono"
          >
            <IconoAnterior className="h-4 w-4" />
          </button>
          <button
            type="button"
            onClick={() => setRotando((r) => !r)}
            aria-pressed={rotando}
            aria-label={
              rotando ? "Detener la rotación automática" : "Rotar automáticamente"
            }
            title={
              rotando
                ? "Detener la rotación automática"
                : "Ver las ediciones una tras otra"
            }
            className={`btn-icono ${rotando ? "bg-azul-suave text-azul" : ""}`}
          >
            {rotando ? (
              <IconoPausa className="h-4 w-4" />
            ) : (
              <IconoReproducir className="h-4 w-4" />
            )}
          </button>
          <button
            type="button"
            onClick={() => mover(1)}
            aria-label="Edición siguiente"
            className="btn-icono"
          >
            <IconoSiguiente className="h-4 w-4" />
          </button>
        </div>
      }
    >
      <div className="p-5">
        <div className="flex items-center gap-4">
          <IconoTrofeo className="h-14 w-14 shrink-0 text-acento" />
          <div className="min-w-0">
            <p className="text-xl font-bold leading-tight tracking-tight">
              {e.pais_sede} {e.anio}
            </p>
            <p className="mt-1 flex items-center gap-1.5 text-xs text-gris-texto">
              <IconoEstadio className="h-3.5 w-3.5 shrink-0" />
              <span className="truncate">{e.sede}</span>
            </p>
          </div>
        </div>

        <dl className="mt-4 divide-y divide-gris-borde rounded-lg border border-gris-borde text-sm">
          <Renglon k="Campeón" v={e.campeon} fuerte />
          <Renglon k="Subcampeón" v={e.subcampeon} />
          <Renglon k="Equipos" v={String(e.equipos)} />
        </dl>

        <div className="mt-4 grid grid-cols-2 gap-3">
          <Dato
            icono={<IconoBalon className="h-4 w-4" />}
            etiqueta="Goleador"
            valor={e.goleador}
            pie={`${e.goles_goleador} goles`}
          />
          <Dato
            icono={<IconoBalon className="h-4 w-4" />}
            etiqueta="Partidos"
            valor={String(e.partidos)}
            pie={`${e.equipos} equipos`}
          />
          <Dato
            icono={<IconoAsistencia className="h-4 w-4" />}
            etiqueta="Asistencia total"
            valor={numero(e.asistencia_total)}
          />
          <Dato
            icono={<IconoAsistencia className="h-4 w-4" />}
            etiqueta="Promedio asistencia"
            valor={numero(e.promedio_asistencia)}
          />
        </div>
      </div>

      {/* Salto directo a cualquier edición: con 22 ediciones, ir de una en una
          con las flechas era el único camino. */}
      <div className="flex items-center gap-3 border-t border-gris-borde px-5 py-3">
        <label className="sr-only" htmlFor="destacado-edicion">
          Elegir la edición destacada
        </label>
        <select
          id="destacado-edicion"
          className="campo"
          value={indice}
          onChange={(evento) => {
            setIndice(Number(evento.target.value));
            setRotando(false);
          }}
        >
          {ediciones.map((edicion, i) => (
            <option key={edicion.id_edicion} value={i}>
              {edicion.pais_sede} {edicion.anio}
            </option>
          ))}
        </select>
        <span className="cifras shrink-0 text-xs text-gris-texto">
          {indice + 1}/{ediciones.length}
        </span>
      </div>
    </Panel>
  );
}

function Renglon({ k, v, fuerte }: { k: string; v: string; fuerte?: boolean }) {
  return (
    <div className="flex items-center justify-between gap-3 px-3.5 py-2">
      <dt className="text-gris-texto">{k}</dt>
      <dd className={`truncate ${fuerte ? "font-semibold" : "font-medium"}`}>{v}</dd>
    </div>
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
      <p className="flex items-start gap-1.5 text-[11px] font-semibold uppercase leading-tight tracking-wide text-gris-texto">
        <span className="mt-px shrink-0 text-azul">{icono}</span>
        <span>{etiqueta}</span>
      </p>
      <p className="cifras mt-1.5 text-sm font-semibold leading-tight">{valor}</p>
      {pie ? <p className="mt-0.5 text-xs text-gris-texto">{pie}</p> : null}
    </div>
  );
}
