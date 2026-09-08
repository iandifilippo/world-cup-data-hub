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
