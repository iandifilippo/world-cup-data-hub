-- =====================================================================
-- World Cup Data Hub · 009 · Mundial 2026 (torneo ya disputado)
--
-- El torneo se jugó del 11 de junio al 19 de julio de 2026 y lo ganó
-- España, que venció 1-0 a Argentina en la prórroga de la final. Hasta
-- la migración 008 la edición seguía cargada como torneo por disputarse:
-- sin campeón, con `finalizada = false`, con el sorteo que el proyecto
-- había supuesto y con las 32 llaves de eliminación como etiquetas del
-- tipo «Ganador SF 1». Por eso la aplicación mostraba «próximos
-- partidos» y el rango de las métricas terminaba en 2022.
--
-- Esta migración reemplaza el Mundial 2026 completo por los datos
-- reales: los 12 grupos, sus 48 selecciones y los 104 partidos con
-- marcador, sede y fase.
--
-- El marcador guarda el resultado de los 120 minutos; las prórrogas y
-- las tandas de penales van en la columna `nota`. La hora exacta no
-- forma parte del dataset: se usa 20:00 UTC como marca convencional.
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

-- 2) Fuera el calendario supuesto: se vuelve a cargar con el real.
--    partido_equipo cae por la cascada de la llave foránea.
delete from partidos p
 using fases f, ediciones e
 where p.id_fase = f.id_fase
   and f.id_edicion = e.id_edicion
   and e.anio = 2026;

delete from edicion_equipo
 where id_edicion = (select id_edicion from ediciones where anio = 2026);

-- 3) El sorteo real: 48 selecciones en 12 grupos (RN04)
insert into edicion_equipo (id_edicion, equipo_id, grupo_inicial)
select e.id_edicion, q.equipo_id, v.grupo
  from (values
    ('México', 'A'::char(1)),
    ('Sudáfrica', 'A'::char(1)),
    ('Corea del Sur', 'A'::char(1)),
    ('República Checa', 'A'::char(1)),
    ('Suiza', 'B'::char(1)),
    ('Canadá', 'B'::char(1)),
    ('Bosnia y Herzegovina', 'B'::char(1)),
    ('Qatar', 'B'::char(1)),
    ('Brasil', 'C'::char(1)),
    ('Marruecos', 'C'::char(1)),
    ('Escocia', 'C'::char(1)),
    ('Haití', 'C'::char(1)),
    ('Estados Unidos', 'D'::char(1)),
    ('Australia', 'D'::char(1)),
    ('Paraguay', 'D'::char(1)),
    ('Türkiye', 'D'::char(1)),
    ('Alemania', 'E'::char(1)),
    ('Costa de Marfil', 'E'::char(1)),
    ('Ecuador', 'E'::char(1)),
    ('Curazao', 'E'::char(1)),
    ('Países Bajos', 'F'::char(1)),
    ('Japón', 'F'::char(1)),
    ('Suecia', 'F'::char(1)),
    ('Túnez', 'F'::char(1)),
    ('Bélgica', 'G'::char(1)),
    ('Egipto', 'G'::char(1)),
    ('Irán', 'G'::char(1)),
    ('Nueva Zelanda', 'G'::char(1)),
    ('España', 'H'::char(1)),
    ('Cabo Verde', 'H'::char(1)),
    ('Uruguay', 'H'::char(1)),
    ('Arabia Saudita', 'H'::char(1)),
    ('Francia', 'I'::char(1)),
    ('Noruega', 'I'::char(1)),
    ('Senegal', 'I'::char(1)),
    ('Irak', 'I'::char(1)),
    ('Argentina', 'J'::char(1)),
    ('Austria', 'J'::char(1)),
    ('Argelia', 'J'::char(1)),
    ('Jordania', 'J'::char(1)),
    ('Colombia', 'K'::char(1)),
    ('Portugal', 'K'::char(1)),
    ('RD del Congo', 'K'::char(1)),
    ('Uzbekistán', 'K'::char(1)),
    ('Inglaterra', 'L'::char(1)),
    ('Croacia', 'L'::char(1)),
    ('Ghana', 'L'::char(1)),
    ('Panamá', 'L'::char(1))
  ) as v(equipo, grupo)
  join ediciones e on e.anio = 2026
  join equipos q on q.nombre_equipo = v.equipo
