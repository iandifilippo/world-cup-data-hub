import type { Config } from "tailwindcss";

/**
 * Colores de la aplicación. Están escritos aquí una sola vez y con su hex, así
 * que para cambiar el aspecto de toda la página basta con tocar este archivo:
 * `azul` es el color principal, `navy` la barra lateral oscura y `lienzo` el
 * fondo. Los nombres son los que se usan en las clases (`bg-azul`,
 * `text-gris-texto`, `border-gris-borde`, …).
 */
const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // Barra lateral y superficies oscuras.
        navy: {
          900: "#081527",
          800: "#0B1D36",
          700: "#12294A",
          600: "#1B3A63",
          texto: "#CBD5E1",
        },
        // Color principal: el azul de la FIFA.
        azul: {
          DEFAULT: "#2563EB",
          claro: "#3B82F6",
          suave: "#DBEAFE",
          contraste: "#FFFFFF",
        },
        lienzo: "#F1F5F9", // fondo de la página
        superficie: "#FFFFFF", // fondo de tarjetas y paneles
        tinta: "#0F172A", // color del texto
        gris: {
          borde: "#E2E8F0",
          texto: "#64748B",
          suave: "#F8FAFC",
        },
        acento: "#FBBF24", // dorado del trofeo
        sube: "#16A34A", // el equipo subió en el ranking
        baja: "#DC2626", // el equipo bajó en el ranking
        // Aviso amarillo (dataset local) y confirmación verde (participa 2026).
        aviso: {
          borde: "#FDE68A",
          fondo: "#FFFBEB",
          texto: "#92400E",
        },
        exito: {
          fondo: "#ECFDF5",
          texto: "#047857",
        },
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "-apple-system", "Segoe UI", "sans-serif"],
        cifra: ["Manrope", "Inter", "system-ui", "sans-serif"],
        mono: ["ui-monospace", "SFMono-Regular", "Menlo", "monospace"],
      },
      boxShadow: {
        tarjeta: "0 1px 2px rgb(15 23 42 / 0.04), 0 1px 3px rgb(15 23 42 / 0.06)",
        panel: "0 4px 20px rgb(15 23 42 / 0.10)",
        modal: "0 24px 60px rgb(15 23 42 / 0.28)",
      },
    },
  },
  plugins: [],
};

export default config;
