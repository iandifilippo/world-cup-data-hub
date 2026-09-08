"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { createPortal } from "react-dom";

import {
  IconoAdvertencia,
  IconoBaseDatos,
  IconoCerrar,
  IconoCopiar,
  IconoMas,
  IconoPaloma,
  IconoTabla,
} from "@/components/Icons";
import {
  TABLAS,
  construirInsert,
  valorJs,
  validar,
  type Columna,
  type Tabla,
} from "@/lib/esquema";
import { getSupabase, supabaseConfigurado } from "@/lib/supabase";

type Valores = Record<string, string>;

/** Valores iniciales de una tabla: los DEFAULT ya vienen escritos. */
function valoresIniciales(tabla: Tabla): Valores {
  const v: Valores = {};
  for (const c of tabla.columnas) v[c.nombre] = c.porDefecto ?? "";
  return v;
}

/**
 * Consola de datos al estilo del "Table editor" de Supabase: se elige una
 * tabla, se llena el formulario que sale del esquema real y abajo se arma el
 * INSERT correspondiente. El botón vive al final de la barra lateral.
 */
export function ConsolaDatos({ variante }: { variante: "lateral" | "compacto" }) {
  const [abierta, setAbierta] = useState(false);
  const [montado, setMontado] = useState(false);
  const lateral = variante === "lateral";

  // El diálogo se saca a <body> con un portal: tanto la barra lateral como la
  // superior son `sticky`, y una caja `sticky` crea un contexto de apilamiento
  // propio, así que un modal declarado dentro de ellas queda por debajo del
  // contenido de la página por mucho z-index que se le ponga.
  useEffect(() => setMontado(true), []);

  return (
    <>
      <button
        type="button"
        onClick={() => setAbierta(true)}
        title="Abrir la consola de datos"
        className={
          lateral
            ? "flex w-full items-center gap-2.5 rounded-lg border border-white/10 bg-navy-700/60 px-3 py-2 text-left text-xs font-medium text-navy-texto transition hover:border-white/25 hover:bg-navy-700 hover:text-white"
            : "btn-icono"
        }
      >
        {lateral ? (
          <>
            <IconoBaseDatos className="h-4 w-4 shrink-0" />
            <span className="min-w-0 flex-1 truncate">Consola de datos</span>
            <IconoMas className="h-3.5 w-3.5 shrink-0" aria-hidden="true" />
          </>
        ) : (
          <>
            <IconoBaseDatos className="h-5 w-5" />
            <span className="sr-only">Abrir la consola de datos</span>
          </>
        )}
      </button>

      {abierta && montado
        ? createPortal(<Modal onCerrar={() => setAbierta(false)} />, document.body)
        : null}
    </>
  );
}

