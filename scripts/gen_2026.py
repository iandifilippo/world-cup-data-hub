#!/usr/bin/env python3
"""Mundial 2026 completo: sorteo real, los 104 partidos y el resultado final.

El torneo se jugó del 11 de junio al 19 de julio de 2026 y lo ganó España, que
venció 1-0 a Argentina en la prórroga de la final. Hasta la migración 008 la
edición seguía cargada como torneo por disputarse: `finalizada = false`, sin
campeón, con el sorteo que el proyecto había supuesto y con las 32 llaves de
eliminación como etiquetas del tipo «Ganador SF 1». Por eso la aplicación
mostraba «próximos partidos» y las métricas terminaban en 2022.

Esta migración reemplaza todo el Mundial 2026 por los datos reales:
  · Los 12 grupos con sus 48 selecciones.
  · Los 104 partidos con marcador, sede y fase.
  · El cierre de la edición con campeón, goleador y cifras de asistencia.

Los partidos se registran en el orden en que los publican las fuentes, que es
el del calendario oficial. El marcador guarda el resultado de los 120 minutos;
las prórrogas y las tandas de penales van en la columna `nota`. La hora exacta
no forma parte del dataset: se usa 20:00 UTC como marca convencional, igual
que en la migración 008.

Salidas:
  supabase/migrations/20260908120009_mundial_2026.sql
  src/lib/data/ediciones.ts          (agrega la edición 2026)
  src/lib/data/calendario.ts         (los 104 partidos reales)
  src/lib/data/partidosHistoricos.ts (los 104 partidos como histórico)
"""
import json
import os
from collections import Counter

B = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HORA_UTC = "20:00"
HORA_LOCAL = "15:00"

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

# Clave usada en este archivo -> sede tal como está en la tabla `sedes`.
SEDE = {
    "CDMX": ("Estadio Azteca", "Ciudad de México", "México"),
    "GDL": ("Estadio Akron", "Guadalajara", "México"),
    "MTY": ("Estadio BBVA", "Monterrey", "México"),
    "VAN": ("BC Place", "Vancouver", "Canadá"),
    "TOR": ("BMO Field", "Toronto", "Canadá"),
    "NYNJ": ("MetLife Stadium", "Nueva York / Nueva Jersey", "Estados Unidos"),
    "DAL": ("AT&T Stadium", "Dallas", "Estados Unidos"),
    "HOU": ("NRG Stadium", "Houston", "Estados Unidos"),
    "KC": ("Arrowhead Stadium", "Kansas City", "Estados Unidos"),
    "SF": ("Levi's Stadium", "San Francisco Bay Area", "Estados Unidos"),
    "LA": ("SoFi Stadium", "Los Ángeles", "Estados Unidos"),
    "SEA": ("Lumen Field", "Seattle", "Estados Unidos"),
    "ATL": ("Mercedes-Benz Stadium", "Atlanta", "Estados Unidos"),
    "MIA": ("Hard Rock Stadium", "Miami", "Estados Unidos"),
    "BOS": ("Gillette Stadium", "Boston", "Estados Unidos"),
    "PHI": ("Lincoln Financial Field", "Filadelfia", "Estados Unidos"),
}

# Sorteo real: los 12 grupos de cuatro selecciones.
GRUPOS = {
    "A": ["México", "Sudáfrica", "Corea del Sur", "República Checa"],
    "B": ["Suiza", "Canadá", "Bosnia y Herzegovina", "Qatar"],
    "C": ["Brasil", "Marruecos", "Escocia", "Haití"],
    "D": ["Estados Unidos", "Australia", "Paraguay", "Türkiye"],
    "E": ["Alemania", "Costa de Marfil", "Ecuador", "Curazao"],
    "F": ["Países Bajos", "Japón", "Suecia", "Túnez"],
    "G": ["Bélgica", "Egipto", "Irán", "Nueva Zelanda"],
    "H": ["España", "Cabo Verde", "Uruguay", "Arabia Saudita"],
    "I": ["Francia", "Noruega", "Senegal", "Irak"],
    "J": ["Argentina", "Austria", "Argelia", "Jordania"],
    "K": ["Colombia", "Portugal", "RD del Congo", "Uzbekistán"],
    "L": ["Inglaterra", "Croacia", "Ghana", "Panamá"],
}

