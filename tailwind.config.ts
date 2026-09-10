import type { Config } from "tailwindcss";

/**
 * Cada color de la aplicación es una variable CSS (`--c-azul`, `--c-lienzo`, …)
 * definida en `src/app/globals.css`. Ahí viven las cinco paletas: cada una da
 * un valor distinto a las mismas variables, y el selector de paleta cambia un
 * atributo en <html> para repintar toda la página sin recargar.
 *
 * El valor se guarda como los tres canales RGB sueltos ("37 99 235", sin
 * comas) en lugar de un hex. Así Tailwind puede añadir la opacidad él mismo
 * cuando se escribe `bg-azul/40` o `ring-azul/20`: sustituye `<alpha-value>`
 * por la fracción y arma el `rgb(37 99 235 / 0.4)` final.
 */
const color = (nombre: string) => `rgb(var(--c-${nombre}) / <alpha-value>)`;

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // Barra lateral y superficies oscuras.
        navy: {
          900: color("navy-900"),
          800: color("navy-800"),
          700: color("navy-700"),
          600: color("navy-600"),
          texto: color("navy-texto"),
        },
        // Color principal de la paleta activa.
        azul: {
          DEFAULT: color("azul"),
          claro: color("azul-claro"),
          suave: color("azul-suave"),
          contraste: color("azul-contraste"),
        },
        lienzo: color("lienzo"), // fondo de la página
        superficie: color("superficie"), // fondo de tarjetas y paneles
        tinta: color("tinta"), // color del texto
        gris: {
          borde: color("gris-borde"),
          texto: color("gris-texto"),
          suave: color("gris-suave"),
        },
        acento: color("acento"), // dorado del trofeo
        sube: color("sube"), // el equipo subió en el ranking
        baja: color("baja"), // el equipo bajó en el ranking
        aviso: {
          borde: color("aviso-borde"),
          fondo: color("aviso-fondo"),
          texto: color("aviso-texto"),
        },
        exito: {
          fondo: color("exito-fondo"),
          texto: color("exito-texto"),
        },
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "-apple-system", "Segoe UI", "sans-serif"],
        cifra: ["Manrope", "Inter", "system-ui", "sans-serif"],
        mono: ["ui-monospace", "SFMono-Regular", "Menlo", "monospace"],
      },
      boxShadow: {
        tarjeta:
          "0 1px 2px rgb(var(--c-sombra) / 0.04), 0 1px 3px rgb(var(--c-sombra) / 0.06)",
        panel: "0 4px 20px rgb(var(--c-sombra) / 0.10)",
        modal: "0 24px 60px rgb(var(--c-sombra) / 0.28)",
      },
    },
  },
  plugins: [],
};

export default config;
