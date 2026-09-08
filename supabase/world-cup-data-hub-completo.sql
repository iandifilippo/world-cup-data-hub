-- =====================================================================
-- World Cup Data Hub · Script SQL completo
--
-- Une, en orden, las 9 migraciones de supabase/migrations/. Sirve para
-- levantar la base entera de una sola vez: pegar este archivo en el SQL
-- Editor de Supabase y ejecutarlo.
--
-- Contenido:
--   001  Esquema base (entidades y tablas intermedias del modelo E-R)
--   002  Reglas de negocio RN01-RN10 (checks, triggers y funciones)
--   003  Vistas de consulta que alimentan el frontend
--   004  Row Level Security: lectura pública, sin escritura anónima
--   005  Catálogos: 16 sedes 2026, 211 selecciones FIFA, 23 ediciones
--   006  Ranking FIFA de los ciclos 2022 y 2026 (422 registros)
--   007  Mundial 2026: 12 grupos, 48 selecciones y 104 partidos
--   008  Histórico 1930-2022: sedes, fases, partidos, planteles y goleadores
--   009  Resultado del Mundial 2026: España campeón y la fase de eliminación
--
-- Es idempotente: todas las inserciones usan ON CONFLICT DO NOTHING, así que
-- se puede volver a ejecutar sin duplicar información.
-- =====================================================================



-- ///////////////////////////////////////////////////////////////////
-- Archivo: supabase/migrations/20260908120001_schema.sql
-- ///////////////////////////////////////////////////////////////////

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


-- ///////////////////////////////////////////////////////////////////
-- Archivo: supabase/migrations/20260908120002_reglas_negocio.sql
-- ///////////////////////////////////////////////////////////////////

-- =====================================================================
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


-- ///////////////////////////////////////////////////////////////////
-- Archivo: supabase/migrations/20260908120003_vistas.sql
-- ///////////////////////////////////////////////////////////////////

-- =====================================================================
-- World Cup Data Hub · 003 · Vistas de consulta para el frontend
-- =====================================================================

-- RF02 / RF03 / RF04 — Historial de Mundiales
create or replace view v_ediciones as
select id_edicion, nombre_edicion, anio, sede, pais_sede, equipos,
       campeon, subcampeon, goleador, goles_goleador,
       asistencia_total, promedio_asistencia, partidos,
       (anio / 10) * 10 as decada, finalizada
  from ediciones
 where finalizada = true
 order by anio;

-- RF05 — Partidos de una edición histórica
create or replace view v_partidos_edicion as
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
create or replace view v_ranking as
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
create or replace view v_calendario_2026 as
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
create or replace view v_metricas_globales as
select
  (select count(*) from ediciones where finalizada)                          as ediciones_historicas,
  (select coalesce(sum(partidos),0) from ediciones where finalizada)         as partidos_historicos,
  (select count(*) from ranking_fifa where ciclo = 2026)                     as selecciones_ranking_2026,
  (select count(*) from v_calendario_2026)                                   as partidos_programados_2026,
  (select min(anio) from ediciones where finalizada)                         as anio_min,
  (select max(anio) from ediciones where finalizada)                         as anio_max;


-- ///////////////////////////////////////////////////////////////////
-- Archivo: supabase/migrations/20260908120004_rls.sql
-- ///////////////////////////////////////////////////////////////////

-- =====================================================================
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


-- ///////////////////////////////////////////////////////////////////
-- Archivo: supabase/migrations/20260908120005_seed_catalogos.sql
-- ///////////////////////////////////////////////////////////////////

-- =====================================================================
-- World Cup Data Hub · 005 · Seed de catálogos
-- 16 sedes · 211 selecciones FIFA · 22 ediciones históricas + Mundial 2026
-- =====================================================================

insert into sedes (nombre_estadio, ciudad, pais, capacidad) values
  ('Estadio Azteca', 'Ciudad de México', 'México', 87523),
  ('Estadio BBVA', 'Monterrey', 'México', 53500),
  ('Estadio Akron', 'Guadalajara', 'México', 48071),
  ('BC Place', 'Vancouver', 'Canadá', 54500),
  ('BMO Field', 'Toronto', 'Canadá', 45500),
  ('MetLife Stadium', 'Nueva York / Nueva Jersey', 'Estados Unidos', 82500),
  ('AT&T Stadium', 'Dallas', 'Estados Unidos', 80000),
  ('NRG Stadium', 'Houston', 'Estados Unidos', 72220),
  ('Arrowhead Stadium', 'Kansas City', 'Estados Unidos', 76416),
  ('Levi''s Stadium', 'San Francisco Bay Area', 'Estados Unidos', 68500),
  ('SoFi Stadium', 'Los Ángeles', 'Estados Unidos', 70240),
  ('Lumen Field', 'Seattle', 'Estados Unidos', 69000),
  ('Mercedes-Benz Stadium', 'Atlanta', 'Estados Unidos', 71000),
  ('Hard Rock Stadium', 'Miami', 'Estados Unidos', 65326),
  ('Gillette Stadium', 'Boston', 'Estados Unidos', 65878),
  ('Lincoln Financial Field', 'Filadelfia', 'Estados Unidos', 69796)
on conflict (nombre_estadio, ciudad) do nothing;

insert into equipos (nombre_equipo, codigo_pais, confederacion, bandera) values
  ('Argentina', 'ARG', 'CONMEBOL', '🇦🇷'),
  ('Brasil', 'BRA', 'CONMEBOL', '🇧🇷'),
  ('Uruguay', 'URU', 'CONMEBOL', '🇺🇾'),
  ('Colombia', 'COL', 'CONMEBOL', '🇨🇴'),
  ('Chile', 'CHI', 'CONMEBOL', '🇨🇱'),
  ('Perú', 'PER', 'CONMEBOL', '🇵🇪'),
  ('Ecuador', 'ECU', 'CONMEBOL', '🇪🇨'),
  ('Paraguay', 'PAR', 'CONMEBOL', '🇵🇾'),
  ('Bolivia', 'BOL', 'CONMEBOL', '🇧🇴'),
  ('Venezuela', 'VEN', 'CONMEBOL', '🇻🇪'),
  ('Francia', 'FRA', 'UEFA', '🇫🇷'),
  ('Inglaterra', 'ENG', 'UEFA', '🏴󠁧󠁢󠁥󠁮󠁧󠁿'),
  ('Bélgica', 'BEL', 'UEFA', '🇧🇪'),
  ('Países Bajos', 'NED', 'UEFA', '🇳🇱'),
  ('Portugal', 'POR', 'UEFA', '🇵🇹'),
  ('España', 'ESP', 'UEFA', '🇪🇸'),
  ('Italia', 'ITA', 'UEFA', '🇮🇹'),
  ('Alemania', 'GER', 'UEFA', '🇩🇪'),
  ('Croacia', 'CRO', 'UEFA', '🇭🇷'),
  ('Dinamarca', 'DEN', 'UEFA', '🇩🇰'),
  ('Suiza', 'SUI', 'UEFA', '🇨🇭'),
  ('Austria', 'AUT', 'UEFA', '🇦🇹'),
  ('Ucrania', 'UKR', 'UEFA', '🇺🇦'),
  ('Suecia', 'SWE', 'UEFA', '🇸🇪'),
  ('Polonia', 'POL', 'UEFA', '🇵🇱'),
  ('Gales', 'WAL', 'UEFA', '🏴󠁧󠁢󠁷󠁬󠁳󠁿'),
  ('Serbia', 'SRB', 'UEFA', '🇷🇸'),
  ('Türkiye', 'TUR', 'UEFA', '🇹🇷'),
  ('Escocia', 'SCO', 'UEFA', '🏴󠁧󠁢󠁳󠁣󠁴󠁿'),
  ('Hungría', 'HUN', 'UEFA', '🇭🇺'),
  ('Noruega', 'NOR', 'UEFA', '🇳🇴'),
  ('República Checa', 'CZE', 'UEFA', '🇨🇿'),
  ('Grecia', 'GRE', 'UEFA', '🇬🇷'),
  ('Rumania', 'ROU', 'UEFA', '🇷🇴'),
  ('Eslovaquia', 'SVK', 'UEFA', '🇸🇰'),
  ('Eslovenia', 'SVN', 'UEFA', '🇸🇮'),
  ('Irlanda', 'IRL', 'UEFA', '🇮🇪'),
  ('Irlanda del Norte', 'NIR', 'UEFA', '🏴'),
  ('Islandia', 'ISL', 'UEFA', '🇮🇸'),
  ('Finlandia', 'FIN', 'UEFA', '🇫🇮'),
  ('Bosnia y Herzegovina', 'BIH', 'UEFA', '🇧🇦'),
  ('Albania', 'ALB', 'UEFA', '🇦🇱'),
  ('Macedonia del Norte', 'MKD', 'UEFA', '🇲🇰'),
  ('Georgia', 'GEO', 'UEFA', '🇬🇪'),
  ('Israel', 'ISR', 'UEFA', '🇮🇱'),
  ('Bulgaria', 'BUL', 'UEFA', '🇧🇬'),
  ('Montenegro', 'MNE', 'UEFA', '🇲🇪'),
  ('Bielorrusia', 'BLR', 'UEFA', '🇧🇾'),
  ('Armenia', 'ARM', 'UEFA', '🇦🇲'),
  ('Luxemburgo', 'LUX', 'UEFA', '🇱🇺'),
  ('Kosovo', 'KVX', 'UEFA', '🇽🇰'),
  ('Azerbaiyán', 'AZE', 'UEFA', '🇦🇿'),
  ('Kazajistán', 'KAZ', 'UEFA', '🇰🇿'),
  ('Estonia', 'EST', 'UEFA', '🇪🇪'),
  ('Letonia', 'LVA', 'UEFA', '🇱🇻'),
  ('Lituania', 'LTU', 'UEFA', '🇱🇹'),
  ('Chipre', 'CYP', 'UEFA', '🇨🇾'),
  ('Islas Feroe', 'FRO', 'UEFA', '🇫🇴'),
  ('Moldavia', 'MDA', 'UEFA', '🇲🇩'),
  ('Malta', 'MLT', 'UEFA', '🇲🇹'),
  ('Andorra', 'AND', 'UEFA', '🇦🇩'),
  ('Gibraltar', 'GIB', 'UEFA', '🇬🇮'),
  ('Liechtenstein', 'LIE', 'UEFA', '🇱🇮'),
  ('San Marino', 'SMR', 'UEFA', '🇸🇲'),
  ('Rusia', 'RUS', 'UEFA', '🇷🇺'),
  ('Estados Unidos', 'USA', 'CONCACAF', '🇺🇸'),
  ('México', 'MEX', 'CONCACAF', '🇲🇽'),
  ('Canadá', 'CAN', 'CONCACAF', '🇨🇦'),
  ('Costa Rica', 'CRC', 'CONCACAF', '🇨🇷'),
  ('Panamá', 'PAN', 'CONCACAF', '🇵🇦'),
  ('Jamaica', 'JAM', 'CONCACAF', '🇯🇲'),
  ('Honduras', 'HON', 'CONCACAF', '🇭🇳'),
  ('El Salvador', 'SLV', 'CONCACAF', '🇸🇻'),
  ('Guatemala', 'GUA', 'CONCACAF', '🇬🇹'),
  ('Curazao', 'CUW', 'CONCACAF', '🇨🇼'),
  ('Haití', 'HAI', 'CONCACAF', '🇭🇹'),
  ('Trinidad y Tobago', 'TRI', 'CONCACAF', '🇹🇹'),
  ('Surinam', 'SUR', 'CONCACAF', '🇸🇷'),
  ('Guyana', 'GUY', 'CONCACAF', '🇬🇾'),
  ('Nicaragua', 'NCA', 'CONCACAF', '🇳🇮'),
  ('República Dominicana', 'DOM', 'CONCACAF', '🇩🇴'),
  ('Cuba', 'CUB', 'CONCACAF', '🇨🇺'),
  ('Antigua y Barbuda', 'ATG', 'CONCACAF', '🇦🇬'),
  ('San Cristóbal y Nieves', 'SKN', 'CONCACAF', '🇰🇳'),
  ('Belice', 'BLZ', 'CONCACAF', '🇧🇿'),
  ('Bermudas', 'BER', 'CONCACAF', '🇧🇲'),
  ('Granada', 'GRN', 'CONCACAF', '🇬🇩'),
  ('San Vicente y las Granadinas', 'VIN', 'CONCACAF', '🇻🇨'),
  ('Barbados', 'BRB', 'CONCACAF', '🇧🇧'),
  ('Puerto Rico', 'PUR', 'CONCACAF', '🇵🇷'),
  ('Santa Lucía', 'LCA', 'CONCACAF', '🇱🇨'),
  ('Dominica', 'DMA', 'CONCACAF', '🇩🇲'),
  ('Montserrat', 'MSR', 'CONCACAF', '🇲🇸'),
  ('Islas Caimán', 'CAY', 'CONCACAF', '🇰🇾'),
  ('Bahamas', 'BAH', 'CONCACAF', '🇧🇸'),
  ('Aruba', 'ARU', 'CONCACAF', '🇦🇼'),
  ('Islas Vírgenes de EE. UU.', 'VIR', 'CONCACAF', '🇻🇮'),
  ('Islas Vírgenes Británicas', 'VGB', 'CONCACAF', '🇻🇬'),
  ('Anguila', 'AIA', 'CONCACAF', '🇦🇮'),
  ('Islas Turcas y Caicos', 'TCA', 'CONCACAF', '🇹🇨'),
  ('Marruecos', 'MAR', 'CAF', '🇲🇦'),
  ('Senegal', 'SEN', 'CAF', '🇸🇳'),
  ('Egipto', 'EGY', 'CAF', '🇪🇬'),
  ('Argelia', 'ALG', 'CAF', '🇩🇿'),
  ('Nigeria', 'NGA', 'CAF', '🇳🇬'),
  ('Costa de Marfil', 'CIV', 'CAF', '🇨🇮'),
  ('Túnez', 'TUN', 'CAF', '🇹🇳'),
  ('Camerún', 'CMR', 'CAF', '🇨🇲'),
  ('Malí', 'MLI', 'CAF', '🇲🇱'),
  ('Ghana', 'GHA', 'CAF', '🇬🇭'),
  ('Sudáfrica', 'RSA', 'CAF', '🇿🇦'),
  ('Burkina Faso', 'BFA', 'CAF', '🇧🇫'),
  ('RD del Congo', 'COD', 'CAF', '🇨🇩'),
  ('Cabo Verde', 'CPV', 'CAF', '🇨🇻'),
  ('Guinea', 'GUI', 'CAF', '🇬🇳'),
  ('Gabón', 'GAB', 'CAF', '🇬🇦'),
  ('Zambia', 'ZAM', 'CAF', '🇿🇲'),
  ('Angola', 'ANG', 'CAF', '🇦🇴'),
  ('Uganda', 'UGA', 'CAF', '🇺🇬'),
  ('Benín', 'BEN', 'CAF', '🇧🇯'),
  ('Guinea Ecuatorial', 'EQG', 'CAF', '🇬🇶'),
  ('Mozambique', 'MOZ', 'CAF', '🇲🇿'),
  ('Madagascar', 'MAD', 'CAF', '🇲🇬'),
  ('Mauritania', 'MTN', 'CAF', '🇲🇷'),
  ('Zimbabue', 'ZIM', 'CAF', '🇿🇼'),
  ('Namibia', 'NAM', 'CAF', '🇳🇦'),
  ('Kenia', 'KEN', 'CAF', '🇰🇪'),
  ('Libia', 'LBY', 'CAF', '🇱🇾'),
  ('Togo', 'TOG', 'CAF', '🇹🇬'),
  ('Sierra Leona', 'SLE', 'CAF', '🇸🇱'),
  ('Congo', 'CGO', 'CAF', '🇨🇬'),
  ('Sudán', 'SDN', 'CAF', '🇸🇩'),
  ('Comoras', 'COM', 'CAF', '🇰🇲'),
  ('Malaui', 'MWI', 'CAF', '🇲🇼'),
  ('Tanzania', 'TAN', 'CAF', '🇹🇿'),
  ('Ruanda', 'RWA', 'CAF', '🇷🇼'),
  ('Níger', 'NIG', 'CAF', '🇳🇪'),
  ('Guinea-Bisáu', 'GNB', 'CAF', '🇬🇼'),
  ('Burundi', 'BDI', 'CAF', '🇧🇮'),
  ('Etiopía', 'ETH', 'CAF', '🇪🇹'),
  ('Liberia', 'LBR', 'CAF', '🇱🇷'),
  ('Botsuana', 'BOT', 'CAF', '🇧🇼'),
  ('Lesoto', 'LES', 'CAF', '🇱🇸'),
  ('Suazilandia', 'SWZ', 'CAF', '🇸🇿'),
  ('Chad', 'CHA', 'CAF', '🇹🇩'),
  ('Gambia', 'GAM', 'CAF', '🇬🇲'),
  ('Sudán del Sur', 'SSD', 'CAF', '🇸🇸'),
  ('Yibuti', 'DJI', 'CAF', '🇩🇯'),
  ('Somalia', 'SOM', 'CAF', '🇸🇴'),
  ('Mauricio', 'MRI', 'CAF', '🇲🇺'),
  ('Santo Tomé y Príncipe', 'STP', 'CAF', '🇸🇹'),
  ('Seychelles', 'SEY', 'CAF', '🇸🇨'),
  ('Eritrea', 'ERI', 'CAF', '🇪🇷'),
  ('República Centroafricana', 'CTA', 'CAF', '🇨🇫'),
  ('Japón', 'JPN', 'AFC', '🇯🇵'),
  ('Irán', 'IRN', 'AFC', '🇮🇷'),
  ('Corea del Sur', 'KOR', 'AFC', '🇰🇷'),
  ('Australia', 'AUS', 'AFC', '🇦🇺'),
  ('Qatar', 'QAT', 'AFC', '🇶🇦'),
  ('Arabia Saudita', 'KSA', 'AFC', '🇸🇦'),
  ('Irak', 'IRQ', 'AFC', '🇮🇶'),
  ('Uzbekistán', 'UZB', 'AFC', '🇺🇿'),
  ('Emiratos Árabes Unidos', 'UAE', 'AFC', '🇦🇪'),
  ('Jordania', 'JOR', 'AFC', '🇯🇴'),
  ('Omán', 'OMA', 'AFC', '🇴🇲'),
  ('Baréin', 'BHR', 'AFC', '🇧🇭'),
  ('China', 'CHN', 'AFC', '🇨🇳'),
  ('Siria', 'SYR', 'AFC', '🇸🇾'),
  ('Palestina', 'PLE', 'AFC', '🇵🇸'),
  ('Vietnam', 'VIE', 'AFC', '🇻🇳'),
  ('Kirguistán', 'KGZ', 'AFC', '🇰🇬'),
  ('India', 'IND', 'AFC', '🇮🇳'),
  ('Tailandia', 'THA', 'AFC', '🇹🇭'),
  ('Líbano', 'LBN', 'AFC', '🇱🇧'),
  ('Tayikistán', 'TJK', 'AFC', '🇹🇯'),
  ('Corea del Norte', 'PRK', 'AFC', '🇰🇵'),
  ('Malasia', 'MAS', 'AFC', '🇲🇾'),
  ('Filipinas', 'PHI', 'AFC', '🇵🇭'),
  ('Turkmenistán', 'TKM', 'AFC', '🇹🇲'),
  ('Hong Kong', 'HKG', 'AFC', '🇭🇰'),
  ('Kuwait', 'KUW', 'AFC', '🇰🇼'),
  ('Myanmar', 'MYA', 'AFC', '🇲🇲'),
  ('Indonesia', 'IDN', 'AFC', '🇮🇩'),
  ('Yemen', 'YEM', 'AFC', '🇾🇪'),
  ('Afganistán', 'AFG', 'AFC', '🇦🇫'),
  ('Singapur', 'SGP', 'AFC', '🇸🇬'),
  ('Maldivas', 'MDV', 'AFC', '🇲🇻'),
  ('Nepal', 'NEP', 'AFC', '🇳🇵'),
  ('Camboya', 'CAM', 'AFC', '🇰🇭'),
  ('Chinese Taipei', 'TPE', 'AFC', '🇹🇼'),
  ('Mongolia', 'MNG', 'AFC', '🇲🇳'),
  ('Laos', 'LAO', 'AFC', '🇱🇦'),
  ('Macao', 'MAC', 'AFC', '🇲🇴'),
  ('Brunéi', 'BRU', 'AFC', '🇧🇳'),
  ('Timor Oriental', 'TLS', 'AFC', '🇹🇱'),
  ('Pakistán', 'PAK', 'AFC', '🇵🇰'),
  ('Sri Lanka', 'SRI', 'AFC', '🇱🇰'),
  ('Guam', 'GUM', 'AFC', '🇬🇺'),
  ('Bután', 'BHU', 'AFC', '🇧🇹'),
  ('Nueva Zelanda', 'NZL', 'OFC', '🇳🇿'),
  ('Nueva Caledonia', 'NCL', 'OFC', '🇳🇨'),
  ('Islas Salomón', 'SOL', 'OFC', '🇸🇧'),
  ('Fiyi', 'FIJ', 'OFC', '🇫🇯'),
  ('Tahití', 'TAH', 'OFC', '🇵🇫'),
  ('Vanuatu', 'VAN', 'OFC', '🇻🇺'),
  ('Papúa Nueva Guinea', 'PNG', 'OFC', '🇵🇬'),
  ('Samoa', 'SAM', 'OFC', '🇼🇸'),
  ('Islas Cook', 'COK', 'OFC', '🇨🇰'),
  ('Tonga', 'TGA', 'OFC', '🇹🇴'),
  ('Samoa Americana', 'ASA', 'OFC', '🇦🇸'),
  ('Bangladés', 'BAN', 'AFC', '🇧🇩')
