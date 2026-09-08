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
