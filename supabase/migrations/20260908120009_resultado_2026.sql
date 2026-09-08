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