# (fecha, local, goles, goles, visitante, fase, sede, grupo, nota)
P = [
 # =================================================== FASE DE GRUPOS (72)
 # --------------------------------------------------------------- Grupo A
 ("2026-06-11","México",2,0,"Sudáfrica","Fase de Grupos","CDMX","A",None),
 ("2026-06-11","Corea del Sur",2,1,"República Checa","Fase de Grupos","GDL","A",None),
 ("2026-06-18","República Checa",1,1,"Sudáfrica","Fase de Grupos","ATL","A",None),
 ("2026-06-18","México",1,0,"Corea del Sur","Fase de Grupos","GDL","A",None),
 ("2026-06-24","República Checa",0,3,"México","Fase de Grupos","CDMX","A",None),
 ("2026-06-24","Sudáfrica",1,0,"Corea del Sur","Fase de Grupos","MTY","A","Sudáfrica llegó por primera vez a la fase de eliminación"),
 # --------------------------------------------------------------- Grupo B
 ("2026-06-12","Canadá",1,1,"Bosnia y Herzegovina","Fase de Grupos","TOR","B",None),
 ("2026-06-13","Qatar",1,1,"Suiza","Fase de Grupos","SF","B",None),
 ("2026-06-18","Suiza",4,1,"Bosnia y Herzegovina","Fase de Grupos","LA","B",None),
 ("2026-06-18","Canadá",6,0,"Qatar","Fase de Grupos","VAN","B",None),
 ("2026-06-24","Suiza",2,1,"Canadá","Fase de Grupos","VAN","B",None),
 ("2026-06-24","Bosnia y Herzegovina",3,1,"Qatar","Fase de Grupos","SEA","B",None),
 # --------------------------------------------------------------- Grupo C
 ("2026-06-13","Brasil",1,1,"Marruecos","Fase de Grupos","NYNJ","C",None),
 ("2026-06-13","Haití",0,1,"Escocia","Fase de Grupos","BOS","C",None),
 ("2026-06-19","Escocia",0,1,"Marruecos","Fase de Grupos","BOS","C",None),
 ("2026-06-19","Brasil",3,0,"Haití","Fase de Grupos","PHI","C",None),
 ("2026-06-24","Escocia",0,3,"Brasil","Fase de Grupos","MIA","C",None),
 ("2026-06-24","Marruecos",4,2,"Haití","Fase de Grupos","ATL","C",None),
 # --------------------------------------------------------------- Grupo D
 ("2026-06-12","Estados Unidos",4,1,"Paraguay","Fase de Grupos","LA","D",None),
 ("2026-06-13","Australia",2,0,"Türkiye","Fase de Grupos","VAN","D",None),
 ("2026-06-19","Estados Unidos",2,0,"Australia","Fase de Grupos","SEA","D",None),
 ("2026-06-19","Türkiye",0,1,"Paraguay","Fase de Grupos","SF","D",None),
 ("2026-06-25","Türkiye",3,2,"Estados Unidos","Fase de Grupos","LA","D",None),
 ("2026-06-25","Paraguay",0,0,"Australia","Fase de Grupos","SF","D",None),
 # --------------------------------------------------------------- Grupo E
 ("2026-06-14","Alemania",7,1,"Curazao","Fase de Grupos","HOU","E",None),
 ("2026-06-14","Costa de Marfil",1,0,"Ecuador","Fase de Grupos","PHI","E",None),
 ("2026-06-20","Alemania",2,1,"Costa de Marfil","Fase de Grupos","TOR","E",None),
 ("2026-06-20","Ecuador",0,0,"Curazao","Fase de Grupos","KC","E",None),
 ("2026-06-25","Curazao",0,2,"Costa de Marfil","Fase de Grupos","PHI","E",None),
 ("2026-06-25","Ecuador",2,1,"Alemania","Fase de Grupos","NYNJ","E",None),
 # --------------------------------------------------------------- Grupo F
 ("2026-06-14","Países Bajos",2,2,"Japón","Fase de Grupos","DAL","F",None),
 ("2026-06-14","Suecia",5,1,"Túnez","Fase de Grupos","MTY","F",None),
 ("2026-06-20","Países Bajos",5,1,"Suecia","Fase de Grupos","HOU","F",None),
 ("2026-06-20","Túnez",0,4,"Japón","Fase de Grupos","MTY","F",None),
 ("2026-06-25","Japón",1,1,"Suecia","Fase de Grupos","DAL","F",None),
 ("2026-06-25","Túnez",1,3,"Países Bajos","Fase de Grupos","KC","F",None),
 # --------------------------------------------------------------- Grupo G
 ("2026-06-15","Bélgica",1,1,"Egipto","Fase de Grupos","SEA","G",None),
 ("2026-06-15","Irán",2,2,"Nueva Zelanda","Fase de Grupos","LA","G",None),
 ("2026-06-21","Bélgica",0,0,"Irán","Fase de Grupos","LA","G",None),
 ("2026-06-21","Nueva Zelanda",1,3,"Egipto","Fase de Grupos","VAN","G",None),
 ("2026-06-26","Egipto",1,1,"Irán","Fase de Grupos","SEA","G",None),
 ("2026-06-26","Nueva Zelanda",1,5,"Bélgica","Fase de Grupos","VAN","G",None),
 # --------------------------------------------------------------- Grupo H
 ("2026-06-15","España",0,0,"Cabo Verde","Fase de Grupos","ATL","H",None),
 ("2026-06-15","Arabia Saudita",1,1,"Uruguay","Fase de Grupos","MIA","H",None),
 ("2026-06-21","España",4,0,"Arabia Saudita","Fase de Grupos","ATL","H",None),
 ("2026-06-21","Uruguay",2,2,"Cabo Verde","Fase de Grupos","MIA","H",None),
 ("2026-06-26","Cabo Verde",0,0,"Arabia Saudita","Fase de Grupos","HOU","H",None),
 ("2026-06-26","Uruguay",0,1,"España","Fase de Grupos","GDL","H",None),
 # --------------------------------------------------------------- Grupo I
 ("2026-06-16","Francia",3,1,"Senegal","Fase de Grupos","NYNJ","I",None),
 ("2026-06-16","Irak",1,4,"Noruega","Fase de Grupos","BOS","I",None),
 ("2026-06-22","Francia",3,0,"Irak","Fase de Grupos","PHI","I",None),
 ("2026-06-22","Noruega",3,2,"Senegal","Fase de Grupos","NYNJ","I",None),
 ("2026-06-26","Noruega",1,4,"Francia","Fase de Grupos","BOS","I",None),
 ("2026-06-26","Senegal",5,0,"Irak","Fase de Grupos","TOR","I","Irak jugó con diez desde el primer tiempo"),
 # --------------------------------------------------------------- Grupo J
 ("2026-06-16","Argentina",3,0,"Argelia","Fase de Grupos","KC","J",None),
 ("2026-06-16","Austria",3,1,"Jordania","Fase de Grupos","SF","J",None),
 ("2026-06-22","Argentina",2,0,"Austria","Fase de Grupos","DAL","J",None),
 ("2026-06-22","Jordania",1,2,"Argelia","Fase de Grupos","SF","J",None),
 ("2026-06-27","Argelia",3,3,"Austria","Fase de Grupos","KC","J",None),
 ("2026-06-27","Jordania",1,3,"Argentina","Fase de Grupos","DAL","J",None),
 # --------------------------------------------------------------- Grupo K
 ("2026-06-17","Portugal",1,1,"RD del Congo","Fase de Grupos","HOU","K",None),
 ("2026-06-17","Uzbekistán",1,3,"Colombia","Fase de Grupos","CDMX","K",None),
 ("2026-06-23","Portugal",5,0,"Uzbekistán","Fase de Grupos","HOU","K",None),
 ("2026-06-23","Colombia",1,0,"RD del Congo","Fase de Grupos","GDL","K",None),
 ("2026-06-27","Colombia",0,0,"Portugal","Fase de Grupos","MIA","K",None),
 ("2026-06-27","RD del Congo",3,1,"Uzbekistán","Fase de Grupos","ATL","K","RD del Congo llegó por primera vez a la fase de eliminación"),
 # --------------------------------------------------------------- Grupo L
 ("2026-06-17","Inglaterra",4,2,"Croacia","Fase de Grupos","DAL","L",None),
 ("2026-06-17","Ghana",1,0,"Panamá","Fase de Grupos","TOR","L",None),
 ("2026-06-23","Inglaterra",0,0,"Ghana","Fase de Grupos","BOS","L",None),
 ("2026-06-23","Panamá",0,1,"Croacia","Fase de Grupos","TOR","L",None),
 ("2026-06-27","Panamá",0,2,"Inglaterra","Fase de Grupos","NYNJ","L",None),
 ("2026-06-27","Croacia",2,1,"Ghana","Fase de Grupos","PHI","L",None),
 # ============================================ DIECISEISAVOS DE FINAL (16)
 ("2026-06-28","Canadá",1,0,"Sudáfrica","Dieciseisavos de Final","LA",None,None),
 ("2026-06-29","Brasil",2,1,"Japón","Dieciseisavos de Final","HOU",None,None),
 ("2026-06-29","Paraguay",1,1,"Alemania","Dieciseisavos de Final","BOS",None,"Prórroga; Paraguay ganó 4-3 en penales"),
 ("2026-06-29","Marruecos",1,1,"Países Bajos","Dieciseisavos de Final","MTY",None,"Prórroga; Marruecos ganó 3-2 en penales"),
 ("2026-06-30","Noruega",2,1,"Costa de Marfil","Dieciseisavos de Final","DAL",None,None),
 ("2026-06-30","Francia",3,0,"Suecia","Dieciseisavos de Final","NYNJ",None,"Doblete de Kylian Mbappé"),
 ("2026-06-30","México",2,0,"Ecuador","Dieciseisavos de Final","CDMX",None,None),
 ("2026-07-01","Inglaterra",2,1,"RD del Congo","Dieciseisavos de Final","ATL",None,"Doblete de Harry Kane en los últimos quince minutos"),
 ("2026-07-01","Bélgica",3,2,"Senegal","Dieciseisavos de Final","SEA",None,"Prórroga: Bélgica remontó un 0-2 a cinco minutos del final"),
 ("2026-07-01","Estados Unidos",2,0,"Bosnia y Herzegovina","Dieciseisavos de Final","SF",None,"Primer triunfo estadounidense en eliminación desde 2002"),
 ("2026-07-02","España",3,0,"Austria","Dieciseisavos de Final","LA",None,"Doblete de Mikel Oyarzabal"),
 ("2026-07-02","Portugal",2,1,"Croacia","Dieciseisavos de Final","TOR",None,None),
 ("2026-07-02","Suiza",2,0,"Argelia","Dieciseisavos de Final","VAN",None,None),
 ("2026-07-03","Egipto",1,1,"Australia","Dieciseisavos de Final","DAL",None,"Egipto ganó 4-2 en penales"),
 ("2026-07-03","Argentina",3,2,"Cabo Verde","Dieciseisavos de Final","MIA",None,"Tiempo suplementario"),
 ("2026-07-03","Colombia",1,0,"Ghana","Dieciseisavos de Final","KC",None,None),
 # =================================================== OCTAVOS DE FINAL (8)
 ("2026-07-04","Marruecos",3,0,"Canadá","Octavos de Final","HOU",None,None),
 ("2026-07-04","Francia",1,0,"Paraguay","Octavos de Final","PHI",None,None),
 ("2026-07-05","Noruega",2,1,"Brasil","Octavos de Final","NYNJ",None,None),
 ("2026-07-05","Inglaterra",3,2,"México","Octavos de Final","CDMX",None,None),
 ("2026-07-06","España",1,0,"Portugal","Octavos de Final","DAL",None,None),
 ("2026-07-06","Bélgica",4,1,"Estados Unidos","Octavos de Final","SEA",None,None),
 ("2026-07-07","Argentina",3,2,"Egipto","Octavos de Final","ATL",None,"Remontada de dos goles en los últimos once minutos"),
 ("2026-07-07","Suiza",0,0,"Colombia","Octavos de Final","VAN",None,"Suiza ganó 4-3 en penales"),
 # =================================================== CUARTOS DE FINAL (4)
 ("2026-07-09","Francia",2,0,"Marruecos","Cuartos de Final","BOS",None,None),
 ("2026-07-10","España",2,1,"Bélgica","Cuartos de Final","LA",None,None),
 ("2026-07-11","Inglaterra",2,1,"Noruega","Cuartos de Final","MIA",None,"Tiempo suplementario"),
 ("2026-07-11","Argentina",3,1,"Suiza","Cuartos de Final","KC",None,"Tiempo suplementario"),
 # ========================================================= SEMIFINALES (2)
 ("2026-07-14","España",2,0,"Francia","Semifinal","DAL",None,None),
 ("2026-07-15","Argentina",2,1,"Inglaterra","Semifinal","ATL",None,None),
 # ================================================ TERCER LUGAR Y FINAL (2)
 ("2026-07-18","Inglaterra",6,4,"Francia","Tercer Lugar","MIA",None,"Hat-trick de Bukayo Saka; el partido con más goles jugado por el tercer puesto"),
 ("2026-07-19","España",1,0,"Argentina","Final","NYNJ",None,"Prórroga: gol de Ferran Torres al minuto 106"),
]

