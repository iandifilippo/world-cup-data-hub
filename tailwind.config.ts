import type { Config } from "tailwindcss";

/**
 * Cada color es una variable CSS con el triplete RGB suelto ("37 99 235") en
 * lugar de un hex fijo. Así Tailwind sigue generando las variantes con opacidad
 * (`bg-azul/20`) y, al mismo tiempo, el selector de paleta puede repintar toda
 * la aplicación cambiando un atributo en <html>. Las paletas viven en
 * `src/app/globals.css`.
 */
const token = (nombre: string) => `rgb(var(--c-${nombre}) / <alpha-value>)`;

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // Barra lateral y superficies oscuras.
        navy: {
          900: token("navy-900"),
          800: token("navy-800"),
          700: token("navy-700"),
          600: token("navy-600"),
          texto: token("navy-texto"),
        },
        // Color primario de la paleta activa.
        azul: {
          DEFAULT: token("azul"),
          claro: token("azul-claro"),
          suave: token("azul-suave"),
          contraste: token("azul-contraste"),
        },
        lienzo: token("lienzo"),
        superficie: token("superficie"),
        tinta: token("tinta"),
        gris: {
          borde: token("gris-borde"),
          texto: token("gris-texto"),
          suave: token("gris-suave"),
        },
        acento: token("acento"),
        sube: token("sube"),
        baja: token("baja"),
        aviso: {
          borde: token("aviso-borde"),
          fondo: token("aviso-fondo"),
          texto: token("aviso-texto"),
        },
        exito: {
          fondo: token("exito-fondo"),
          texto: token("exito-texto"),
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
