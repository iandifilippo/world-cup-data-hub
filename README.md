# World Cup Data Hub

Plataforma web frontend para consultar y relacionar en un solo lugar la historia
de la Copa Mundial de Fútbol (1930–2022), el Ranking FIFA y el calendario del
Mundial 2026.

Proyecto de la clase de Front-End · Ian Di Filippo Espeleta, Juan Felipe Morales
Ortiz, Alejandro Rivera Reyes.

---

## Stack

| Capa | Tecnología |
|---|---|
| Framework | Next.js 15 (App Router, React Server Components) |
| Lenguaje | TypeScript en modo `strict` |
| Estilos | Tailwind CSS 3.4 + CSS propio en `globals.css` |
| Base de datos | Supabase (PostgreSQL 17) |
| Despliegue | Vercel |

No se usa Vue en ninguna parte del proyecto.

---

## Arranque local

```bash
npm install
cp .env.example .env.local     # opcional: ver "Conectar Supabase"
npm run dev                    # http://localhost:3000
```

La aplicación arranca aunque no exista base de datos. Si las variables de
Supabase no están definidas, la capa de consultas (`src/lib/queries.ts`) usa el
dataset local de `src/lib/data/` y la interfaz muestra un aviso indicándolo. Eso
permite desplegar en Vercel antes de tener la base lista y comparar el
comportamiento con y sin backend.

Comandos disponibles:

```bash
npm run dev        # servidor de desarrollo
npm run build      # build de producción
npm run start      # servir el build
npm run typecheck  # tsc --noEmit
npm run lint       # next lint
```

---

## Estructura

```
src/
  app/
    layout.tsx            Shell: barra lateral + barra superior (RF12)
    page.tsx              Inicio — métricas globales y destacado (RF01, RF11)
    historial/page.tsx    Historial de Mundiales (RF02–RF05)
    ranking/page.tsx      Ranking FIFA comparativo (RF06, RF07)
    calendario/page.tsx   Calendario 2026 (RF08–RF10)
    not-found.tsx         404
    globals.css           Tokens de diseño y clases compartidas
  components/
    Navegacion.tsx        Sidebar oscuro + tabs superiores
    Piezas.tsx            Tarjetas de métrica, paneles, banderas, insignias
    Icons.tsx             Iconografía SVG propia
    Destacado.tsx         Destacado histórico rotativo
    HistorialClient.tsx   Filtros, orden, paginación y detalle de edición
    RankingClient.tsx     Tabla de ranking y comparador 2022 vs 2026
    CalendarioClient.tsx  Filtros, vista tarjetas/calendario y detalle
  lib/
    types.ts              Tipos del dominio
    format.ts             Formato de números y fechas en español
    supabase.ts           Cliente Supabase opcional
    queries.ts            Acceso a datos con respaldo local
    comparar.ts           Comparación entre ciclos (regla RN10)
    data/                 Dataset local autogenerado
supabase/
  migrations/             Las 7 migraciones SQL, en orden
scripts/                  Generadores Python del dataset y del SQL
```

Los archivos de `src/lib/data/` y las migraciones son **autogenerados**. Si
necesitas cambiar los datos, edita los scripts de `scripts/` y vuelve a
ejecutarlos:

```bash
python3 scripts/gen_data.py        # construye data_build/*.json
python3 scripts/gen_historicos.py  # partidos históricos
python3 scripts/gen_ts.py          # regenera src/lib/data/*.ts
python3 scripts/gen_sql.py         # regenera supabase/migrations/*.sql
```

---

## Conectar Supabase

