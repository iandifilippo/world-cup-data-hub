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
