#!/usr/bin/env python3
"""Resultado del Mundial 2026, ya disputado (11 de junio – 19 de julio de 2026).

Hasta ahora la edición 2026 estaba cargada como torneo por jugarse: sin
campeón, con `finalizada = false` y con las 32 llaves de eliminación como
etiquetas del tipo «Ganador SF 1». Por eso la aplicación seguía diciendo
«próximos partidos» y el rango de las métricas terminaba en 2022.

Este script cierra la edición con el resultado real y reemplaza esas llaves
por los 25 partidos de eliminación verificados.

Cobertura de partidos de eliminación:
  · Octavos, cuartos, semifinales, tercer lugar y final: los 16, completos.
    El cuadro cierra solo (los ocho ganadores de octavos son exactamente los
    ocho de cuartos), lo que sirve de comprobación cruzada.
  · Dieciseisavos: 9 de los 16. Los otros 7 no se cargan.
  · Fase de grupos: el calendario conserva el sorteo que armó el grupo, que no
    corresponde al sorteo real; sus 72 partidos siguen sin marcador.

Salidas:
  supabase/migrations/20260908120009_resultado_2026.sql
  src/lib/data/ediciones.ts          (agrega la edición 2026)
  src/lib/data/calendario.ts         (reemplaza las llaves por resultados)
  src/lib/data/partidosHistoricos.ts (agrega los partidos de 2026)
"""
import json
import os

B = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ------------------------------------------------------------------ EDICIÓN
EDICION_2026 = {
    "id_edicion": 23,
    "nombre_edicion": "Norteamérica 2026",
    "anio": 2026,
    "sede": "Canadá, Estados Unidos y México",
    "pais_sede": "Estados Unidos",
    "equipos": 48,
    "campeon": "España",
    "subcampeon": "Argentina",
    "goleador": "Kylian Mbappé",
    "goles_goleador": 10,
    "asistencia_total": 6810966,
    "promedio_asistencia": 65490,
    "partidos": 104,
    "decada": 2020,
}

# Ciudad de la fuente -> sede tal como está registrada en la tabla `sedes`.
SEDE = {
    "Inglewood": ("SoFi Stadium", "Los Ángeles"),
    "Houston": ("NRG Stadium", "Houston"),
    "Foxborough": ("Gillette Stadium", "Boston"),
    "Guadalajara": ("Estadio Akron", "Guadalajara"),
    "Arlington": ("AT&T Stadium", "Dallas"),
    "Ciudad de México": ("Estadio Azteca", "Ciudad de México"),
    "Miami Gardens": ("Hard Rock Stadium", "Miami"),
    "Kansas City": ("Arrowhead Stadium", "Kansas City"),
    "Filadelfia": ("Lincoln Financial Field", "Filadelfia"),
    "East Rutherford": ("MetLife Stadium", "Nueva York / Nueva Jersey"),
    "Seattle": ("Lumen Field", "Seattle"),
    "Atlanta": ("Mercedes-Benz Stadium", "Atlanta"),
    "Vancouver": ("BC Place", "Vancouver"),
}

