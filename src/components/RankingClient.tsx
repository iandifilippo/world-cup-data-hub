"use client";

import { useMemo, useState } from "react";

import {
  Bandera,
  CampoBusqueda,
  Insignia,
  Panel,
  Renglon,
  Variacion,
  Vacio,
} from "@/components/Piezas";
import { normalizar, puntos } from "@/lib/format";
import { compararSeleccion } from "@/lib/comparar";
import type { Confederacion, PartidoCalendario, RankingFila } from "@/lib/types";

const CONFEDERACIONES: Confederacion[] = [
  "CONMEBOL",
  "UEFA",
  "CONCACAF",
  "CAF",
  "AFC",
  "OFC",
];

const TOPE_VISIBLE = 60;

export function RankingClient({
  ranking,
  calendario,
}: {
  ranking: RankingFila[];
  calendario: PartidoCalendario[];
}) {
  const [ciclo, setCiclo] = useState<2022 | 2026>(2026);
  const [confederacion, setConfederacion] = useState<string>("");
  const [busqueda, setBusqueda] = useState<string>("");
  const [verTodo, setVerTodo] = useState<boolean>(false);
  const [seleccion, setSeleccion] = useState<string>("COL");

  const delCiclo = useMemo(
    () => ranking.filter((r) => r.ciclo === ciclo),
    [ranking, ciclo],
  );

  const filtradas = useMemo(() => {
    const q = normalizar(busqueda);
    return delCiclo
      .filter((r) => {
        if (confederacion && r.confederacion !== confederacion) return false;
        if (q) {
          return (
            normalizar(r.nombre_equipo).includes(q) ||
            normalizar(r.codigo_pais).includes(q)
          );
        }
        return true;
      })
      .sort((a, b) => a.posicion - b.posicion);
  }, [delCiclo, confederacion, busqueda]);

  const visibles = verTodo ? filtradas : filtradas.slice(0, TOPE_VISIBLE);

  const opcionesSeleccion = useMemo(
    () =>
      [...ranking.filter((r) => r.ciclo === 2026)]
        .sort((a, b) => a.nombre_equipo.localeCompare(b.nombre_equipo, "es"))
        .map((r) => ({ codigo: r.codigo_pais, nombre: r.nombre_equipo })),
    [ranking],
  );

  const comparacion = useMemo(
    () => compararSeleccion(ranking, seleccion, calendario),
    [ranking, seleccion, calendario],
  );

  return (
    <>
      <Panel className="mb-5">
        <div className="grid gap-4 p-5 lg:grid-cols-3">
          <div>
            <label className="etiqueta-campo" htmlFor="ciclo">
              Año
            </label>
            <select
              id="ciclo"
              className="campo"
              value={ciclo}
              onChange={(e) => setCiclo(Number(e.target.value) as 2022 | 2026)}
            >
              <option value={2026}>Ranking 2026</option>
              <option value={2022}>Ranking 2022</option>
            </select>
          </div>
          <div>
            <label className="etiqueta-campo" htmlFor="confederacion">
              Filtrar por confederación
            </label>
            <select
              id="confederacion"
              className="campo"
              value={confederacion}
              onChange={(e) => setConfederacion(e.target.value)}
            >
              <option value="">Todas</option>
              {CONFEDERACIONES.map((c) => (
                <option key={c} value={c}>
                  {c}
                </option>
              ))}
            </select>
          </div>
          <CampoBusqueda
            id="buscar-seleccion"
            etiqueta="Buscar"
            placeholder="Buscar selección o código…"
            valor={busqueda}
            onCambio={setBusqueda}
          />
        </div>
      </Panel>

      {/* RF06 — tabla de ranking */}
      <Panel>
        {visibles.length === 0 ? (
          <Vacio
            mensaje="Ninguna selección coincide con la búsqueda."
            accion="Prueba con el nombre completo o el código de tres letras."
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full border-collapse">
              <caption className="sr-only">Ranking FIFA por selección</caption>
              <thead className="border-b border-gris-borde bg-gris-suave">
                <tr>
                  <th scope="col" className="th">Pos</th>
                  <th scope="col" className="th">Selección</th>
                  <th scope="col" className="th">Código</th>
                  <th scope="col" className="th">Confederación</th>
                  <th scope="col" className="th">Puntos</th>
                  <th scope="col" className="th">Pos. anterior</th>
                  <th scope="col" className="th">Variación</th>
                  <th scope="col" className="th">Partidos eval.</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gris-borde">
                {visibles.map((r) => (
                  <tr key={`${r.ciclo}-${r.codigo_pais}`} className="fila transition">
                    <td className="td cifras font-semibold">{r.posicion}</td>
                    <td className="td">
                      <span className="flex items-center gap-2">
                        <Bandera emoji={r.bandera} nombre={r.nombre_equipo} />
                        <span className="font-medium">{r.nombre_equipo}</span>
                      </span>
                    </td>
                    <td className="td font-mono text-xs text-gris-texto">
                      {r.codigo_pais}
                    </td>
                    <td className="td text-xs">{r.confederacion}</td>
                    <td className="td cifras font-semibold">{puntos(r.puntos)}</td>
                    <td className="td cifras">{r.posicion_anterior ?? "—"}</td>
                    <td className="td">
                      <Variacion valor={r.variacion} />
                    </td>
                    <td className="td cifras">{r.partidos_evaluados}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <div className="flex items-center justify-between gap-4 border-t border-gris-borde px-5 py-3">
          <p className="text-xs text-gris-texto">
            Mostrando {visibles.length} de {filtradas.length} selecciones.
          </p>
          {filtradas.length > TOPE_VISIBLE ? (
            <button
              type="button"
              onClick={() => setVerTodo((v) => !v)}
              className="btn btn-enlace btn-sm"
            >
              {verTodo
                ? `Mostrar solo las primeras ${TOPE_VISIBLE}`
                : `Ver las ${filtradas.length} selecciones`}
            </button>
          ) : null}
        </div>
      </Panel>

      {/* RF07 / RN10 — comparador entre ciclos */}
      <div className="mt-5 grid gap-5 lg:grid-cols-[1.4fr_1fr]">
        <Panel titulo="Comparar selección entre 2022 y 2026">
          <div className="p-5">
            <div className="max-w-xs">
              <label className="etiqueta-campo" htmlFor="comparar">
                Seleccionar
              </label>
              <select
                id="comparar"
                className="campo"
                value={seleccion}
                onChange={(e) => setSeleccion(e.target.value)}
              >
                {opcionesSeleccion.map((o) => (
                  <option key={o.codigo} value={o.codigo}>
                    {o.nombre} ({o.codigo})
                  </option>
                ))}
              </select>
            </div>

            {!comparacion ? (
              <p className="mt-5 text-sm text-gris-texto">
                Esa selección no tiene registros de ranking.
              </p>
            ) : !comparacion.comparable ? (
              <p className="mt-5 rounded-lg border border-aviso-borde bg-aviso-fondo px-4 py-3 text-sm text-aviso-texto">
                {comparacion.nombre_equipo} no tiene posición registrada en los dos
                ciclos, así que la comparación no está disponible. No se muestra un
                valor estimado.
              </p>
            ) : (
              <div className="mt-5 overflow-x-auto">
                <table className="w-full border-collapse text-sm">
                  <caption className="sr-only">
                    Comparación de la selección entre los ciclos 2022 y 2026
                  </caption>
                  <thead className="border-b border-gris-borde bg-gris-suave">
                    <tr>
                      <th scope="col" className="th" />
                      <th scope="col" className="th">2022</th>
                      <th scope="col" className="th">2026</th>
                      <th scope="col" className="th">Diferencia</th>
                      <th scope="col" className="th">Bandera</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gris-borde">
                    <tr>
                      <th scope="row" className="td text-left font-medium text-gris-texto">
                        Ranking
                      </th>
                      <td className="td cifras">{comparacion.posicion_2022}</td>
                      <td className="td cifras">{comparacion.posicion_2026}</td>
                      <td className="td">
                        <Variacion valor={comparacion.dif_posiciones} />
                      </td>
                      <td className="td" rowSpan={4}>
                        <Bandera
                          emoji={comparacion.bandera}
                          nombre={comparacion.nombre_equipo}
                          className="text-4xl"
                        />
                      </td>
                    </tr>
                    <tr>
                      <th scope="row" className="td text-left font-medium text-gris-texto">
                        Puntos
                      </th>
                      <td className="td cifras">{puntos(comparacion.puntos_2022)}</td>
                      <td className="td cifras">{puntos(comparacion.puntos_2026)}</td>
                      <td className="td">
                        <DifPuntos valor={comparacion.dif_puntos} />
                      </td>
                    </tr>
                    <tr>
                      <th scope="row" className="td text-left font-medium text-gris-texto">
                        Confederación
                      </th>
                      <td className="td">{comparacion.confederacion}</td>
                      <td className="td">{comparacion.confederacion}</td>
                      <td className="td text-gris-texto">—</td>
                    </tr>
                    <tr>
                      <th scope="row" className="td text-left font-medium text-gris-texto">
                        Participación 2026
                      </th>
                      <td className="td text-gris-texto">—</td>
                      <td className="td">
                        {comparacion.participa_2026 ? (
                          <Insignia tono="verde">Sí</Insignia>
                        ) : (
                          <Insignia>No clasificó</Insignia>
                        )}
                      </td>
                      <td className="td text-gris-texto">—</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </Panel>

        {comparacion?.comparable ? (
          <Panel titulo={`Comparación — ${comparacion.nombre_equipo} (${comparacion.codigo_pais})`}>
            <dl className="divide-y divide-gris-borde text-sm">
              <Renglon etiqueta="Ranking 2022" valor={comparacion.posicion_2022} />
              <Renglon etiqueta="Ranking 2026" valor={comparacion.posicion_2026} />
              <Renglon
                etiqueta="Diferencia posiciones"
                valor={<Variacion valor={comparacion.dif_posiciones} />}
              />
              <Renglon
                etiqueta="Puntos 2022"
                valor={puntos(comparacion.puntos_2022)}
              />
              <Renglon
                etiqueta="Puntos 2026"
                valor={puntos(comparacion.puntos_2026)}
              />
              <Renglon
                etiqueta="Diferencia puntos"
                valor={<DifPuntos valor={comparacion.dif_puntos} />}
              />
              <Renglon etiqueta="Confederación" valor={comparacion.confederacion} />
              <Renglon
                etiqueta="Participación 2026"
                valor={
                  comparacion.participa_2026 ? (
                    <Insignia tono="verde">Sí</Insignia>
                  ) : (
                    <Insignia>No</Insignia>
                  )
                }
              />
            </dl>
          </Panel>
        ) : null}
      </div>
    </>
  );
}

/** Diferencia de puntos entre ciclos, con signo y color según suba o baje. */
function DifPuntos({ valor }: { valor: number | null }) {
  if (valor === null) return <span className="text-gris-texto">—</span>;
  return (
    <span className={`cifras font-semibold ${valor >= 0 ? "text-sube" : "text-baja"}`}>
      {valor >= 0 ? "+" : ""}
      {puntos(valor)}
    </span>
  );
}
