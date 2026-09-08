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
