#!/usr/bin/env python3
"""Genera las migraciones SQL de Supabase a partir de los datasets JSON."""
import json, os

B = os.path.join(os.path.dirname(__file__), "..")
D = os.path.join(B, "data_build")
M = os.path.join(B, "supabase", "migrations")
os.makedirs(M, exist_ok=True)
L = lambda n: json.load(open(os.path.join(D, f"{n}.json"), encoding="utf-8"))

ediciones, equipos, ranking, sedes, partidos = (
    L("ediciones"), L("equipos"), L("ranking"), L("sedes"), L("partidos_2026"))

def q(v):
    if v is None: return "NULL"
    if isinstance(v, bool): return "true" if v else "false"
    if isinstance(v, (int, float)): return str(v)
    return "'" + str(v).replace("'", "''") + "'"

def rows(vals, per=1):
    return ",\n".join("  (" + ", ".join(q(x) for x in v) + ")" for v in vals)

# ============================================================ 001 SCHEMA
schema = """-- =====================================================================
-- World Cup Data Hub · 001 · Esquema base
-- Modelo entidad-relación del documento de propuesta (sección 2)
-- =====================================================================

create schema if not exists public;

-- ---------------------------------------------------------- ENTIDADES
create table if not exists sedes (
  id_sede         integer generated always as identity primary key,
  nombre_estadio  text    not null,
  ciudad          text    not null,
  pais            text    not null,
  capacidad       integer check (capacidad is null or capacidad > 0),
  unique (nombre_estadio, ciudad)
);
comment on table sedes is 'Estadios que han servido de sede en las distintas ediciones.';

create table if not exists ediciones (
  id_edicion           integer generated always as identity primary key,
  nombre_edicion       text    not null unique,
  anio                 integer not null unique check (anio between 1930 and 2100),
  sede                 text    not null,
  pais_sede            text    not null,
  equipos              integer not null check (equipos > 0),
  campeon              text,
  subcampeon           text,
  goleador             text,
  goles_goleador       integer check (goles_goleador is null or goles_goleador >= 0),
  asistencia_total     bigint  check (asistencia_total is null or asistencia_total >= 0),
  promedio_asistencia  integer check (promedio_asistencia is null or promedio_asistencia >= 0),
  partidos             integer not null check (partidos >= 0),
  fecha_inicio         date,
  finalizada           boolean not null default true,
  -- RN01: toda edición finalizada debe tener campeón y subcampeón
  constraint rn01_campeon_subcampeon check (
    finalizada = false or (campeon is not null and subcampeon is not null)
  ),
  -- RN01b: campeón y subcampeón no pueden ser la misma selección
  constraint rn01b_distintos check (campeon is null or campeon is distinct from subcampeon)
);
comment on table ediciones is 'Cada Copa del Mundo como tal (por ejemplo, "Qatar 2022").';

create table if not exists equipos (
  equipo_id      integer generated always as identity primary key,
  nombre_equipo  text not null unique,
  codigo_pais    char(3) not null unique,
  confederacion  text not null check (
                   confederacion in ('CONMEBOL','UEFA','CONCACAF','CAF','AFC','OFC')),
  bandera        text
);
comment on table equipos is 'Catálogo de las 211 selecciones nacionales miembro de la FIFA.';

create table if not exists jugadores (
  id_jugador        integer generated always as identity primary key,
  nombre_completo   text not null,
  fecha_nacimiento  date,
  posicion          text check (
                      posicion in ('Portero','Defensa','Centrocampista','Delantero')),
  equipo_id         integer references equipos(equipo_id) on delete set null
);
comment on table jugadores is 'Registro de futbolistas convocados.';

create table if not exists fases (
  id_fase      integer generated always as identity primary key,
  id_edicion   integer not null references ediciones(id_edicion) on delete cascade,
  nombre_fase  text not null,
  orden        smallint not null default 0,
  unique (id_edicion, nombre_fase)
);
comment on table fases is 'Fases dentro de un torneo (grupos, octavos, final, etc.).';

create table if not exists partidos (
  id_partido           integer generated always as identity primary key,
  numero_partido       integer not null,
  fecha_hora           timestamptz not null,
  id_sede              integer not null references sedes(id_sede),
  id_fase              integer not null references fases(id_fase) on delete cascade,
  grupo                char(1),
  etiqueta_local       text,
  etiqueta_visitante   text,
  unique (id_fase, numero_partido)
);
comment on table partidos is 'Cada partido jugado o programado. Para eliminatorias sin sorteo resuelto se usan etiquetas.';

-- ------------------------------------------------ TABLAS INTERMEDIAS (N:M)
create table if not exists edicion_sede (
  id_edicion integer not null references ediciones(id_edicion) on delete cascade,
  id_sede    integer not null references sedes(id_sede) on delete cascade,
  primary key (id_edicion, id_sede)
);
comment on table edicion_sede is 'Qué sedes se usaron en cada edición del torneo (RN08).';

create table if not exists edicion_equipo (
  id_edicion     integer not null references ediciones(id_edicion) on delete cascade,
  equipo_id      integer not null references equipos(equipo_id) on delete cascade,
  grupo_inicial  char(1),
  primary key (id_edicion, equipo_id)
);
-- RN04: un equipo no puede figurar dos veces en el mismo grupo de una edición
create unique index if not exists rn04_equipo_unico_por_grupo
  on edicion_equipo (id_edicion, equipo_id, grupo_inicial);
comment on table edicion_equipo is 'Qué equipos clasificaron a cada edición y en qué grupo quedaron.';

create table if not exists edicion_jugador (
  id_edicion  integer not null references ediciones(id_edicion) on delete cascade,
  id_jugador  integer not null references jugadores(id_jugador) on delete cascade,
  dorsal      smallint check (dorsal is null or dorsal between 1 and 99),
  primary key (id_edicion, id_jugador)
);
comment on table edicion_jugador is 'Qué jugadores fueron convocados en cada edición (RN06).';

create table if not exists partido_equipo (
  id_partido  integer not null references partidos(id_partido) on delete cascade,
  equipo_id   integer not null references equipos(equipo_id) on delete cascade,
  tipo        text not null check (tipo in ('local','visitante')),
  goles       integer check (goles is null or goles >= 0),   -- RN07
  primary key (id_partido, equipo_id),
  unique (id_partido, tipo)                                   -- RN03 (parcial)
);
comment on table partido_equipo is 'Qué equipos jugaron cada partido (local/visitante) y cuántos goles anotó cada uno.';

-- ------------------------------------------------------- RANKING FIFA
create table if not exists ranking_fifa (
  id_ranking          integer generated always as identity primary key,
  ciclo               integer not null check (ciclo in (2022, 2026)),  -- RN09
  equipo_id           integer not null references equipos(equipo_id) on delete cascade,
  posicion            integer not null check (posicion > 0),
  puntos              numeric(7,2) not null check (puntos >= 0),
  partidos_evaluados  integer not null default 0 check (partidos_evaluados >= 0),
  unique (ciclo, equipo_id),
  unique (ciclo, posicion)
);
comment on table ranking_fifa is 'Ranking FIFA por ciclo. RN09: los ciclos nunca se promedian ni se mezclan.';

-- --------------------------------------------------------------- ÍNDICES
create index if not exists idx_ediciones_anio      on ediciones (anio);
create index if not exists idx_ediciones_campeon   on ediciones (campeon);
create index if not exists idx_partidos_fecha      on partidos (fecha_hora);
create index if not exists idx_partidos_fase       on partidos (id_fase);
create index if not exists idx_partidos_sede       on partidos (id_sede);
create index if not exists idx_pe_equipo           on partido_equipo (equipo_id);
create index if not exists idx_ranking_ciclo_pos   on ranking_fifa (ciclo, posicion);
create index if not exists idx_equipos_conf        on equipos (confederacion);
"""

