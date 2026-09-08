"use client";

import { useCallback, useEffect, useRef, useState } from "react";

import { IconoPaleta, IconoPaloma } from "@/components/Icons";
import {
  CLAVE_PALETA,
  PALETAS,
  PALETA_POR_DEFECTO,
  esPaletaValida,
  type Paleta,
} from "@/lib/paletas";

/**
 * Selector de paleta. Escribe `data-paleta` en <html> y guarda la elección en
 * localStorage; el script de `SCRIPT_PALETA` la vuelve a aplicar en la
 * siguiente visita antes del primer pintado, así que no hay parpadeo.
 */
export function SelectorPaleta({ variante }: { variante: "lateral" | "compacto" }) {
  const [paleta, setPaleta] = useState<string>(PALETA_POR_DEFECTO);
  const [abierto, setAbierto] = useState(false);
  const contenedor = useRef<HTMLDivElement>(null);

  // El servidor siempre renderiza la paleta por defecto; en cuanto monta el
  // componente se sincroniza con lo que ya aplicó el script del <head>.
  useEffect(() => {
    const actual = document.documentElement.getAttribute("data-paleta");
    if (esPaletaValida(actual)) setPaleta(actual as string);
  }, []);

  useEffect(() => {
    if (!abierto) return;

    function alHacerClic(evento: MouseEvent) {
      if (!contenedor.current?.contains(evento.target as Node)) setAbierto(false);
    }
    function alTeclear(evento: KeyboardEvent) {
      if (evento.key === "Escape") setAbierto(false);
    }

    document.addEventListener("mousedown", alHacerClic);
    document.addEventListener("keydown", alTeclear);
    return () => {
      document.removeEventListener("mousedown", alHacerClic);
      document.removeEventListener("keydown", alTeclear);
    };
  }, [abierto]);

  const aplicar = useCallback((id: string) => {
    document.documentElement.setAttribute("data-paleta", id);
    setPaleta(id);
    setAbierto(false);
    try {
      localStorage.setItem(CLAVE_PALETA, id);
    } catch {
      // Modo incógnito o almacenamiento bloqueado: la paleta sigue aplicada
      // durante esta visita, solo no se recuerda para la próxima.
    }
  }, []);

  const activa = PALETAS.find((p) => p.id === paleta) ?? PALETAS[0];
  const lateral = variante === "lateral";

  return (
    <div ref={contenedor} className="relative">
      <button
        type="button"
        onClick={() => setAbierto((a) => !a)}
        aria-haspopup="menu"
        aria-expanded={abierto}
        title={`Paleta de colores: ${activa.nombre}`}
        className={
          lateral
            ? "flex w-full items-center gap-2.5 rounded-lg border border-white/10 bg-navy-700/60 px-3 py-2 text-left text-xs font-medium text-navy-texto transition hover:border-white/25 hover:bg-navy-700 hover:text-white"
            : "btn-icono"
        }
      >
        {lateral ? (
          <>
            <IconoPaleta className="h-4 w-4 shrink-0" />
            <span className="min-w-0 flex-1 truncate">Paleta · {activa.nombre}</span>
            <Muestra paleta={activa} />
          </>
        ) : (
          <>
            <IconoPaleta className="h-5 w-5" />
            <span className="sr-only">Cambiar la paleta de colores</span>
          </>
        )}
      </button>

      {abierto ? (
        <div
          role="menu"
          aria-label="Paletas disponibles"
          className={[
            "absolute z-40 w-60 rounded-xl border border-gris-borde bg-superficie p-1.5 shadow-modal",
            lateral ? "bottom-full left-0 mb-2" : "right-0 top-full mt-2",
          ].join(" ")}
        >
          <p className="px-2.5 py-1.5 text-[11px] font-semibold uppercase tracking-wide text-gris-texto">
            Paleta de la página
          </p>
          {PALETAS.map((p) => {
            const seleccionada = p.id === paleta;
            return (
              <button
                key={p.id}
                type="button"
                role="menuitemradio"
                aria-checked={seleccionada}
                onClick={() => aplicar(p.id)}
                className={[
                  "flex w-full items-center gap-2.5 rounded-lg px-2.5 py-2 text-left transition",
                  seleccionada
                    ? "bg-azul-suave text-azul"
                    : "text-tinta hover:bg-gris-suave",
                ].join(" ")}
              >
                <Muestra paleta={p} />
                <span className="min-w-0 flex-1">
                  <span className="block text-sm font-semibold leading-tight">
                    {p.nombre}
                  </span>
                  <span className="block truncate text-[11px] text-gris-texto">
                    {p.descripcion}
                  </span>
                </span>
                {seleccionada ? (
                  <IconoPaloma className="h-4 w-4 shrink-0" aria-hidden="true" />
                ) : null}
              </button>
            );
          })}
        </div>
      ) : null}
    </div>
  );
}

function Muestra({ paleta }: { paleta: Paleta }) {
  return (
    <span
      aria-hidden="true"
      className="flex shrink-0 overflow-hidden rounded-full border border-black/10"
    >
      {paleta.muestra.map((color) => (
        <span
          key={color}
          className="block h-4 w-2.5"
          style={{ backgroundColor: color }}
        />
      ))}
    </span>
  );
}