on conflict (codigo_pais) do nothing;

insert into ediciones (nombre_edicion, anio, sede, pais_sede, equipos, campeon,
                       subcampeon, goleador, goles_goleador, asistencia_total,
                       promedio_asistencia, partidos, finalizada) values
  ('Uruguay 1930', 1930, 'Uruguay', 'Uruguay', 13, 'Uruguay', 'Argentina', 'Guillermo Stábile', 8, 590549, 32808, 18, true),
  ('Italia 1934', 1934, 'Italia', 'Italia', 16, 'Italia', 'Checoslovaquia', 'Oldřich Nejedlý', 5, 363000, 21353, 17, true),
  ('Francia 1938', 1938, 'Francia', 'Francia', 15, 'Italia', 'Hungría', 'Leônidas', 7, 375700, 20872, 18, true),
  ('Brasil 1950', 1950, 'Brasil', 'Brasil', 13, 'Uruguay', 'Brasil', 'Ademir', 9, 1045246, 47511, 22, true),
  ('Suiza 1954', 1954, 'Suiza', 'Suiza', 16, 'Alemania', 'Hungría', 'Sándor Kocsis', 11, 768607, 29562, 26, true),
  ('Suecia 1958', 1958, 'Suecia', 'Suecia', 16, 'Brasil', 'Suecia', 'Just Fontaine', 13, 819810, 23423, 35, true),
  ('Chile 1962', 1962, 'Chile', 'Chile', 16, 'Brasil', 'Checoslovaquia', 'Garrincha', 4, 893172, 27912, 32, true),
  ('Inglaterra 1966', 1966, 'Inglaterra', 'Inglaterra', 16, 'Inglaterra', 'Alemania', 'Eusébio', 9, 1563135, 48848, 32, true),
  ('México 1970', 1970, 'México', 'México', 16, 'Brasil', 'Italia', 'Gerd Müller', 10, 1673975, 52312, 32, true),
  ('Alemania 1974', 1974, 'Alemania', 'Alemania', 16, 'Alemania', 'Países Bajos', 'Grzegorz Lato', 7, 1865753, 49099, 38, true),
  ('Argentina 1978', 1978, 'Argentina', 'Argentina', 16, 'Argentina', 'Países Bajos', 'Mario Kempes', 6, 1545791, 40679, 38, true),
  ('España 1982', 1982, 'España', 'España', 24, 'Italia', 'Alemania', 'Paolo Rossi', 6, 2109723, 40572, 52, true),
  ('México 1986', 1986, 'México', 'México', 24, 'Argentina', 'Alemania', 'Gary Lineker', 6, 2394031, 46039, 52, true),
  ('Italia 1990', 1990, 'Italia', 'Italia', 24, 'Alemania', 'Argentina', 'Salvatore Schillaci', 6, 2516215, 48389, 52, true),
  ('Estados Unidos 1994', 1994, 'Estados Unidos', 'Estados Unidos', 24, 'Brasil', 'Italia', 'Oleg Salenko', 6, 3587538, 68991, 52, true),
  ('Francia 1998', 1998, 'Francia', 'Francia', 32, 'Francia', 'Brasil', 'Davor Šuker', 6, 2785100, 43517, 64, true),
  ('Corea del Sur 2002', 2002, 'Corea del Sur y Japón', 'Corea del Sur', 32, 'Brasil', 'Alemania', 'Ronaldo', 8, 2705197, 42269, 64, true),
  ('Alemania 2006', 2006, 'Alemania', 'Alemania', 32, 'Italia', 'Francia', 'Miroslav Klose', 5, 3359439, 52491, 64, true),
  ('Sudáfrica 2010', 2010, 'Sudáfrica', 'Sudáfrica', 32, 'España', 'Países Bajos', 'Thomas Müller', 5, 3178856, 49670, 64, true),
  ('Brasil 2014', 2014, 'Brasil', 'Brasil', 32, 'Alemania', 'Argentina', 'James Rodríguez', 6, 3429873, 53591, 64, true),
  ('Rusia 2018', 2018, 'Rusia', 'Rusia', 32, 'Francia', 'Croacia', 'Harry Kane', 6, 3031768, 47371, 64, true),
  ('Qatar 2022', 2022, 'Qatar', 'Qatar', 32, 'Argentina', 'Francia', 'Kylian Mbappé', 8, 3404252, 53191, 64, true)
on conflict (anio) do nothing;

-- Edición en curso: Mundial 2026 (sin campeón todavía → finalizada = false, RN01)
insert into ediciones (nombre_edicion, anio, sede, pais_sede, equipos, campeon,
                       subcampeon, goleador, goles_goleador, asistencia_total,
                       promedio_asistencia, partidos, fecha_inicio, finalizada) values
  ('Norteamérica 2026', 2026, 'Canadá, Estados Unidos y México', 'Estados Unidos',
   48, null, null, null, null, null, null, 104, '2026-06-11', false)
on conflict (anio) do nothing;


-- ///////////////////////////////////////////////////////////////////
-- Archivo: supabase/migrations/20260908120006_seed_ranking.sql
-- ///////////////////////////////////////////////////////////////////

-- =====================================================================
-- World Cup Data Hub · 006 · Seed del Ranking FIFA (ciclos 2022 y 2026)
-- 211 selecciones x 2 ciclos = 422 registros
-- =====================================================================