# ============================================================ 002 REGLAS
reglas = """-- =====================================================================
-- World Cup Data Hub · 002 · Reglas de negocio (RN02, RN03, RN05, RN06, RN08)
-- Las reglas RN01, RN04, RN07 y RN09 ya quedaron como CHECK/UNIQUE en 001.
-- =====================================================================

-- RN02: un partido pertenece a una fase, y esa fase debe ser de la misma
-- edición que las demás referencias del partido.
-- RN05: la fecha del partido debe ser posterior al inicio de la edición.
-- RN08: la sede del partido debe estar habilitada para esa edición.
create or replace function fn_validar_partido()
returns trigger
language plpgsql
as $$
declare
  v_id_edicion   integer;
  v_fecha_inicio date;
  v_sede_ok      boolean;
begin
  select f.id_edicion, e.fecha_inicio
    into v_id_edicion, v_fecha_inicio
    from fases f
    join ediciones e on e.id_edicion = f.id_edicion
   where f.id_fase = new.id_fase;

  if v_id_edicion is null then
    raise exception 'RN02: la fase % no existe o no pertenece a ninguna edición', new.id_fase;
  end if;

  if v_fecha_inicio is not null and new.fecha_hora::date < v_fecha_inicio then
    raise exception 'RN05: el partido (%) es anterior al inicio de la edición (%)',
      new.fecha_hora::date, v_fecha_inicio;
  end if;

  select exists (
    select 1 from edicion_sede es
     where es.id_edicion = v_id_edicion and es.id_sede = new.id_sede
  ) into v_sede_ok;

  if not v_sede_ok then
    raise exception 'RN08: la sede % no está habilitada para la edición %',
      new.id_sede, v_id_edicion;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validar_partido on partidos;
create trigger trg_validar_partido
  before insert or update on partidos
  for each row execute function fn_validar_partido();

-- RN06: un jugador solo puede ser convocado a una edición si su selección
-- también está registrada como participante de esa edición.
create or replace function fn_validar_convocatoria()
returns trigger
language plpgsql
as $$
declare
  v_equipo integer;
begin
  select equipo_id into v_equipo from jugadores where id_jugador = new.id_jugador;

  if v_equipo is null then
    return new; -- jugador sin selección asignada: no aplica la regla
  end if;

  if not exists (
    select 1 from edicion_equipo ee
     where ee.id_edicion = new.id_edicion and ee.equipo_id = v_equipo
  ) then
    raise exception 'RN06: la selección del jugador % no participa en la edición %',
      new.id_jugador, new.id_edicion;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validar_convocatoria on edicion_jugador;
create trigger trg_validar_convocatoria
  before insert or update on edicion_jugador
  for each row execute function fn_validar_convocatoria();

-- RN03: cada partido debe tener exactamente dos registros en partido_equipo.
-- Se expone como función de auditoría (un trigger estricto impediría insertar
-- el primer registro de la pareja).
create or replace function fn_auditar_rn03()
returns table (id_partido integer, registros bigint)
language sql
stable
as $$
  select p.id_partido, count(pe.equipo_id)
    from partidos p
    left join partido_equipo pe on pe.id_partido = p.id_partido
   group by p.id_partido
  having count(pe.equipo_id) not in (0, 2);
$$;
comment on function fn_auditar_rn03 is
  'RN03: devuelve los partidos que NO tienen exactamente dos equipos asociados.';

-- RN10: comparación de ranking solo si existe registro en AMBOS ciclos.
create or replace function fn_comparar_ranking(p_codigo char(3))
returns table (
  codigo_pais    char(3),
  nombre_equipo  text,
  confederacion  text,
  bandera        text,
  posicion_2022  integer,
  posicion_2026  integer,
  puntos_2022    numeric,
  puntos_2026    numeric,
  dif_posiciones integer,
  dif_puntos     numeric,
  comparable     boolean
)
language sql
stable
as $$
  select e.codigo_pais,
         e.nombre_equipo,
         e.confederacion,
         e.bandera,
         r22.posicion,
         r26.posicion,
         r22.puntos,
         r26.puntos,
         case when r22.posicion is not null and r26.posicion is not null
              then r22.posicion - r26.posicion end,
         case when r22.puntos is not null and r26.puntos is not null
              then round(r26.puntos - r22.puntos, 2) end,
         (r22.posicion is not null and r26.posicion is not null)
    from equipos e
    left join ranking_fifa r22 on r22.equipo_id = e.equipo_id and r22.ciclo = 2022
    left join ranking_fifa r26 on r26.equipo_id = e.equipo_id and r26.ciclo = 2026
   where e.codigo_pais = upper(p_codigo);
$$;
comment on function fn_comparar_ranking is
  'RN10: si la selección no tiene registro en ambos ciclos, comparable = false y las diferencias van en NULL.';
"""