1. Crea un proyecto en [supabase.com](https://supabase.com).
2. Abre **SQL Editor** y ejecuta las migraciones **en orden numérico**:

   ```
   20260908120001_schema.sql
   20260908120002_reglas_negocio.sql
   20260908120003_vistas.sql
   20260908120004_rls.sql
   20260908120005_seed_catalogos.sql
   20260908120006_seed_ranking.sql
   20260908120007_seed_calendario_2026.sql
   ```

   El orden importa: las vistas dependen de las tablas, el RLS depende de las
   vistas, y el seed del calendario depende de que las sedes ya estén habilitadas
   para la edición 2026 (por la regla RN08).

3. Copia las credenciales de **Project Settings → API** a `.env.local`:

   ```
   NEXT_PUBLIC_SUPABASE_URL=https://xxxx.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...
   ```

4. Reinicia `npm run dev`. El aviso amarillo desaparece cuando la app está
   leyendo de Supabase.

Verificación rápida después del seed:

```sql
select * from v_metricas_globales;
-- ediciones_historicas 22 | partidos_historicos 964
-- selecciones_ranking_2026 211 | partidos_programados_2026 104

select * from fn_auditar_rn03();          -- debe devolver 0 filas
select * from fn_comparar_ranking('COL'); -- 17 → 12, +57.5 puntos
```

La clave `anon` es pública por diseño: el RLS solo permite `SELECT`, así que
nadie puede escribir con ella.

---

## Publicar en GitHub

```bash
cd world-cup-data-hub
git init
git add .
git commit -m "World Cup Data Hub: frontend Next.js + esquema Supabase"
git branch -M main
git remote add origin https://github.com/TU-USUARIO/world-cup-data-hub.git
git push -u origin main
```

Crea el repositorio vacío en GitHub antes del `push` (sin README, sin
`.gitignore`, para que no haya conflicto en el primer commit).

## Desplegar en Vercel

1. Entra a [vercel.com/new](https://vercel.com/new) e importa el repositorio.
2. Vercel detecta Next.js solo; no cambies el framework preset ni los comandos
   de build.
3. En **Environment Variables** agrega `NEXT_PUBLIC_SUPABASE_URL` y
   `NEXT_PUBLIC_SUPABASE_ANON_KEY` para los tres entornos (Production, Preview,
   Development). Si las omites, el sitio despliega igual usando el dataset
   local.
4. **Deploy**. Cada `git push` a `main` genera un despliegue nuevo.

Si agregas las variables después del primer deploy, hay que redesplegar
(**Deployments → ⋯ → Redeploy**) para que Next.js las incorpore al build.

---

## Trazabilidad de requerimientos

| Req. | Dónde está implementado |
|---|---|
| RF01 | `app/page.tsx` + vista `v_metricas_globales` |
| RF02 | `HistorialClient.tsx` + vista `v_ediciones` |
| RF03 | Filtro de década en `HistorialClient.tsx` |
| RF04 | Buscador en tiempo real por sede, campeón, subcampeón o goleador |
| RF05 | Panel de detalle con los partidos de la edición (`v_partidos_edicion`) |
| RF06 | Tabla de ranking con las 7 columnas, vista `v_ranking` |
| RF07 | Comparador 2022 vs 2026 en `RankingClient.tsx` |
| RF08 | Alternancia tarjetas/calendario sin perder filtros |
| RF09 | Filtros combinables por fecha, equipo y fase |
| RF10 | Panel de detalle con banderas, estadio y comparación de ranking |
| RF11 | `Destacado.tsx`, rota cada 12 s con controles de pausa |
| RF12 | `Navegacion.tsx`, presente en todas las pantallas |
| RN01 | `CHECK rn01_campeon_subcampeon` en `ediciones` |
| RN02, RN05, RN08 | Trigger `fn_validar_partido()` |
| RN03 | `UNIQUE (id_partido, tipo)` + función `fn_auditar_rn03()` |
| RN04 | Clave primaria e índice único en `edicion_equipo` |
| RN06 | Trigger `fn_validar_convocatoria()` |
| RN07 | `CHECK (goles >= 0)` en `partido_equipo` |
| RN09 | `CHECK (ciclo in (2022, 2026))` + `UNIQUE (ciclo, equipo_id)` |
| RN10 | `fn_comparar_ranking()` y `lib/comparar.ts` |

Requerimientos no funcionales: el modo de respaldo local cubre la
disponibilidad; el `strict` de TypeScript y el `CHECK`/RLS del esquema cubren la
integridad; el foco visible, el enlace de salto al contenido, las etiquetas ARIA
y el respeto a `prefers-reduced-motion` cubren la accesibilidad.

---

## Sobre los datos

Lo que es dato real y verificable:

- Las 22 ediciones históricas con año, sede, campeón, subcampeón, goleador y
  cifras de asistencia. La suma de partidos da 964, que coincide con la métrica
  del mockup.
- Las 211 selecciones miembro de la FIFA con su confederación.
- Las 16 sedes del Mundial 2026 en Canadá, Estados Unidos y México.
- Las finales de las 22 ediciones y el detalle de México 1970.

Lo que es dato construido para la maqueta y **debe reemplazarse** antes de
cualquier uso real:

- Los puntajes del Ranking FIFA. Los siete primeros puestos y Colombia usan los
  valores exactos de los mockups; el resto sigue una curva calibrada al perfil
  real del ranking (≈1860 pts en el puesto 1, ≈760 en el 211). Para usar cifras
  oficiales, sustituye el seed de `20260908120006_seed_ranking.sql` con el CSV
  que publica la FIFA.
- El sorteo del Mundial 2026: los 12 grupos, el emparejamiento y la asignación
  de sedes son un escenario plausible, no el sorteo oficial. La estructura sí es
  la real: 72 partidos de grupos + 32 de eliminatorias = 104.
- La cifra de asistencia de México 1970 (1.673.975) se tomó del mockup. Las
  fuentes de FIFA reportan alrededor de 1.604.000; conviene verificarla antes de
  la entrega final.
- En el mockup, Bélgica 3-0 El Salvador aparece con fecha 31 de mayo de 1970. El
  partido se jugó el 3 de junio, y así quedó cargado en el dataset.