with datos (ciclo, codigo, posicion, puntos, partidos) as (values
  (2026, 'ARG', 1, 1855.0, 27),
  (2026, 'FRA', 2, 1842.0, 27),
  (2026, 'BRA', 3, 1821.0, 27),
  (2026, 'ENG', 4, 1798.0, 27),
  (2026, 'BEL', 5, 1765.0, 27),
  (2026, 'NED', 6, 1742.0, 27),
  (2026, 'POR', 7, 1739.0, 27),
  (2026, 'ESP', 8, 1727.26, 27),
  (2026, 'ITA', 9, 1716.38, 27),
  (2026, 'GER', 10, 1703.18, 27),
  (2026, 'CRO', 11, 1692.07, 27),
  (2026, 'COL', 12, 1678.9, 27),
  (2026, 'URU', 13, 1670.29, 27),
  (2026, 'USA', 14, 1659.61, 27),
  (2026, 'MEX', 15, 1648.01, 27),
  (2026, 'MAR', 16, 1640.02, 27),
  (2026, 'SUI', 17, 1627.64, 27),
  (2026, 'DEN', 18, 1621.31, 27),
  (2026, 'JPN', 19, 1609.61, 27),
  (2026, 'IRN', 20, 1601.57, 27),
  (2026, 'KOR', 21, 1595.43, 27),
  (2026, 'SEN', 22, 1589.9, 27),
  (2026, 'AUT', 23, 1582.05, 27),
  (2026, 'UKR', 24, 1576.76, 27),
  (2026, 'SWE', 25, 1574.9, 27),
  (2026, 'POL', 26, 1569.15, 27),
  (2026, 'WAL', 27, 1563.03, 27),
  (2026, 'AUS', 28, 1558.5, 27),
  (2026, 'SRB', 29, 1550.57, 27),
  (2026, 'TUR', 30, 1542.88, 27),
  (2026, 'PER', 31, 1540.05, 27),
  (2026, 'ECU', 32, 1536.99, 27),
  (2026, 'CHI', 33, 1531.51, 27),
  (2026, 'EGY', 34, 1528.19, 27),
  (2026, 'ALG', 35, 1526.13, 27),
  (2026, 'NGA', 36, 1521.12, 27),
  (2026, 'CIV', 37, 1516.34, 27),
  (2026, 'TUN', 38, 1509.42, 27),
  (2026, 'CMR', 39, 1508.7, 27),
  (2026, 'CAN', 40, 1502.82, 27),
  (2026, 'QAT', 41, 1498.96, 27),
  (2026, 'KSA', 42, 1494.69, 27),
  (2026, 'CRC', 43, 1491.48, 27),
  (2026, 'SCO', 44, 1486.89, 27),
  (2026, 'HUN', 45, 1480.83, 27),
  (2026, 'NOR', 46, 1478.63, 27),
  (2026, 'CZE', 47, 1475.7, 27),
  (2026, 'GRE', 48, 1470.8, 27),
  (2026, 'RUS', 49, 1466.11, 27),
  (2026, 'PAR', 50, 1464.08, 27),
  (2026, 'VEN', 51, 1457.51, 27),
  (2026, 'BOL', 52, 1455.04, 27),
  (2026, 'GHA', 53, 1454.29, 27),
  (2026, 'MLI', 54, 1448.78, 27),
  (2026, 'RSA', 55, 1445.69, 27),
  (2026, 'IRQ', 56, 1439.95, 27),
  (2026, 'UZB', 57, 1437.66, 27),
  (2026, 'UAE', 58, 1433.9, 27),
  (2026, 'JAM', 59, 1430.22, 27),
  (2026, 'PAN', 60, 1429.82, 27),
  (2026, 'ROU', 61, 1427.85, 27),
  (2026, 'SVK', 62, 1420.65, 27),
  (2026, 'SVN', 63, 1419.97, 27),
  (2026, 'IRL', 64, 1415.93, 27),
  (2026, 'ISL', 65, 1412.71, 27),
  (2026, 'FIN', 66, 1408.16, 27),
  (2026, 'BIH', 67, 1407.76, 27),
  (2026, 'ALB', 68, 1403.59, 27),
  (2026, 'MKD', 69, 1399.46, 27),
  (2026, 'GEO', 70, 1396.25, 27),
  (2026, 'ISR', 71, 1395.27, 27),
  (2026, 'BUL', 72, 1392.28, 27),
  (2026, 'MNE', 73, 1386.79, 27),
  (2026, 'NZL', 74, 1383.58, 27),
  (2026, 'BFA', 75, 1380.85, 27),
  (2026, 'COD', 76, 1375.84, 27),
  (2026, 'CPV', 77, 1375.1, 27),
  (2026, 'GUI', 78, 1370.41, 27),
  (2026, 'GAB', 79, 1367.09, 27),
  (2026, 'ZAM', 80, 1365.92, 27),
  (2026, 'ANG', 81, 1360.47, 27),
  (2026, 'JOR', 82, 1356.57, 27),
  (2026, 'OMA', 83, 1353.25, 27),
  (2026, 'BHR', 84, 1348.87, 27),
  (2026, 'CHN', 85, 1348.78, 27),
  (2026, 'SYR', 86, 1345.29, 27),
  (2026, 'PLE', 87, 1341.39, 27),
  (2026, 'VIE', 88, 1338.51, 27),
  (2026, 'HON', 89, 1335.15, 27),
  (2026, 'SLV', 90, 1334.11, 27),
  (2026, 'GUA', 91, 1327.6, 27),
  (2026, 'CUW', 92, 1325.53, 27),
  (2026, 'HAI', 93, 1322.46, 27),
  (2026, 'TRI', 94, 1320.83, 27),
  (2026, 'BLR', 95, 1317.54, 27),
  (2026, 'ARM', 96, 1313.09, 27),
  (2026, 'LUX', 97, 1311.64, 27),
  (2026, 'KVX', 98, 1308.06, 27),
  (2026, 'AZE', 99, 1302.28, 27),
  (2026, 'KAZ', 100, 1302.08, 27),
  (2026, 'EST', 101, 1294.99, 27),
  (2026, 'LVA', 102, 1294.95, 27),
  (2026, 'LTU', 103, 1292.43, 27),
  (2026, 'CYP', 104, 1288.08, 27),
  (2026, 'FRO', 105, 1284.76, 27),
  (2026, 'MDA', 106, 1284.33, 27),
  (2026, 'MLT', 107, 1281.34, 27),
  (2026, 'AND', 108, 1277.71, 27),
  (2026, 'GIB', 109, 1272.9, 27),
  (2026, 'LIE', 110, 1267.82, 27),
  (2026, 'SMR', 111, 1265.83, 27),
  (2026, 'NIR', 112, 1263.99, 27),
  (2026, 'UGA', 113, 1258.98, 27),
  (2026, 'BEN', 114, 1258.58, 27),
  (2026, 'EQG', 115, 1254.56, 27),
  (2026, 'MOZ', 116, 1251.75, 27),
  (2026, 'MAD', 117, 1246.57, 27),
  (2026, 'MTN', 118, 1243.5, 27),
  (2026, 'ZIM', 119, 1243.4, 27),
  (2026, 'NAM', 120, 1242.16, 27),
  (2026, 'KEN', 121, 1234.92, 27),
  (2026, 'LBY', 122, 1234.52, 27),
  (2026, 'TOG', 123, 1229.74, 27),
  (2026, 'SLE', 124, 1228.61, 27),
  (2026, 'CGO', 125, 1226.26, 27),
  (2026, 'SDN', 126, 1223.88, 27),
  (2026, 'COM', 127, 1219.04, 27),
  (2026, 'MWI', 128, 1215.48, 27),
  (2026, 'TAN', 129, 1209.67, 27),
  (2026, 'RWA', 130, 1207.07, 27),
  (2026, 'NIG', 131, 1205.02, 27),
  (2026, 'GNB', 132, 1202.55, 27),
  (2026, 'BDI', 133, 1200.05, 27),
  (2026, 'ETH', 134, 1194.36, 27),
  (2026, 'LBR', 135, 1192.1, 27),
  (2026, 'BOT', 136, 1185.77, 27),
  (2026, 'LES', 137, 1182.81, 27),
  (2026, 'SWZ', 138, 1181.24, 27),
  (2026, 'CHA', 139, 1179.69, 27),
  (2026, 'GAM', 140, 1175.88, 27),
  (2026, 'SSD', 141, 1170.62, 27),
  (2026, 'DJI', 142, 1165.12, 27),
  (2026, 'SOM', 143, 1164.64, 27),
  (2026, 'MRI', 144, 1162.58, 27),
  (2026, 'STP', 145, 1158.42, 27),
  (2026, 'SEY', 146, 1155.68, 27),
  (2026, 'ERI', 147, 1149.23, 27),
  (2026, 'CTA', 148, 1146.36, 27),
  (2026, 'KGZ', 149, 1144.94, 27),
  (2026, 'IND', 150, 1140.1, 27),
  (2026, 'THA', 151, 1134.28, 27),
  (2026, 'LBN', 152, 1129.17, 27),
  (2026, 'TJK', 153, 1125.43, 27),
  (2026, 'PRK', 154, 1125.14, 27),
  (2026, 'MAS', 155, 1116.76, 27),
  (2026, 'BAN', 156, 1114.04, 27),
  (2026, 'PHI', 157, 1109.87, 27),
  (2026, 'TKM', 158, 1107.75, 27),
  (2026, 'HKG', 159, 1099.83, 27),
  (2026, 'KUW', 160, 1098.05, 27),
  (2026, 'MYA', 161, 1092.94, 27),
  (2026, 'IDN', 162, 1088.62, 27),
  (2026, 'YEM', 163, 1084.53, 27),
  (2026, 'AFG', 164, 1079.31, 27),
  (2026, 'SGP', 165, 1079.24, 27),
  (2026, 'MDV', 166, 1073.16, 27),
  (2026, 'NEP', 167, 1070.12, 27),
  (2026, 'CAM', 168, 1062.67, 27),
  (2026, 'TPE', 169, 1060.3, 27),
  (2026, 'MNG', 170, 1055.67, 27),
  (2026, 'LAO', 171, 1050.98, 27),
  (2026, 'MAC', 172, 1048.09, 27),
  (2026, 'BRU', 173, 1044.29, 27),
  (2026, 'TLS', 174, 1037.05, 27),
  (2026, 'PAK', 175, 1034.5, 27),
  (2026, 'SRI', 176, 1028.08, 27),
  (2026, 'GUM', 177, 1026.31, 27),
  (2026, 'BHU', 178, 1016.53, 27),
  (2026, 'NCL', 179, 1013.62, 27),
  (2026, 'SOL', 180, 1009.69, 27),
  (2026, 'FIJ', 181, 1002.36, 27),
  (2026, 'TAH', 182, 998.47, 27),
  (2026, 'VAN', 183, 990.24, 27),
  (2026, 'PNG', 184, 987.45, 27),
  (2026, 'SAM', 185, 982.89, 27),
  (2026, 'COK', 186, 973.75, 27),
  (2026, 'TGA', 187, 970.35, 27),
  (2026, 'ASA', 188, 966.23, 27),
  (2026, 'SUR', 189, 959.48, 27),
  (2026, 'GUY', 190, 956.28, 27),
  (2026, 'NCA', 191, 946.9, 27),
  (2026, 'DOM', 192, 944.92, 27),
  (2026, 'CUB', 193, 937.25, 27),
  (2026, 'ATG', 194, 932.03, 27),
  (2026, 'SKN', 195, 926.57, 27),
  (2026, 'BLZ', 196, 919.49, 27),
  (2026, 'BER', 197, 915.22, 27),
  (2026, 'GRN', 198, 910.02, 27),
  (2026, 'VIN', 199, 904.22, 27),
  (2026, 'BRB', 200, 899.99, 27),
  (2026, 'PUR', 201, 890.49, 27),
  (2026, 'LCA', 202, 877.76, 27),
  (2026, 'DMA', 203, 867.11, 27),
  (2026, 'MSR', 204, 855.49, 27),
  (2026, 'CAY', 205, 845.36, 27),
  (2026, 'BAH', 206, 832.65, 27),
  (2026, 'ARU', 207, 825.12, 27),
  (2026, 'VIR', 208, 814.21, 27),
  (2026, 'VGB', 209, 803.4, 27),
  (2026, 'AIA', 210, 792.65, 27),
  (2026, 'TCA', 211, 778.66, 27),
  (2022, 'ARG', 1, 1843.7, 25),
  (2022, 'FRA', 2, 1831.98, 25),
  (2022, 'BRA', 3, 1813.36, 25),
  (2022, 'BEL', 4, 1788.04, 25),
  (2022, 'ENG', 5, 1759.48, 25),
  (2022, 'CRO', 6, 1734.08, 25),
  (2022, 'POR', 7, 1733.04, 25),
  (2022, 'NED', 8, 1720.34, 25),
  (2022, 'GER', 9, 1706.65, 25),
  (2022, 'ESP', 10, 1695.86, 25),
  (2022, 'ITA', 11, 1684.05, 25),
  (2022, 'DEN', 12, 1670.58, 25),
  (2022, 'SUI', 13, 1663.57, 25),
  (2022, 'URU', 14, 1649.81, 25),
  (2022, 'MEX', 15, 1641.99, 25),
  (2022, 'SEN', 16, 1633.72, 25),
  (2022, 'COL', 17, 1621.4, 25),
  (2022, 'USA', 18, 1612.22, 25),
  (2022, 'JPN', 19, 1603.04, 25),
  (2022, 'IRN', 20, 1590.71, 25),
  (2022, 'KOR', 21, 1588.72, 25),
  (2022, 'MAR', 22, 1579.79, 25),
  (2022, 'POL', 23, 1576.35, 25),
  (2022, 'WAL', 24, 1569.96, 25),
  (2022, 'UKR', 25, 1566.69, 25),
  (2022, 'AUS', 26, 1558.58, 25),
  (2022, 'TUR', 27, 1553.6, 25),
  (2022, 'AUT', 28, 1549.03, 25),
  (2022, 'SWE', 29, 1542.68, 25),
  (2022, 'PER', 30, 1540.08, 25),
  (2022, 'CHI', 31, 1535.04, 25),
  (2022, 'SRB', 32, 1531.57, 25),
  (2022, 'CIV', 33, 1525.17, 25),
  (2022, 'EGY', 34, 1519.91, 25),
  (2022, 'CAN', 35, 1518.92, 25),
  (2022, 'ECU', 36, 1511.86, 25),
  (2022, 'ALG', 37, 1510.07, 25),
  (2022, 'NGA', 38, 1504.24, 25),
  (2022, 'CMR', 39, 1502.3, 25),
  (2022, 'KSA', 40, 1496.28, 25),
  (2022, 'TUN', 41, 1494.12, 25),
  (2022, 'HUN', 42, 1487.88, 25),
  (2022, 'CRC', 43, 1482.61, 25),
  (2022, 'SCO', 44, 1481.42, 25),
  (2022, 'PAR', 45, 1476.86, 25),
  (2022, 'NOR', 46, 1470.08, 25),
  (2022, 'QAT', 47, 1466.65, 25),
  (2022, 'VEN', 48, 1465.36, 25),
  (2022, 'BOL', 49, 1458.65, 25),
  (2022, 'RUS', 50, 1457.13, 25),
  (2022, 'GHA', 51, 1451.88, 25),
  (2022, 'GRE', 52, 1447.12, 25),
  (2022, 'CZE', 53, 1446.26, 25),
  (2022, 'UZB', 54, 1441.03, 25),
  (2022, 'RSA', 55, 1440.63, 25),
  (2022, 'MLI', 56, 1436.14, 25),
  (2022, 'JAM', 57, 1430.68, 25),
  (2022, 'IRL', 58, 1428.27, 25),
  (2022, 'SVN', 59, 1425.82, 25),
  (2022, 'IRQ', 60, 1422.27, 25),
  (2022, 'UAE', 61, 1417.11, 25),
  (2022, 'PAN', 62, 1416.71, 25),
  (2022, 'ROU', 63, 1413.84, 25),
  (2022, 'ISL', 64, 1408.89, 25),
  (2022, 'SVK', 65, 1407.34, 25),
  (2022, 'ALB', 66, 1405.29, 25),
  (2022, 'BUL', 67, 1401.95, 25),
  (2022, 'CPV', 68, 1398.38, 25),
  (2022, 'BIH', 69, 1395.65, 25),
  (2022, 'FIN', 70, 1390.95, 25),
  (2022, 'GEO', 71, 1387.08, 25),
  (2022, 'NZL', 72, 1382.14, 25),
  (2022, 'MKD', 73, 1379.58, 25),
  (2022, 'COD', 74, 1376.21, 25),
  (2022, 'ISR', 75, 1375.9, 25),
  (2022, 'GAB', 76, 1371.73, 25),
  (2022, 'JOR', 77, 1364.97, 25),
  (2022, 'BFA', 78, 1364.53, 25),
  (2022, 'MNE', 79, 1359.81, 25),
  (2022, 'GUI', 80, 1357.03, 25),
  (2022, 'BHR', 81, 1355.4, 25),
  (2022, 'ANG', 82, 1351.06, 25),
  (2022, 'PLE', 83, 1349.7, 25),
  (2022, 'SLV', 84, 1345.0, 25),
  (2022, 'ZAM', 85, 1343.88, 25),
  (2022, 'OMA', 86, 1337.94, 25),
  (2022, 'SYR', 87, 1333.25, 25),
  (2022, 'CUW', 88, 1330.98, 25),
  (2022, 'HAI', 89, 1327.3, 25),
  (2022, 'VIE', 90, 1326.9, 25),
  (2022, 'CHN', 91, 1321.66, 25),
  (2022, 'LUX', 92, 1317.22, 25),
  (2022, 'HON', 93, 1315.0, 25),
  (2022, 'TRI', 94, 1313.05, 25),
  (2022, 'GUA', 95, 1308.96, 25),
  (2022, 'BLR', 96, 1307.54, 25),
  (2022, 'AZE', 97, 1301.6, 25),
  (2022, 'ARM', 98, 1301.48, 25),
  (2022, 'EST', 99, 1297.53, 25),
  (2022, 'KAZ', 100, 1291.71, 25),
  (2022, 'KVX', 101, 1289.14, 25),
  (2022, 'CYP', 102, 1287.33, 25),
  (2022, 'LTU', 103, 1283.79, 25),
  (2022, 'LVA', 104, 1282.02, 25),
  (2022, 'FRO', 105, 1279.75, 25),
  (2022, 'NIR', 106, 1274.58, 25),
  (2022, 'SMR', 107, 1272.29, 25),
  (2022, 'LIE', 108, 1270.6, 25),
  (2022, 'GIB', 109, 1268.33, 25),
  (2022, 'MDA', 110, 1265.19, 25),
  (2022, 'AND', 111, 1261.59, 25),
  (2022, 'UGA', 112, 1256.35, 25),
  (2022, 'EQG', 113, 1254.18, 25),
  (2022, 'MLT', 114, 1251.94, 25),
  (2022, 'BEN', 115, 1247.78, 25),
  (2022, 'MOZ', 116, 1247.54, 25),
  (2022, 'MTN', 117, 1245.82, 25),
  (2022, 'NAM', 118, 1242.83, 25),
  (2022, 'SLE', 119, 1239.46, 25),
  (2022, 'MAD', 120, 1235.21, 25),
  (2022, 'KEN', 121, 1230.64, 25),
  (2022, 'ZIM', 122, 1227.68, 25),
  (2022, 'TAN', 123, 1225.99, 25),
  (2022, 'TOG', 124, 1221.25, 25),
  (2022, 'COM', 125, 1220.85, 25),
  (2022, 'CGO', 126, 1217.8, 25),
  (2022, 'LBY', 127, 1210.4, 25),
  (2022, 'SDN', 128, 1209.28, 25),
  (2022, 'MWI', 129, 1203.56, 25),
  (2022, 'NIG', 130, 1203.16, 25),
  (2022, 'BDI', 131, 1197.95, 25),
  (2022, 'RWA', 132, 1197.07, 25),
  (2022, 'LES', 133, 1190.9, 25),
  (2022, 'GAM', 134, 1187.89, 25),
  (2022, 'GNB', 135, 1187.35, 25),
  (2022, 'ETH', 136, 1181.76, 25),
  (2022, 'SOM', 137, 1177.46, 25),
  (2022, 'DJI', 138, 1173.26, 25),
  (2022, 'LBR', 139, 1171.66, 25),
  (2022, 'BOT', 140, 1166.54, 25),
  (2022, 'MRI', 141, 1166.44, 25),
  (2022, 'SWZ', 142, 1162.75, 25),
  (2022, 'CHA', 143, 1159.47, 25),
  (2022, 'SSD', 144, 1156.51, 25),
  (2022, 'IND', 145, 1150.79, 25),
  (2022, 'SEY', 146, 1148.32, 25),
  (2022, 'STP', 147, 1142.98, 25),
  (2022, 'ERI', 148, 1141.69, 25),
  (2022, 'LBN', 149, 1138.37, 25),
  (2022, 'KGZ', 150, 1134.0, 25),
  (2022, 'CTA', 151, 1129.78, 25),
  (2022, 'THA', 152, 1125.71, 25),
  (2022, 'KUW', 153, 1120.73, 25),
  (2022, 'TJK', 154, 1120.59, 25),
  (2022, 'YEM', 155, 1115.78, 25),
  (2022, 'MAS', 156, 1108.16, 25),
  (2022, 'PRK', 157, 1104.39, 25),
  (2022, 'PHI', 158, 1103.66, 25),
  (2022, 'MYA', 159, 1099.1, 25),
  (2022, 'BAN', 160, 1093.16, 25),
  (2022, 'MDV', 161, 1088.29, 25),
  (2022, 'HKG', 162, 1082.73, 25),
  (2022, 'TKM', 163, 1081.06, 25),
  (2022, 'NEP', 164, 1074.91, 25),
  (2022, 'IDN', 165, 1071.97, 25),
  (2022, 'AFG', 166, 1066.52, 25),
  (2022, 'TPE', 167, 1063.83, 25),
  (2022, 'MAC', 168, 1059.74, 25),
  (2022, 'MNG', 169, 1055.5, 25),
  (2022, 'SGP', 170, 1052.71, 25),
  (2022, 'SRI', 171, 1045.92, 25),
  (2022, 'CAM', 172, 1044.75, 25),
  (2022, 'BHU', 173, 1038.65, 25),
  (2022, 'TLS', 174, 1034.82, 25),
  (2022, 'LAO', 175, 1032.05, 25),
  (2022, 'TAH', 176, 1024.1, 25),
  (2022, 'PAK', 177, 1022.08, 25),
  (2022, 'GUM', 178, 1013.68, 25),
  (2022, 'SOL', 179, 1009.42, 25),
  (2022, 'FIJ', 180, 1003.66, 25),
  (2022, 'BRU', 181, 996.35, 25),
  (2022, 'SAM', 182, 992.97, 25),
  (2022, 'NCL', 183, 989.74, 25),
  (2022, 'COK', 184, 983.1, 25),
  (2022, 'VAN', 185, 974.74, 25),
  (2022, 'DOM', 186, 972.79, 25),
  (2022, 'GUY', 187, 966.62, 25),
  (2022, 'ASA', 188, 958.26, 25),
  (2022, 'PNG', 189, 955.92, 25),
  (2022, 'TGA', 190, 947.38, 25),
  (2022, 'ATG', 191, 945.78, 25),
  (2022, 'NCA', 192, 941.16, 25),
  (2022, 'SKN', 193, 931.97, 25),
  (2022, 'CUB', 194, 927.04, 25),
  (2022, 'SUR', 195, 923.03, 25),
  (2022, 'BRB', 196, 916.74, 25),
  (2022, 'LCA', 197, 911.86, 25),
  (2022, 'BLZ', 198, 905.13, 25),
  (2022, 'MSR', 199, 899.09, 25),
  (2022, 'PUR', 200, 894.38, 25),
  (2022, 'BER', 201, 883.36, 25),
  (2022, 'VGB', 202, 874.94, 25),
  (2022, 'DMA', 203, 863.32, 25),
  (2022, 'GRN', 204, 852.74, 25),
  (2022, 'VIN', 205, 839.3, 25),
  (2022, 'BAH', 206, 829.39, 25),
  (2022, 'AIA', 207, 819.25, 25),
  (2022, 'TCA', 208, 809.28, 25),
  (2022, 'CAY', 209, 798.04, 25),
  (2022, 'VIR', 210, 788.59, 25),
  (2022, 'ARU', 211, 774.77, 25)
)
insert into ranking_fifa (ciclo, equipo_id, posicion, puntos, partidos_evaluados)
select d.ciclo, e.equipo_id, d.posicion, d.puntos, d.partidos
  from datos d
  join equipos e on e.codigo_pais = d.codigo