ORDEN_FASE = {
    "Fase de Grupos": 1, "Dieciseisavos de Final": 2, "Octavos de Final": 3,
    "Cuartos de Final": 4, "Semifinal": 5, "Tercer Lugar": 6, "Final": 7,
}


def q(v):
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return str(v)
    return "'" + str(v).replace("'", "''") + "'"


def leer_ts(archivo, marcador):
    ruta = os.path.join(B, "src", "lib", "data", archivo)
    s = open(ruta, encoding="utf-8").read()
    i = s.index(marcador) + len(marcador)
    j = s.index("];", i) + 1
    return ruta, s, json.loads(s[i:j]), i, j


def escribir_ts(ruta, s, i, j, datos):
    open(ruta, "w", encoding="utf-8").write(
        s[:i] + json.dumps(datos, ensure_ascii=False, separators=(",", ":")) + s[j:])


def comprobar(por_nombre):
    """El dataset tiene que ser internamente consistente antes de generar nada."""
    if len(P) != 104:
        raise SystemExit(f"Se esperaban 104 partidos y hay {len(P)}")

    planos = [e for eq in GRUPOS.values() for e in eq]
    if len(planos) != 48 or len(set(planos)) != 48:
        raise SystemExit("El sorteo no tiene 48 selecciones distintas")

    faltan = sorted({t for p in P for t in (p[1], p[4])} | set(planos)
                    - set(por_nombre))
    faltan = [f for f in faltan if f not in por_nombre]
    if faltan:
        raise SystemExit(f"Selecciones sin fila en equipos: {faltan}")

    # Cada grupo: seis partidos y solo entre sus cuatro selecciones.
    for letra, eq in GRUPOS.items():
        del_grupo = [p for p in P if p[7] == letra]
        if len(del_grupo) != 6:
            raise SystemExit(f"El grupo {letra} tiene {len(del_grupo)} partidos")
        for p in del_grupo:
            if p[1] not in eq or p[4] not in eq:
                raise SystemExit(f"Grupo {letra}: {p[1]} vs {p[4]} no son del grupo")

    # El cuadro tiene que cerrar: los ganadores de una ronda son exactamente
    # los participantes de la siguiente.
    def ganadores(fase):
        g = set()
        for p in P:
            if p[5] != fase:
                continue
            if p[2] > p[3]:
                g.add(p[1])
            elif p[3] > p[2]:
                g.add(p[4])
            else:                       # empate: lo resuelve la nota
                g.add(p[1] if p[8] and p[1] in p[8] else p[4])
        return g

    rondas = ["Dieciseisavos de Final", "Octavos de Final",
              "Cuartos de Final", "Semifinal"]
    for actual, siguiente in zip(rondas, rondas[1:] + ["Final"]):
        gana = ganadores(actual)
        if siguiente == "Final":
            juegan = {p[1] for p in P if p[5] == "Final"} | \
                     {p[4] for p in P if p[5] == "Final"}
        else:
            juegan = {p[1] for p in P if p[5] == siguiente} | \
                     {p[4] for p in P if p[5] == siguiente}
        if gana != juegan:
            raise SystemExit(
                f"El cuadro no cierra entre {actual} y {siguiente}: "
                f"sobran {gana - juegan}, faltan {juegan - gana}")

    # Campeón y subcampeón declarados = los de la final cargada.
    final = [p for p in P if p[5] == "Final"][0]
    campeon = final[1] if final[2] > final[3] else final[4]
    if campeon != EDICION_2026["campeon"]:
        raise SystemExit(f"La final dice que ganó {campeon}")