# (fecha, ganador, goles, goles, rival, fase, ciudad, nota)
# Se registra primero al equipo que ganó o avanzó: en sede neutral no hay
# local ni visitante reales.
P = [
 # ------------------------------------------------- Dieciseisavos (9 de 16)
 ("2026-06-28","Canadá",1,0,"Sudáfrica","Dieciseisavos de Final","Inglewood",None),
 ("2026-06-29","Brasil",2,1,"Japón","Dieciseisavos de Final","Houston",None),
 ("2026-06-29","Paraguay",1,1,"Alemania","Dieciseisavos de Final","Foxborough","Paraguay ganó 4-3 en penales"),
 ("2026-06-29","Marruecos",1,1,"Países Bajos","Dieciseisavos de Final","Guadalajara","Marruecos ganó 3-2 en penales"),
 ("2026-06-30","Noruega",2,1,"Costa de Marfil","Dieciseisavos de Final","Arlington",None),
 ("2026-06-30","México",2,0,"Ecuador","Dieciseisavos de Final","Ciudad de México",None),
 ("2026-07-03","Egipto",1,1,"Australia","Dieciseisavos de Final","Arlington","Egipto ganó 4-2 en penales"),
 ("2026-07-03","Argentina",3,2,"Cabo Verde","Dieciseisavos de Final","Miami Gardens","Tiempo suplementario"),
 ("2026-07-03","Colombia",1,0,"Ghana","Dieciseisavos de Final","Kansas City",None),
 # -------------------------------------------------------- Octavos (8 de 8)
 ("2026-07-04","Marruecos",3,0,"Canadá","Octavos de Final","Houston",None),
 ("2026-07-04","Francia",1,0,"Paraguay","Octavos de Final","Filadelfia",None),
 ("2026-07-05","Noruega",2,1,"Brasil","Octavos de Final","East Rutherford",None),
 ("2026-07-05","Inglaterra",3,2,"México","Octavos de Final","Ciudad de México",None),
 ("2026-07-06","España",1,0,"Portugal","Octavos de Final","Arlington",None),
 ("2026-07-06","Bélgica",4,1,"Estados Unidos","Octavos de Final","Seattle",None),
 ("2026-07-07","Argentina",3,2,"Egipto","Octavos de Final","Atlanta","Remontada de dos goles en los últimos once minutos"),
 ("2026-07-07","Suiza",0,0,"Colombia","Octavos de Final","Vancouver","Suiza ganó 4-3 en penales"),
 # -------------------------------------------------------- Cuartos (4 de 4)
 ("2026-07-09","Francia",2,0,"Marruecos","Cuartos de Final","Foxborough",None),
 ("2026-07-10","España",2,1,"Bélgica","Cuartos de Final","Inglewood",None),
 ("2026-07-11","Inglaterra",2,1,"Noruega","Cuartos de Final","Miami Gardens","Tiempo suplementario"),
 ("2026-07-11","Argentina",3,1,"Suiza","Cuartos de Final","Kansas City","Tiempo suplementario"),
 # ----------------------------------------------------- Semifinales (2 de 2)
 ("2026-07-14","España",2,0,"Francia","Semifinal","Arlington",None),
 ("2026-07-15","Argentina",2,1,"Inglaterra","Semifinal","Atlanta",None),
 # ------------------------------------------------------ Tercer lugar y final
 ("2026-07-18","Inglaterra",6,4,"Francia","Tercer Lugar","Miami Gardens","Hat-trick de Bukayo Saka; más goles en un partido por el tercer puesto"),
 ("2026-07-19","España",1,0,"Argentina","Final","East Rutherford","Tiempo suplementario: gol de Ferran Torres al minuto 106"),
]

ORDEN_FASE = {
    "Fase de Grupos": 1, "Dieciseisavos de Final": 2, "Octavos de Final": 3,
    "Cuartos de Final": 4, "Semifinal": 5, "Tercer Lugar": 6, "Final": 7,
}

# La hora exacta de cada partido no forma parte del dataset; se usa la misma
# marca convencional que el resto de los partidos cargados.
HORA_UTC = "20:00"
HORA_LOCAL = "15:00"


def q(v):
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return str(v)
    return "'" + str(v).replace("'", "''") + "'"


def leer_ts(archivo, marcador):
    """Devuelve (texto completo, lista de objetos, inicio, fin) del arreglo."""
    ruta = os.path.join(B, "src", "lib", "data", archivo)
    s = open(ruta, encoding="utf-8").read()
    i = s.index(marcador) + len(marcador)
    j = s.index("];", i) + 1
    return ruta, s, json.loads(s[i:j]), i, j


def escribir_ts(ruta, s, i, j, datos):
    nuevo = s[:i] + json.dumps(datos, ensure_ascii=False, separators=(",", ":")) + s[j:]
    open(ruta, "w", encoding="utf-8").write(nuevo)