on conflict (ciclo, equipo_id) do update
  set posicion = excluded.posicion,
      puntos   = excluded.puntos,
      partidos_evaluados = excluded.partidos_evaluados;


-- ///////////////////////////////////////////////////////////////////
-- Archivo: supabase/migrations/20260908120007_seed_calendario_2026.sql
-- ///////////////////////////////////////////////////////////////////

-- =====================================================================
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
       (values ('Fase de Grupos', 1), ('Dieciseisavos de Final', 2), ('Octavos de Final', 3), ('Cuartos de Final', 4), ('Semifinal', 5), ('Tercer Lugar', 6), ('Final', 7)) as f(nombre, orden)
 where e.anio = 2026
on conflict (id_edicion, nombre_fase) do nothing;

-- 3) Registrar las 48 selecciones clasificadas con su grupo (RN04)
with clasificados (equipo, grupo) as (values
  ('México', 'A'),
  ('Canadá', 'A'),
  ('Noruega', 'A'),
  ('Uzbekistán', 'A'),
  ('España', 'B'),
  ('Marruecos', 'B'),
  ('Escocia', 'B'),
  ('Curazao', 'B'),
  ('Argentina', 'C'),
  ('Australia', 'C'),
  ('Egipto', 'C'),
  ('Panamá', 'C'),
  ('Brasil', 'D'),
  ('Corea del Sur', 'D'),
  ('Costa de Marfil', 'D'),
  ('Austria', 'D'),
  ('Francia', 'E'),
  ('Japón', 'E'),
  ('Senegal', 'E'),
  ('Jordania', 'E'),
  ('Estados Unidos', 'F'),
  ('Croacia', 'F'),
  ('Túnez', 'F'),
  ('Nueva Zelanda', 'F'),
  ('Inglaterra', 'G'),
  ('Irán', 'G'),
  ('Argelia', 'G'),
  ('Paraguay', 'G'),
  ('Portugal', 'H'),
  ('Ecuador', 'H'),
  ('Sudáfrica', 'H'),
  ('Qatar', 'H'),
  ('Países Bajos', 'I'),
  ('Colombia', 'I'),
  ('Ghana', 'I'),
  ('Arabia Saudita', 'I'),
  ('Bélgica', 'J'),
  ('Uruguay', 'J'),
  ('Cabo Verde', 'J'),
  ('Haití', 'J'),
  ('Alemania', 'K'),
  ('Suiza', 'K'),
  ('Nigeria', 'K'),
  ('Jamaica', 'K'),
  ('Italia', 'L'),
  ('Dinamarca', 'L'),
  ('Camerún', 'L'),
  ('Honduras', 'L')
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
  (1, '2026-06-11 12:00:00-05'::timestamptz, 1, 'Fase de Grupos', 'A'::char(1), NULL, NULL, 'México', 'Canadá'),
  (2, '2026-06-11 15:00:00-05'::timestamptz, 2, 'Fase de Grupos', 'B'::char(1), NULL, NULL, 'España', 'Marruecos'),
  (3, '2026-06-12 12:00:00-05'::timestamptz, 3, 'Fase de Grupos', 'C'::char(1), NULL, NULL, 'Argentina', 'Australia'),
  (4, '2026-06-12 15:00:00-05'::timestamptz, 4, 'Fase de Grupos', 'D'::char(1), NULL, NULL, 'Brasil', 'Corea del Sur'),
  (5, '2026-06-13 12:00:00-05'::timestamptz, 5, 'Fase de Grupos', 'E'::char(1), NULL, NULL, 'Francia', 'Japón'),
  (6, '2026-06-13 15:00:00-05'::timestamptz, 6, 'Fase de Grupos', 'F'::char(1), NULL, NULL, 'Estados Unidos', 'Croacia'),
  (7, '2026-06-14 12:00:00-05'::timestamptz, 7, 'Fase de Grupos', 'G'::char(1), NULL, NULL, 'Inglaterra', 'Irán'),
  (8, '2026-06-14 15:00:00-05'::timestamptz, 8, 'Fase de Grupos', 'H'::char(1), NULL, NULL, 'Portugal', 'Ecuador'),
  (9, '2026-06-15 12:00:00-05'::timestamptz, 9, 'Fase de Grupos', 'I'::char(1), NULL, NULL, 'Países Bajos', 'Colombia'),
  (10, '2026-06-15 15:00:00-05'::timestamptz, 10, 'Fase de Grupos', 'J'::char(1), NULL, NULL, 'Bélgica', 'Uruguay'),
  (11, '2026-06-16 12:00:00-05'::timestamptz, 11, 'Fase de Grupos', 'K'::char(1), NULL, NULL, 'Alemania', 'Suiza'),
  (12, '2026-06-16 15:00:00-05'::timestamptz, 12, 'Fase de Grupos', 'L'::char(1), NULL, NULL, 'Italia', 'Dinamarca'),
  (13, '2026-06-11 18:00:00-05'::timestamptz, 13, 'Fase de Grupos', 'A'::char(1), NULL, NULL, 'Noruega', 'Uzbekistán'),
  (14, '2026-06-11 21:00:00-05'::timestamptz, 14, 'Fase de Grupos', 'B'::char(1), NULL, NULL, 'Escocia', 'Curazao'),
  (15, '2026-06-12 18:00:00-05'::timestamptz, 15, 'Fase de Grupos', 'C'::char(1), NULL, NULL, 'Egipto', 'Panamá'),
  (16, '2026-06-12 21:00:00-05'::timestamptz, 16, 'Fase de Grupos', 'D'::char(1), NULL, NULL, 'Costa de Marfil', 'Austria'),
  (17, '2026-06-13 18:00:00-05'::timestamptz, 1, 'Fase de Grupos', 'E'::char(1), NULL, NULL, 'Senegal', 'Jordania'),
  (18, '2026-06-13 21:00:00-05'::timestamptz, 2, 'Fase de Grupos', 'F'::char(1), NULL, NULL, 'Túnez', 'Nueva Zelanda'),
  (19, '2026-06-14 18:00:00-05'::timestamptz, 3, 'Fase de Grupos', 'G'::char(1), NULL, NULL, 'Argelia', 'Paraguay'),
  (20, '2026-06-14 21:00:00-05'::timestamptz, 4, 'Fase de Grupos', 'H'::char(1), NULL, NULL, 'Sudáfrica', 'Qatar'),
  (21, '2026-06-15 18:00:00-05'::timestamptz, 5, 'Fase de Grupos', 'I'::char(1), NULL, NULL, 'Ghana', 'Arabia Saudita'),
  (22, '2026-06-15 21:00:00-05'::timestamptz, 6, 'Fase de Grupos', 'J'::char(1), NULL, NULL, 'Cabo Verde', 'Haití'),
  (23, '2026-06-16 18:00:00-05'::timestamptz, 7, 'Fase de Grupos', 'K'::char(1), NULL, NULL, 'Nigeria', 'Jamaica'),
  (24, '2026-06-16 21:00:00-05'::timestamptz, 8, 'Fase de Grupos', 'L'::char(1), NULL, NULL, 'Camerún', 'Honduras'),
  (25, '2026-06-17 12:00:00-05'::timestamptz, 9, 'Fase de Grupos', 'A'::char(1), NULL, NULL, 'México', 'Noruega'),
  (26, '2026-06-17 15:00:00-05'::timestamptz, 10, 'Fase de Grupos', 'B'::char(1), NULL, NULL, 'España', 'Escocia'),
  (27, '2026-06-18 12:00:00-05'::timestamptz, 11, 'Fase de Grupos', 'C'::char(1), NULL, NULL, 'Argentina', 'Egipto'),
  (28, '2026-06-18 15:00:00-05'::timestamptz, 12, 'Fase de Grupos', 'D'::char(1), NULL, NULL, 'Brasil', 'Costa de Marfil'),
  (29, '2026-06-19 12:00:00-05'::timestamptz, 13, 'Fase de Grupos', 'E'::char(1), NULL, NULL, 'Francia', 'Senegal'),
  (30, '2026-06-19 15:00:00-05'::timestamptz, 14, 'Fase de Grupos', 'F'::char(1), NULL, NULL, 'Estados Unidos', 'Túnez'),
  (31, '2026-06-20 12:00:00-05'::timestamptz, 15, 'Fase de Grupos', 'G'::char(1), NULL, NULL, 'Inglaterra', 'Argelia'),
  (32, '2026-06-20 15:00:00-05'::timestamptz, 16, 'Fase de Grupos', 'H'::char(1), NULL, NULL, 'Portugal', 'Sudáfrica'),
  (33, '2026-06-21 12:00:00-05'::timestamptz, 1, 'Fase de Grupos', 'I'::char(1), NULL, NULL, 'Países Bajos', 'Ghana'),
  (34, '2026-06-21 15:00:00-05'::timestamptz, 2, 'Fase de Grupos', 'J'::char(1), NULL, NULL, 'Bélgica', 'Cabo Verde'),
  (35, '2026-06-22 12:00:00-05'::timestamptz, 3, 'Fase de Grupos', 'K'::char(1), NULL, NULL, 'Alemania', 'Nigeria'),
  (36, '2026-06-22 15:00:00-05'::timestamptz, 4, 'Fase de Grupos', 'L'::char(1), NULL, NULL, 'Italia', 'Camerún'),
  (37, '2026-06-17 18:00:00-05'::timestamptz, 5, 'Fase de Grupos', 'A'::char(1), NULL, NULL, 'Canadá', 'Uzbekistán'),
  (38, '2026-06-17 21:00:00-05'::timestamptz, 6, 'Fase de Grupos', 'B'::char(1), NULL, NULL, 'Marruecos', 'Curazao'),
  (39, '2026-06-18 18:00:00-05'::timestamptz, 7, 'Fase de Grupos', 'C'::char(1), NULL, NULL, 'Australia', 'Panamá'),
  (40, '2026-06-18 21:00:00-05'::timestamptz, 8, 'Fase de Grupos', 'D'::char(1), NULL, NULL, 'Corea del Sur', 'Austria'),
  (41, '2026-06-19 18:00:00-05'::timestamptz, 9, 'Fase de Grupos', 'E'::char(1), NULL, NULL, 'Japón', 'Jordania'),
  (42, '2026-06-19 21:00:00-05'::timestamptz, 10, 'Fase de Grupos', 'F'::char(1), NULL, NULL, 'Croacia', 'Nueva Zelanda'),
  (43, '2026-06-20 18:00:00-05'::timestamptz, 11, 'Fase de Grupos', 'G'::char(1), NULL, NULL, 'Irán', 'Paraguay'),
  (44, '2026-06-20 21:00:00-05'::timestamptz, 12, 'Fase de Grupos', 'H'::char(1), NULL, NULL, 'Ecuador', 'Qatar'),
  (45, '2026-06-21 18:00:00-05'::timestamptz, 13, 'Fase de Grupos', 'I'::char(1), NULL, NULL, 'Colombia', 'Arabia Saudita'),
  (46, '2026-06-21 21:00:00-05'::timestamptz, 14, 'Fase de Grupos', 'J'::char(1), NULL, NULL, 'Uruguay', 'Haití'),
  (47, '2026-06-22 18:00:00-05'::timestamptz, 15, 'Fase de Grupos', 'K'::char(1), NULL, NULL, 'Suiza', 'Jamaica'),
  (48, '2026-06-22 21:00:00-05'::timestamptz, 16, 'Fase de Grupos', 'L'::char(1), NULL, NULL, 'Dinamarca', 'Honduras'),
  (49, '2026-06-23 12:00:00-05'::timestamptz, 1, 'Fase de Grupos', 'A'::char(1), NULL, NULL, 'México', 'Uzbekistán'),
  (50, '2026-06-23 15:00:00-05'::timestamptz, 2, 'Fase de Grupos', 'B'::char(1), NULL, NULL, 'España', 'Curazao'),
  (51, '2026-06-24 12:00:00-05'::timestamptz, 3, 'Fase de Grupos', 'C'::char(1), NULL, NULL, 'Argentina', 'Panamá'),
  (52, '2026-06-24 15:00:00-05'::timestamptz, 4, 'Fase de Grupos', 'D'::char(1), NULL, NULL, 'Brasil', 'Austria'),
  (53, '2026-06-25 12:00:00-05'::timestamptz, 5, 'Fase de Grupos', 'E'::char(1), NULL, NULL, 'Francia', 'Jordania'),
  (54, '2026-06-25 15:00:00-05'::timestamptz, 6, 'Fase de Grupos', 'F'::char(1), NULL, NULL, 'Estados Unidos', 'Nueva Zelanda'),
  (55, '2026-06-26 12:00:00-05'::timestamptz, 7, 'Fase de Grupos', 'G'::char(1), NULL, NULL, 'Inglaterra', 'Paraguay'),
  (56, '2026-06-26 15:00:00-05'::timestamptz, 8, 'Fase de Grupos', 'H'::char(1), NULL, NULL, 'Portugal', 'Qatar'),
  (57, '2026-06-27 12:00:00-05'::timestamptz, 9, 'Fase de Grupos', 'I'::char(1), NULL, NULL, 'Países Bajos', 'Arabia Saudita'),
  (58, '2026-06-27 15:00:00-05'::timestamptz, 10, 'Fase de Grupos', 'J'::char(1), NULL, NULL, 'Bélgica', 'Haití'),
  (59, '2026-06-28 12:00:00-05'::timestamptz, 11, 'Fase de Grupos', 'K'::char(1), NULL, NULL, 'Alemania', 'Jamaica'),
  (60, '2026-06-28 15:00:00-05'::timestamptz, 12, 'Fase de Grupos', 'L'::char(1), NULL, NULL, 'Italia', 'Honduras'),
  (61, '2026-06-23 18:00:00-05'::timestamptz, 13, 'Fase de Grupos', 'A'::char(1), NULL, NULL, 'Canadá', 'Noruega'),
  (62, '2026-06-23 21:00:00-05'::timestamptz, 14, 'Fase de Grupos', 'B'::char(1), NULL, NULL, 'Marruecos', 'Escocia'),
  (63, '2026-06-24 18:00:00-05'::timestamptz, 15, 'Fase de Grupos', 'C'::char(1), NULL, NULL, 'Australia', 'Egipto'),
  (64, '2026-06-24 21:00:00-05'::timestamptz, 16, 'Fase de Grupos', 'D'::char(1), NULL, NULL, 'Corea del Sur', 'Costa de Marfil'),
  (65, '2026-06-25 18:00:00-05'::timestamptz, 1, 'Fase de Grupos', 'E'::char(1), NULL, NULL, 'Japón', 'Senegal'),
  (66, '2026-06-25 21:00:00-05'::timestamptz, 2, 'Fase de Grupos', 'F'::char(1), NULL, NULL, 'Croacia', 'Túnez'),
  (67, '2026-06-26 18:00:00-05'::timestamptz, 3, 'Fase de Grupos', 'G'::char(1), NULL, NULL, 'Irán', 'Argelia'),
  (68, '2026-06-26 21:00:00-05'::timestamptz, 4, 'Fase de Grupos', 'H'::char(1), NULL, NULL, 'Ecuador', 'Sudáfrica'),
  (69, '2026-06-27 18:00:00-05'::timestamptz, 5, 'Fase de Grupos', 'I'::char(1), NULL, NULL, 'Colombia', 'Ghana'),
  (70, '2026-06-27 21:00:00-05'::timestamptz, 6, 'Fase de Grupos', 'J'::char(1), NULL, NULL, 'Uruguay', 'Cabo Verde'),
  (71, '2026-06-28 18:00:00-05'::timestamptz, 7, 'Fase de Grupos', 'K'::char(1), NULL, NULL, 'Suiza', 'Nigeria'),
  (72, '2026-06-28 21:00:00-05'::timestamptz, 8, 'Fase de Grupos', 'L'::char(1), NULL, NULL, 'Dinamarca', 'Camerún'),
  (73, '2026-06-28 12:00:00-05'::timestamptz, 9, 'Dieciseisavos de Final', NULL::char(1), '1º/2º Grupo 1', '1º/2º Grupo 2', NULL, NULL),
  (74, '2026-06-29 15:00:00-05'::timestamptz, 10, 'Dieciseisavos de Final', NULL::char(1), '1º/2º Grupo 3', '1º/2º Grupo 4', NULL, NULL),
  (75, '2026-06-30 18:00:00-05'::timestamptz, 11, 'Dieciseisavos de Final', NULL::char(1), '1º/2º Grupo 5', '1º/2º Grupo 6', NULL, NULL),
  (76, '2026-07-01 21:00:00-05'::timestamptz, 12, 'Dieciseisavos de Final', NULL::char(1), '1º/2º Grupo 7', '1º/2º Grupo 8', NULL, NULL),
  (77, '2026-07-02 12:00:00-05'::timestamptz, 13, 'Dieciseisavos de Final', NULL::char(1), '1º/2º Grupo 9', '1º/2º Grupo 10', NULL, NULL),
  (78, '2026-07-03 15:00:00-05'::timestamptz, 14, 'Dieciseisavos de Final', NULL::char(1), '1º/2º Grupo 11', '1º/2º Grupo 12', NULL, NULL),
  (79, '2026-06-28 18:00:00-05'::timestamptz, 15, 'Dieciseisavos de Final', NULL::char(1), '1º/2º Grupo 13', '1º/2º Grupo 14', NULL, NULL),
  (80, '2026-06-29 21:00:00-05'::timestamptz, 16, 'Dieciseisavos de Final', NULL::char(1), '1º/2º Grupo 15', '1º/2º Grupo 16', NULL, NULL),
  (81, '2026-06-30 12:00:00-05'::timestamptz, 1, 'Dieciseisavos de Final', NULL::char(1), '1º/2º Grupo 17', '1º/2º Grupo 18', NULL, NULL),
  (82, '2026-07-01 15:00:00-05'::timestamptz, 2, 'Dieciseisavos de Final', NULL::char(1), '1º/2º Grupo 19', '1º/2º Grupo 20', NULL, NULL),
  (83, '2026-07-02 18:00:00-05'::timestamptz, 3, 'Dieciseisavos de Final', NULL::char(1), '1º/2º Grupo 21', '1º/2º Grupo 22', NULL, NULL),
  (84, '2026-07-03 21:00:00-05'::timestamptz, 4, 'Dieciseisavos de Final', NULL::char(1), '1º/2º Grupo 23', '1º/2º Grupo 24', NULL, NULL),
  (85, '2026-06-28 12:00:00-05'::timestamptz, 5, 'Dieciseisavos de Final', NULL::char(1), '1º/2º Grupo 25', '1º/2º Grupo 26', NULL, NULL),
  (86, '2026-06-29 15:00:00-05'::timestamptz, 6, 'Dieciseisavos de Final', NULL::char(1), '1º/2º Grupo 27', '1º/2º Grupo 28', NULL, NULL),
  (87, '2026-06-30 18:00:00-05'::timestamptz, 7, 'Dieciseisavos de Final', NULL::char(1), '1º/2º Grupo 29', '1º/2º Grupo 30', NULL, NULL),
  (88, '2026-07-01 21:00:00-05'::timestamptz, 8, 'Dieciseisavos de Final', NULL::char(1), '1º/2º Grupo 31', '1º/2º Grupo 32', NULL, NULL),
  (89, '2026-07-04 12:00:00-05'::timestamptz, 9, 'Octavos de Final', NULL::char(1), 'Ganador D 1', 'Ganador D 2', NULL, NULL),
  (90, '2026-07-05 15:00:00-05'::timestamptz, 10, 'Octavos de Final', NULL::char(1), 'Ganador D 3', 'Ganador D 4', NULL, NULL),
  (91, '2026-07-06 18:00:00-05'::timestamptz, 11, 'Octavos de Final', NULL::char(1), 'Ganador D 5', 'Ganador D 6', NULL, NULL),
  (92, '2026-07-07 21:00:00-05'::timestamptz, 12, 'Octavos de Final', NULL::char(1), 'Ganador D 7', 'Ganador D 8', NULL, NULL),
  (93, '2026-07-04 12:00:00-05'::timestamptz, 13, 'Octavos de Final', NULL::char(1), 'Ganador D 9', 'Ganador D 10', NULL, NULL),
  (94, '2026-07-05 15:00:00-05'::timestamptz, 14, 'Octavos de Final', NULL::char(1), 'Ganador D 11', 'Ganador D 12', NULL, NULL),
  (95, '2026-07-06 18:00:00-05'::timestamptz, 15, 'Octavos de Final', NULL::char(1), 'Ganador D 13', 'Ganador D 14', NULL, NULL),
  (96, '2026-07-07 21:00:00-05'::timestamptz, 16, 'Octavos de Final', NULL::char(1), 'Ganador D 15', 'Ganador D 16', NULL, NULL),
  (97, '2026-07-09 12:00:00-05'::timestamptz, 1, 'Cuartos de Final', NULL::char(1), 'Ganador O 1', 'Ganador O 2', NULL, NULL),
  (98, '2026-07-10 15:00:00-05'::timestamptz, 2, 'Cuartos de Final', NULL::char(1), 'Ganador O 3', 'Ganador O 4', NULL, NULL),
  (99, '2026-07-11 18:00:00-05'::timestamptz, 3, 'Cuartos de Final', NULL::char(1), 'Ganador O 5', 'Ganador O 6', NULL, NULL),
  (100, '2026-07-09 21:00:00-05'::timestamptz, 4, 'Cuartos de Final', NULL::char(1), 'Ganador O 7', 'Ganador O 8', NULL, NULL),
  (101, '2026-07-14 12:00:00-05'::timestamptz, 5, 'Semifinal', NULL::char(1), 'Ganador C 1', 'Ganador C 2', NULL, NULL),
  (102, '2026-07-15 15:00:00-05'::timestamptz, 6, 'Semifinal', NULL::char(1), 'Ganador C 3', 'Ganador C 4', NULL, NULL),
  (103, '2026-07-18 12:00:00-05'::timestamptz, 14, 'Tercer Lugar', NULL::char(1), 'Perdedor SF 1', 'Perdedor SF 2', NULL, NULL),
  (104, '2026-07-19 15:00:00-05'::timestamptz, 6, 'Final', NULL::char(1), 'Ganador SF 1', 'Ganador SF 2', NULL, NULL)
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


-- ///////////////////////////////////////////////////////////////////
-- Archivo: supabase/migrations/20260908120008_seed_historico.sql
-- ///////////////////////////////////////////////////////////////////

-- =====================================================================
-- World Cup Data Hub · 008 · Seed histórico (1930–2022)
--
-- Completa las tablas del modelo entidad-relación que el seed 007 solo
-- llenaba para el Mundial 2026: sedes históricas, fases, partidos,
-- partido_equipo, edicion_sede, edicion_equipo, jugadores y
-- edicion_jugador.
--
-- Cobertura: 111 partidos de las 22 ediciones — la fase final
-- completa de cada torneo (semifinales donde existieron, tercer lugar y
-- final), la ronda final de Brasil 1950, el torneo ampliado de México
-- 1970 y todas las eliminatorias de Qatar 2022. El total oficial de
-- partidos por edición sigue viviendo en la columna ediciones.partidos.
--
-- En sede neutral no hay local ni visitante reales: en los partidos de
-- eliminación se registra primero al equipo que ganó o avanzó. La hora
-- exacta de los partidos antiguos no forma parte del dataset, así que
-- fecha_hora usa 15:00:00+00 como marca convencional.
-- =====================================================================

-- 1) Fecha de inicio de cada edición (la exige RN05 al insertar partidos)
update ediciones set fecha_inicio = v.inicio::date
  from (values
    (1930, '1930-07-13'),
    (1934, '1934-05-27'),
    (1938, '1938-06-04'),
    (1950, '1950-06-24'),
    (1954, '1954-06-16'),
    (1958, '1958-06-08'),
    (1962, '1962-05-30'),
    (1966, '1966-07-11'),
    (1970, '1970-05-31'),
    (1974, '1974-06-13'),
    (1978, '1978-06-01'),
    (1982, '1982-06-13'),
    (1986, '1986-05-31'),
    (1990, '1990-06-08'),
    (1994, '1994-06-17'),
    (1998, '1998-06-10'),
    (2002, '2002-05-31'),
    (2006, '2006-06-09'),
    (2010, '2010-06-11'),
    (2014, '2014-06-12'),
    (2018, '2018-06-14'),
    (2022, '2022-11-20')
  ) as v(anio, inicio)
 where ediciones.anio = v.anio and ediciones.fecha_inicio is null;