# ============================================================ 003 VISTAS
vistas = """-- =====================================================================
-- World Cup Data Hub · 003 · Vistas de consulta para el frontend
--
-- Se sueltan y se vuelven a crear en lugar de usar CREATE OR REPLACE VIEW.
-- Las migraciones 008 y 009 le agregan columnas a v_partidos_edicion,
-- v_calendario_2026 y v_metricas_globales, y CREATE OR REPLACE no admite que
-- una vista pierda columnas: al volver a ejecutar el script sobre una base ya
-- actualizada fallaba con «42P16: cannot drop columns from view».
--
-- El orden de los DROP importa: v_metricas_globales consulta v_calendario_2026,
-- así que tiene que soltarse antes que ella.
-- =====================================================================

drop view if exists v_metricas_globales;
drop view if exists v_calendario_2026;
drop view if exists v_partidos_edicion;
drop view if exists v_ranking;
drop view if exists v_ediciones;

-- RF02 / RF03 / RF04 — Historial de Mundiales
create view v_ediciones as
select id_edicion, nombre_edicion, anio, sede, pais_sede, equipos,
       campeon, subcampeon, goleador, goles_goleador,
       asistencia_total, promedio_asistencia, partidos,
       (anio / 10) * 10 as decada, finalizada
  from ediciones
 where finalizada = true
 order by anio;

-- RF05 — Partidos de una edición histórica
create view v_partidos_edicion as
select e.id_edicion,
       e.anio,
       p.id_partido,
       p.numero_partido,
       p.fecha_hora,
       f.nombre_fase                            as fase,
       coalesce(el.nombre_equipo, p.etiqueta_local)      as equipo_local,
       coalesce(ev.nombre_equipo, p.etiqueta_visitante)  as equipo_visitante,
       pel.goles                                as goles_local,
       pev.goles                                as goles_visitante,
       s.nombre_estadio,
       s.ciudad,
       p.grupo
  from partidos p
  join fases f     on f.id_fase = p.id_fase
  join ediciones e on e.id_edicion = f.id_edicion
  join sedes s     on s.id_sede = p.id_sede
  left join partido_equipo pel on pel.id_partido = p.id_partido and pel.tipo = 'local'
  left join partido_equipo pev on pev.id_partido = p.id_partido and pev.tipo = 'visitante'
  left join equipos el on el.equipo_id = pel.equipo_id
  left join equipos ev on ev.equipo_id = pev.equipo_id;

-- RF06 — Ranking FIFA con variación respecto al ciclo anterior
create view v_ranking as
select r.ciclo,
       r.posicion,
       e.nombre_equipo,
       e.codigo_pais,
       e.confederacion,
       e.bandera,
       r.puntos,
       ant.posicion                       as posicion_anterior,
       case when ant.posicion is null then null
            else ant.posicion - r.posicion end as variacion,
       r.partidos_evaluados
  from ranking_fifa r
  join equipos e on e.equipo_id = r.equipo_id
  left join ranking_fifa ant
         on ant.equipo_id = r.equipo_id
        and ant.ciclo = case r.ciclo when 2026 then 2022 else null end;

-- RF08 / RF09 / RF10 — Calendario del Mundial 2026
create view v_calendario_2026 as
select p.id_partido,
       p.numero_partido,
       p.fecha_hora,
       (p.fecha_hora at time zone 'America/Bogota')::date as fecha,
       to_char(p.fecha_hora at time zone 'America/Bogota', 'HH24:MI') as hora,
       f.nombre_fase as fase,
       p.grupo,
       coalesce(el.nombre_equipo, p.etiqueta_local)     as equipo_local,
       el.codigo_pais  as codigo_local,
       el.bandera      as bandera_local,
       coalesce(ev.nombre_equipo, p.etiqueta_visitante) as equipo_visitante,
       ev.codigo_pais  as codigo_visitante,
       ev.bandera      as bandera_visitante,
       s.nombre_estadio,
       s.ciudad,
       s.pais          as pais_sede,
       rl.posicion     as ranking_local,
       rl.puntos       as puntos_local,
       rv.posicion     as ranking_visitante,
       rv.puntos       as puntos_visitante
  from partidos p
  join fases f     on f.id_fase = p.id_fase
  join ediciones e on e.id_edicion = f.id_edicion and e.anio = 2026
  join sedes s     on s.id_sede = p.id_sede
  left join partido_equipo pel on pel.id_partido = p.id_partido and pel.tipo = 'local'
  left join partido_equipo pev on pev.id_partido = p.id_partido and pev.tipo = 'visitante'
  left join equipos el on el.equipo_id = pel.equipo_id
  left join equipos ev on ev.equipo_id = pev.equipo_id
  left join ranking_fifa rl on rl.equipo_id = el.equipo_id and rl.ciclo = 2026
  left join ranking_fifa rv on rv.equipo_id = ev.equipo_id and rv.ciclo = 2026;

-- RF01 — Métricas globales de la pantalla de Inicio
create view v_metricas_globales as
select
  (select count(*) from ediciones where finalizada)                          as ediciones_historicas,
  (select coalesce(sum(partidos),0) from ediciones where finalizada)         as partidos_historicos,
  (select count(*) from ranking_fifa where ciclo = 2026)                     as selecciones_ranking_2026,
  (select count(*) from v_calendario_2026)                                   as partidos_programados_2026,
  (select min(anio) from ediciones where finalizada)                         as anio_min,
  (select max(anio) from ediciones where finalizada)                         as anio_max;
"""

