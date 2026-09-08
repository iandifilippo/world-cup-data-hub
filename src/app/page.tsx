import Link from "next/link";

import {
  IconoBalon,
  IconoCalendario,
  IconoFlecha,
  IconoSelecciones,
  IconoTrofeo,
} from "@/components/Icons";
import { AvisoOrigen, Bandera, Panel, TarjetaMetrica } from "@/components/Piezas";
import { Destacado } from "@/components/Destacado";
import { fechaCorta, puntos } from "@/lib/format";
import { getCalendario, getEdiciones, getMetricas, getRanking } from "@/lib/queries";

export default async function PaginaInicio() {
  const [metricas, ediciones, ranking, calendario] = await Promise.all([
    getMetricas(),
    getEdiciones(),
    getRanking(),
    getCalendario(),
  ]);

  const lideres = ranking.datos
    .filter((r) => r.ciclo === 2026)
    .slice(0, 5);

  const proximos = calendario.datos.slice(0, 5);

  return (
    <>
      <div className="mb-6">
        <h1 className="text-2xl font-bold tracking-tight sm:text-[28px]">
          Bienvenido al World Cup Data Hub
        </h1>
        <p className="mt-1 text-sm text-gris-texto">
          Explora estadísticas históricas, rankings y el calendario del Mundial 2026.
        </p>
      </div>

      <AvisoOrigen origen={metricas.origen} />

      {/* RF01 — métricas globales */}
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <TarjetaMetrica
          icono={<IconoTrofeo className="h-6 w-6" />}
          etiqueta="Ediciones históricas"
          valor={metricas.datos.ediciones_historicas}
          pie={`${metricas.datos.anio_min} – ${metricas.datos.anio_max}`}
        />
        <TarjetaMetrica
          icono={<IconoBalon className="h-6 w-6" />}
          etiqueta="Partidos históricos"
          valor={metricas.datos.partidos_historicos}
          pie={`${metricas.datos.anio_min} – ${metricas.datos.anio_max}`}
        />
        <TarjetaMetrica
          icono={<IconoSelecciones className="h-6 w-6" />}
          etiqueta="Selecciones en ranking 2026"
          valor={metricas.datos.selecciones_ranking_2026}
          pie="Miembros FIFA con puntaje"
        />
        <TarjetaMetrica
          icono={<IconoCalendario className="h-6 w-6" />}
          etiqueta="Partidos programados 2026"
          valor={metricas.datos.partidos_programados_2026}
          pie="Fase de grupos y eliminatorias"
        />
      </div>

      <div className="mt-5 grid gap-5 lg:grid-cols-2">
        {/* Próximos partidos */}
        <Panel titulo="Próximos partidos (2026)">
          <ul className="divide-y divide-gris-borde">
            {proximos.map((p) => (
              <li
                key={p.id_partido}
                className="grid grid-cols-[auto_auto_1fr] items-center gap-x-4 gap-y-1 px-5 py-3"
              >
                <span className="cifras text-xs font-medium text-gris-texto">
                  {fechaCorta(p.fecha)}
                </span>
                <span className="cifras text-xs text-gris-texto">{p.hora}</span>
                <span className="flex items-center justify-end gap-2 text-sm">
                  <span className="flex items-center gap-1.5">
                    <Bandera emoji={p.bandera_local} nombre={p.equipo_local} />
                    <span className="font-medium">{p.equipo_local}</span>
                  </span>
                  <span className="text-xs text-gris-texto">vs</span>
                  <span className="flex items-center gap-1.5">
                    <Bandera emoji={p.bandera_visitante} nombre={p.equipo_visitante} />
                    <span className="font-medium">{p.equipo_visitante}</span>
                  </span>
                </span>
              </li>
            ))}
          </ul>
          <div className="border-t border-gris-borde px-5 py-3 text-right">
            <Link
              href="/calendario"
              className="inline-flex items-center gap-1.5 text-sm font-semibold text-azul hover:underline"
            >
              Ver calendario completo
              <IconoFlecha className="h-4 w-4" />
            </Link>
          </div>
        </Panel>

        {/* Líderes del ranking */}
        <Panel titulo="Líderes del ranking 2026">
          <ol className="divide-y divide-gris-borde">
            {lideres.map((r) => (
              <li
                key={r.codigo_pais}
                className="flex items-center gap-3 px-5 py-3 text-sm"
              >
                <span className="cifras w-4 text-gris-texto">{r.posicion}</span>
                <Bandera emoji={r.bandera} nombre={r.nombre_equipo} />
                <span className="font-medium">{r.nombre_equipo}</span>
                <span className="cifras ml-auto font-semibold">
                  {puntos(r.puntos)} pts
                </span>
              </li>
            ))}
          </ol>
          <div className="border-t border-gris-borde px-5 py-3 text-right">
            <Link
              href="/ranking"
              className="inline-flex items-center gap-1.5 text-sm font-semibold text-azul hover:underline"
            >
              Ver ranking completo
              <IconoFlecha className="h-4 w-4" />
            </Link>
          </div>
        </Panel>
      </div>

      {/* RF11 — destacado histórico rotativo */}
      <div className="mt-5">
        <Destacado ediciones={ediciones.datos} />
      </div>
    </>
  );
}
