#!/usr/bin/env python3
"""Partidos históricos representativos: la final de cada edición + el detalle de México 1970."""
import json, os
B = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# anio, fecha, local, gl, gv, visitante, fase, nota
FINALES = [
 (1930,"1930-07-30","Uruguay",4,2,"Argentina","Final",None),
 (1934,"1934-06-10","Italia",2,1,"Checoslovaquia","Final","Tiempo suplementario"),
 (1938,"1938-06-19","Italia",4,2,"Hungría","Final",None),
 (1950,"1950-07-16","Uruguay",2,1,"Brasil","Ronda final","Partido decisivo"),
 (1954,"1954-07-04","Alemania",3,2,"Hungría","Final",None),
 (1958,"1958-06-29","Brasil",5,2,"Suecia","Final",None),
 (1962,"1962-06-17","Brasil",3,1,"Checoslovaquia","Final",None),
 (1966,"1966-07-30","Inglaterra",4,2,"Alemania","Final","Tiempo suplementario"),
 (1970,"1970-06-21","Brasil",4,1,"Italia","Final",None),
 (1974,"1974-07-07","Alemania",2,1,"Países Bajos","Final",None),
 (1978,"1978-06-25","Argentina",3,1,"Países Bajos","Final","Tiempo suplementario"),
 (1982,"1982-07-11","Italia",3,1,"Alemania","Final",None),
 (1986,"1986-06-29","Argentina",3,2,"Alemania","Final",None),
 (1990,"1990-07-08","Alemania",1,0,"Argentina","Final",None),
 (1994,"1994-07-17","Brasil",0,0,"Italia","Final","Brasil ganó 3-2 en penales"),
 (1998,"1998-07-12","Francia",3,0,"Brasil","Final",None),
 (2002,"2002-06-30","Brasil",2,0,"Alemania","Final",None),
 (2006,"2006-07-09","Italia",1,1,"Francia","Final","Italia ganó 5-3 en penales"),
 (2010,"2010-07-11","España",1,0,"Países Bajos","Final","Tiempo suplementario"),
 (2014,"2014-07-13","Alemania",1,0,"Argentina","Final","Tiempo suplementario"),
 (2018,"2018-07-15","Francia",4,2,"Croacia","Final",None),
 (2022,"2022-12-18","Argentina",3,3,"Francia","Final","Argentina ganó 4-2 en penales"),
]

# Detalle ampliado de México 1970 (la edición destacada en los mockups)
M1970 = [
 ("1970-05-31","México",0,0,"URSS","Fase de Grupos",None),
 ("1970-06-02","Bélgica",3,0,"El Salvador","Fase de Grupos",None),
 ("1970-06-02","Uruguay",2,0,"Israel","Fase de Grupos",None),
 ("1970-06-03","Brasil",4,1,"Checoslovaquia","Fase de Grupos",None),
 ("1970-06-03","Inglaterra",1,0,"Rumania","Fase de Grupos",None),
 ("1970-06-03","Perú",3,2,"Bulgaria","Fase de Grupos",None),
 ("1970-06-06","México",4,0,"El Salvador","Fase de Grupos",None),
 ("1970-06-07","Brasil",1,0,"Inglaterra","Fase de Grupos",None),
 ("1970-06-10","Italia",0,0,"Israel","Fase de Grupos",None),
 ("1970-06-11","Alemania",3,1,"Perú","Fase de Grupos",None),
 ("1970-06-14","Brasil",4,2,"Perú","Cuartos de Final",None),
 ("1970-06-14","Italia",4,1,"México","Cuartos de Final",None),
 ("1970-06-14","Alemania",3,2,"Inglaterra","Cuartos de Final","Tiempo suplementario"),
 ("1970-06-14","Uruguay",1,0,"URSS","Cuartos de Final","Tiempo suplementario"),
 ("1970-06-17","Italia",4,3,"Alemania","Semifinal","El «Partido del Siglo»"),
 ("1970-06-17","Brasil",3,1,"Uruguay","Semifinal",None),
 ("1970-06-20","Alemania",1,0,"Uruguay","Tercer Lugar",None),
]

partidos = []
pid = 0
for anio, fecha, l, gl, gv, v, fase, nota in FINALES:
    if anio == 1970:
        continue
    pid += 1
    partidos.append({"id_partido": pid, "anio": anio, "fecha": fecha,
                     "equipo_local": l, "goles_local": gl, "goles_visitante": gv,
                     "equipo_visitante": v, "fase": fase, "nota": nota})
for fecha, l, gl, gv, v, fase, nota in M1970:
    pid += 1
    partidos.append({"id_partido": pid, "anio": 1970, "fecha": fecha,
                     "equipo_local": l, "goles_local": gl, "goles_visitante": gv,
                     "equipo_visitante": v, "fase": fase, "nota": nota})
pid += 1
partidos.append({"id_partido": pid, "anio": 1970, "fecha": "1970-06-21",
                 "equipo_local": "Brasil", "goles_local": 4, "goles_visitante": 1,
                 "equipo_visitante": "Italia", "fase": "Final", "nota": None})

partidos.sort(key=lambda p: (p["anio"], p["fecha"]))
for i, p in enumerate(partidos, start=1):
    p["id_partido"] = i

os.makedirs(os.path.join(B, "data_build"), exist_ok=True)
json.dump(partidos, open(os.path.join(B, "data_build", "partidos_historicos.json"), "w",
                          encoding="utf-8"), ensure_ascii=False, indent=1)

ts = ("""// AUTOGENERADO por scripts/gen_historicos.py — no editar a mano.
import type { PartidoHistoricoDetallado } from "@/lib/types";

export const PARTIDOS_HISTORICOS: PartidoHistoricoDetallado[] = """
      + json.dumps(partidos, ensure_ascii=False, separators=(",", ":")) + ";\n")
open(os.path.join(B, "src", "lib", "data", "partidosHistoricos.ts"), "w",
     encoding="utf-8").write(ts)
print("partidos históricos:", len(partidos))
print("1970:", sum(1 for p in partidos if p["anio"] == 1970))
