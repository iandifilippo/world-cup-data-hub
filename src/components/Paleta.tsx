"use client";

import { useEffect, useState } from "react";

import { IconoPaleta } from "@/components/Icons";
import {
  CLAVE_PALETA,
  PALETAS,
  PALETA_POR_DEFECTO,
  esPaletaValida,
} from "@/lib/paletas";

/** Nombre del evento con el que las dos copias del selector se avisan entre sí. */
const EVENTO = "wcdh:paleta";

/**
 * Estado de la paleta activa.
 *
 * El servidor siempre pinta "clasico" (así el HTML sale coloreado sin esperar
 * a JavaScript). Al montar, este hook lee la paleta que quedó guardada en
 * `localStorage` y, si es distinta, la aplica escribiendo `data-paleta` en
 * <html>. `cambiar()` hace lo mismo y además avisa por un evento a la otra
 * copia del selector (la de la barra lateral y la de la barra superior) para
 * que las dos muestren siempre lo mismo.
 */
function usePaleta() {
  const [paleta, setPaleta] = useState<string>(PALETA_POR_DEFECTO);

  useEffect(() => {
    const guardada = localStorage.getItem(CLAVE_PALETA);
    if (esPaletaValida(guardada)) {
      setPaleta(guardada);
      document.documentElement.setAttribute("data-paleta", guardada);
    }

    const alCambiar = (e: Event) => setPaleta((e as CustomEvent<string>).detail);
    window.addEventListener(EVENTO, alCambiar);
    return () => window.removeEventListener(EVENTO, alCambiar);
  }, []);

  function cambiar(id: string) {
    document.documentElement.setAttribute("data-paleta", id);
    setPaleta(id);
    try {
      localStorage.setItem(CLAVE_PALETA, id);
    } catch {
      // Almacenamiento bloqueado (modo incógnito): la paleta se aplica igual,
      // sólo no se recuerda para la próxima visita.
    }
    window.dispatchEvent(new CustomEvent(EVENTO, { detail: id }));
  }

  return { paleta, cambiar };
}

/**
 * Selector de paleta. En la barra lateral es un grupo de radios (`<fieldset>`
 * + `<legend>`) que enseña las cinco opciones a la vez; en la barra superior,
 * donde hay menos sitio, es un `<select>`. Los dos controles son nativos: el
 * navegador ya sabe moverse entre ellos con el teclado.
 */
export function SelectorPaleta({ variante }: { variante: "lateral" | "compacto" }) {
  const { paleta, cambiar } = usePaleta();

  if (variante === "compacto") {
    return (
      <div>
        <label className="sr-only" htmlFor="paleta-compacta">
          Paleta de colores
        </label>
        <select
          id="paleta-compacta"
          className="campo w-auto max-w-[7.5rem] py-1.5 pr-7 text-xs"
          value={paleta}
          onChange={(e) => cambiar(e.target.value)}
        >
          {PALETAS.map((p) => (
            <option key={p.id} value={p.id}>
              {p.nombre}
            </option>
          ))}
        </select>
      </div>
    );
  }

  return (
    <fieldset className="mt-1">
      <legend className="flex items-center gap-2 px-1 pb-1.5 text-[10px] font-semibold uppercase tracking-wider text-navy-texto/70">
        <IconoPaleta className="h-3.5 w-3.5" aria-hidden="true" />
        Paleta de colores
      </legend>
      <div className="flex flex-col gap-0.5">
        {PALETAS.map((p) => (
          <label
            key={p.id}
            title={p.descripcion}
            className="flex cursor-pointer items-center gap-2.5 rounded-lg px-2 py-1.5 text-xs
                       text-navy-texto transition hover:bg-navy-700
                       has-[:checked]:bg-navy-700 has-[:checked]:font-semibold has-[:checked]:text-white"
          >
            <input
              type="radio"
              name="paleta"
              value={p.id}
              checked={paleta === p.id}
              onChange={() => cambiar(p.id)}
              className="h-3.5 w-3.5 shrink-0 accent-azul-claro"
            />
            <Muestra colores={p.muestra} />
            <span className="min-w-0 flex-1 truncate">{p.nombre}</span>
          </label>
        ))}
      </div>
    </fieldset>
  );
}

/** Tres franjas con los colores característicos de la paleta. */
function Muestra({ colores }: { colores: readonly string[] }) {
  return (
    <span
      aria-hidden="true"
      className="flex shrink-0 overflow-hidden rounded border border-white/20"
    >
      {colores.map((c) => (
        <span key={c} className="block h-3.5 w-2" style={{ backgroundColor: c }} />
      ))}
    </span>
  );
}
