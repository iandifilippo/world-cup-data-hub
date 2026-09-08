# Migraciones — World Cup Data Hub

Ejecuta los archivos en orden numérico desde el SQL Editor de Supabase, o con la
CLI (`supabase db push`) si tienes el proyecto enlazado.

| # | Archivo | Qué hace |
|---|---|---|
| 001 | `schema.sql` | 6 entidades + 4 tablas intermedias + `ranking_fifa`, con los CHECK de RN01, RN04, RN07 y RN09 |
| 002 | `reglas_negocio.sql` | Triggers y funciones para RN02, RN03, RN05, RN06, RN08 y RN10 |
| 003 | `vistas.sql` | Las 5 vistas que consume el frontend |
| 004 | `rls.sql` | Row Level Security: lectura pública, escritura bloqueada |
| 005 | `seed_catalogos.sql` | 16 sedes, 211 selecciones, 22 ediciones + Mundial 2026 |
| 006 | `seed_ranking.sql` | 422 filas de ranking (211 selecciones × 2 ciclos) |
| 007 | `seed_calendario_2026.sql` | Sedes habilitadas, 7 fases, 48 clasificados, 104 partidos |

Los scripts son idempotentes: usan `on conflict do nothing` o `do update`, así
que puedes reejecutarlos sin duplicar datos.

## Verificación

```sql
select * from v_metricas_globales;
--  22 | 964 | 211 | 104

select count(*) from equipos;                       -- 211
select count(*) from ranking_fifa;                  -- 422
select count(*) from v_calendario_2026;             -- 104
select fase, count(*) from v_calendario_2026 group by fase;
--  Fase de Grupos 72 · Dieciseisavos 16 · Octavos 8 · Cuartos 4
--  Semifinal 2 · Tercer Lugar 1 · Final 1

select * from fn_auditar_rn03();                    -- 0 filas = RN03 se cumple
select * from fn_comparar_ranking('COL');           -- 17 → 12, +57.5 pts
select * from fn_comparar_ranking('XXX');           -- 0 filas: no inventa datos
```

## Probar que las reglas de negocio realmente bloquean

```sql
-- RN01: una edición finalizada sin campeón debe fallar
insert into ediciones (nombre_edicion, anio, sede, pais_sede, equipos, partidos)
values ('Prueba 2030', 2030, 'X', 'X', 48, 104);
-- ERROR: viola la restricción «rn01_campeon_subcampeon»

-- RN08: un partido en una sede no habilitada debe fallar
insert into sedes (nombre_estadio, ciudad, pais) values ('Estadio Fantasma','Bogotá','Colombia');
insert into partidos (numero_partido, fecha_hora, id_sede, id_fase)
select 999, '2026-06-20 15:00-05',
       (select id_sede from sedes where nombre_estadio = 'Estadio Fantasma'),
       (select f.id_fase from fases f join ediciones e using (id_edicion)
         where e.anio = 2026 and f.nombre_fase = 'Final');
-- ERROR: RN08: la sede N no está habilitada para la edición M

-- RN05: un partido anterior al inicio del torneo debe fallar
insert into partidos (numero_partido, fecha_hora, id_sede, id_fase)
select 998, '2026-01-05 15:00-05', 1,
       (select f.id_fase from fases f join ediciones e using (id_edicion)
         where e.anio = 2026 and f.nombre_fase = 'Final');
-- ERROR: RN05: el partido (2026-01-05) es anterior al inicio de la edición
```

## Borrar todo y volver a empezar

```sql
drop view if exists v_metricas_globales, v_calendario_2026, v_ranking,
                    v_partidos_edicion, v_ediciones cascade;
drop table if exists partido_equipo, edicion_jugador, edicion_equipo, edicion_sede,
                     ranking_fifa, partidos, fases, jugadores, equipos,
                     ediciones, sedes cascade;
drop function if exists fn_validar_partido, fn_validar_convocatoria,
                        fn_auditar_rn03, fn_comparar_ranking cascade;
```
