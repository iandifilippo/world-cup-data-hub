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