def main():
    # -------------------------------------------------- catálogos de apoyo
    _, _, equipos, _, _ = leer_ts("equipos.ts", "EQUIPOS: Equipo[] = ")
    por_nombre = {e["nombre_equipo"]: e for e in equipos}
    _, _, ranking, _, _ = leer_ts("ranking.ts", "RANKING: RankingFila[] = ")
    rank26 = {r["codigo_pais"]: r for r in ranking if r["ciclo"] == 2026}

    faltan = sorted({t for p in P for t in (p[1], p[4])} - set(por_nombre))
    if faltan:
        raise SystemExit(f"Selecciones sin fila en equipos: {faltan}")

    # ------------------------------------------------------- ediciones.ts
    ruta, s, ediciones, i, j = leer_ts("ediciones.ts", "EDICIONES: Edicion[] = ")
    ediciones = [e for e in ediciones if e["anio"] != 2026] + [EDICION_2026]
    ediciones.sort(key=lambda e: e["anio"])
    escribir_ts(ruta, s, i, j, ediciones)

    # ------------------------------------------------------ calendario.ts
    ruta, s, cal, i, j = leer_ts("calendario.ts", "CALENDARIO_2026: PartidoCalendario[] = ")
    grupos = [c for c in cal if c["fase"] == "Fase de Grupos"]
    for c in grupos:                      # los de grupos siguen sin marcador
        c["goles_local"] = None
        c["goles_visitante"] = None

    nuevos = []
    numero = max(c["numero_partido"] for c in grupos)
    for fecha, loc, gl, gv, vis, fase, ciudad, nota in P:
        numero += 1
        el, ev = por_nombre[loc], por_nombre[vis]
        rl, rv = rank26.get(el["codigo_pais"]), rank26.get(ev["codigo_pais"])
        estadio, ciudad_sede = SEDE[ciudad]
        nuevos.append({
            "id_partido": 1000 + numero,
            "numero_partido": numero,
            "fecha": fecha,
            "hora": HORA_LOCAL,
            "fase": fase,
            "grupo": None,
            "equipo_local": loc,
            "codigo_local": el["codigo_pais"],
            "bandera_local": el["bandera"],
            "equipo_visitante": vis,
            "codigo_visitante": ev["codigo_pais"],
            "bandera_visitante": ev["bandera"],
            "nombre_estadio": estadio,
            "ciudad": ciudad_sede,
            "pais_sede": "México" if ciudad_sede in ("Ciudad de México", "Guadalajara", "Monterrey")
                         else "Canadá" if ciudad_sede in ("Vancouver", "Toronto")
                         else "Estados Unidos",
            "ranking_local": rl["posicion"] if rl else None,
            "puntos_local": rl["puntos"] if rl else None,
            "ranking_visitante": rv["posicion"] if rv else None,
            "puntos_visitante": rv["puntos"] if rv else None,
            "goles_local": gl,
            "goles_visitante": gv,
        })
    escribir_ts(ruta, s, i, j, grupos + nuevos)

    # ---------------------------------------------- partidosHistoricos.ts
    ruta, s, hist, i, j = leer_ts("partidosHistoricos.ts",
                                  "PARTIDOS_HISTORICOS: PartidoHistoricoDetallado[] = ")
    hist = [h for h in hist if h["anio"] != 2026]
    siguiente = max(h["id_partido"] for h in hist) + 1
    for fecha, loc, gl, gv, vis, fase, ciudad, nota in P:
        estadio, ciudad_sede = SEDE[ciudad]
        hist.append({
            "id_partido": siguiente, "anio": 2026, "fecha": fecha,
            "equipo_local": loc, "goles_local": gl, "goles_visitante": gv,
            "equipo_visitante": vis, "fase": fase,
            "nombre_estadio": estadio, "ciudad": ciudad_sede, "nota": nota,
        })
        siguiente += 1
    hist.sort(key=lambda h: (h["anio"], h["fecha"], ORDEN_FASE.get(h["fase"], 0)))
    escribir_ts(ruta, s, i, j, hist)

    # ------------------------------------------------------------------ SQL
    o, w = [], None
    w = o.append
    w("-- =====================================================================")
    w("-- World Cup Data Hub · 009 · Resultado del Mundial 2026")
    w("--")
    w("-- El torneo se jugó del 11 de junio al 19 de julio de 2026 y lo ganó")
    w("-- España. Hasta la migración 008 la edición seguía cargada como torneo")
    w("-- por disputarse (finalizada = false, sin campeón y con las 32 llaves de")
    w("-- eliminación como etiquetas del tipo «Ganador SF 1»), así que la")
    w("-- aplicación mostraba «próximos partidos» y las métricas terminaban en")
    w("-- 2022.")
    w("--")
    w("-- Cobertura de los partidos de eliminación que se cargan:")
    w("--   · Octavos, cuartos, semifinales, tercer lugar y final: los 16.")
    w("--   · Dieciseisavos: 9 de los 16.")
    w("--   · La fase de grupos conserva el sorteo del proyecto, que no")
    w("--     corresponde al sorteo real, y sigue sin marcador.")
    w("--")
    w("-- La hora exacta de cada partido no forma parte del dataset: se usa")
    w(f"-- {HORA_UTC} UTC como marca convencional, igual que en la migración 008.")
    w("-- =====================================================================")
    w("")
    w("-- 1) Cierre de la edición con el resultado y las cifras oficiales")
    w("update ediciones set")
    w(f"     campeon             = {q(EDICION_2026['campeon'])},")
    w(f"     subcampeon          = {q(EDICION_2026['subcampeon'])},")
    w(f"     goleador            = {q(EDICION_2026['goleador'])},")
    w(f"     goles_goleador      = {EDICION_2026['goles_goleador']},")
    w(f"     asistencia_total    = {EDICION_2026['asistencia_total']},")
    w(f"     promedio_asistencia = {EDICION_2026['promedio_asistencia']},")
    w("     finalizada          = true")
    w(" where anio = 2026;")
    w("")
    w("-- 2) Fuera las llaves sin resolver: ya no hay nada por sortear.")
    w("delete from partidos p")
    w(" using fases f, ediciones e")
    w(" where p.id_fase = f.id_fase")
    w("   and f.id_edicion = e.id_edicion")
    w("   and e.anio = 2026")
    w("   and f.nombre_fase <> 'Fase de Grupos';")
    w("")
    w(f"-- 3) Los {len(P)} partidos de eliminación con su marcador")
    w("with datos (numero, fecha, fase, estadio, ciudad,")
    w("            local, goles_local, visitante, goles_visitante, nota) as (values")
    filas = []
    numero = 72
    for fecha, loc, gl, gv, vis, fase, ciudad, nota in P:
        numero += 1
        estadio, ciudad_sede = SEDE[ciudad]
        filas.append((numero, fecha, fase, estadio, ciudad_sede, loc, gl, vis, gv, nota))
    w(",\n".join(
        "  (" + q(f[0]) + ", " + q(f[1]) + "::date, "
        + ", ".join(q(x) for x in f[2:5]) + ", "
        + ", ".join(q(x) for x in f[5:]) + ")" for f in filas))
    w("),")
    w("insertados as (")
    w("  insert into partidos (numero_partido, fecha_hora, id_sede, id_fase, nota)")
    w("  select d.numero,")
    w(f"         (d.fecha + time '{HORA_UTC}') at time zone 'UTC',")
    w("         s.id_sede, f.id_fase, d.nota")
    w("    from datos d")
    w("    join ediciones e on e.anio = 2026")
    w("    join fases f on f.id_edicion = e.id_edicion and f.nombre_fase = d.fase")
    w("    join sedes s on s.nombre_estadio = d.estadio and s.ciudad = d.ciudad")
    w("  on conflict (id_fase, numero_partido) do nothing")
    w("  returning id_partido, id_fase, numero_partido")
    w(")")
    w("-- 4) Equipos y goles de cada partido (RN03: exactamente dos por partido)")
    w("insert into partido_equipo (id_partido, equipo_id, tipo, goles)")
    w("select i.id_partido, q.equipo_id, t.tipo,")
    w("       case t.tipo when 'local' then d.goles_local else d.goles_visitante end")
    w("  from insertados i")
    w("  join datos d on d.numero = i.numero_partido")
    w("  cross join (values ('local'), ('visitante')) as t(tipo)")
    w("  join equipos q on q.nombre_equipo =")
    w("       case t.tipo when 'local' then d.local else d.visitante end")
    w("on conflict (id_partido, equipo_id) do nothing;")
    w("")
    w("-- 5) El goleador del torneo, convocado a esta edición (RN06)")
    w("insert into edicion_jugador (id_edicion, id_jugador)")
    w("select e.id_edicion, j.id_jugador")
    w("  from ediciones e, jugadores j")
    w(f" where e.anio = 2026 and j.nombre_completo = {q(EDICION_2026['goleador'])}")
    w("on conflict do nothing;")
    w("")
    w("-- 6) El calendario ahora también lleva el marcador de cada partido.")
    w("drop view if exists v_calendario_2026;")
    w("create view v_calendario_2026 as")
    w("select p.id_partido,")
    w("       p.numero_partido,")
    w("       p.fecha_hora,")
    w("       (p.fecha_hora at time zone 'America/Bogota')::date as fecha,")
    w("       to_char(p.fecha_hora at time zone 'America/Bogota', 'HH24:MI') as hora,")
    w("       f.nombre_fase as fase,")
    w("       p.grupo,")
    w("       coalesce(el.nombre_equipo, p.etiqueta_local)     as equipo_local,")
    w("       el.codigo_pais  as codigo_local,")
    w("       el.bandera      as bandera_local,")
    w("       coalesce(ev.nombre_equipo, p.etiqueta_visitante) as equipo_visitante,")
    w("       ev.codigo_pais  as codigo_visitante,")
    w("       ev.bandera      as bandera_visitante,")
    w("       s.nombre_estadio,")
    w("       s.ciudad,")
    w("       s.pais          as pais_sede,")
    w("       rl.posicion     as ranking_local,")
    w("       rl.puntos       as puntos_local,")
    w("       rv.posicion     as ranking_visitante,")
    w("       rv.puntos       as puntos_visitante,")
    w("       pel.goles       as goles_local,")
    w("       pev.goles       as goles_visitante")
    w("  from partidos p")
    w("  join fases f     on f.id_fase = p.id_fase")
    w("  join ediciones e on e.id_edicion = f.id_edicion and e.anio = 2026")
    w("  join sedes s     on s.id_sede = p.id_sede")
    w("  left join partido_equipo pel on pel.id_partido = p.id_partido and pel.tipo = 'local'")
    w("  left join partido_equipo pev on pev.id_partido = p.id_partido and pev.tipo = 'visitante'")
    w("  left join equipos el on el.equipo_id = pel.equipo_id")
    w("  left join equipos ev on ev.equipo_id = pev.equipo_id")
    w("  left join ranking_fifa rl on rl.equipo_id = el.equipo_id and rl.ciclo = 2026")
    w("  left join ranking_fifa rv on rv.equipo_id = ev.equipo_id and rv.ciclo = 2026;")
    w("")
    w("alter view v_calendario_2026 set (security_invoker = on);")
    w("grant select on v_calendario_2026 to anon, authenticated;")
    w("")
    w("-- 7) La métrica de partidos de 2026 debe ser el total del torneo (104),")
    w("--    no cuántos partidos se alcanzaron a cargar en la tabla.")
    w("drop view if exists v_metricas_globales;")
    w("create view v_metricas_globales as")
    w("select")
    w("  (select count(*) from ediciones where finalizada)                  as ediciones_historicas,")
    w("  (select coalesce(sum(partidos),0) from ediciones where finalizada) as partidos_historicos,")
    w("  (select count(*) from ranking_fifa where ciclo = 2026)             as selecciones_ranking_2026,")
    w("  (select partidos from ediciones where anio = 2026)                 as partidos_programados_2026,")
    w("  (select min(anio) from ediciones where finalizada)                 as anio_min,")
    w("  (select max(anio) from ediciones where finalizada)                 as anio_max;")
    w("")
    w("alter view v_metricas_globales set (security_invoker = on);")
    w("grant select on v_metricas_globales to anon, authenticated;")
    w("")
    w("-- 8) Comprobaciones")
    w("-- select anio, campeon, subcampeon, goleador from ediciones where anio = 2026;")
    w("-- select count(*) from v_calendario_2026 where goles_local is not null;  -- 25")
    w("-- select * from fn_auditar_rn03();  -- sin filas")
    w("")

    ruta = os.path.join(B, "supabase", "migrations",
                        "20260908120009_resultado_2026.sql")
    open(ruta, "w", encoding="utf-8").write("\n".join(o))

    print(f"edición 2026:      {EDICION_2026['campeon']} campeón, "
          f"{EDICION_2026['subcampeon']} subcampeón")
    print(f"partidos cargados: {len(P)} de eliminación")
    print(f"ediciones totales: {len(ediciones)}")
    print(f"calendario:        {len(grupos)} de grupos + {len(nuevos)} con marcador")
    print(f"escrito:           {os.path.relpath(ruta, B)}")


if __name__ == "__main__":
    main()