-- 2) Selecciones desaparecidas que disputaron estas ediciones y que ya
--    no figuran entre las 211 miembros actuales de la FIFA.
insert into equipos (nombre_equipo, codigo_pais, confederacion, bandera) values
  ('Checoslovaquia', 'TCH', 'UEFA', '🇨🇿'),
  ('URSS', 'URS', 'UEFA', '🇷🇺'),
  ('Yugoslavia', 'YUG', 'UEFA', '🇷🇸')
on conflict (codigo_pais) do nothing;

-- 3) Sedes históricas (63 estadios). La capacidad queda en null:
--    no forma parte del dataset para los estadios antiguos.
insert into sedes (nombre_estadio, ciudad, pais) values
  ('Estadio Centenario', 'Montevideo', 'Uruguay'),
  ('Stadio San Siro', 'Milán', 'Italia'),
  ('Stadio Giovanni Berta', 'Florencia', 'Italia'),
  ('Stadio Giorgio Ascarelli', 'Nápoles', 'Italia'),
  ('Stadio Nazionale PNF', 'Roma', 'Italia'),
  ('Stade Vélodrome', 'Marsella', 'Francia'),
  ('Parc des Princes', 'París', 'Francia'),
  ('Parc Lescure', 'Burdeos', 'Francia'),
  ('Stade Olympique de Colombes', 'Colombes', 'Francia'),
  ('Estadio Maracaná', 'Río de Janeiro', 'Brasil'),
  ('Estadio Pacaembú', 'São Paulo', 'Brasil'),
  ('Estadio St. Jakob', 'Basilea', 'Suiza'),
  ('Estadio La Pontaise', 'Lausana', 'Suiza'),
  ('Estadio Hardturm', 'Zúrich', 'Suiza'),
  ('Estadio Wankdorf', 'Berna', 'Suiza'),
  ('Estadio Råsunda', 'Solna', 'Suecia'),
  ('Nya Ullevi', 'Gotemburgo', 'Suecia'),
  ('Estadio Nacional de Chile', 'Santiago', 'Chile'),
  ('Estadio Sausalito', 'Viña del Mar', 'Chile'),
  ('Estadio de Wembley', 'Londres', 'Inglaterra'),
  ('Goodison Park', 'Liverpool', 'Inglaterra'),
  ('Estadio Azteca', 'Ciudad de México', 'México'),
  ('Estadio Cuauhtémoc', 'Puebla', 'México'),
  ('Estadio Jalisco', 'Guadalajara', 'México'),
  ('Estadio Nou Camp', 'León', 'México'),
  ('Olympiastadion', 'Múnich', 'Alemania'),
  ('Estadio Monumental', 'Buenos Aires', 'Argentina'),
  ('Camp Nou', 'Barcelona', 'España'),
  ('Estadio Ramón Sánchez Pizjuán', 'Sevilla', 'España'),
  ('Estadio José Rico Pérez', 'Alicante', 'España'),
  ('Estadio Santiago Bernabéu', 'Madrid', 'España'),
  ('Stadio San Paolo', 'Nápoles', 'Italia'),
  ('Stadio delle Alpi', 'Turín', 'Italia'),
  ('Stadio San Nicola', 'Bari', 'Italia'),
  ('Stadio Olimpico', 'Roma', 'Italia'),
  ('Giants Stadium', 'East Rutherford', 'Estados Unidos'),
  ('Rose Bowl', 'Pasadena', 'Estados Unidos'),
  ('Stade de France', 'Saint-Denis', 'Francia'),
  ('Estadio Mundialista de Seúl', 'Seúl', 'Corea del Sur'),
  ('Estadio Mundialista de Saitama', 'Saitama', 'Japón'),
  ('Estadio Mundialista de Daegu', 'Daegu', 'Corea del Sur'),
  ('Estadio Internacional de Yokohama', 'Yokohama', 'Japón'),
  ('Signal Iduna Park', 'Dortmund', 'Alemania'),
  ('Allianz Arena', 'Múnich', 'Alemania'),
  ('Gottlieb-Daimler-Stadion', 'Stuttgart', 'Alemania'),
  ('Olympiastadion', 'Berlín', 'Alemania'),
  ('Cape Town Stadium', 'Ciudad del Cabo', 'Sudáfrica'),
  ('Moses Mabhida', 'Durban', 'Sudáfrica'),
  ('Nelson Mandela Bay', 'Puerto Elizabeth', 'Sudáfrica'),
  ('Soccer City', 'Johannesburgo', 'Sudáfrica'),
  ('Estadio Mineirão', 'Belo Horizonte', 'Brasil'),
  ('Arena Corinthians', 'São Paulo', 'Brasil'),
  ('Estadio Nacional Mané Garrincha', 'Brasilia', 'Brasil'),
  ('Estadio Krestovski', 'San Petersburgo', 'Rusia'),
  ('Estadio Luzhnikí', 'Moscú', 'Rusia'),
  ('Estadio Internacional Jalifa', 'Rayán', 'Qatar'),
  ('Estadio Ahmad bin Ali', 'Rayán', 'Qatar'),
  ('Estadio Al Thumama', 'Doha', 'Qatar'),
  ('Estadio Al Bayt', 'Jor', 'Qatar'),
  ('Estadio Al Janoub', 'Wakrah', 'Qatar'),
  ('Estadio 974', 'Doha', 'Qatar'),
  ('Estadio Ciudad de la Educación', 'Rayán', 'Qatar'),
  ('Estadio Lusail', 'Lusail', 'Qatar')
on conflict (nombre_estadio, ciudad) do nothing;