on conflict (id_edicion, equipo_id) do nothing;

-- 4) Los 104 partidos con su fase, sede, grupo y marcador
with datos (numero, fecha, fase, estadio, ciudad, grupo,
            local, goles_local, visitante, goles_visitante, nota) as (values
  (1, '2026-06-11'::date, 'Fase de Grupos', 'Estadio Azteca', 'Ciudad de México', 'A'::char(1), 'México', 2, 'Sudáfrica', 0, null),
  (2, '2026-06-11'::date, 'Fase de Grupos', 'Estadio Akron', 'Guadalajara', 'A'::char(1), 'Corea del Sur', 2, 'República Checa', 1, null),
  (3, '2026-06-18'::date, 'Fase de Grupos', 'Mercedes-Benz Stadium', 'Atlanta', 'A'::char(1), 'República Checa', 1, 'Sudáfrica', 1, null),
  (4, '2026-06-18'::date, 'Fase de Grupos', 'Estadio Akron', 'Guadalajara', 'A'::char(1), 'México', 1, 'Corea del Sur', 0, null),
  (5, '2026-06-24'::date, 'Fase de Grupos', 'Estadio Azteca', 'Ciudad de México', 'A'::char(1), 'República Checa', 0, 'México', 3, null),
  (6, '2026-06-24'::date, 'Fase de Grupos', 'Estadio BBVA', 'Monterrey', 'A'::char(1), 'Sudáfrica', 1, 'Corea del Sur', 0, 'Sudáfrica llegó por primera vez a la fase de eliminación'),
  (7, '2026-06-12'::date, 'Fase de Grupos', 'BMO Field', 'Toronto', 'B'::char(1), 'Canadá', 1, 'Bosnia y Herzegovina', 1, null),
  (8, '2026-06-13'::date, 'Fase de Grupos', 'Levi''s Stadium', 'San Francisco Bay Area', 'B'::char(1), 'Qatar', 1, 'Suiza', 1, null),
  (9, '2026-06-18'::date, 'Fase de Grupos', 'SoFi Stadium', 'Los Ángeles', 'B'::char(1), 'Suiza', 4, 'Bosnia y Herzegovina', 1, null),
  (10, '2026-06-18'::date, 'Fase de Grupos', 'BC Place', 'Vancouver', 'B'::char(1), 'Canadá', 6, 'Qatar', 0, null),
  (11, '2026-06-24'::date, 'Fase de Grupos', 'BC Place', 'Vancouver', 'B'::char(1), 'Suiza', 2, 'Canadá', 1, null),
  (12, '2026-06-24'::date, 'Fase de Grupos', 'Lumen Field', 'Seattle', 'B'::char(1), 'Bosnia y Herzegovina', 3, 'Qatar', 1, null),
  (13, '2026-06-13'::date, 'Fase de Grupos', 'MetLife Stadium', 'Nueva York / Nueva Jersey', 'C'::char(1), 'Brasil', 1, 'Marruecos', 1, null),
  (14, '2026-06-13'::date, 'Fase de Grupos', 'Gillette Stadium', 'Boston', 'C'::char(1), 'Haití', 0, 'Escocia', 1, null),
  (15, '2026-06-19'::date, 'Fase de Grupos', 'Gillette Stadium', 'Boston', 'C'::char(1), 'Escocia', 0, 'Marruecos', 1, null),
  (16, '2026-06-19'::date, 'Fase de Grupos', 'Lincoln Financial Field', 'Filadelfia', 'C'::char(1), 'Brasil', 3, 'Haití', 0, null),
  (17, '2026-06-24'::date, 'Fase de Grupos', 'Hard Rock Stadium', 'Miami', 'C'::char(1), 'Escocia', 0, 'Brasil', 3, null),
  (18, '2026-06-24'::date, 'Fase de Grupos', 'Mercedes-Benz Stadium', 'Atlanta', 'C'::char(1), 'Marruecos', 4, 'Haití', 2, null),
  (19, '2026-06-12'::date, 'Fase de Grupos', 'SoFi Stadium', 'Los Ángeles', 'D'::char(1), 'Estados Unidos', 4, 'Paraguay', 1, null),
  (20, '2026-06-13'::date, 'Fase de Grupos', 'BC Place', 'Vancouver', 'D'::char(1), 'Australia', 2, 'Türkiye', 0, null),
  (21, '2026-06-19'::date, 'Fase de Grupos', 'Lumen Field', 'Seattle', 'D'::char(1), 'Estados Unidos', 2, 'Australia', 0, null),
  (22, '2026-06-19'::date, 'Fase de Grupos', 'Levi''s Stadium', 'San Francisco Bay Area', 'D'::char(1), 'Türkiye', 0, 'Paraguay', 1, null),
  (23, '2026-06-25'::date, 'Fase de Grupos', 'SoFi Stadium', 'Los Ángeles', 'D'::char(1), 'Türkiye', 3, 'Estados Unidos', 2, null),
  (24, '2026-06-25'::date, 'Fase de Grupos', 'Levi''s Stadium', 'San Francisco Bay Area', 'D'::char(1), 'Paraguay', 0, 'Australia', 0, null),
  (25, '2026-06-14'::date, 'Fase de Grupos', 'NRG Stadium', 'Houston', 'E'::char(1), 'Alemania', 7, 'Curazao', 1, null),
  (26, '2026-06-14'::date, 'Fase de Grupos', 'Lincoln Financial Field', 'Filadelfia', 'E'::char(1), 'Costa de Marfil', 1, 'Ecuador', 0, null),
  (27, '2026-06-20'::date, 'Fase de Grupos', 'BMO Field', 'Toronto', 'E'::char(1), 'Alemania', 2, 'Costa de Marfil', 1, null),
  (28, '2026-06-20'::date, 'Fase de Grupos', 'Arrowhead Stadium', 'Kansas City', 'E'::char(1), 'Ecuador', 0, 'Curazao', 0, null),
  (29, '2026-06-25'::date, 'Fase de Grupos', 'Lincoln Financial Field', 'Filadelfia', 'E'::char(1), 'Curazao', 0, 'Costa de Marfil', 2, null),
  (30, '2026-06-25'::date, 'Fase de Grupos', 'MetLife Stadium', 'Nueva York / Nueva Jersey', 'E'::char(1), 'Ecuador', 2, 'Alemania', 1, null),
  (31, '2026-06-14'::date, 'Fase de Grupos', 'AT&T Stadium', 'Dallas', 'F'::char(1), 'Países Bajos', 2, 'Japón', 2, null),
  (32, '2026-06-14'::date, 'Fase de Grupos', 'Estadio BBVA', 'Monterrey', 'F'::char(1), 'Suecia', 5, 'Túnez', 1, null),
  (33, '2026-06-20'::date, 'Fase de Grupos', 'NRG Stadium', 'Houston', 'F'::char(1), 'Países Bajos', 5, 'Suecia', 1, null),
  (34, '2026-06-20'::date, 'Fase de Grupos', 'Estadio BBVA', 'Monterrey', 'F'::char(1), 'Túnez', 0, 'Japón', 4, null),
  (35, '2026-06-25'::date, 'Fase de Grupos', 'AT&T Stadium', 'Dallas', 'F'::char(1), 'Japón', 1, 'Suecia', 1, null),
  (36, '2026-06-25'::date, 'Fase de Grupos', 'Arrowhead Stadium', 'Kansas City', 'F'::char(1), 'Túnez', 1, 'Países Bajos', 3, null),
  (37, '2026-06-15'::date, 'Fase de Grupos', 'Lumen Field', 'Seattle', 'G'::char(1), 'Bélgica', 1, 'Egipto', 1, null),
  (38, '2026-06-15'::date, 'Fase de Grupos', 'SoFi Stadium', 'Los Ángeles', 'G'::char(1), 'Irán', 2, 'Nueva Zelanda', 2, null),
  (39, '2026-06-21'::date, 'Fase de Grupos', 'SoFi Stadium', 'Los Ángeles', 'G'::char(1), 'Bélgica', 0, 'Irán', 0, null),
  (40, '2026-06-21'::date, 'Fase de Grupos', 'BC Place', 'Vancouver', 'G'::char(1), 'Nueva Zelanda', 1, 'Egipto', 3, null),
  (41, '2026-06-26'::date, 'Fase de Grupos', 'Lumen Field', 'Seattle', 'G'::char(1), 'Egipto', 1, 'Irán', 1, null),
  (42, '2026-06-26'::date, 'Fase de Grupos', 'BC Place', 'Vancouver', 'G'::char(1), 'Nueva Zelanda', 1, 'Bélgica', 5, null),
  (43, '2026-06-15'::date, 'Fase de Grupos', 'Mercedes-Benz Stadium', 'Atlanta', 'H'::char(1), 'España', 0, 'Cabo Verde', 0, null),
  (44, '2026-06-15'::date, 'Fase de Grupos', 'Hard Rock Stadium', 'Miami', 'H'::char(1), 'Arabia Saudita', 1, 'Uruguay', 1, null),
  (45, '2026-06-21'::date, 'Fase de Grupos', 'Mercedes-Benz Stadium', 'Atlanta', 'H'::char(1), 'España', 4, 'Arabia Saudita', 0, null),
  (46, '2026-06-21'::date, 'Fase de Grupos', 'Hard Rock Stadium', 'Miami', 'H'::char(1), 'Uruguay', 2, 'Cabo Verde', 2, null),
  (47, '2026-06-26'::date, 'Fase de Grupos', 'NRG Stadium', 'Houston', 'H'::char(1), 'Cabo Verde', 0, 'Arabia Saudita', 0, null),
  (48, '2026-06-26'::date, 'Fase de Grupos', 'Estadio Akron', 'Guadalajara', 'H'::char(1), 'Uruguay', 0, 'España', 1, null),
  (49, '2026-06-16'::date, 'Fase de Grupos', 'MetLife Stadium', 'Nueva York / Nueva Jersey', 'I'::char(1), 'Francia', 3, 'Senegal', 1, null),
  (50, '2026-06-16'::date, 'Fase de Grupos', 'Gillette Stadium', 'Boston', 'I'::char(1), 'Irak', 1, 'Noruega', 4, null),
  (51, '2026-06-22'::date, 'Fase de Grupos', 'Lincoln Financial Field', 'Filadelfia', 'I'::char(1), 'Francia', 3, 'Irak', 0, null),
  (52, '2026-06-22'::date, 'Fase de Grupos', 'MetLife Stadium', 'Nueva York / Nueva Jersey', 'I'::char(1), 'Noruega', 3, 'Senegal', 2, null),
  (53, '2026-06-26'::date, 'Fase de Grupos', 'Gillette Stadium', 'Boston', 'I'::char(1), 'Noruega', 1, 'Francia', 4, null),
  (54, '2026-06-26'::date, 'Fase de Grupos', 'BMO Field', 'Toronto', 'I'::char(1), 'Senegal', 5, 'Irak', 0, 'Irak jugó con diez desde el primer tiempo'),
  (55, '2026-06-16'::date, 'Fase de Grupos', 'Arrowhead Stadium', 'Kansas City', 'J'::char(1), 'Argentina', 3, 'Argelia', 0, null),
  (56, '2026-06-16'::date, 'Fase de Grupos', 'Levi''s Stadium', 'San Francisco Bay Area', 'J'::char(1), 'Austria', 3, 'Jordania', 1, null),
  (57, '2026-06-22'::date, 'Fase de Grupos', 'AT&T Stadium', 'Dallas', 'J'::char(1), 'Argentina', 2, 'Austria', 0, null),
  (58, '2026-06-22'::date, 'Fase de Grupos', 'Levi''s Stadium', 'San Francisco Bay Area', 'J'::char(1), 'Jordania', 1, 'Argelia', 2, null),
  (59, '2026-06-27'::date, 'Fase de Grupos', 'Arrowhead Stadium', 'Kansas City', 'J'::char(1), 'Argelia', 3, 'Austria', 3, null),
  (60, '2026-06-27'::date, 'Fase de Grupos', 'AT&T Stadium', 'Dallas', 'J'::char(1), 'Jordania', 1, 'Argentina', 3, null),
  (61, '2026-06-17'::date, 'Fase de Grupos', 'NRG Stadium', 'Houston', 'K'::char(1), 'Portugal', 1, 'RD del Congo', 1, null),
  (62, '2026-06-17'::date, 'Fase de Grupos', 'Estadio Azteca', 'Ciudad de México', 'K'::char(1), 'Uzbekistán', 1, 'Colombia', 3, null),
  (63, '2026-06-23'::date, 'Fase de Grupos', 'NRG Stadium', 'Houston', 'K'::char(1), 'Portugal', 5, 'Uzbekistán', 0, null),
  (64, '2026-06-23'::date, 'Fase de Grupos', 'Estadio Akron', 'Guadalajara', 'K'::char(1), 'Colombia', 1, 'RD del Congo', 0, null),
  (65, '2026-06-27'::date, 'Fase de Grupos', 'Hard Rock Stadium', 'Miami', 'K'::char(1), 'Colombia', 0, 'Portugal', 0, null),
  (66, '2026-06-27'::date, 'Fase de Grupos', 'Mercedes-Benz Stadium', 'Atlanta', 'K'::char(1), 'RD del Congo', 3, 'Uzbekistán', 1, 'RD del Congo llegó por primera vez a la fase de eliminación'),
  (67, '2026-06-17'::date, 'Fase de Grupos', 'AT&T Stadium', 'Dallas', 'L'::char(1), 'Inglaterra', 4, 'Croacia', 2, null),
  (68, '2026-06-17'::date, 'Fase de Grupos', 'BMO Field', 'Toronto', 'L'::char(1), 'Ghana', 1, 'Panamá', 0, null),
  (69, '2026-06-23'::date, 'Fase de Grupos', 'Gillette Stadium', 'Boston', 'L'::char(1), 'Inglaterra', 0, 'Ghana', 0, null),
  (70, '2026-06-23'::date, 'Fase de Grupos', 'BMO Field', 'Toronto', 'L'::char(1), 'Panamá', 0, 'Croacia', 1, null),
  (71, '2026-06-27'::date, 'Fase de Grupos', 'MetLife Stadium', 'Nueva York / Nueva Jersey', 'L'::char(1), 'Panamá', 0, 'Inglaterra', 2, null),
  (72, '2026-06-27'::date, 'Fase de Grupos', 'Lincoln Financial Field', 'Filadelfia', 'L'::char(1), 'Croacia', 2, 'Ghana', 1, null),
  (73, '2026-06-28'::date, 'Dieciseisavos de Final', 'SoFi Stadium', 'Los Ángeles', null::char(1), 'Canadá', 1, 'Sudáfrica', 0, null),
  (74, '2026-06-29'::date, 'Dieciseisavos de Final', 'NRG Stadium', 'Houston', null::char(1), 'Brasil', 2, 'Japón', 1, null),
  (75, '2026-06-29'::date, 'Dieciseisavos de Final', 'Gillette Stadium', 'Boston', null::char(1), 'Paraguay', 1, 'Alemania', 1, 'Prórroga; Paraguay ganó 4-3 en penales'),
  (76, '2026-06-29'::date, 'Dieciseisavos de Final', 'Estadio BBVA', 'Monterrey', null::char(1), 'Marruecos', 1, 'Países Bajos', 1, 'Prórroga; Marruecos ganó 3-2 en penales'),
  (77, '2026-06-30'::date, 'Dieciseisavos de Final', 'AT&T Stadium', 'Dallas', null::char(1), 'Noruega', 2, 'Costa de Marfil', 1, null),
  (78, '2026-06-30'::date, 'Dieciseisavos de Final', 'MetLife Stadium', 'Nueva York / Nueva Jersey', null::char(1), 'Francia', 3, 'Suecia', 0, 'Doblete de Kylian Mbappé'),
  (79, '2026-06-30'::date, 'Dieciseisavos de Final', 'Estadio Azteca', 'Ciudad de México', null::char(1), 'México', 2, 'Ecuador', 0, null),
  (80, '2026-07-01'::date, 'Dieciseisavos de Final', 'Mercedes-Benz Stadium', 'Atlanta', null::char(1), 'Inglaterra', 2, 'RD del Congo', 1, 'Doblete de Harry Kane en los últimos quince minutos'),
  (81, '2026-07-01'::date, 'Dieciseisavos de Final', 'Lumen Field', 'Seattle', null::char(1), 'Bélgica', 3, 'Senegal', 2, 'Prórroga: Bélgica remontó un 0-2 a cinco minutos del final'),
  (82, '2026-07-01'::date, 'Dieciseisavos de Final', 'Levi''s Stadium', 'San Francisco Bay Area', null::char(1), 'Estados Unidos', 2, 'Bosnia y Herzegovina', 0, 'Primer triunfo estadounidense en eliminación desde 2002'),
  (83, '2026-07-02'::date, 'Dieciseisavos de Final', 'SoFi Stadium', 'Los Ángeles', null::char(1), 'España', 3, 'Austria', 0, 'Doblete de Mikel Oyarzabal'),
  (84, '2026-07-02'::date, 'Dieciseisavos de Final', 'BMO Field', 'Toronto', null::char(1), 'Portugal', 2, 'Croacia', 1, null),
  (85, '2026-07-02'::date, 'Dieciseisavos de Final', 'BC Place', 'Vancouver', null::char(1), 'Suiza', 2, 'Argelia', 0, null),
  (86, '2026-07-03'::date, 'Dieciseisavos de Final', 'AT&T Stadium', 'Dallas', null::char(1), 'Egipto', 1, 'Australia', 1, 'Egipto ganó 4-2 en penales'),
  (87, '2026-07-03'::date, 'Dieciseisavos de Final', 'Hard Rock Stadium', 'Miami', null::char(1), 'Argentina', 3, 'Cabo Verde', 2, 'Tiempo suplementario'),
  (88, '2026-07-03'::date, 'Dieciseisavos de Final', 'Arrowhead Stadium', 'Kansas City', null::char(1), 'Colombia', 1, 'Ghana', 0, null),
  (89, '2026-07-04'::date, 'Octavos de Final', 'NRG Stadium', 'Houston', null::char(1), 'Marruecos', 3, 'Canadá', 0, null),
  (90, '2026-07-04'::date, 'Octavos de Final', 'Lincoln Financial Field', 'Filadelfia', null::char(1), 'Francia', 1, 'Paraguay', 0, null),
  (91, '2026-07-05'::date, 'Octavos de Final', 'MetLife Stadium', 'Nueva York / Nueva Jersey', null::char(1), 'Noruega', 2, 'Brasil', 1, null),
  (92, '2026-07-05'::date, 'Octavos de Final', 'Estadio Azteca', 'Ciudad de México', null::char(1), 'Inglaterra', 3, 'México', 2, null),
  (93, '2026-07-06'::date, 'Octavos de Final', 'AT&T Stadium', 'Dallas', null::char(1), 'España', 1, 'Portugal', 0, null),
  (94, '2026-07-06'::date, 'Octavos de Final', 'Lumen Field', 'Seattle', null::char(1), 'Bélgica', 4, 'Estados Unidos', 1, null),
  (95, '2026-07-07'::date, 'Octavos de Final', 'Mercedes-Benz Stadium', 'Atlanta', null::char(1), 'Argentina', 3, 'Egipto', 2, 'Remontada de dos goles en los últimos once minutos'),
  (96, '2026-07-07'::date, 'Octavos de Final', 'BC Place', 'Vancouver', null::char(1), 'Suiza', 0, 'Colombia', 0, 'Suiza ganó 4-3 en penales'),
  (97, '2026-07-09'::date, 'Cuartos de Final', 'Gillette Stadium', 'Boston', null::char(1), 'Francia', 2, 'Marruecos', 0, null),
  (98, '2026-07-10'::date, 'Cuartos de Final', 'SoFi Stadium', 'Los Ángeles', null::char(1), 'España', 2, 'Bélgica', 1, null),
  (99, '2026-07-11'::date, 'Cuartos de Final', 'Hard Rock Stadium', 'Miami', null::char(1), 'Inglaterra', 2, 'Noruega', 1, 'Tiempo suplementario'),
  (100, '2026-07-11'::date, 'Cuartos de Final', 'Arrowhead Stadium', 'Kansas City', null::char(1), 'Argentina', 3, 'Suiza', 1, 'Tiempo suplementario'),
  (101, '2026-07-14'::date, 'Semifinal', 'AT&T Stadium', 'Dallas', null::char(1), 'España', 2, 'Francia', 0, null),
  (102, '2026-07-15'::date, 'Semifinal', 'Mercedes-Benz Stadium', 'Atlanta', null::char(1), 'Argentina', 2, 'Inglaterra', 1, null),
  (103, '2026-07-18'::date, 'Tercer Lugar', 'Hard Rock Stadium', 'Miami', null::char(1), 'Inglaterra', 6, 'Francia', 4, 'Hat-trick de Bukayo Saka; el partido con más goles jugado por el tercer puesto'),
  (104, '2026-07-19'::date, 'Final', 'MetLife Stadium', 'Nueva York / Nueva Jersey', null::char(1), 'España', 1, 'Argentina', 0, 'Prórroga: gol de Ferran Torres al minuto 106')
),
insertados as (
  insert into partidos (numero_partido, fecha_hora, id_sede, id_fase,
                        grupo, nota)
  select d.numero,
         (d.fecha + time '20:00') at time zone 'UTC',
         s.id_sede, f.id_fase, d.grupo, d.nota
    from datos d
    join ediciones e on e.anio = 2026
    join fases f on f.id_edicion = e.id_edicion and f.nombre_fase = d.fase
    join sedes s on s.nombre_estadio = d.estadio and s.ciudad = d.ciudad
  on conflict (id_fase, numero_partido) do nothing
  returning id_partido, numero_partido
)
-- 5) Equipos y goles de cada partido (RN03: exactamente dos por partido)
insert into partido_equipo (id_partido, equipo_id, tipo, goles)
select i.id_partido, q.equipo_id, t.tipo,
       case t.tipo when 'local' then d.goles_local else d.goles_visitante end
  from insertados i
  join datos d on d.numero = i.numero_partido
  cross join (values ('local'), ('visitante')) as t(tipo)
  join equipos q on q.nombre_equipo =
       case t.tipo when 'local' then d.local else d.visitante end