# ============================================================ 004 RLS
rls = """-- =====================================================================
-- World Cup Data Hub · 004 · Row Level Security (lectura pública)
-- La plataforma es de solo consulta: anon y authenticated pueden LEER,
-- nadie puede escribir con la clave pública.
-- =====================================================================

alter table sedes            enable row level security;
alter table ediciones        enable row level security;
alter table equipos          enable row level security;
alter table jugadores        enable row level security;
alter table fases            enable row level security;
alter table partidos         enable row level security;
alter table edicion_sede     enable row level security;
alter table edicion_equipo   enable row level security;
alter table edicion_jugador  enable row level security;
alter table partido_equipo   enable row level security;
alter table ranking_fifa     enable row level security;

do $$
declare t text;
begin
  foreach t in array array[
    'sedes','ediciones','equipos','jugadores','fases','partidos',
    'edicion_sede','edicion_equipo','edicion_jugador','partido_equipo','ranking_fifa'
  ] loop
    execute format('drop policy if exists %I on %I', 'lectura_publica_' || t, t);
    execute format(
      'create policy %I on %I for select to anon, authenticated using (true)',
      'lectura_publica_' || t, t);
  end loop;
end $$;

-- Las vistas heredan el RLS de sus tablas base (security_invoker).
alter view v_ediciones          set (security_invoker = on);
alter view v_partidos_edicion   set (security_invoker = on);
alter view v_ranking            set (security_invoker = on);
alter view v_calendario_2026    set (security_invoker = on);
alter view v_metricas_globales  set (security_invoker = on);

grant usage on schema public to anon, authenticated;
grant select on all tables in schema public to anon, authenticated;
"""

