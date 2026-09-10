import Link from "next/link";

import {
  IconoBalon,
  IconoCalendario,
  IconoFlecha,
  IconoSelecciones,
  IconoTrofeo,
} from "@/components/Icons";
import {
  AvisoOrigen,
  Bandera,
  Fecha,
  Marcador,
  Panel,
  TarjetaMetrica,
} from "@/components/Piezas";
import { Destacado } from "@/components/Destacado";
import { puntos } from "@/lib/format";
import { getCalendario, getEdiciones, getMetricas, getRanking } from "@/lib/queries";

/** Cuántas filas se muestran en los paneles de resumen. */
const RESUMEN = 5;

export default async function PaginaInicio() {
  const [metricas, ediciones, ranking, calendario] = await Promise.all([
    getMetricas(),
    getEdiciones(),
    getRanking(),
    getCalendario(),
  ]);

  const lideres = ranking.datos.filter((r) => r.ciclo === 2026).slice(0, RESUMEN);

  // El Mundial 2026 ya se jugó, así que el panel muestra los últimos partidos
  // disputados (final, tercer puesto y semifinales) y no los primeros.
  const jugados = calendario.datos.filter((p) => p.goles_local !== null);
  const ultimos = (jugados.length > 0 ? jugados : calendario.datos)
    .slice(-RESUMEN)
    .reverse();

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
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
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
          etiqueta="Partidos del Mundial 2026"
          valor={metricas.datos.partidos_programados_2026}
          pie="Fase de grupos y eliminación"
        />
      </div>

      {/* Los dos paneles de resumen van lado a lado como en el mockup y se
          apilan en una sola columna cuando la pantalla es angosta. */}
      <div className="mt-5 grid gap-5 lg:grid-cols-2">
        <Panel titulo="Mundial 2026 · últimos resultados">
          <ul className="divide-y divide-gris-borde">
            {ultimos.map((p) => (
              <li
                key={p.id_partido}
                className="flex flex-wrap items-center gap-x-3 gap-y-1 px-5 py-3 text-sm"
              >
                <Fecha
                  iso={p.fecha}
                  className="cifras text-xs font-medium text-gris-texto"
                />
                <span className="ml-auto flex flex-wrap items-center justify-end gap-x-2 gap-y-1">
                  <Bandera emoji={p.bandera_local} nombre={p.equipo_local} />
                  <span className="font-medium">{p.equipo_local}</span>
                  <Marcador p={p} />
                  <Bandera emoji={p.bandera_visitante} nombre={p.equipo_visitante} />
                  <span className="font-medium">{p.equipo_visitante}</span>
                </span>
              </li>
            ))}
          </ul>
          <PieEnlace href="/calendario">Ver el calendario completo</PieEnlace>
        </Panel>

        <Panel titulo="Líderes del ranking 2026">
          <ol className="divide-y divide-gris-borde">
            {lideres.map((r) => (
              <li
                key={r.codigo_pais}
                className="flex items-center gap-3 px-5 py-3 text-sm"
              >
                <span className="cifras w-4 text-gris-texto">{r.posicion}</span>
                <Bandera emoji={r.bandera} nombre={r.nombre_equipo} />
                <span className="min-w-0 truncate font-medium">{r.nombre_equipo}</span>
                <span className="cifras ml-auto shrink-0 font-semibold">
                  {puntos(r.puntos)} pts
                </span>
              </li>
            ))}
          </ol>
          <PieEnlace href="/ranking">Ver ranking completo</PieEnlace>
        </Panel>
      </div>

      {/* RF11 — destacado histórico, a lo ancho de la página. */}
      <div className="mt-5">
        <Destacado ediciones={ediciones.datos} />
      </div>
    </>
  );
}

/** Enlace del pie de un panel de resumen ("Ver … completo →"). */
function PieEnlace({ href, children }: { href: string; children: string }) {
  return (
    <div className="border-t border-gris-borde px-5 py-2.5 text-right">
      <Link href={href} className="btn btn-enlace text-sm font-semibold">
        {children}
        <IconoFlecha className="h-4 w-4" />
      </Link>
    </div>
  );
}