-- 4) Sedes habilitadas por edición (RN08)
insert into edicion_sede (id_edicion, id_sede)
select e.id_edicion, s.id_sede
  from (values
    (1930, 'Estadio Centenario', 'Montevideo'),
    (1934, 'Stadio Giorgio Ascarelli', 'Nápoles'),
    (1934, 'Stadio Giovanni Berta', 'Florencia'),
    (1934, 'Stadio Nazionale PNF', 'Roma'),
    (1934, 'Stadio San Siro', 'Milán'),
    (1938, 'Parc Lescure', 'Burdeos'),
    (1938, 'Parc des Princes', 'París'),
    (1938, 'Stade Olympique de Colombes', 'Colombes'),
    (1938, 'Stade Vélodrome', 'Marsella'),
    (1950, 'Estadio Maracaná', 'Río de Janeiro'),
    (1950, 'Estadio Pacaembú', 'São Paulo'),
    (1954, 'Estadio Hardturm', 'Zúrich'),
    (1954, 'Estadio La Pontaise', 'Lausana'),
    (1954, 'Estadio St. Jakob', 'Basilea'),
    (1954, 'Estadio Wankdorf', 'Berna'),
    (1958, 'Estadio Råsunda', 'Solna'),
    (1958, 'Nya Ullevi', 'Gotemburgo'),
    (1962, 'Estadio Nacional de Chile', 'Santiago'),
    (1962, 'Estadio Sausalito', 'Viña del Mar'),
    (1966, 'Estadio de Wembley', 'Londres'),
    (1966, 'Goodison Park', 'Liverpool'),
    (1970, 'Estadio Azteca', 'Ciudad de México'),
    (1970, 'Estadio Cuauhtémoc', 'Puebla'),
    (1970, 'Estadio Jalisco', 'Guadalajara'),
    (1970, 'Estadio Nou Camp', 'León'),
    (1974, 'Olympiastadion', 'Múnich'),
    (1978, 'Estadio Monumental', 'Buenos Aires'),
    (1982, 'Camp Nou', 'Barcelona'),
    (1982, 'Estadio José Rico Pérez', 'Alicante'),
    (1982, 'Estadio Ramón Sánchez Pizjuán', 'Sevilla'),
    (1982, 'Estadio Santiago Bernabéu', 'Madrid'),
    (1986, 'Estadio Azteca', 'Ciudad de México'),
    (1986, 'Estadio Cuauhtémoc', 'Puebla'),
    (1986, 'Estadio Jalisco', 'Guadalajara'),
    (1990, 'Stadio Olimpico', 'Roma'),
    (1990, 'Stadio San Nicola', 'Bari'),
    (1990, 'Stadio San Paolo', 'Nápoles'),
    (1990, 'Stadio delle Alpi', 'Turín'),
    (1994, 'Giants Stadium', 'East Rutherford'),
    (1994, 'Rose Bowl', 'Pasadena'),
    (1998, 'Parc des Princes', 'París'),
    (1998, 'Stade Vélodrome', 'Marsella'),
    (1998, 'Stade de France', 'Saint-Denis'),
    (2002, 'Estadio Internacional de Yokohama', 'Yokohama'),
    (2002, 'Estadio Mundialista de Daegu', 'Daegu'),
    (2002, 'Estadio Mundialista de Saitama', 'Saitama'),
    (2002, 'Estadio Mundialista de Seúl', 'Seúl'),
    (2006, 'Allianz Arena', 'Múnich'),
    (2006, 'Gottlieb-Daimler-Stadion', 'Stuttgart'),
    (2006, 'Olympiastadion', 'Berlín'),
    (2006, 'Signal Iduna Park', 'Dortmund'),
    (2010, 'Cape Town Stadium', 'Ciudad del Cabo'),
    (2010, 'Moses Mabhida', 'Durban'),
    (2010, 'Nelson Mandela Bay', 'Puerto Elizabeth'),
    (2010, 'Soccer City', 'Johannesburgo'),
    (2014, 'Arena Corinthians', 'São Paulo'),
    (2014, 'Estadio Maracaná', 'Río de Janeiro'),
    (2014, 'Estadio Mineirão', 'Belo Horizonte'),
    (2014, 'Estadio Nacional Mané Garrincha', 'Brasilia'),
    (2018, 'Estadio Krestovski', 'San Petersburgo'),
    (2018, 'Estadio Luzhnikí', 'Moscú'),
    (2022, 'Estadio 974', 'Doha'),
    (2022, 'Estadio Ahmad bin Ali', 'Rayán'),
    (2022, 'Estadio Al Bayt', 'Jor'),
    (2022, 'Estadio Al Janoub', 'Wakrah'),
    (2022, 'Estadio Al Thumama', 'Doha'),
    (2022, 'Estadio Ciudad de la Educación', 'Rayán'),
    (2022, 'Estadio Internacional Jalifa', 'Rayán'),
    (2022, 'Estadio Lusail', 'Lusail')
  ) as v(anio, estadio, ciudad)
  join ediciones e on e.anio = v.anio
  join sedes s on s.nombre_estadio = v.estadio and s.ciudad = v.ciudad
on conflict do nothing;

-- 5) Fases de cada edición histórica
insert into fases (id_edicion, nombre_fase, orden)
select e.id_edicion, v.fase, v.orden
  from (values
    (1930, 'Semifinal', 5),
    (1930, 'Final', 7),
    (1934, 'Semifinal', 5),
    (1934, 'Tercer Lugar', 6),
    (1934, 'Final', 7),
    (1938, 'Semifinal', 5),
    (1938, 'Tercer Lugar', 6),
    (1938, 'Final', 7),
    (1950, 'Ronda Final', 2),
    (1954, 'Semifinal', 5),
    (1954, 'Tercer Lugar', 6),
    (1954, 'Final', 7),
    (1958, 'Semifinal', 5),
    (1958, 'Tercer Lugar', 6),
    (1958, 'Final', 7),
    (1962, 'Semifinal', 5),
    (1962, 'Tercer Lugar', 6),
    (1962, 'Final', 7),
    (1966, 'Semifinal', 5),
    (1966, 'Tercer Lugar', 6),
    (1966, 'Final', 7),
    (1970, 'Fase de Grupos', 1),
    (1970, 'Cuartos de Final', 4),
    (1970, 'Semifinal', 5),
    (1970, 'Tercer Lugar', 6),
    (1970, 'Final', 7),
    (1974, 'Tercer Lugar', 6),
    (1974, 'Final', 7),
    (1978, 'Tercer Lugar', 6),
    (1978, 'Final', 7),
    (1982, 'Semifinal', 5),
    (1982, 'Tercer Lugar', 6),
    (1982, 'Final', 7),
    (1986, 'Semifinal', 5),
    (1986, 'Tercer Lugar', 6),
    (1986, 'Final', 7),
    (1990, 'Semifinal', 5),
    (1990, 'Tercer Lugar', 6),
    (1990, 'Final', 7),
    (1994, 'Semifinal', 5),
    (1994, 'Tercer Lugar', 6),
    (1994, 'Final', 7),
    (1998, 'Semifinal', 5),
    (1998, 'Tercer Lugar', 6),
    (1998, 'Final', 7),
    (2002, 'Semifinal', 5),
    (2002, 'Tercer Lugar', 6),
    (2002, 'Final', 7),
    (2006, 'Semifinal', 5),
    (2006, 'Tercer Lugar', 6),
    (2006, 'Final', 7),
    (2010, 'Semifinal', 5),
    (2010, 'Tercer Lugar', 6),
    (2010, 'Final', 7),
    (2014, 'Semifinal', 5),
    (2014, 'Tercer Lugar', 6),
    (2014, 'Final', 7),
    (2018, 'Semifinal', 5),
    (2018, 'Tercer Lugar', 6),
    (2018, 'Final', 7),
    (2022, 'Octavos de Final', 3),
    (2022, 'Cuartos de Final', 4),
    (2022, 'Semifinal', 5),
    (2022, 'Tercer Lugar', 6),
    (2022, 'Final', 7)
  ) as v(anio, fase, orden)
  join ediciones e on e.anio = v.anio
on conflict (id_edicion, nombre_fase) do nothing;

-- 6) Selecciones participantes por edición (RN04). Para México 1970 y
--    Qatar 2022 se registra además el grupo inicial.
insert into edicion_equipo (id_edicion, equipo_id, grupo_inicial)
select e.id_edicion, q.equipo_id, v.grupo
  from (values
    (1930, 'Argentina', null),
    (1930, 'Estados Unidos', null),
    (1930, 'Uruguay', null),
    (1930, 'Yugoslavia', null),
    (1934, 'Alemania', null),
    (1934, 'Austria', null),
    (1934, 'Checoslovaquia', null),
    (1934, 'Italia', null),
    (1938, 'Brasil', null),
    (1938, 'Hungría', null),
    (1938, 'Italia', null),
    (1938, 'Suecia', null),
    (1950, 'Brasil', null),
    (1950, 'España', null),
    (1950, 'Suecia', null),
    (1950, 'Uruguay', null),
    (1954, 'Alemania', null),
    (1954, 'Austria', null),
    (1954, 'Hungría', null),
    (1954, 'Uruguay', null),
    (1958, 'Alemania', null),
    (1958, 'Brasil', null),
    (1958, 'Francia', null),
    (1958, 'Suecia', null),
    (1962, 'Brasil', null),
    (1962, 'Checoslovaquia', null),
    (1962, 'Chile', null),
    (1962, 'Yugoslavia', null),
    (1966, 'Alemania', null),
    (1966, 'Inglaterra', null),
    (1966, 'Portugal', null),
    (1966, 'URSS', null),
    (1970, 'Alemania', '4'),
    (1970, 'Brasil', '3'),
    (1970, 'Bulgaria', '4'),
    (1970, 'Bélgica', '1'),
    (1970, 'Checoslovaquia', '3'),
    (1970, 'El Salvador', '1'),
    (1970, 'Inglaterra', '3'),
    (1970, 'Israel', '2'),
    (1970, 'Italia', '2'),
    (1970, 'Marruecos', '4'),
    (1970, 'México', '1'),
    (1970, 'Perú', '4'),
    (1970, 'Rumania', '3'),
    (1970, 'Suecia', '2'),
    (1970, 'URSS', '1'),
    (1970, 'Uruguay', '2'),
    (1974, 'Alemania', null),
    (1974, 'Brasil', null),
    (1974, 'Países Bajos', null),
    (1974, 'Polonia', null),
    (1978, 'Argentina', null),
    (1978, 'Brasil', null),
    (1978, 'Italia', null),
    (1978, 'Países Bajos', null),
    (1982, 'Alemania', null),
    (1982, 'Francia', null),
    (1982, 'Italia', null),
    (1982, 'Polonia', null),
    (1986, 'Alemania', null),
    (1986, 'Argentina', null),
    (1986, 'Bélgica', null),
    (1986, 'Francia', null),
    (1986, 'Inglaterra', null),
    (1990, 'Alemania', null),
    (1990, 'Argentina', null),
    (1990, 'Inglaterra', null),
    (1990, 'Italia', null),
    (1994, 'Brasil', null),
    (1994, 'Bulgaria', null),
    (1994, 'Italia', null),
    (1994, 'Rusia', null),
    (1994, 'Suecia', null),
    (1998, 'Brasil', null),
    (1998, 'Croacia', null),
    (1998, 'Francia', null),
    (1998, 'Países Bajos', null),
    (2002, 'Alemania', null),
    (2002, 'Brasil', null),
    (2002, 'Corea del Sur', null),
    (2002, 'Türkiye', null),
    (2006, 'Alemania', null),
    (2006, 'Francia', null),
    (2006, 'Italia', null),
    (2006, 'Portugal', null),
    (2010, 'Alemania', null),
    (2010, 'España', null),
    (2010, 'Países Bajos', null),
    (2010, 'Uruguay', null),
    (2014, 'Alemania', null),
    (2014, 'Argentina', null),
    (2014, 'Brasil', null),
    (2014, 'Colombia', null),
    (2014, 'Países Bajos', null),
    (2018, 'Bélgica', null),
    (2018, 'Croacia', null),
    (2018, 'Francia', null),
    (2018, 'Inglaterra', null),
    (2022, 'Alemania', 'E'),
    (2022, 'Arabia Saudita', 'C'),
    (2022, 'Argentina', 'C'),
    (2022, 'Australia', 'D'),
    (2022, 'Brasil', 'G'),
    (2022, 'Bélgica', 'F'),
    (2022, 'Camerún', 'G'),
    (2022, 'Canadá', 'F'),
    (2022, 'Corea del Sur', 'H'),
    (2022, 'Costa Rica', 'E'),
    (2022, 'Croacia', 'F'),
    (2022, 'Dinamarca', 'D'),
    (2022, 'Ecuador', 'A'),
    (2022, 'España', 'E'),
    (2022, 'Estados Unidos', 'B'),
    (2022, 'Francia', 'D'),
    (2022, 'Gales', 'B'),
    (2022, 'Ghana', 'H'),
    (2022, 'Inglaterra', 'B'),
    (2022, 'Irán', 'B'),
    (2022, 'Japón', 'E'),
    (2022, 'Marruecos', 'F'),
    (2022, 'México', 'C'),
    (2022, 'Países Bajos', 'A'),
    (2022, 'Polonia', 'C'),
    (2022, 'Portugal', 'H'),
    (2022, 'Qatar', 'A'),
    (2022, 'Senegal', 'A'),
    (2022, 'Serbia', 'G'),
    (2022, 'Suiza', 'G'),
    (2022, 'Túnez', 'D'),
    (2022, 'Uruguay', 'H')
  ) as v(anio, equipo, grupo)
  join ediciones e on e.anio = v.anio
  join equipos q on q.nombre_equipo = v.equipo
on conflict (id_edicion, equipo_id) do nothing;

-- 7) La nota contextual de un partido (prórroga, penales, apodo del
--    encuentro) no estaba en el modelo original y es parte del dato.
alter table partidos add column if not exists nota text;
comment on column partidos.nota is
  'Detalle contextual del partido: prórroga, definición por penales o apodo histórico.';

-- La vista de RF05 expone ahora también la fecha suelta y esa nota.
drop view if exists v_partidos_edicion;
create view v_partidos_edicion as
select e.id_edicion,
       e.anio,
       p.id_partido,
       p.numero_partido,
       p.fecha_hora,
       (p.fecha_hora at time zone 'UTC')::date       as fecha,
       f.nombre_fase                                 as fase,
       coalesce(el.nombre_equipo, p.etiqueta_local)     as equipo_local,
       coalesce(ev.nombre_equipo, p.etiqueta_visitante) as equipo_visitante,
       pel.goles                                     as goles_local,
       pev.goles                                     as goles_visitante,
       s.nombre_estadio,
       s.ciudad,
       p.grupo,
       p.nota
  from partidos p
  join fases f     on f.id_fase = p.id_fase
  join ediciones e on e.id_edicion = f.id_edicion
  join sedes s     on s.id_sede = p.id_sede
  left join partido_equipo pel on pel.id_partido = p.id_partido and pel.tipo = 'local'
  left join partido_equipo pev on pev.id_partido = p.id_partido and pev.tipo = 'visitante'
  left join equipos el on el.equipo_id = pel.equipo_id
  left join equipos ev on ev.equipo_id = pev.equipo_id;

-- La vista se recreó, así que hay que devolverle el security_invoker
-- que le puso la migración 004 (hereda el RLS de sus tablas base).
alter view v_partidos_edicion set (security_invoker = on);
grant select on v_partidos_edicion to anon, authenticated;