on conflict (id_partido, equipo_id) do nothing;

-- 6) El goleador del torneo, convocado a esta edición (RN06)
insert into edicion_jugador (id_edicion, id_jugador)
select e.id_edicion, j.id_jugador
  from ediciones e, jugadores j
 where e.anio = 2026 and j.nombre_completo = 'Kylian Mbappé'
on conflict do nothing;

-- 7) El calendario ahora también lleva el marcador de cada partido.
--    v_metricas_globales se suelta primero porque consulta esta vista;
--    se vuelve a crear en el paso 8.
drop view if exists v_metricas_globales;
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

-- 8) La métrica de partidos de 2026 sale del total del torneo (104).
--    Ya no consulta v_calendario_2026, así que deja de depender de ella.
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

-- 9) Comprobaciones
-- select anio, campeon, subcampeon, goleador from ediciones where anio = 2026;
-- select count(*) from v_calendario_2026;  -- 104
-- select count(*) from v_calendario_2026 where goles_local is not null;  -- 104
-- select grupo_inicial, count(*) from edicion_equipo
--  where id_edicion = (select id_edicion from ediciones where anio = 2026)
--  group by grupo_inicial order by grupo_inicial;  -- 12 grupos de 4
-- select * from fn_auditar_rn03();  -- sin filas