# ============================================================ 005 SEED catálogos
def edicion_row(e):
    inicio = {1930:"1930-07-13",2022:"2022-11-20"}.get(e["anio"])
    return (e["nombre_edicion"], e["anio"], e["sede"], e["pais_sede"], e["equipos"],
            e["campeon"], e["subcampeon"], e["goleador"], e["goles_goleador"],
            e["asistencia_total"], e["promedio_asistencia"], e["partidos"], True)

seed_cat = """-- =====================================================================
-- World Cup Data Hub · 005 · Seed de catálogos
-- 16 sedes · 211 selecciones FIFA · 22 ediciones históricas + Mundial 2026
-- =====================================================================

insert into sedes (nombre_estadio, ciudad, pais, capacidad) values
""" + rows([(s["nombre_estadio"], s["ciudad"], s["pais"], s["capacidad"]) for s in sedes]) + """
on conflict (nombre_estadio, ciudad) do nothing;

insert into equipos (nombre_equipo, codigo_pais, confederacion, bandera) values
""" + rows([(e["nombre_equipo"], e["codigo_pais"], e["confederacion"], e["bandera"]) for e in equipos]) + """
on conflict (codigo_pais) do nothing;

insert into ediciones (nombre_edicion, anio, sede, pais_sede, equipos, campeon,
                       subcampeon, goleador, goles_goleador, asistencia_total,
                       promedio_asistencia, partidos, finalizada) values
""" + rows([edicion_row(e) for e in ediciones]) + """
on conflict (anio) do nothing;

-- Edición en curso: Mundial 2026 (sin campeón todavía → finalizada = false, RN01)
insert into ediciones (nombre_edicion, anio, sede, pais_sede, equipos, campeon,
                       subcampeon, goleador, goles_goleador, asistencia_total,
                       promedio_asistencia, partidos, fecha_inicio, finalizada) values
  ('Norteamérica 2026', 2026, 'Canadá, Estados Unidos y México', 'Estados Unidos',
   48, null, null, null, null, null, null, 104, '2026-06-11', false)
on conflict (anio) do nothing;
"""

