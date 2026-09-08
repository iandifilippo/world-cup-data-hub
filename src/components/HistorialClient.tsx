"use client";

import { useMemo, useState } from "react";

import { IconoBuscar, IconoCerrar, IconoTrofeo } from "@/components/Icons";
import { Panel, Vacio } from "@/components/Piezas";
import { fechaCorta, normalizar, numero } from "@/lib/format";
import type { Edicion, PartidoHistoricoDetallado } from "@/lib/types";

const POR_PAGINA = 5;

type Orden =
  | "anio-asc"
  | "anio-desc"
  | "asistencia-desc"
  | "campeon-asc";

const ORDENES: { valor: Orden; texto: string }[] = [
  { valor: "anio-asc", texto: "Año (ascendente)" },
  { valor: "anio-desc", texto: "Año (descendente)" },
  { valor: "asistencia-desc", texto: "Mayor asistencia total" },
  { valor: "campeon-asc", texto: "Campeón (A–Z)" },
];

export function HistorialClient({
  ediciones,
  partidos,
}: {
  ediciones: Edicion[];
  partidos: PartidoHistoricoDetallado[];
}) {
  const [decada, setDecada] = useState<string>("");
  const [desde, setDesde] = useState<string>("");
  const [hasta, setHasta] = useState<string>("");
  const [busqueda, setBusqueda] = useState<string>("");
  const [orden, setOrden] = useState<Orden>("anio-asc");
  const [pagina, setPagina] = useState<number>(1);
  const [detalle, setDetalle] = useState<Edicion | null>(null);

  const decadas = useMemo(
    () => Array.from(new Set(ediciones.map((e) => e.decada))).sort((a, b) => a - b),
    [ediciones],
  );

  const rangoAnios = useMemo(() => {
    const anios = ediciones.map((e) => e.anio);
    return { min: Math.min(...anios), max: Math.max(...anios) };
  }, [ediciones]);

  const filtradas = useMemo(() => {
    const q = normalizar(busqueda);
    const min = desde ? Number(desde) : rangoAnios.min;
    const max = hasta ? Number(hasta) : rangoAnios.max;

    const lista = ediciones.filter((e) => {
      // RF03 — filtro por década
      if (decada && e.decada !== Number(decada)) return false;
      // Filtro por rango de años
      if (e.anio < min || e.anio > max) return false;
      // RF04 — búsqueda por país sede, campeón o subcampeón
      if (q) {
        const campos = [e.pais_sede, e.sede, e.campeon, e.subcampeon, e.goleador];
        if (!campos.some((c) => normalizar(c).includes(q))) return false;
      }
      return true;
    });

    const ordenada = [...lista];
    ordenada.sort((a, b) => {
      switch (orden) {
        case "anio-desc":
          return b.anio - a.anio;
        case "asistencia-desc":
          return b.asistencia_total - a.asistencia_total;
        case "campeon-asc":
          return a.campeon.localeCompare(b.campeon, "es") || a.anio - b.anio;
        default:
          return a.anio - b.anio;
      }
    });
    return ordenada;
  }, [ediciones, decada, desde, hasta, busqueda, orden, rangoAnios]);

  const totalPaginas = Math.max(1, Math.ceil(filtradas.length / POR_PAGINA));
  const paginaActual = Math.min(pagina, totalPaginas);
  const visibles = filtradas.slice(
    (paginaActual - 1) * POR_PAGINA,
    paginaActual * POR_PAGINA,
  );

  function reiniciar<T>(setter: (v: T) => void) {
    return (v: T) => {
      setter(v);
      setPagina(1);
    };
  }

  const partidosDetalle = detalle
    ? partidos.filter((p) => p.anio === detalle.anio)
    : [];

  return (
    <>
      {/* Filtros */}
      <Panel className="mb-5">
        <div className="grid gap-4 p-5 lg:grid-cols-[1.2fr_1.4fr_1fr]">
          <div>
            <span className="etiqueta-campo">Filtrar por década / años</span>
            <div className="flex gap-2">
              <select
                aria-label="Década"
                className="campo"
                value={decada}
                onChange={(e) => reiniciar(setDecada)(e.target.value)}
              >
                <option value="">Década</option>
                {decadas.map((d) => (
                  <option key={d} value={d}>
                    {d}s
                  </option>
                ))}
              </select>
              <input
                aria-label="Desde el año"
                className="campo cifras"
                type="number"
                inputMode="numeric"
                placeholder={`Desde ${rangoAnios.min}`}
                value={desde}
                onChange={(e) => reiniciar(setDesde)(e.target.value)}
              />
              <input
                aria-label="Hasta el año"
                className="campo cifras"
                type="number"
                inputMode="numeric"
                placeholder={`Hasta ${rangoAnios.max}`}
                value={hasta}
                onChange={(e) => reiniciar(setHasta)(e.target.value)}
              />
            </div>
          </div>

          <div>
            <label className="etiqueta-campo" htmlFor="buscar-edicion">
              Buscar
            </label>
            <div className="relative">
              <input
                id="buscar-edicion"
                className="campo pr-10"
                type="search"
                placeholder="País, campeón o subcampeón…"
                value={busqueda}
                onChange={(e) => reiniciar(setBusqueda)(e.target.value)}
              />
              <IconoBuscar className="pointer-events-none absolute right-3 top-2.5 h-4 w-4 text-gris-texto" />
            </div>
          </div>

          <div>
            <label className="etiqueta-campo" htmlFor="ordenar-edicion">
              Ordenar por
            </label>
            <select
              id="ordenar-edicion"
              className="campo"
              value={orden}
              onChange={(e) => setOrden(e.target.value as Orden)}
            >
              {ORDENES.map((o) => (
                <option key={o.valor} value={o.valor}>
                  {o.texto}
                </option>
              ))}
            </select>
          </div>
        </div>
      </Panel>

      {/* Tabla */}
      <Panel>
        {visibles.length === 0 ? (
          <Vacio
            mensaje="Ninguna edición coincide con esos filtros."
            accion="Amplía el rango de años o borra el texto de búsqueda."
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse">
              <thead className="border-b border-gris-borde bg-gris-suave">
                <tr>
                  <th className="th">Año</th>
                  <th className="th">Sede</th>
                  <th className="th">Equipos</th>
                  <th className="th">Campeón</th>
                  <th className="th">Subcampeón</th>
                  <th className="th">Goleador</th>
                  <th className="th">Asistencia total</th>
                  <th className="th">Prom. asist.</th>
                  <th className="th">Partidos</th>
                  <th className="th sr-only">Detalle</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gris-borde">
                {visibles.map((e) => (
                  <tr key={e.id_edicion} className="fila transition">
                    <td className="td cifras font-semibold">{e.anio}</td>
                    <td className="td">{e.pais_sede}</td>
                    <td className="td cifras">{e.equipos}</td>
                    <td className="td font-medium">{e.campeon}</td>
                    <td className="td">{e.subcampeon}</td>
                    <td className="td">{e.goleador}</td>
                    <td className="td cifras">{numero(e.asistencia_total)}</td>
                    <td className="td cifras">{numero(e.promedio_asistencia)}</td>
                    <td className="td cifras">{e.partidos}</td>
                    <td className="td text-right">
                      <button
                        type="button"
                        onClick={() => setDetalle(e)}
                        className="rounded-md border border-gris-borde px-2.5 py-1 text-xs font-semibold text-azul transition hover:bg-azul-suave"
                      >
                        Ver
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Paginación */}
        {filtradas.length > POR_PAGINA ? (
          <nav
            aria-label="Paginación del historial"
            className="flex items-center justify-center gap-1 border-t border-gris-borde px-5 py-3"
          >
            <BotonPagina
              etiqueta="Página anterior"
              texto="«"
              onClick={() => setPagina(Math.max(1, paginaActual - 1))}
              deshabilitado={paginaActual === 1}
            />
            {Array.from({ length: totalPaginas }, (_, i) => i + 1).map((n) => (
              <BotonPagina
                key={n}
                etiqueta={`Ir a la página ${n}`}
                texto={String(n)}
                activo={n === paginaActual}
                onClick={() => setPagina(n)}
              />
            ))}
            <BotonPagina
              etiqueta="Página siguiente"
              texto="»"
              onClick={() => setPagina(Math.min(totalPaginas, paginaActual + 1))}
              deshabilitado={paginaActual === totalPaginas}
            />
          </nav>
        ) : null}
      </Panel>

      {/* RF05 — detalle expandible de la edición */}
      {detalle ? (
        <Panel
          className="mt-5"
          titulo={`Detalle del torneo — ${detalle.pais_sede} ${detalle.anio}`}
          accion={
            <button
              type="button"
              onClick={() => setDetalle(null)}
              aria-label="Cerrar el detalle del torneo"
              className="rounded-md p-1 text-gris-texto transition hover:bg-slate-100 hover:text-tinta"
            >
              <IconoCerrar className="h-4 w-4" />
            </button>
          }
        >
          <div className="grid gap-5 p-5 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.7fr)]">
            <div className="flex gap-4">
              <IconoTrofeo className="h-14 w-14 shrink-0 text-amber-400" />
              <dl className="space-y-1 text-sm">
                <Fila k="Sede" v={detalle.sede} />
                <Fila k="Campeón" v={detalle.campeon} fuerte />
                <Fila k="Subcampeón" v={detalle.subcampeon} />
                <Fila
                  k="Goleador"
                  v={`${detalle.goleador} (${detalle.goles_goleador} goles)`}
                />
                <Fila k="Asistencia total" v={numero(detalle.asistencia_total)} />
                <Fila
                  k="Promedio asistencia"
                  v={numero(detalle.promedio_asistencia)}
                />
                <Fila k="Partidos" v={String(detalle.partidos)} />
                <Fila k="Equipos" v={String(detalle.equipos)} />
              </dl>
            </div>

            <div>
              <h3 className="mb-2 text-[13px] font-semibold uppercase tracking-wide text-gris-texto">
                Partidos del torneo
              </h3>
              {partidosDetalle.length === 0 ? (
                <p className="rounded-lg border border-dashed border-gris-borde px-4 py-8 text-center text-sm text-gris-texto">
                  Todavía no hay partidos cargados para esta edición.
                </p>
              ) : (
                <div className="max-h-80 overflow-auto rounded-lg border border-gris-borde">
                  <table className="w-full border-collapse">
                    <thead className="sticky top-0 border-b border-gris-borde bg-gris-suave">
                      <tr>
                        <th className="th">Fecha</th>
                        <th className="th">Local</th>
                        <th className="th">Resultado</th>
                        <th className="th">Visitante</th>
                        <th className="th">Fase</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gris-borde">
                      {partidosDetalle.map((p) => (
                        <tr key={p.id_partido}>
                          <td className="td cifras text-xs">{fechaCorta(p.fecha)}</td>
                          <td className="td">{p.equipo_local}</td>
                          <td className="td cifras font-semibold">
                            {p.goles_local} - {p.goles_visitante}
                            {p.nota ? (
                              <span className="ml-2 font-normal text-xs text-gris-texto">
                                {p.nota}
                              </span>
                            ) : null}
                          </td>
                          <td className="td">{p.equipo_visitante}</td>
                          <td className="td text-xs text-gris-texto">{p.fase}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
              <p className="mt-2 text-xs text-gris-texto">
                Se muestran los partidos cargados en la base para esta edición.
              </p>
            </div>
          </div>
        </Panel>
      ) : null}
    </>
  );
}

function Fila({ k, v, fuerte }: { k: string; v: string; fuerte?: boolean }) {
  return (
    <div className="flex gap-2">
      <dt className="text-gris-texto">{k}:</dt>
      <dd className={fuerte ? "font-semibold" : undefined}>{v}</dd>
    </div>
  );
}

function BotonPagina({
  texto,
  etiqueta,
  onClick,
  activo,
  deshabilitado,
}: {
  texto: string;
  etiqueta: string;
  onClick: () => void;
  activo?: boolean;
  deshabilitado?: boolean;
}) {
  return (
    <button
      type="button"
      aria-label={etiqueta}
      aria-current={activo ? "page" : undefined}
      disabled={deshabilitado}
      onClick={onClick}
      className={[
        "cifras min-w-8 rounded-md px-2.5 py-1 text-sm transition",
        activo
          ? "bg-azul font-semibold text-white"
          : "text-gris-texto hover:bg-slate-100 hover:text-tinta",
        deshabilitado ? "cursor-not-allowed opacity-40 hover:bg-transparent" : "",
      ].join(" ")}
    >
      {texto}
    </button>
  );
}
