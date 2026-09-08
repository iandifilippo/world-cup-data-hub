#!/usr/bin/env python3
"""Convierte los datasets JSON en módulos TypeScript (fallback offline del frontend)."""
import json, os
B = os.path.join(os.path.dirname(__file__), "..")
D = os.path.join(B, "data_build"); T = os.path.join(B, "src", "lib", "data")
os.makedirs(T, exist_ok=True)
L = lambda n: json.load(open(os.path.join(D, f"{n}.json"), encoding="utf-8"))

ediciones, equipos, ranking, sedes, partidos = (
    L("ediciones"), L("equipos"), L("ranking"), L("sedes"), L("partidos_2026"))

def js(o):
    return json.dumps(o, ensure_ascii=False, separators=(",", ":"))

# ---- ediciones.ts
open(os.path.join(T, "ediciones.ts"), "w", encoding="utf-8").write(
"""// AUTOGENERADO por scripts/gen_ts.py — no editar a mano.
import type { Edicion } from "@/lib/types";

export const EDICIONES: Edicion[] = """ + js([{
  "id_edicion": e["id_edicion"], "nombre_edicion": e["nombre_edicion"], "anio": e["anio"],
  "sede": e["sede"], "pais_sede": e["pais_sede"], "equipos": e["equipos"],
  "campeon": e["campeon"], "subcampeon": e["subcampeon"], "goleador": e["goleador"],
  "goles_goleador": e["goles_goleador"], "asistencia_total": e["asistencia_total"],
  "promedio_asistencia": e["promedio_asistencia"], "partidos": e["partidos"],
  "decada": e["decada"],
} for e in ediciones]) + ";\n")

# ---- equipos.ts
open(os.path.join(T, "equipos.ts"), "w", encoding="utf-8").write(
"""// AUTOGENERADO por scripts/gen_ts.py — no editar a mano.
import type { Equipo } from "@/lib/types";

export const EQUIPOS: Equipo[] = """ + js(equipos) + """;

export const EQUIPO_POR_NOMBRE = new Map(EQUIPOS.map((e) => [e.nombre_equipo, e]));
export const EQUIPO_POR_CODIGO = new Map(EQUIPOS.map((e) => [e.codigo_pais, e]));
""")

# ---- ranking.ts (con variación precalculada, igual que la vista v_ranking)
by = {}
for r in ranking:
    by.setdefault(r["ciclo"], {})[r["codigo_pais"]] = r
eq_by = {e["codigo_pais"]: e for e in equipos}
filas = []
for ciclo in (2026, 2022):
    for r in sorted(by[ciclo].values(), key=lambda x: x["posicion"]):
        prev = by.get(2022, {}).get(r["codigo_pais"]) if ciclo == 2026 else None
        e = eq_by[r["codigo_pais"]]
        filas.append({
            "ciclo": ciclo, "posicion": r["posicion"], "nombre_equipo": e["nombre_equipo"],
            "codigo_pais": e["codigo_pais"], "confederacion": e["confederacion"],
            "bandera": e["bandera"], "puntos": r["puntos"],
            "posicion_anterior": prev["posicion"] if prev else None,
            "variacion": (prev["posicion"] - r["posicion"]) if prev else None,
            "partidos_evaluados": r["partidos_evaluados"],
        })
open(os.path.join(T, "ranking.ts"), "w", encoding="utf-8").write(
"""// AUTOGENERADO por scripts/gen_ts.py — no editar a mano.
import type { RankingFila } from "@/lib/types";

export const RANKING: RankingFila[] = """ + js(filas) + ";\n")

# ---- calendario.ts
sede_by = {s["id_sede"]: s for s in sedes}
eq_nom = {e["nombre_equipo"]: e for e in equipos}
rk26 = by[2026]
cal = []
for p in partidos:
    s = sede_by[p["id_sede"]]
    el = eq_nom.get(p["equipo_local"]); ev = eq_nom.get(p["equipo_visitante"])
    rl = rk26.get(el["codigo_pais"]) if el else None
    rv = rk26.get(ev["codigo_pais"]) if ev else None
    cal.append({
        "id_partido": p["id_partido"], "numero_partido": p["numero_partido"],
        "fecha": p["fecha"], "hora": p["hora"], "fase": p["fase"], "grupo": p["grupo"],
        "equipo_local": p["equipo_local"], "codigo_local": el["codigo_pais"] if el else None,
        "bandera_local": el["bandera"] if el else None,
        "equipo_visitante": p["equipo_visitante"],
        "codigo_visitante": ev["codigo_pais"] if ev else None,
        "bandera_visitante": ev["bandera"] if ev else None,
        "nombre_estadio": s["nombre_estadio"], "ciudad": s["ciudad"], "pais_sede": s["pais"],
        "ranking_local": rl["posicion"] if rl else None,
        "puntos_local": rl["puntos"] if rl else None,
        "ranking_visitante": rv["posicion"] if rv else None,
        "puntos_visitante": rv["puntos"] if rv else None,
    })
open(os.path.join(T, "calendario.ts"), "w", encoding="utf-8").write(
"""// AUTOGENERADO por scripts/gen_ts.py — no editar a mano.
import type { PartidoCalendario, Sede } from "@/lib/types";

export const SEDES: Sede[] = """ + js(sedes) + """;

export const CALENDARIO_2026: PartidoCalendario[] = """ + js(cal) + ";\n")

for f in ["ediciones.ts","equipos.ts","ranking.ts","calendario.ts"]:
    print(f, os.path.getsize(os.path.join(T, f)), "bytes")