# ============================================================ 006 SEED ranking
rank_rows = []
for r in ranking:
    rank_rows.append((r["ciclo"], r["codigo_pais"], r["posicion"], r["puntos"],
                      r["partidos_evaluados"]))

seed_rank = """-- =====================================================================
-- World Cup Data Hub · 006 · Seed del Ranking FIFA (ciclos 2022 y 2026)
-- 211 selecciones x 2 ciclos = 422 registros
-- =====================================================================

with datos (ciclo, codigo, posicion, puntos, partidos) as (values
""" + ",\n".join(
    "  (" + ", ".join([q(c), q(cod), q(p), q(pt), q(pe)]) + ")"
    for c, cod, p, pt, pe in rank_rows
) + """
)
insert into ranking_fifa (ciclo, equipo_id, posicion, puntos, partidos_evaluados)
select d.ciclo, e.equipo_id, d.posicion, d.puntos, d.partidos
  from datos d
  join equipos e on e.codigo_pais = d.codigo
on conflict (ciclo, equipo_id) do update
  set posicion = excluded.posicion,
      puntos   = excluded.puntos,
      partidos_evaluados = excluded.partidos_evaluados;
"""

# ============================================================ 007 SEED calendario
FASES_2026 = ["Fase de Grupos","Dieciseisavos de Final","Octavos de Final",
              "Cuartos de Final","Semifinal","Tercer Lugar","Final"]

grupos_map = {}
CLAS = [
 ["México","Canadá","Noruega","Uzbekistán"],
 ["España","Marruecos","Escocia","Curazao"],
 ["Argentina","Australia","Egipto","Panamá"],
 ["Brasil","Corea del Sur","Costa de Marfil","Austria"],
 ["Francia","Japón","Senegal","Jordania"],
 ["Estados Unidos","Croacia","Túnez","Nueva Zelanda"],
 ["Inglaterra","Irán","Argelia","Paraguay"],
 ["Portugal","Ecuador","Sudáfrica","Qatar"],
 ["Países Bajos","Colombia","Ghana","Arabia Saudita"],
 ["Bélgica","Uruguay","Cabo Verde","Haití"],
 ["Alemania","Suiza","Nigeria","Jamaica"],
 ["Italia","Dinamarca","Camerún","Honduras"],
]
for i, g in enumerate(CLAS):
    for t in g:
        grupos_map[t] = "ABCDEFGHIJKL"[i]