function Modal({ onCerrar }: { onCerrar: () => void }) {
  const [tabla, setTabla] = useState<Tabla>(TABLAS[0]);
  const [valores, setValores] = useState<Valores>(() => valoresIniciales(TABLAS[0]));
  const [errores, setErrores] = useState<Record<string, string>>({});
  const [script, setScript] = useState<string[]>([]);
  const [aviso, setAviso] = useState<{ tono: "ok" | "error"; texto: string } | null>(
    null,
  );
  const [enviando, setEnviando] = useState(false);
  const primerCampo = useRef<HTMLInputElement | HTMLSelectElement | null>(null);

  const conectado = supabaseConfigurado();

  // Cerrar con Escape y bloquear el desplazamiento del fondo mientras la
  // consola esté abierta.
  useEffect(() => {
    function alTeclear(e: KeyboardEvent) {
      if (e.key === "Escape") onCerrar();
    }
    document.addEventListener("keydown", alTeclear);
    const anterior = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", alTeclear);
      document.body.style.overflow = anterior;
    };
  }, [onCerrar]);

  useEffect(() => {
    primerCampo.current?.focus();
  }, [tabla]);

  const sql = useMemo(() => construirInsert(tabla, valores), [tabla, valores]);

  function cambiarTabla(nombre: string) {
    const nueva = TABLAS.find((t) => t.nombre === nombre) ?? TABLAS[0];
    setTabla(nueva);
    setValores(valoresIniciales(nueva));
    setErrores({});
    setAviso(null);
  }

  function escribir(columna: string, valor: string) {
    setValores((v) => ({ ...v, [columna]: valor }));
    // Al corregir un campo se borra su error, no los de los demás.
    setErrores((e) => {
      if (!(columna in e)) return e;
      const resto = { ...e };
      delete resto[columna];
      return resto;
    });
    setAviso(null);
  }

  function revisar(): boolean {
    const fallos = validar(tabla, valores);
    if (fallos.length === 0) {
      setErrores({});
      return true;
    }
    setErrores(Object.fromEntries(fallos.map((f) => [f.columna, f.mensaje])));
    setAviso({
      tono: "error",
      texto: `Revisa ${fallos.length} campo(s): el registro no cumple las restricciones de la tabla.`,
    });
    return false;
  }

  function limpiar() {
    setValores(valoresIniciales(tabla));
    setErrores({});
    setAviso(null);
  }

  function agregarAlScript() {
    if (!revisar()) return;
    setScript((s) => [...s, construirInsert(tabla, valores)]);
    setValores(valoresIniciales(tabla));
    setAviso({
      tono: "ok",
      texto: "INSERT agregado al script. Puedes seguir cargando registros.",
    });
  }

  async function copiar(texto: string, mensaje: string) {
    try {
      await navigator.clipboard.writeText(texto);
      setAviso({ tono: "ok", texto: mensaje });
    } catch {
      setAviso({
        tono: "error",
        texto: "El navegador bloqueó el portapapeles. Selecciona el SQL y cópialo a mano.",
      });
    }
  }

  async function insertarEnSupabase() {
    if (!revisar()) return;
    const sb = getSupabase();
    if (!sb) return;

    setEnviando(true);
    setAviso(null);
    try {
      const fila: Record<string, unknown> = {};
      for (const c of tabla.columnas) {
        const bruto = (valores[c.nombre] ?? "").trim();
        if (bruto !== "") fila[c.nombre] = valorJs(c, bruto);
      }
      const { error } = await sb.from(tabla.nombre).insert(fila);
      if (error) {
        setAviso({ tono: "error", texto: `Supabase rechazó el INSERT: ${error.message}` });
      } else {
        setAviso({ tono: "ok", texto: `Registro insertado en ${tabla.nombre}.` });
        setValores(valoresIniciales(tabla));
      }
    } catch (e) {
      setAviso({
        tono: "error",
        texto: e instanceof Error ? e.message : "No se pudo contactar a Supabase.",
      });
    } finally {
      setEnviando(false);
    }
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-navy-900/60 p-0 backdrop-blur-sm sm:items-center sm:p-6"
      onMouseDown={(e) => {
        if (e.target === e.currentTarget) onCerrar();
      }}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="titulo-consola"
        className="flex max-h-[92vh] w-full max-w-4xl flex-col overflow-hidden rounded-t-2xl border border-gris-borde bg-superficie shadow-modal sm:max-h-[86vh] sm:rounded-2xl"
      >
        {/* Cabecera */}
        <div className="flex items-center gap-3 border-b border-gris-borde px-5 py-3.5">
          <span className="grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-azul-suave text-azul">
            <IconoBaseDatos className="h-5 w-5" />
          </span>
          <div className="min-w-0">
            <h2 id="titulo-consola" className="text-sm font-semibold leading-tight">
              Consola de datos
            </h2>
            <p className="truncate text-xs text-gris-texto">
              Inserta registros en el esquema de Supabase del proyecto.
            </p>
          </div>
          <EstadoConexion conectado={conectado} />
          <button
            type="button"
            onClick={onCerrar}
            aria-label="Cerrar la consola de datos"
            className="btn-icono ml-1 shrink-0"
          >
            <IconoCerrar className="h-4 w-4" />
          </button>
        </div>

        <div className="grid min-h-0 flex-1 lg:grid-cols-[210px_minmax(0,1fr)]">
          {/* Lista de tablas */}
          <div className="barra-fina border-b border-gris-borde bg-gris-suave p-2 lg:max-h-none lg:overflow-y-auto lg:border-b-0 lg:border-r">
            <p className="px-2 py-1.5 text-[11px] font-semibold uppercase tracking-wide text-gris-texto">
              Tablas
            </p>
            <div className="flex gap-1 overflow-x-auto lg:flex-col lg:overflow-visible">
              {TABLAS.map((t) => {
                const activa = t.nombre === tabla.nombre;
                return (
                  <button
                    key={t.nombre}
                    type="button"
                    onClick={() => cambiarTabla(t.nombre)}
                    aria-current={activa ? "true" : undefined}
                    className={[
                      "flex shrink-0 items-center gap-2 rounded-lg px-2.5 py-1.5 text-left font-mono text-xs transition lg:w-full lg:shrink",
                      activa
                        ? "bg-azul text-azul-contraste"
                        : "text-gris-texto hover:bg-superficie hover:text-tinta",
                    ].join(" ")}
                  >
                    <IconoTabla className="h-3.5 w-3.5 shrink-0" />
                    <span className="truncate">{t.nombre}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Formulario */}
          <div className="barra-fina min-h-0 overflow-y-auto p-5">
            <p className="text-sm text-gris-texto">{tabla.descripcion}</p>
            {tabla.reglas?.length ? (
              <ul className="mt-2 space-y-1">
                {tabla.reglas.map((r) => (
                  <li
                    key={r}
                    className="flex gap-1.5 text-xs font-medium text-gris-texto"
                  >
                    <IconoAdvertencia
                      className="mt-px h-3.5 w-3.5 shrink-0 text-acento"
                      aria-hidden="true"
                    />
                    {r}
                  </li>
                ))}
              </ul>
            ) : null}

            <div className="mt-5 grid gap-4 sm:grid-cols-2">
              {tabla.columnas.map((c, i) => (
                <Campo
                  key={`${tabla.nombre}-${c.nombre}`}
                  columna={c}
                  valor={valores[c.nombre] ?? ""}
                  error={errores[c.nombre]}
                  onCambio={(v) => escribir(c.nombre, v)}
                  refPrimero={
                    i === 0
                      ? (el) => {
                          primerCampo.current = el;
                        }
                      : undefined
                  }
                />
              ))}
            </div>

            {/* SQL generado */}
            <div className="mt-6">
              <div className="mb-1.5 flex items-center justify-between gap-3">
                <span className="text-[11px] font-semibold uppercase tracking-wide text-gris-texto">
                  SQL generado
                </span>
                <button
                  type="button"
                  onClick={() => copiar(sql, "INSERT copiado al portapapeles.")}
                  className="btn btn-fantasma btn-sm"
                >
                  <IconoCopiar className="h-3.5 w-3.5" />
                  Copiar
                </button>
              </div>
              <pre className="barra-fina overflow-x-auto rounded-lg border border-gris-borde bg-gris-suave p-3 font-mono text-xs leading-relaxed text-tinta">
                {sql}
              </pre>
            </div>

            {script.length > 0 ? (
              <div className="mt-5">
                <div className="mb-1.5 flex items-center justify-between gap-3">
                  <span className="text-[11px] font-semibold uppercase tracking-wide text-gris-texto">
                    Script acumulado · {script.length} registro(s)
                  </span>
                  <div className="flex gap-1">
                    <button
                      type="button"
                      onClick={() =>
                        copiar(script.join("\n\n"), "Script completo copiado.")
                      }
                      className="btn btn-fantasma btn-sm"
                    >
                      <IconoCopiar className="h-3.5 w-3.5" />
                      Copiar script
                    </button>
                    <button
                      type="button"
                      onClick={() => setScript([])}
                      className="btn btn-fantasma btn-sm"
                    >
                      Vaciar
                    </button>
                  </div>
                </div>
                <pre className="barra-fina max-h-40 overflow-auto rounded-lg border border-gris-borde bg-gris-suave p-3 font-mono text-xs leading-relaxed text-gris-texto">
                  {script.join("\n\n")}
                </pre>
              </div>
            ) : null}

            {aviso ? (
              <p
                role="status"
                className={[
                  "mt-4 flex items-start gap-2 rounded-lg border px-3.5 py-2.5 text-xs",
                  aviso.tono === "ok"
                    ? "border-exito-texto/30 bg-exito-fondo text-exito-texto"
                    : "border-aviso-borde bg-aviso-fondo text-aviso-texto",
                ].join(" ")}
              >
                {aviso.tono === "ok" ? (
                  <IconoPaloma className="mt-px h-3.5 w-3.5 shrink-0" />
                ) : (
                  <IconoAdvertencia className="mt-px h-3.5 w-3.5 shrink-0" />
                )}
                {aviso.texto}
              </p>
            ) : null}

            {!conectado ? (
              <p className="mt-4 rounded-lg border border-aviso-borde bg-aviso-fondo px-3.5 py-2.5 text-xs text-aviso-texto">
                Sin conexión a Supabase, la consola no escribe en ninguna base: arma
                el SQL para que lo ejecutes en el editor de Supabase. Define{" "}
                <code className="font-mono">NEXT_PUBLIC_SUPABASE_URL</code> y{" "}
                <code className="font-mono">NEXT_PUBLIC_SUPABASE_ANON_KEY</code> para
                habilitar la inserción directa.
              </p>
            ) : (
              <p className="mt-4 rounded-lg border border-gris-borde bg-gris-suave px-3.5 py-2.5 text-xs text-gris-texto">
                Las políticas RLS del proyecto solo conceden lectura a la clave
                pública: si el INSERT se rechaza, ejecuta el SQL desde el editor de
                Supabase con una clave con permisos de escritura.
              </p>
            )}
          </div>
        </div>

        {/* Pie con las acciones */}
        <div className="flex flex-wrap items-center gap-2 border-t border-gris-borde bg-gris-suave px-5 py-3">
          <span className="mr-auto font-mono text-xs text-gris-texto">
            public.{tabla.nombre}
          </span>
          <button type="button" onClick={limpiar} className="btn btn-fantasma">
            Limpiar
          </button>
          <button type="button" onClick={agregarAlScript} className="btn btn-secundario">
            <IconoMas className="h-4 w-4" />
            Añadir al script
          </button>
          <button
            type="button"
            onClick={insertarEnSupabase}
            disabled={!conectado || enviando}
            title={
              conectado
                ? "Insertar el registro en Supabase"
                : "Requiere las variables de entorno de Supabase"
            }
            className="btn btn-primario"
          >
            {enviando ? "Insertando…" : "Insertar registro"}
          </button>
        </div>
      </div>
    </div>
  );
}

function EstadoConexion({ conectado }: { conectado: boolean }) {
  return (
    <span
      className={[
        "ml-auto hidden shrink-0 items-center gap-1.5 rounded-full border px-2.5 py-1 text-[11px] font-semibold sm:inline-flex",
        conectado
          ? "border-exito-texto/30 bg-exito-fondo text-exito-texto"
          : "border-gris-borde bg-gris-suave text-gris-texto",
      ].join(" ")}
    >
      <span
        aria-hidden="true"
        className={`h-1.5 w-1.5 rounded-full ${
          conectado ? "bg-exito-texto" : "bg-gris-texto"
        }`}
      />
      {conectado ? "Supabase conectado" : "Dataset local"}
    </span>
  );
}

function Campo({
  columna,
  valor,
  error,
  onCambio,
  refPrimero,
}: {
  columna: Columna;
  valor: string;
  error?: string;
  onCambio: (valor: string) => void;
  refPrimero?: (elemento: HTMLInputElement | HTMLSelectElement | null) => void;
}) {
  const id = `campo-${columna.nombre}`;
  const idAyuda = `${id}-ayuda`;
  const descrito = error ? `${id}-error` : columna.ayuda ? idAyuda : undefined;

  const comunes = {
    id,
    value: valor,
    "aria-invalid": error ? true : undefined,
    "aria-describedby": descrito,
    className: `campo ${error ? "border-baja focus:border-baja focus:ring-baja/20" : ""}`,
  };

  return (
    <div>
      <label className="etiqueta-campo flex items-center gap-1.5" htmlFor={id}>
        <span className="font-mono normal-case tracking-normal text-tinta">
          {columna.nombre}
        </span>
        {columna.requerido ? (
          <span className="text-baja" title="Obligatorio">
            *
          </span>
        ) : null}
        <span className="ml-auto font-mono text-[10px] font-normal normal-case tracking-normal text-gris-texto">
          {columna.tipoSql}
        </span>
      </label>

      {columna.opciones ? (
        <select
          {...comunes}
          ref={refPrimero}
          onChange={(e) => onCambio(e.target.value)}
        >
          <option value="">{columna.requerido ? "Elegir…" : "null"}</option>
          {columna.opciones.map((o) => (
            <option key={o} value={o}>
              {o}
            </option>
          ))}
        </select>
      ) : columna.tipo === "booleano" ? (
        <select
          {...comunes}
          ref={refPrimero}
          onChange={(e) => onCambio(e.target.value)}
        >
          <option value="true">true</option>
          <option value="false">false</option>
          <option value="">null</option>
        </select>
      ) : (
        <input
          {...comunes}
          ref={refPrimero}
          type={
            columna.tipo === "entero" || columna.tipo === "decimal"
              ? "number"
              : columna.tipo === "fecha"
                ? "date"
                : columna.tipo === "fecha_hora"
                  ? "datetime-local"
                  : "text"
          }
          step={columna.tipo === "decimal" ? "0.01" : undefined}
          min={columna.minimo}
          max={columna.maximo}
          maxLength={columna.largoExacto}
          placeholder={columna.requerido ? "" : "null"}
          onChange={(e) => onCambio(e.target.value)}
        />
      )}

      {error ? (
        <p id={`${id}-error`} className="mt-1 text-[11px] font-medium text-baja">
          {error}
        </p>
      ) : columna.ayuda ? (
        <p id={idAyuda} className="mt-1 text-[11px] text-gris-texto">
          {columna.ayuda}
        </p>
      ) : null}
    </div>
  );
}