def main():
    _, _, equipos, _, _ = leer_ts("equipos.ts", "EQUIPOS: Equipo[] = ")
    por_nombre = {e["nombre_equipo"]: e for e in equipos}
    comprobar(por_nombre)

    _, _, ranking, _, _ = leer_ts("ranking.ts", "RANKING: RankingFila[] = ")
    rank26 = {r["codigo_pais"]: r for r in ranking if r["ciclo"] == 2026}

    # ------------------------------------------------------- ediciones.ts
    ruta, s, ediciones, i, j = leer_ts("ediciones.ts", "EDICIONES: Edicion[] = ")
    ediciones = [e for e in ediciones if e["anio"] != 2026] + [EDICION_2026]
    ediciones.sort(key=lambda e: e["anio"])
    escribir_ts(ruta, s, i, j, ediciones)

    # ------------------------------------------------------ calendario.ts
    ruta, s, _, i, j = leer_ts("calendario.ts",
                               "CALENDARIO_2026: PartidoCalendario[] = ")
    calendario = []
    for n, (fecha, loc, gl, gv, vis, fase, sede, grupo, nota) in enumerate(P, 1):
        el, ev = por_nombre[loc], por_nombre[vis]
        rl, rv = rank26.get(el["codigo_pais"]), rank26.get(ev["codigo_pais"])
        estadio, ciudad, pais = SEDE[sede]
        calendario.append({
            "id_partido": 2000 + n, "numero_partido": n, "fecha": fecha,
            "hora": HORA_LOCAL, "fase": fase, "grupo": grupo,
            "equipo_local": loc, "codigo_local": el["codigo_pais"],
            "bandera_local": el["bandera"],
            "equipo_visitante": vis, "codigo_visitante": ev["codigo_pais"],
            "bandera_visitante": ev["bandera"],
            "nombre_estadio": estadio, "ciudad": ciudad, "pais_sede": pais,
            "ranking_local": rl["posicion"] if rl else None,
            "puntos_local": rl["puntos"] if rl else None,
            "ranking_visitante": rv["posicion"] if rv else None,
            "puntos_visitante": rv["puntos"] if rv else None,
            "goles_local": gl, "goles_visitante": gv,
        })
    escribir_ts(ruta, s, i, j, calendario)

    # ---------------------------------------------- partidosHistoricos.ts
    ruta, s, hist, i, j = leer_ts(
        "partidosHistoricos.ts",
        "PARTIDOS_HISTORICOS: PartidoHistoricoDetallado[] = ")
    hist = [h for h in hist if h["anio"] != 2026]
    siguiente = max(h["id_partido"] for h in hist) + 1
    for fecha, loc, gl, gv, vis, fase, sede, grupo, nota in P:
        estadio, ciudad, _ = SEDE[sede]
        hist.append({
            "id_partido": siguiente, "anio": 2026, "fecha": fecha,
            "equipo_local": loc, "goles_local": gl, "goles_visitante": gv,
            "equipo_visitante": vis, "fase": fase,
            "nombre_estadio": estadio, "ciudad": ciudad, "nota": nota,
        })
        siguiente += 1
    hist.sort(key=lambda h: (h["anio"], h["fecha"], ORDEN_FASE.get(h["fase"], 0)))
    escribir_ts(ruta, s, i, j, hist)

    # ------------------------------------------------------------------ SQL
    o = []
    w = o.append
    w("-- =====================================================================")
    w("-- World Cup Data Hub · 009 · Mundial 2026 (torneo ya disputado)")
    w("--")
    w("-- El torneo se jugó del 11 de junio al 19 de julio de 2026 y lo ganó")
    w("-- España, que venció 1-0 a Argentina en la prórroga de la final. Hasta")
    w("-- la migración 008 la edición seguía cargada como torneo por disputarse:")
    w("-- sin campeón, con `finalizada = false`, con el sorteo que el proyecto")
    w("-- había supuesto y con las 32 llaves de eliminación como etiquetas del")
    w("-- tipo «Ganador SF 1». Por eso la aplicación mostraba «próximos")
    w("-- partidos» y el rango de las métricas terminaba en 2022.")
    w("--")
    w("-- Esta migración reemplaza el Mundial 2026 completo por los datos")
    w(f"-- reales: los 12 grupos, sus 48 selecciones y los {len(P)} partidos con")
    w("-- marcador, sede y fase.")
    w("--")
    w("-- El marcador guarda el resultado de los 120 minutos; las prórrogas y")
    w("-- las tandas de penales van en la columna `nota`. La hora exacta no")
    w(f"-- forma parte del dataset: se usa {HORA_UTC} UTC como marca convencional.")
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
    w("-- 2) Fuera el calendario supuesto: se vuelve a cargar con el real.")
    w("--    partido_equipo cae por la cascada de la llave foránea.")
    w("delete from partidos p")
    w(" using fases f, ediciones e")
    w(" where p.id_fase = f.id_fase")
    w("   and f.id_edicion = e.id_edicion")
    w("   and e.anio = 2026;")
    w("")
    w("delete from edicion_equipo")
    w(" where id_edicion = (select id_edicion from ediciones where anio = 2026);")
    w("")
    w("-- 3) El sorteo real: 48 selecciones en 12 grupos (RN04)")
    w("insert into edicion_equipo (id_edicion, equipo_id, grupo_inicial)")
    w("select e.id_edicion, q.equipo_id, v.grupo")
    w("  from (values")
    filas = [(n, g) for g, eq in sorted(GRUPOS.items()) for n in eq]
    w(",\n".join("    (" + q(f[0]) + ", " + q(f[1]) + "::char(1))" for f in filas))
    w("  ) as v(equipo, grupo)")
    w("  join ediciones e on e.anio = 2026")
    w("  join equipos q on q.nombre_equipo = v.equipo")
    w("on conflict (id_edicion, equipo_id) do nothing;")
    w("")
    w(f"-- 4) Los {len(P)} partidos con su fase, sede, grupo y marcador")
    w("with datos (numero, fecha, fase, estadio, ciudad, grupo,")
    w("            local, goles_local, visitante, goles_visitante, nota) as (values")
    filas = []
    for n, (fecha, loc, gl, gv, vis, fase, sede, grupo, nota) in enumerate(P, 1):
        estadio, ciudad, _ = SEDE[sede]
        filas.append((n, fecha, fase, estadio, ciudad, grupo, loc, gl, vis, gv, nota))
    w(",\n".join(
        "  (" + q(f[0]) + ", " + q(f[1]) + "::date, "
        + ", ".join(q(x) for x in f[2:5]) + ", " + q(f[5]) + "::char(1), "
        + ", ".join(q(x) for x in f[6:]) + ")" for f in filas))
    w("),")
    w("insertados as (")
    w("  insert into partidos (numero_partido, fecha_hora, id_sede, id_fase,")
    w("                        grupo, nota)")
    w("  select d.numero,")
    w(f"         (d.fecha + time '{HORA_UTC}') at time zone 'UTC',")
    w("         s.id_sede, f.id_fase, d.grupo, d.nota")
    w("    from datos d")
    w("    join ediciones e on e.anio = 2026")
    w("    join fases f on f.id_edicion = e.id_edicion and f.nombre_fase = d.fase")
    w("    join sedes s on s.nombre_estadio = d.estadio and s.ciudad = d.ciudad")
    w("  on conflict (id_fase, numero_partido) do nothing")
    w("  returning id_partido, numero_partido")
    w(")")
    w("-- 5) Equipos y goles de cada partido (RN03: exactamente dos por partido)")
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
    w("-- 6) El goleador del torneo, convocado a esta edición (RN06)")
    w("insert into edicion_jugador (id_edicion, id_jugador)")
    w("select e.id_edicion, j.id_jugador")
    w("  from ediciones e, jugadores j")
    w(f" where e.anio = 2026 and j.nombre_completo = {q(EDICION_2026['goleador'])}")
    w("on conflict do nothing;")
    w("")
    w("-- 7) El calendario ahora también lleva el marcador de cada partido.")
    w("--    v_metricas_globales se suelta primero porque consulta esta vista;")
    w("--    se vuelve a crear en el paso 8.")
    w("drop view if exists v_metricas_globales;")
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
    w("-- 8) La métrica de partidos de 2026 sale del total del torneo (104).")
    w("--    Ya no consulta v_calendario_2026, así que deja de depender de ella.")
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
    w("-- 9) Comprobaciones")
    w("-- select anio, campeon, subcampeon, goleador from ediciones where anio = 2026;")
    w(f"-- select count(*) from v_calendario_2026;  -- {len(P)}")
    w(f"-- select count(*) from v_calendario_2026 where goles_local is not null;  -- {len(P)}")
    w("-- select grupo_inicial, count(*) from edicion_equipo")
    w("--  where id_edicion = (select id_edicion from ediciones where anio = 2026)")
    w("--  group by grupo_inicial order by grupo_inicial;  -- 12 grupos de 4")
    w("-- select * from fn_auditar_rn03();  -- sin filas")
    w("")

    ruta = os.path.join(B, "supabase", "migrations",
                        "20260908120009_mundial_2026.sql")
    open(ruta, "w", encoding="utf-8").write("\n".join(o))

    fases = Counter(p[5] for p in P)
    print(f"campeón:     {EDICION_2026['campeon']} · subcampeón "
          f"{EDICION_2026['subcampeon']} · goleador {EDICION_2026['goleador']} "
          f"({EDICION_2026['goles_goleador']})")
    print(f"partidos:    {len(P)}")
    for f in sorted(fases, key=lambda x: ORDEN_FASE[x]):
        print(f"   {f:<24} {fases[f]:>3}")
    print(f"selecciones: 48 en {len(GRUPOS)} grupos")
    print("el cuadro de eliminación cierra correctamente")
    print(f"escrito:     {os.path.relpath(ruta, B)}")


if __name__ == "__main__":
    main()