-- 8) Partidos (111) con su fase, sede, marcador y nota
with datos (anio, numero, fecha, fase, estadio, ciudad, grupo,
            local, goles_local, visitante, goles_visitante, nota) as (values
  (1930, 1, '1930-07-26'::date, 'Semifinal', 'Estadio Centenario', 'Montevideo', null::char(1), 'Argentina', 6, 'Estados Unidos', 1, null),
  (1930, 2, '1930-07-27'::date, 'Semifinal', 'Estadio Centenario', 'Montevideo', null::char(1), 'Uruguay', 6, 'Yugoslavia', 1, null),
  (1930, 1, '1930-07-30'::date, 'Final', 'Estadio Centenario', 'Montevideo', null::char(1), 'Uruguay', 4, 'Argentina', 2, 'Primera final de la historia del torneo'),
  (1934, 1, '1934-06-03'::date, 'Semifinal', 'Stadio San Siro', 'Milán', null::char(1), 'Italia', 1, 'Austria', 0, null),
  (1934, 2, '1934-06-03'::date, 'Semifinal', 'Stadio Giovanni Berta', 'Florencia', null::char(1), 'Checoslovaquia', 3, 'Alemania', 1, null),
  (1934, 1, '1934-06-07'::date, 'Tercer Lugar', 'Stadio Giorgio Ascarelli', 'Nápoles', null::char(1), 'Alemania', 3, 'Austria', 2, null),
  (1934, 1, '1934-06-10'::date, 'Final', 'Stadio Nazionale PNF', 'Roma', null::char(1), 'Italia', 2, 'Checoslovaquia', 1, 'Tiempo suplementario'),
  (1938, 1, '1938-06-16'::date, 'Semifinal', 'Stade Vélodrome', 'Marsella', null::char(1), 'Italia', 2, 'Brasil', 1, null),
  (1938, 2, '1938-06-16'::date, 'Semifinal', 'Parc des Princes', 'París', null::char(1), 'Hungría', 5, 'Suecia', 1, null),
  (1938, 1, '1938-06-19'::date, 'Tercer Lugar', 'Parc Lescure', 'Burdeos', null::char(1), 'Brasil', 4, 'Suecia', 2, null),
  (1938, 1, '1938-06-19'::date, 'Final', 'Stade Olympique de Colombes', 'Colombes', null::char(1), 'Italia', 4, 'Hungría', 2, null),
  (1950, 1, '1950-07-09'::date, 'Ronda Final', 'Estadio Maracaná', 'Río de Janeiro', null::char(1), 'Brasil', 7, 'Suecia', 1, null),
  (1950, 2, '1950-07-09'::date, 'Ronda Final', 'Estadio Pacaembú', 'São Paulo', null::char(1), 'Uruguay', 2, 'España', 2, null),
  (1950, 3, '1950-07-13'::date, 'Ronda Final', 'Estadio Maracaná', 'Río de Janeiro', null::char(1), 'Brasil', 6, 'España', 1, null),
  (1950, 4, '1950-07-13'::date, 'Ronda Final', 'Estadio Pacaembú', 'São Paulo', null::char(1), 'Uruguay', 3, 'Suecia', 2, null),
  (1950, 5, '1950-07-16'::date, 'Ronda Final', 'Estadio Pacaembú', 'São Paulo', null::char(1), 'Suecia', 3, 'España', 1, null),
  (1950, 6, '1950-07-16'::date, 'Ronda Final', 'Estadio Maracaná', 'Río de Janeiro', null::char(1), 'Uruguay', 2, 'Brasil', 1, 'Partido decisivo: el «Maracanazo»'),
  (1954, 1, '1954-06-30'::date, 'Semifinal', 'Estadio St. Jakob', 'Basilea', null::char(1), 'Alemania', 6, 'Austria', 1, null),
  (1954, 2, '1954-06-30'::date, 'Semifinal', 'Estadio La Pontaise', 'Lausana', null::char(1), 'Hungría', 4, 'Uruguay', 2, null),
  (1954, 1, '1954-07-03'::date, 'Tercer Lugar', 'Estadio Hardturm', 'Zúrich', null::char(1), 'Austria', 3, 'Uruguay', 1, null),
  (1954, 1, '1954-07-04'::date, 'Final', 'Estadio Wankdorf', 'Berna', null::char(1), 'Alemania', 3, 'Hungría', 2, 'El «Milagro de Berna»'),
  (1958, 1, '1958-06-24'::date, 'Semifinal', 'Estadio Råsunda', 'Solna', null::char(1), 'Brasil', 5, 'Francia', 2, null),
  (1958, 2, '1958-06-24'::date, 'Semifinal', 'Nya Ullevi', 'Gotemburgo', null::char(1), 'Suecia', 3, 'Alemania', 1, null),
  (1958, 1, '1958-06-28'::date, 'Tercer Lugar', 'Nya Ullevi', 'Gotemburgo', null::char(1), 'Francia', 6, 'Alemania', 3, null),
  (1958, 1, '1958-06-29'::date, 'Final', 'Estadio Råsunda', 'Solna', null::char(1), 'Brasil', 5, 'Suecia', 2, 'Debut mundialista de Pelé como campeón'),
  (1962, 1, '1962-06-13'::date, 'Semifinal', 'Estadio Nacional de Chile', 'Santiago', null::char(1), 'Brasil', 4, 'Chile', 2, null),
  (1962, 2, '1962-06-13'::date, 'Semifinal', 'Estadio Sausalito', 'Viña del Mar', null::char(1), 'Checoslovaquia', 3, 'Yugoslavia', 1, null),
  (1962, 1, '1962-06-16'::date, 'Tercer Lugar', 'Estadio Nacional de Chile', 'Santiago', null::char(1), 'Chile', 1, 'Yugoslavia', 0, null),
  (1962, 1, '1962-06-17'::date, 'Final', 'Estadio Nacional de Chile', 'Santiago', null::char(1), 'Brasil', 3, 'Checoslovaquia', 1, null),
  (1966, 1, '1966-07-25'::date, 'Semifinal', 'Estadio de Wembley', 'Londres', null::char(1), 'Inglaterra', 2, 'Portugal', 1, null),
  (1966, 2, '1966-07-25'::date, 'Semifinal', 'Goodison Park', 'Liverpool', null::char(1), 'Alemania', 2, 'URSS', 1, null),
  (1966, 1, '1966-07-28'::date, 'Tercer Lugar', 'Estadio de Wembley', 'Londres', null::char(1), 'Portugal', 2, 'URSS', 1, null),
  (1966, 1, '1966-07-30'::date, 'Final', 'Estadio de Wembley', 'Londres', null::char(1), 'Inglaterra', 4, 'Alemania', 2, 'Tiempo suplementario'),
  (1970, 1, '1970-05-31'::date, 'Fase de Grupos', 'Estadio Azteca', 'Ciudad de México', '1'::char(1), 'México', 0, 'URSS', 0, null),
  (1970, 2, '1970-06-02'::date, 'Fase de Grupos', 'Estadio Azteca', 'Ciudad de México', '1'::char(1), 'Bélgica', 3, 'El Salvador', 0, null),
  (1970, 3, '1970-06-02'::date, 'Fase de Grupos', 'Estadio Cuauhtémoc', 'Puebla', '2'::char(1), 'Uruguay', 2, 'Israel', 0, null),
  (1970, 4, '1970-06-03'::date, 'Fase de Grupos', 'Estadio Jalisco', 'Guadalajara', '3'::char(1), 'Brasil', 4, 'Checoslovaquia', 1, null),
  (1970, 5, '1970-06-03'::date, 'Fase de Grupos', 'Estadio Jalisco', 'Guadalajara', '3'::char(1), 'Inglaterra', 1, 'Rumania', 0, null),
  (1970, 6, '1970-06-03'::date, 'Fase de Grupos', 'Estadio Nou Camp', 'León', '4'::char(1), 'Perú', 3, 'Bulgaria', 2, null),
  (1970, 7, '1970-06-06'::date, 'Fase de Grupos', 'Estadio Azteca', 'Ciudad de México', '1'::char(1), 'México', 4, 'El Salvador', 0, null),
  (1970, 8, '1970-06-07'::date, 'Fase de Grupos', 'Estadio Jalisco', 'Guadalajara', '3'::char(1), 'Brasil', 1, 'Inglaterra', 0, null),
  (1970, 9, '1970-06-10'::date, 'Fase de Grupos', 'Estadio Cuauhtémoc', 'Puebla', '2'::char(1), 'Italia', 0, 'Israel', 0, null),
  (1970, 10, '1970-06-11'::date, 'Fase de Grupos', 'Estadio Nou Camp', 'León', '4'::char(1), 'Alemania', 3, 'Perú', 1, null),
  (1970, 1, '1970-06-14'::date, 'Cuartos de Final', 'Estadio Jalisco', 'Guadalajara', null::char(1), 'Brasil', 4, 'Perú', 2, null),
  (1970, 2, '1970-06-14'::date, 'Cuartos de Final', 'Estadio Azteca', 'Ciudad de México', null::char(1), 'Italia', 4, 'México', 1, null),
  (1970, 3, '1970-06-14'::date, 'Cuartos de Final', 'Estadio Nou Camp', 'León', null::char(1), 'Alemania', 3, 'Inglaterra', 2, 'Tiempo suplementario'),
  (1970, 4, '1970-06-14'::date, 'Cuartos de Final', 'Estadio Azteca', 'Ciudad de México', null::char(1), 'Uruguay', 1, 'URSS', 0, 'Tiempo suplementario'),
  (1970, 1, '1970-06-17'::date, 'Semifinal', 'Estadio Azteca', 'Ciudad de México', null::char(1), 'Italia', 4, 'Alemania', 3, 'El «Partido del Siglo»'),
  (1970, 2, '1970-06-17'::date, 'Semifinal', 'Estadio Jalisco', 'Guadalajara', null::char(1), 'Brasil', 3, 'Uruguay', 1, null),
  (1970, 1, '1970-06-20'::date, 'Tercer Lugar', 'Estadio Azteca', 'Ciudad de México', null::char(1), 'Alemania', 1, 'Uruguay', 0, null),
  (1970, 1, '1970-06-21'::date, 'Final', 'Estadio Azteca', 'Ciudad de México', null::char(1), 'Brasil', 4, 'Italia', 1, 'Brasil se queda con la Copa Jules Rimet'),
  (1974, 1, '1974-07-06'::date, 'Tercer Lugar', 'Olympiastadion', 'Múnich', null::char(1), 'Polonia', 1, 'Brasil', 0, null),
  (1974, 1, '1974-07-07'::date, 'Final', 'Olympiastadion', 'Múnich', null::char(1), 'Alemania', 2, 'Países Bajos', 1, 'Sin semifinales: el torneo tuvo segunda fase de grupos'),
  (1978, 1, '1978-06-24'::date, 'Tercer Lugar', 'Estadio Monumental', 'Buenos Aires', null::char(1), 'Brasil', 2, 'Italia', 1, null),
  (1978, 1, '1978-06-25'::date, 'Final', 'Estadio Monumental', 'Buenos Aires', null::char(1), 'Argentina', 3, 'Países Bajos', 1, 'Tiempo suplementario'),
  (1982, 1, '1982-07-08'::date, 'Semifinal', 'Camp Nou', 'Barcelona', null::char(1), 'Italia', 2, 'Polonia', 0, null),
  (1982, 2, '1982-07-08'::date, 'Semifinal', 'Estadio Ramón Sánchez Pizjuán', 'Sevilla', null::char(1), 'Alemania', 3, 'Francia', 3, 'Alemania ganó 5-4 en penales'),
  (1982, 1, '1982-07-10'::date, 'Tercer Lugar', 'Estadio José Rico Pérez', 'Alicante', null::char(1), 'Polonia', 3, 'Francia', 2, null),
  (1982, 1, '1982-07-11'::date, 'Final', 'Estadio Santiago Bernabéu', 'Madrid', null::char(1), 'Italia', 3, 'Alemania', 1, null),
  (1986, 1, '1986-06-25'::date, 'Semifinal', 'Estadio Azteca', 'Ciudad de México', null::char(1), 'Argentina', 2, 'Bélgica', 0, null),
  (1986, 2, '1986-06-25'::date, 'Semifinal', 'Estadio Jalisco', 'Guadalajara', null::char(1), 'Alemania', 2, 'Francia', 0, null),
  (1986, 1, '1986-06-28'::date, 'Tercer Lugar', 'Estadio Cuauhtémoc', 'Puebla', null::char(1), 'Francia', 4, 'Bélgica', 2, 'Tiempo suplementario'),
  (1986, 1, '1986-06-29'::date, 'Final', 'Estadio Azteca', 'Ciudad de México', null::char(1), 'Argentina', 3, 'Alemania', 2, null),
  (1990, 1, '1990-07-03'::date, 'Semifinal', 'Stadio San Paolo', 'Nápoles', null::char(1), 'Argentina', 1, 'Italia', 1, 'Argentina ganó 4-3 en penales'),
  (1990, 2, '1990-07-04'::date, 'Semifinal', 'Stadio delle Alpi', 'Turín', null::char(1), 'Alemania', 1, 'Inglaterra', 1, 'Alemania ganó 4-3 en penales'),
  (1990, 1, '1990-07-07'::date, 'Tercer Lugar', 'Stadio San Nicola', 'Bari', null::char(1), 'Italia', 2, 'Inglaterra', 1, null),
  (1990, 1, '1990-07-08'::date, 'Final', 'Stadio Olimpico', 'Roma', null::char(1), 'Alemania', 1, 'Argentina', 0, null),
  (1994, 1, '1994-07-13'::date, 'Semifinal', 'Giants Stadium', 'East Rutherford', null::char(1), 'Italia', 2, 'Bulgaria', 1, null),
  (1994, 2, '1994-07-13'::date, 'Semifinal', 'Rose Bowl', 'Pasadena', null::char(1), 'Brasil', 1, 'Suecia', 0, null),
  (1994, 1, '1994-07-16'::date, 'Tercer Lugar', 'Rose Bowl', 'Pasadena', null::char(1), 'Suecia', 4, 'Bulgaria', 0, null),
  (1994, 1, '1994-07-17'::date, 'Final', 'Rose Bowl', 'Pasadena', null::char(1), 'Brasil', 0, 'Italia', 0, 'Brasil ganó 3-2 en penales'),
  (1998, 1, '1998-07-07'::date, 'Semifinal', 'Stade Vélodrome', 'Marsella', null::char(1), 'Brasil', 1, 'Países Bajos', 1, 'Brasil ganó 4-2 en penales'),
  (1998, 2, '1998-07-08'::date, 'Semifinal', 'Stade de France', 'Saint-Denis', null::char(1), 'Francia', 2, 'Croacia', 1, null),
  (1998, 1, '1998-07-11'::date, 'Tercer Lugar', 'Parc des Princes', 'París', null::char(1), 'Croacia', 2, 'Países Bajos', 1, null),
  (1998, 1, '1998-07-12'::date, 'Final', 'Stade de France', 'Saint-Denis', null::char(1), 'Francia', 3, 'Brasil', 0, null),
  (2002, 1, '2002-06-25'::date, 'Semifinal', 'Estadio Mundialista de Seúl', 'Seúl', null::char(1), 'Alemania', 1, 'Corea del Sur', 0, null),
  (2002, 2, '2002-06-26'::date, 'Semifinal', 'Estadio Mundialista de Saitama', 'Saitama', null::char(1), 'Brasil', 1, 'Türkiye', 0, null),
  (2002, 1, '2002-06-29'::date, 'Tercer Lugar', 'Estadio Mundialista de Daegu', 'Daegu', null::char(1), 'Türkiye', 3, 'Corea del Sur', 2, null),
  (2002, 1, '2002-06-30'::date, 'Final', 'Estadio Internacional de Yokohama', 'Yokohama', null::char(1), 'Brasil', 2, 'Alemania', 0, 'Primer Mundial organizado por dos países'),
  (2006, 1, '2006-07-04'::date, 'Semifinal', 'Signal Iduna Park', 'Dortmund', null::char(1), 'Italia', 2, 'Alemania', 0, 'Tiempo suplementario'),
  (2006, 2, '2006-07-05'::date, 'Semifinal', 'Allianz Arena', 'Múnich', null::char(1), 'Francia', 1, 'Portugal', 0, null),
  (2006, 1, '2006-07-08'::date, 'Tercer Lugar', 'Gottlieb-Daimler-Stadion', 'Stuttgart', null::char(1), 'Alemania', 3, 'Portugal', 1, null),
  (2006, 1, '2006-07-09'::date, 'Final', 'Olympiastadion', 'Berlín', null::char(1), 'Italia', 1, 'Francia', 1, 'Italia ganó 5-3 en penales'),
  (2010, 1, '2010-07-06'::date, 'Semifinal', 'Cape Town Stadium', 'Ciudad del Cabo', null::char(1), 'Países Bajos', 3, 'Uruguay', 2, null),
  (2010, 2, '2010-07-07'::date, 'Semifinal', 'Moses Mabhida', 'Durban', null::char(1), 'España', 1, 'Alemania', 0, null),
  (2010, 1, '2010-07-10'::date, 'Tercer Lugar', 'Nelson Mandela Bay', 'Puerto Elizabeth', null::char(1), 'Alemania', 3, 'Uruguay', 2, null),
  (2010, 1, '2010-07-11'::date, 'Final', 'Soccer City', 'Johannesburgo', null::char(1), 'España', 1, 'Países Bajos', 0, 'Tiempo suplementario'),
  (2014, 1, '2014-07-08'::date, 'Semifinal', 'Estadio Mineirão', 'Belo Horizonte', null::char(1), 'Alemania', 7, 'Brasil', 1, 'El «Mineirazo»'),
  (2014, 2, '2014-07-09'::date, 'Semifinal', 'Arena Corinthians', 'São Paulo', null::char(1), 'Argentina', 0, 'Países Bajos', 0, 'Argentina ganó 4-2 en penales'),
  (2014, 1, '2014-07-12'::date, 'Tercer Lugar', 'Estadio Nacional Mané Garrincha', 'Brasilia', null::char(1), 'Países Bajos', 3, 'Brasil', 0, null),
  (2014, 1, '2014-07-13'::date, 'Final', 'Estadio Maracaná', 'Río de Janeiro', null::char(1), 'Alemania', 1, 'Argentina', 0, 'Tiempo suplementario'),
  (2018, 1, '2018-07-10'::date, 'Semifinal', 'Estadio Krestovski', 'San Petersburgo', null::char(1), 'Francia', 1, 'Bélgica', 0, null),
  (2018, 2, '2018-07-11'::date, 'Semifinal', 'Estadio Luzhnikí', 'Moscú', null::char(1), 'Croacia', 2, 'Inglaterra', 1, 'Tiempo suplementario'),
  (2018, 1, '2018-07-14'::date, 'Tercer Lugar', 'Estadio Krestovski', 'San Petersburgo', null::char(1), 'Bélgica', 2, 'Inglaterra', 0, null),
  (2018, 1, '2018-07-15'::date, 'Final', 'Estadio Luzhnikí', 'Moscú', null::char(1), 'Francia', 4, 'Croacia', 2, null),
  (2022, 1, '2022-12-03'::date, 'Octavos de Final', 'Estadio Internacional Jalifa', 'Rayán', null::char(1), 'Países Bajos', 3, 'Estados Unidos', 1, null),
  (2022, 2, '2022-12-03'::date, 'Octavos de Final', 'Estadio Ahmad bin Ali', 'Rayán', null::char(1), 'Argentina', 2, 'Australia', 1, null),
  (2022, 3, '2022-12-04'::date, 'Octavos de Final', 'Estadio Al Thumama', 'Doha', null::char(1), 'Francia', 3, 'Polonia', 1, null),
  (2022, 4, '2022-12-04'::date, 'Octavos de Final', 'Estadio Al Bayt', 'Jor', null::char(1), 'Inglaterra', 3, 'Senegal', 0, null),
  (2022, 5, '2022-12-05'::date, 'Octavos de Final', 'Estadio Al Janoub', 'Wakrah', null::char(1), 'Croacia', 1, 'Japón', 1, 'Croacia ganó 3-1 en penales'),
  (2022, 6, '2022-12-05'::date, 'Octavos de Final', 'Estadio 974', 'Doha', null::char(1), 'Brasil', 4, 'Corea del Sur', 1, null),
  (2022, 7, '2022-12-06'::date, 'Octavos de Final', 'Estadio Ciudad de la Educación', 'Rayán', null::char(1), 'Marruecos', 0, 'España', 0, 'Marruecos ganó 3-0 en penales'),
  (2022, 8, '2022-12-06'::date, 'Octavos de Final', 'Estadio Lusail', 'Lusail', null::char(1), 'Portugal', 6, 'Suiza', 1, null),
  (2022, 1, '2022-12-09'::date, 'Cuartos de Final', 'Estadio Ciudad de la Educación', 'Rayán', null::char(1), 'Croacia', 1, 'Brasil', 1, 'Croacia ganó 4-2 en penales'),
  (2022, 2, '2022-12-09'::date, 'Cuartos de Final', 'Estadio Lusail', 'Lusail', null::char(1), 'Argentina', 2, 'Países Bajos', 2, 'Argentina ganó 4-3 en penales'),
  (2022, 3, '2022-12-10'::date, 'Cuartos de Final', 'Estadio Al Thumama', 'Doha', null::char(1), 'Marruecos', 1, 'Portugal', 0, 'Primera selección africana en semifinales'),
  (2022, 4, '2022-12-10'::date, 'Cuartos de Final', 'Estadio Al Bayt', 'Jor', null::char(1), 'Francia', 2, 'Inglaterra', 1, null),
  (2022, 1, '2022-12-13'::date, 'Semifinal', 'Estadio Lusail', 'Lusail', null::char(1), 'Argentina', 3, 'Croacia', 0, null),
  (2022, 2, '2022-12-14'::date, 'Semifinal', 'Estadio Al Bayt', 'Jor', null::char(1), 'Francia', 2, 'Marruecos', 0, null),
  (2022, 1, '2022-12-17'::date, 'Tercer Lugar', 'Estadio Internacional Jalifa', 'Rayán', null::char(1), 'Croacia', 2, 'Marruecos', 1, null),
  (2022, 1, '2022-12-18'::date, 'Final', 'Estadio Lusail', 'Lusail', null::char(1), 'Argentina', 3, 'Francia', 3, 'Argentina ganó 4-2 en penales')
),
insertados as (
  insert into partidos (numero_partido, fecha_hora, id_sede, id_fase,
                        grupo, nota)
  select d.numero,
         (d.fecha + time '15:00') at time zone 'UTC',
         s.id_sede, f.id_fase, d.grupo, d.nota
    from datos d
    join ediciones e on e.anio = d.anio
    join fases f on f.id_edicion = e.id_edicion and f.nombre_fase = d.fase
    join sedes s on s.nombre_estadio = d.estadio and s.ciudad = d.ciudad
  on conflict (id_fase, numero_partido) do nothing
  returning id_partido, id_fase, numero_partido
)
-- 9) Equipos y goles de cada partido (RN03: exactamente dos por partido)
insert into partido_equipo (id_partido, equipo_id, tipo, goles)
select i.id_partido, q.equipo_id, t.tipo,
       case t.tipo when 'local' then d.goles_local else d.goles_visitante end
  from insertados i
  join fases f on f.id_fase = i.id_fase
  join ediciones e on e.id_edicion = f.id_edicion
  join datos d on d.anio = e.anio and d.fase = f.nombre_fase
               and d.numero = i.numero_partido
  cross join (values ('local'), ('visitante')) as t(tipo)
  join equipos q on q.nombre_equipo =
       case t.tipo when 'local' then d.local else d.visitante end
