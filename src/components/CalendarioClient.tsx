"use client";

import { useMemo, useState, type ReactNode } from "react";

import { IconoBuscar, IconoCerrar, IconoEstadio } from "@/components/Icons";
import { Bandera, Insignia, Panel, Vacio } from "@/components/Piezas";
import { claveMes, fechaCorta, mesLargo, normalizar, puntos } from "@/lib/format";
import type { Fase, PartidoCalendario } from "@/lib/types";

const FASES: Fase[] = [
  "Fase de Grupos",
  "Dieciseisavos de Final",
  "Octavos de Final",
  "Cuartos de Final",
  "Semifinal",
  "Tercer Lugar",
  "Final",
];

const LOTE = 12;

type Vista = "tarjetas" | "calendario";

export function CalendarioClient({ partidos }: { partidos: PartidoCalendario[] }) {
  const [desde, setDesde] = useState("");
  const [hasta, setHasta] = useState("");
  const [equipo, setEquipo] = useState("");
  const [fase, setFase] = useState("");
  const [busqueda, setBusqueda] = useState("");
  const [vista, setVista] = useState<Vista>("tarjetas");
  const [mostrar, setMostrar] = useState(LOTE);
  const [detalle, setDetalle] = useState<PartidoCalendario | null>(null);

  const equipos = useMemo(() => {
    const set = new Set<string>();
    for (const p of partidos) {
      if (p.codigo_local) set.add(p.equipo_local);
      if (p.codigo_visitante) set.add(p.equipo_visitante);
    }
    return Array.from(set).sort((a, b) => a.localeCompare(b, "es"));
  }, [partidos]);

  // RF09 — filtros por fecha, equipo y fase (se combinan entre sí)
  const filtrados = useMemo(() => {
    const q = normalizar(busqueda);
    return partidos.filter((p) => {
      if (desde && p.fecha < desde) return false;
      if (hasta && p.fecha > hasta) return false;
      if (fase && p.fase !== fase) return false;
      if (equipo && p.equipo_local !== equipo && p.equipo_visitante !== equipo) {
        return false;
      }
      if (q) {
        const campos = [
          p.equipo_local,
          p.equipo_visitante,
          p.nombre_estadio,
          p.ciudad,
        ];
        if (!campos.some((c) => normalizar(c).includes(q))) return false;
      }
      return true;
    });
  }, [partidos, desde, hasta, equipo, fase, busqueda]);

  const visibles = filtrados.slice(0, mostrar);

  // RF08 — la vista de calendario agrupa por mes y día sin perder los filtros
  const porMes = useMemo(() => {
    const mapa = new Map<string, PartidoCalendario[]>();
    for (const p of filtrados) {
      const k = claveMes(p.fecha);
      const lista = mapa.get(k);
      if (lista) lista.push(p);
      else mapa.set(k, [p]);
    }
    return Array.from(mapa.entries()).sort((a, b) => a[0].localeCompare(b[0]));
  }, [filtrados]);

  function limpiar() {
    setDesde("");
    setHasta("");
    setEquipo("");
    setFase("");
    setBusqueda("");
    setMostrar(LOTE);
  }

  const hayFiltros = Boolean(desde || hasta || equipo || fase || busqueda);

  return (
    <>
      <Panel className="mb-5">
        <div className="grid gap-4 p-5 lg:grid-cols-4">
          <div>
            <span className="etiqueta-campo">Filtrar por fecha</span>
            <div className="flex items-center gap-2">
              <input
                aria-label="Desde la fecha"
                type="date"
                className="campo"
                min="2026-06-11"
                max="2026-07-19"
                value={desde}
                onChange={(e) => {
                  setDesde(e.target.value);
                  setMostrar(LOTE);
                }}
              />
              <span className="text-gris-texto">–</span>
              <input
                aria-label="Hasta la fecha"
                type="date"
                className="campo"
                min="2026-06-11"
                max="2026-07-19"
                value={hasta}
                onChange={(e) => {
                  setHasta(e.target.value);
                  setMostrar(LOTE);
                }}
              />
            </div>
          </div>

          <div>
            <label className="etiqueta-campo" htmlFor="equipo">
              Filtrar por equipo
            </label>
            <select
              id="equipo"
              className="campo"
              value={equipo}
              onChange={(e) => {
                setEquipo(e.target.value);
                setMostrar(LOTE);
              }}
            >
              <option value="">Todos</option>
              {equipos.map((e) => (
                <option key={e} value={e}>
                  {e}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="etiqueta-campo" htmlFor="fase">
              Filtrar por fase
            </label>
            <select
              id="fase"
              className="campo"
              value={fase}
              onChange={(e) => {
                setFase(e.target.value);
                setMostrar(LOTE);
              }}
            >
              <option value="">Todas</option>
              {FASES.map((f) => (
                <option key={f} value={f}>
                  {f}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="etiqueta-campo" htmlFor="buscar-partido">
              Buscar equipo o sede
            </label>
            <div className="relative">
              <input
                id="buscar-partido"
                className="campo pr-10"
                type="search"
                placeholder="Buscar equipo…"
                value={busqueda}
                onChange={(e) => {
                  setBusqueda(e.target.value);
                  setMostrar(LOTE);
                }}
              />
              <IconoBuscar className="pointer-events-none absolute right-3 top-2.5 h-4 w-4 text-gris-texto" />
            </div>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-2 border-t border-gris-borde px-5 py-3">
          <BotonVista activo={vista === "tarjetas"} onClick={() => setVista("tarjetas")}>
            Vista tarjetas
          </BotonVista>
          <BotonVista
            activo={vista === "calendario"}
            onClick={() => setVista("calendario")}
          >
            Vista calendario
          </BotonVista>
          <p className="ml-auto text-xs text-gris-texto">
            {filtrados.length} de {partidos.length} partidos
          </p>
          {hayFiltros ? (
            <button
              type="button"
              onClick={limpiar}
              className="btn btn-enlace btn-sm"
            >
              Limpiar filtros
            </button>
          ) : null}
        </div>
      </Panel>

      <div className="grid gap-5 xl:grid-cols-[minmax(0,1fr)_360px]">
        <div>
          {filtrados.length === 0 ? (
            <Panel>
              <Vacio
                mensaje="No hay partidos con esos filtros."
                accion="Cambia el rango de fechas o elige otra fase."
              />
            </Panel>
          ) : vista === "tarjetas" ? (
            <>
              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                {visibles.map((p) => (
                  <TarjetaPartido
                    key={p.id_partido}
                    p={p}
                    activo={detalle?.id_partido === p.id_partido}
                    onClick={() => setDetalle(p)}
                  />
                ))}
              </div>
              {mostrar < filtrados.length ? (
                <div className="mt-4 text-center">
                  <button
                    type="button"
                    onClick={() => setMostrar((m) => m + LOTE)}
                    className="btn btn-secundario"
                  >
                    Ver más partidos
                  </button>
                </div>
              ) : null}
            </>
          ) : (
            <div className="space-y-5">
              {porMes.map(([mes, lista]) => (
                <Panel key={mes} titulo={mesLargo(`${mes}-01`)}>
                  <ul className="divide-y divide-gris-borde">
                    {lista.map((p) => (
                      <li key={p.id_partido}>
                        <button
                          type="button"
                          onClick={() => setDetalle(p)}
                          className="grid w-full grid-cols-[92px_54px_1fr_auto] items-center gap-3 px-5 py-3 text-left transition hover:bg-azul-suave/40"
                        >
                          <span className="cifras text-xs font-medium text-gris-texto">
                            {fechaCorta(p.fecha)}
                          </span>
                          <span className="cifras text-xs text-gris-texto">{p.hora}</span>
                          <span className="flex items-center gap-2 text-sm">
                            <Bandera emoji={p.bandera_local} nombre={p.equipo_local} />
                            <span className="truncate font-medium">{p.equipo_local}</span>
                            <span className="text-xs text-gris-texto">vs</span>
                            <Bandera
                              emoji={p.bandera_visitante}
                              nombre={p.equipo_visitante}
                            />
                            <span className="truncate font-medium">
                              {p.equipo_visitante}
                            </span>
                          </span>
                          <Insignia tono={p.grupo ? "neutro" : "azul"}>
                            {p.grupo ? `Grupo ${p.grupo}` : p.fase}
                          </Insignia>
                        </button>
                      </li>
                    ))}
                  </ul>
                </Panel>
              ))}
            </div>
          )}
        </div>

        {/* RF10 — detalle del partido */}
        <div className="xl:sticky xl:top-20 xl:self-start">
          {detalle ? (
            <DetallePartido p={detalle} onCerrar={() => setDetalle(null)} />
          ) : (
            <Panel titulo="Detalle del partido">
              <Vacio
                mensaje="Elige un partido para ver el detalle."
                accion="Verás las banderas, el estadio y la comparación de ranking FIFA."
              />
            </Panel>
          )}
        </div>
      </div>
    </>
  );
}

function BotonVista({
  activo,
  onClick,
  children,
}: {
  activo: boolean;
  onClick: () => void;
  children: ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={activo}
      className={[
        "btn btn-sm px-3.5 py-1.5",
        activo ? "btn-primario" : "btn-secundario",
      ].join(" ")}
    >
      {children}
    </button>
  );
}

function TarjetaPartido({
  p,
  activo,
  onClick,
}: {
  p: PartidoCalendario;
  activo: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={[
        "tarjeta w-full p-4 text-left transition hover:border-azul/40",
        activo ? "border-azul ring-2 ring-azul/20" : "",
      ].join(" ")}
    >
      <p className="cifras text-xs font-medium text-gris-texto">
        {fechaCorta(p.fecha)} · {p.hora}
      </p>
      <p className="mt-0.5 text-[11px] font-semibold uppercase tracking-wide text-azul">
        {p.grupo ? `Grupo ${p.grupo}` : p.fase}
      </p>
      <div className="mt-3 flex items-center justify-between gap-2">
        <span className="flex min-w-0 flex-col items-center gap-1 text-center">
          <Bandera emoji={p.bandera_local} nombre={p.equipo_local} className="text-2xl" />
          <span className="w-full truncate text-xs font-medium">{p.equipo_local}</span>
        </span>
        <span className="text-xs text-gris-texto">vs</span>
        <span className="flex min-w-0 flex-col items-center gap-1 text-center">
          <Bandera
            emoji={p.bandera_visitante}
            nombre={p.equipo_visitante}
            className="text-2xl"
          />
          <span className="w-full truncate text-xs font-medium">
            {p.equipo_visitante}
          </span>
        </span>
      </div>
      <p className="mt-3 flex items-center gap-1.5 truncate text-xs text-gris-texto">
        <IconoEstadio className="h-3.5 w-3.5 shrink-0" />
        {p.nombre_estadio}
      </p>
    </button>
  );
}

function DetallePartido({
  p,
  onCerrar,
}: {
  p: PartidoCalendario;
  onCerrar: () => void;
}) {
  const comparable = p.ranking_local !== null && p.ranking_visitante !== null;

  return (
    <Panel
      titulo="Detalle del partido"
      accion={
        <button
          type="button"
          onClick={onCerrar}
          aria-label="Cerrar el detalle del partido"
          className="btn-icono"
        >
          <IconoCerrar className="h-4 w-4" />
        </button>
      }
    >
      <div className="p-5">
        <p className="cifras text-center text-xs font-medium text-gris-texto">
          {fechaCorta(p.fecha)} · {p.hora}
        </p>
        <p className="mt-0.5 text-center text-[11px] font-semibold uppercase tracking-wide text-azul">
          {p.grupo ? `Grupo ${p.grupo}` : p.fase}
        </p>

        <div className="mt-4 flex items-center justify-between gap-3">
          <span className="flex flex-1 flex-col items-center gap-1.5 text-center">
            <Bandera
              emoji={p.bandera_local}
              nombre={p.equipo_local}
              className="text-4xl"
            />
            <span className="text-sm font-semibold">{p.equipo_local}</span>
          </span>
          <span className="text-sm font-bold text-gris-texto">VS</span>
          <span className="flex flex-1 flex-col items-center gap-1.5 text-center">
            <Bandera
              emoji={p.bandera_visitante}
              nombre={p.equipo_visitante}
              className="text-4xl"
            />
            <span className="text-sm font-semibold">{p.equipo_visitante}</span>
          </span>
        </div>

        <p className="mt-4 flex items-center justify-center gap-1.5 text-center text-sm text-gris-texto">
          <IconoEstadio className="h-4 w-4" />
          {p.nombre_estadio}, {p.ciudad}
        </p>

        <h3 className="mt-6 text-[13px] font-semibold uppercase tracking-wide text-gris-texto">
          Comparación rápida (Ranking FIFA 2026)
        </h3>

        {!comparable ? (
          <p className="mt-3 rounded-lg border border-dashed border-gris-borde px-4 py-6 text-center text-sm text-gris-texto">
            Los rivales de esta llave se definen al terminar la fase anterior, así
            que todavía no hay ranking que comparar.
          </p>
        ) : (
          <dl className="mt-3 divide-y divide-gris-borde rounded-lg border border-gris-borde">
            <ParDato
              etiqueta="Posición FIFA"
              izq={String(p.ranking_local)}
              der={String(p.ranking_visitante)}
              destacarMenor
            />
            <ParDato
              etiqueta="Puntos"
              izq={puntos(p.puntos_local)}
              der={puntos(p.puntos_visitante)}
            />
            <ParDato etiqueta="Participa 2026" izq="Sí" der="Sí" />
          </dl>
        )}
      </div>
    </Panel>
  );
}

function ParDato({
  etiqueta,
  izq,
  der,
  destacarMenor,
}: {
  etiqueta: string;
  izq: string;
  der: string;
  destacarMenor?: boolean;
}) {
  const mejorIzq = destacarMenor && Number(izq) < Number(der);
  const mejorDer = destacarMenor && Number(der) < Number(izq);
  return (
    <div className="grid grid-cols-3 items-center gap-2 px-4 py-2.5 text-center">
      <dd className={`cifras text-lg font-bold ${mejorIzq ? "text-azul" : ""}`}>
        {izq}
      </dd>
      <dt className="text-[11px] font-semibold uppercase tracking-wide text-gris-texto">
        {etiqueta}
      </dt>
      <dd className={`cifras text-lg font-bold ${mejorDer ? "text-azul" : ""}`}>
        {der}
      </dd>
    </div>
  );
}
