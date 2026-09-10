#!/usr/bin/env python3
"""Une las migraciones de supabase/migrations/ en un solo script.

El archivo resultante sirve para levantar la base entera de una sola vez:
se pega en el SQL Editor de Supabase y se ejecuta.

Antes este archivo se mantenía a mano y se quedaba viejo sin que nadie se
diera cuenta cada vez que cambiaba una migración. Ahora se regenera, y las
cifras de las comprobaciones finales se cuentan del dataset en lugar de
escribirse a mano.

Se ejecuta al final del resto de generadores:

    python3 scripts/gen_historico.py
    python3 scripts/gen_2026.py
    python3 scripts/gen_completo.py

Salida:
  supabase/world-cup-data-hub-completo.sql
"""
import os
import re

B = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRACIONES = os.path.join(B, "supabase", "migrations")
SALIDA = os.path.join(B, "supabase", "world-cup-data-hub-completo.sql")

# Qué trae cada migración, para la cabecera del script.
CONTENIDO = [
    ("001", "Esquema base (entidades y tablas intermedias del modelo E-R)"),
    ("002", "Reglas de negocio RN01-RN10 (checks, triggers y funciones)"),
    ("003", "Vistas de consulta que alimentan el frontend"),
    ("004", "Row Level Security: lectura pública, sin escritura anónima"),
    ("005", "Catálogos: 16 sedes 2026, 211 selecciones FIFA, 23 ediciones"),
    ("006", "Ranking FIFA de los ciclos 2022 y 2026 (422 registros)"),
    ("007", "Estructura del Mundial 2026 (sedes, fases y calendario supuesto)"),
    ("008", "Histórico 1930-2022: sedes, fases, partidos, planteles y goleadores"),
    ("009", "Mundial 2026 real: sorteo, los 104 partidos y España campeona"),
]

RAYA = "-- " + "=" * 69
BARRAS = "-- " + "/" * 67


def migraciones():
    """Las migraciones .sql ordenadas por nombre (que empieza por la fecha)."""
    return sorted(f for f in os.listdir(MIGRACIONES) if f.endswith(".sql"))


def filas_insertadas(sql, tabla):
    """Cuenta las filas de los `insert into <tabla> ... values (...)` del script.

    Las migraciones escriben una fila por línea, empezando por `  ('`, así que
    basta con recorrer el bloque que va del insert hasta el `;` final.
    """
    filas = []
    dentro = False
    for linea in sql.splitlines():
        if re.match(r"^insert into %s\b" % re.escape(tabla), linea):
            dentro = True
        elif dentro:
            if linea.startswith("  ('"):
                filas.append(linea)
            if linea.rstrip().endswith(";"):
                dentro = False
    return filas


def contar_sedes(scripts):
    """Sedes distintas: la 008 repite las de 2026 y el insert las descarta."""
    vistas = set()
    for sql in scripts.values():
        for fila in filas_insertadas(sql, "sedes"):
            # ('Estadio Azteca', 'Ciudad de México', 'México'),
            partes = re.findall(r"'((?:[^']|'')*)'", fila)
            if len(partes) >= 2:
                vistas.add((partes[0], partes[1]))
    return len(vistas)


def contar_partidos_jugados():
    """Partidos con marcador cargado.

    Las migraciones insertan los partidos desde un CTE, así que contarlos en el
    SQL sería frágil. El dataset de `src/lib/data/partidosHistoricos.ts` sale de
    los mismos generadores y solo tiene partidos jugados, así que sirve igual.
    """
    ruta = os.path.join(B, "src", "lib", "data", "partidosHistoricos.ts")
    with open(ruta, encoding="utf-8") as f:
        return f.read().count('"id_partido"')


def main():
    nombres = migraciones()
    scripts = {}
    for nombre in nombres:
        with open(os.path.join(MIGRACIONES, nombre), encoding="utf-8") as f:
            scripts[nombre] = f.read()

    sedes = contar_sedes(scripts)
    partidos = contar_partidos_jugados()

    fuera = [
        RAYA,
        "-- World Cup Data Hub · Script SQL completo",
        "--",
        "-- AUTOGENERADO por scripts/gen_completo.py — no editar a mano.",
        "--",
        f"-- Une, en orden, las {len(nombres)} migraciones de supabase/migrations/. Sirve",
        "-- para levantar la base entera de una sola vez: pegar este archivo en el",
        "-- SQL Editor de Supabase y ejecutarlo.",
        "--",
        "-- Contenido:",
    ]
    for numero, texto in CONTENIDO:
        fuera.append(f"--   {numero}  {texto}")
    fuera += [
        "--",
        "-- Se puede ejecutar varias veces: las inserciones usan ON CONFLICT DO",
        "-- NOTHING y las vistas se sueltan antes de crearse.",
        RAYA,
    ]

    for nombre in nombres:
        fuera += [
            "",
            BARRAS,
            f"-- Archivo: supabase/migrations/{nombre}",
            BARRAS,
            "",
            scripts[nombre].rstrip("\n"),
        ]

    fuera += [
        "",
        RAYA,
        "-- Comprobaciones finales (opcionales)",
        RAYA,
        "-- select count(*) from ediciones where finalizada;        -- 23, de 1930 a 2026",
        "-- select anio, campeon, subcampeon, goleador from ediciones where anio = 2026;",
        "-- select count(*) from equipos;                           -- 214",
        f"-- select count(*) from sedes;                             -- {sedes}",
        "-- select count(*) from ranking_fifa where ciclo = 2026;   -- 211",
        "-- select count(*) from v_calendario_2026;                 -- 104",
        f"-- select count(*) from v_partidos_edicion where goles_local is not null; -- {partidos}",
        "-- select * from fn_auditar_rn03();                        -- sin filas",
        "",
    ]

    with open(SALIDA, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(fuera))

    print(f"migraciones: {len(nombres)}")
    print(f"sedes:       {sedes}")
    print(f"partidos:    {partidos}")
    print(f"escrito:     {os.path.relpath(SALIDA, B)}")


if __name__ == "__main__":
    main()
