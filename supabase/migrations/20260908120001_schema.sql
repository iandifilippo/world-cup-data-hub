-- =====================================================================
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