partidos_vals = []
for p in partidos:
    real = p["grupo"] is not None
    partidos_vals.append((
        p["numero_partido"], f'{p["fecha"]} {p["hora"]}:00-05', p["id_sede"],
        p["fase"], p["grupo"],
        None if real else p["equipo_local"],
        None if real else p["equipo_visitante"],
        p["equipo_local"] if real else None,
        p["equipo_visitante"] if real else None,
    ))

seed_cal = """-- =====================================================================
-- World Cup Data Hub · 007 · Seed del Mundial 2026
-- 16 sedes habilitadas (RN08) · 48 selecciones en 12 grupos · 104 partidos
-- =====================================================================

-- 1) Habilitar TODAS las sedes para la edición 2026 (requisito de RN08)
insert into edicion_sede (id_edicion, id_sede)
select e.id_edicion, s.id_sede
  from ediciones e cross join sedes s
 where e.anio = 2026
on conflict do nothing;

-- 2) Crear las 7 fases del torneo
insert into fases (id_edicion, nombre_fase, orden)
select e.id_edicion, f.nombre, f.orden
  from ediciones e,
       (values """ + ", ".join(
    f"('{n}', {i})" for i, n in enumerate(FASES_2026, start=1)
) + """) as f(nombre, orden)
 where e.anio = 2026
on conflict (id_edicion, nombre_fase) do nothing;

-- 3) Registrar las 48 selecciones clasificadas con su grupo (RN04)
with clasificados (equipo, grupo) as (values
""" + ",\n".join(
    "  (" + q(t) + ", " + q(grupos_map[t]) + ")" for g in CLAS for t in g
) + """
)
insert into edicion_equipo (id_edicion, equipo_id, grupo_inicial)
select ed.id_edicion, eq.equipo_id, c.grupo
  from clasificados c
  join equipos eq   on eq.nombre_equipo = c.equipo
  join ediciones ed on ed.anio = 2026
on conflict (id_edicion, equipo_id) do update set grupo_inicial = excluded.grupo_inicial;

-- 4) Cargar los 104 partidos
with datos (numero, fecha_hora, id_sede, fase, grupo,
            etq_local, etq_visitante, eq_local, eq_visitante) as (values
""" + ",\n".join(
    "  (" + ", ".join([q(v[0]), f"{q(v[1])}::timestamptz", q(v[2]), q(v[3]),
                       f"{q(v[4])}::char(1)", q(v[5]), q(v[6]), q(v[7]), q(v[8])]) + ")"
    for v in partidos_vals
) + """
), insertados as (
  insert into partidos (numero_partido, fecha_hora, id_sede, id_fase, grupo,
                        etiqueta_local, etiqueta_visitante)
  select d.numero, d.fecha_hora, d.id_sede, f.id_fase, d.grupo,
         d.etq_local, d.etq_visitante
    from datos d
    join ediciones ed on ed.anio = 2026
    join fases f on f.id_edicion = ed.id_edicion and f.nombre_fase = d.fase
  on conflict (id_fase, numero_partido) do nothing
  returning id_partido, numero_partido
)
insert into partido_equipo (id_partido, equipo_id, tipo, goles)
select i.id_partido, eq.equipo_id, t.tipo, null
  from insertados i
  join datos d on d.numero = i.numero_partido
  cross join lateral (values ('local', d.eq_local), ('visitante', d.eq_visitante))
             as t(tipo, nombre)
  join equipos eq on eq.nombre_equipo = t.nombre
on conflict do nothing;

-- 5) Verificación RN03 (debe devolver 0 filas)
-- select * from fn_auditar_rn03();
"""

archivos = {
 "20260908120001_schema.sql": schema,
 "20260908120002_reglas_negocio.sql": reglas,
 "20260908120003_vistas.sql": vistas,
 "20260908120004_rls.sql": rls,
 "20260908120005_seed_catalogos.sql": seed_cat,
 "20260908120006_seed_ranking.sql": seed_rank,
 "20260908120007_seed_calendario_2026.sql": seed_cal,
}
for n, c in archivos.items():
    open(os.path.join(M, n), "w", encoding="utf-8").write(c)
    print(n, len(c), "bytes")