on conflict (id_partido, equipo_id) do nothing;

-- 10) Goleadores de cada edición como jugadores del modelo
insert into jugadores (nombre_completo, posicion, equipo_id)
select v.nombre, v.posicion, q.equipo_id
  from (values
    ('Guillermo Stábile', 'Delantero', 'Argentina'),
    ('Oldřich Nejedlý', 'Delantero', 'Checoslovaquia'),
    ('Leônidas', 'Delantero', 'Brasil'),
    ('Ademir', 'Delantero', 'Brasil'),
    ('Sándor Kocsis', 'Delantero', 'Hungría'),
    ('Just Fontaine', 'Delantero', 'Francia'),
    ('Garrincha', 'Delantero', 'Brasil'),
    ('Eusébio', 'Delantero', 'Portugal'),
    ('Gerd Müller', 'Delantero', 'Alemania'),
    ('Grzegorz Lato', 'Delantero', 'Polonia'),
    ('Mario Kempes', 'Delantero', 'Argentina'),
    ('Paolo Rossi', 'Delantero', 'Italia'),
    ('Gary Lineker', 'Delantero', 'Inglaterra'),
    ('Salvatore Schillaci', 'Delantero', 'Italia'),
    ('Oleg Salenko', 'Delantero', 'Rusia'),
    ('Davor Šuker', 'Delantero', 'Croacia'),
    ('Ronaldo', 'Delantero', 'Brasil'),
    ('Miroslav Klose', 'Delantero', 'Alemania'),
    ('Thomas Müller', 'Delantero', 'Alemania'),
    ('James Rodríguez', 'Centrocampista', 'Colombia'),
    ('Harry Kane', 'Delantero', 'Inglaterra'),
    ('Kylian Mbappé', 'Delantero', 'Francia')
  ) as v(nombre, posicion, seleccion)
  join equipos q on q.nombre_equipo = v.seleccion
 where not exists (select 1 from jugadores j
                    where j.nombre_completo = v.nombre);

-- 11) Convocatoria del goleador a su edición (RN06)
insert into edicion_jugador (id_edicion, id_jugador)
select e.id_edicion, j.id_jugador
  from (values
    (1930, 'Guillermo Stábile'),
    (1934, 'Oldřich Nejedlý'),
    (1938, 'Leônidas'),
    (1950, 'Ademir'),
    (1954, 'Sándor Kocsis'),
    (1958, 'Just Fontaine'),
    (1962, 'Garrincha'),
    (1966, 'Eusébio'),
    (1970, 'Gerd Müller'),
    (1974, 'Grzegorz Lato'),
    (1978, 'Mario Kempes'),
    (1982, 'Paolo Rossi'),
    (1986, 'Gary Lineker'),
    (1990, 'Salvatore Schillaci'),
    (1994, 'Oleg Salenko'),
    (1998, 'Davor Šuker'),
    (2002, 'Ronaldo'),
    (2006, 'Miroslav Klose'),
    (2010, 'Thomas Müller'),
    (2014, 'James Rodríguez'),
    (2018, 'Harry Kane'),
    (2022, 'Kylian Mbappé')
  ) as v(anio, nombre)
  join ediciones e on e.anio = v.anio
  join jugadores j on j.nombre_completo = v.nombre
on conflict do nothing;

-- 12) Comprobación de RN03: no debe devolver ninguna fila
-- select * from fn_auditar_rn03();


-- ///////////////////////////////////////////////////////////////////
-- Archivo: supabase/migrations/20260908120009_resultado_2026.sql
-- ///////////////////////////////////////////////////////////////////

-- =====================================================================
-- World Cup Data Hub · 009 · Resultado del Mundial 2026
--
-- El torneo se jugó del 11 de junio al 19 de julio de 2026 y lo ganó
-- España. Hasta la migración 008 la edición seguía cargada como torneo
-- por disputarse (finalizada = false, sin campeón y con las 32 llaves de
-- eliminación como etiquetas del tipo «Ganador SF 1»), así que la
-- aplicación mostraba «próximos partidos» y las métricas terminaban en
-- 2022.
--
-- Cobertura de los partidos de eliminación que se cargan:
--   · Octavos, cuartos, semifinales, tercer lugar y final: los 16.
--   · Dieciseisavos: 9 de los 16.
--   · La fase de grupos conserva el sorteo del proyecto, que no
--     corresponde al sorteo real, y sigue sin marcador.
--
-- La hora exacta de cada partido no forma parte del dataset: se usa
-- 20:00 UTC como marca convencional, igual que en la migración 008.
-- =====================================================================

-- 1) Cierre de la edición con el resultado y las cifras oficiales
update ediciones set
     campeon             = 'España',
     subcampeon          = 'Argentina',
     goleador            = 'Kylian Mbappé',
     goles_goleador      = 10,
     asistencia_total    = 6810966,
     promedio_asistencia = 65490,
     finalizada          = true
 where anio = 2026;

-- 2) Fuera las llaves sin resolver: ya no hay nada por sortear.
delete from partidos p
 using fases f, ediciones e
 where p.id_fase = f.id_fase
   and f.id_edicion = e.id_edicion
   and e.anio = 2026
   and f.nombre_fase <> 'Fase de Grupos';

-- 3) Los 25 partidos de eliminación con su marcador
with datos (numero, fecha, fase, estadio, ciudad,
            local, goles_local, visitante, goles_visitante, nota) as (values
  (73, '2026-06-28'::date, 'Dieciseisavos de Final', 'SoFi Stadium', 'Los Ángeles', 'Canadá', 1, 'Sudáfrica', 0, null),
  (74, '2026-06-29'::date, 'Dieciseisavos de Final', 'NRG Stadium', 'Houston', 'Brasil', 2, 'Japón', 1, null),
  (75, '2026-06-29'::date, 'Dieciseisavos de Final', 'Gillette Stadium', 'Boston', 'Paraguay', 1, 'Alemania', 1, 'Paraguay ganó 4-3 en penales'),
  (76, '2026-06-29'::date, 'Dieciseisavos de Final', 'Estadio Akron', 'Guadalajara', 'Marruecos', 1, 'Países Bajos', 1, 'Marruecos ganó 3-2 en penales'),
  (77, '2026-06-30'::date, 'Dieciseisavos de Final', 'AT&T Stadium', 'Dallas', 'Noruega', 2, 'Costa de Marfil', 1, null),
  (78, '2026-06-30'::date, 'Dieciseisavos de Final', 'Estadio Azteca', 'Ciudad de México', 'México', 2, 'Ecuador', 0, null),
  (79, '2026-07-03'::date, 'Dieciseisavos de Final', 'AT&T Stadium', 'Dallas', 'Egipto', 1, 'Australia', 1, 'Egipto ganó 4-2 en penales'),
  (80, '2026-07-03'::date, 'Dieciseisavos de Final', 'Hard Rock Stadium', 'Miami', 'Argentina', 3, 'Cabo Verde', 2, 'Tiempo suplementario'),
  (81, '2026-07-03'::date, 'Dieciseisavos de Final', 'Arrowhead Stadium', 'Kansas City', 'Colombia', 1, 'Ghana', 0, null),
  (82, '2026-07-04'::date, 'Octavos de Final', 'NRG Stadium', 'Houston', 'Marruecos', 3, 'Canadá', 0, null),
  (83, '2026-07-04'::date, 'Octavos de Final', 'Lincoln Financial Field', 'Filadelfia', 'Francia', 1, 'Paraguay', 0, null),
  (84, '2026-07-05'::date, 'Octavos de Final', 'MetLife Stadium', 'Nueva York / Nueva Jersey', 'Noruega', 2, 'Brasil', 1, null),
  (85, '2026-07-05'::date, 'Octavos de Final', 'Estadio Azteca', 'Ciudad de México', 'Inglaterra', 3, 'México', 2, null),
  (86, '2026-07-06'::date, 'Octavos de Final', 'AT&T Stadium', 'Dallas', 'España', 1, 'Portugal', 0, null),
  (87, '2026-07-06'::date, 'Octavos de Final', 'Lumen Field', 'Seattle', 'Bélgica', 4, 'Estados Unidos', 1, null),
  (88, '2026-07-07'::date, 'Octavos de Final', 'Mercedes-Benz Stadium', 'Atlanta', 'Argentina', 3, 'Egipto', 2, 'Remontada de dos goles en los últimos once minutos'),
  (89, '2026-07-07'::date, 'Octavos de Final', 'BC Place', 'Vancouver', 'Suiza', 0, 'Colombia', 0, 'Suiza ganó 4-3 en penales'),
  (90, '2026-07-09'::date, 'Cuartos de Final', 'Gillette Stadium', 'Boston', 'Francia', 2, 'Marruecos', 0, null),
  (91, '2026-07-10'::date, 'Cuartos de Final', 'SoFi Stadium', 'Los Ángeles', 'España', 2, 'Bélgica', 1, null),
  (92, '2026-07-11'::date, 'Cuartos de Final', 'Hard Rock Stadium', 'Miami', 'Inglaterra', 2, 'Noruega', 1, 'Tiempo suplementario'),
  (93, '2026-07-11'::date, 'Cuartos de Final', 'Arrowhead Stadium', 'Kansas City', 'Argentina', 3, 'Suiza', 1, 'Tiempo suplementario'),
  (94, '2026-07-14'::date, 'Semifinal', 'AT&T Stadium', 'Dallas', 'España', 2, 'Francia', 0, null),
  (95, '2026-07-15'::date, 'Semifinal', 'Mercedes-Benz Stadium', 'Atlanta', 'Argentina', 2, 'Inglaterra', 1, null),
  (96, '2026-07-18'::date, 'Tercer Lugar', 'Hard Rock Stadium', 'Miami', 'Inglaterra', 6, 'Francia', 4, 'Hat-trick de Bukayo Saka; más goles en un partido por el tercer puesto'),
  (97, '2026-07-19'::date, 'Final', 'MetLife Stadium', 'Nueva York / Nueva Jersey', 'España', 1, 'Argentina', 0, 'Tiempo suplementario: gol de Ferran Torres al minuto 106')
),
insertados as (
  insert into partidos (numero_partido, fecha_hora, id_sede, id_fase, nota)
  select d.numero,
         (d.fecha + time '20:00') at time zone 'UTC',
         s.id_sede, f.id_fase, d.nota
    from datos d
    join ediciones e on e.anio = 2026
    join fases f on f.id_edicion = e.id_edicion and f.nombre_fase = d.fase
    join sedes s on s.nombre_estadio = d.estadio and s.ciudad = d.ciudad
  on conflict (id_fase, numero_partido) do nothing
  returning id_partido, id_fase, numero_partido
)
-- 4) Equipos y goles de cada partido (RN03: exactamente dos por partido)
insert into partido_equipo (id_partido, equipo_id, tipo, goles)
select i.id_partido, q.equipo_id, t.tipo,
       case t.tipo when 'local' then d.goles_local else d.goles_visitante end
  from insertados i
  join datos d on d.numero = i.numero_partido
  cross join (values ('local'), ('visitante')) as t(tipo)
  join equipos q on q.nombre_equipo =
       case t.tipo when 'local' then d.local else d.visitante end
on conflict (id_partido, equipo_id) do nothing;

-- 5) El goleador del torneo, convocado a esta edición (RN06)
insert into edicion_jugador (id_edicion, id_jugador)
select e.id_edicion, j.id_jugador
  from ediciones e, jugadores j
 where e.anio = 2026 and j.nombre_completo = 'Kylian Mbappé'
on conflict do nothing;

-- 6) El calendario ahora también lleva el marcador de cada partido.
drop view if exists v_calendario_2026;
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
       rv.puntos       as puntos_visitante,
       pel.goles       as goles_local,
       pev.goles       as goles_visitante
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

alter view v_calendario_2026 set (security_invoker = on);
grant select on v_calendario_2026 to anon, authenticated;

-- 7) La métrica de partidos de 2026 debe ser el total del torneo (104),
--    no cuántos partidos se alcanzaron a cargar en la tabla.
drop view if exists v_metricas_globales;
create view v_metricas_globales as
select
  (select count(*) from ediciones where finalizada)                  as ediciones_historicas,
  (select coalesce(sum(partidos),0) from ediciones where finalizada) as partidos_historicos,
  (select count(*) from ranking_fifa where ciclo = 2026)             as selecciones_ranking_2026,
  (select partidos from ediciones where anio = 2026)                 as partidos_programados_2026,
  (select min(anio) from ediciones where finalizada)                 as anio_min,
  (select max(anio) from ediciones where finalizada)                 as anio_max;

alter view v_metricas_globales set (security_invoker = on);
grant select on v_metricas_globales to anon, authenticated;

-- 8) Comprobaciones
-- select anio, campeon, subcampeon, goleador from ediciones where anio = 2026;
-- select count(*) from v_calendario_2026 where goles_local is not null;  -- 25
-- select * from fn_auditar_rn03();  -- sin filas

-- =====================================================================
-- Comprobaciones finales (opcionales)
-- =====================================================================
-- select count(*) from ediciones where finalizada;        -- 23, de 1930 a 2026
-- select anio, campeon, subcampeon, goleador from ediciones where anio = 2026;
-- select count(*) from equipos;                           -- 214
-- select count(*) from sedes;                             -- 79
-- select count(*) from ranking_fifa where ciclo = 2026;   -- 211
-- select count(*) from v_calendario_2026;                 -- 97
-- select count(*) from v_calendario_2026 where goles_local is not null;  -- 25
-- select count(*) from v_partidos_edicion where goles_local is not null; -- 136
-- select * from fn_auditar_rn03();                        -- sin filas
