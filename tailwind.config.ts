import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        navy: {
          900: "#081527",
          800: "#0B1D36",
          700: "#12294A",
          600: "#1B3A63",
        },
        azul: {
          DEFAULT: "#2563EB",
          claro: "#3B82F6",
          suave: "#DBEAFE",
        },
        lienzo: "#F1F5F9",
        tinta: "#0F172A",
        gris: {
          borde: "#E2E8F0",
          texto: "#64748B",
          suave: "#F8FAFC",
        },
        sube: "#16A34A",
        baja: "#DC2626",
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "-apple-system", "Segoe UI", "sans-serif"],
        cifra: ["Manrope", "Inter", "system-ui", "sans-serif"],
      },
      boxShadow: {
        tarjeta: "0 1px 2px rgba(15, 23, 42, 0.04), 0 1px 3px rgba(15, 23, 42, 0.06)",
        panel: "0 4px 20px rgba(15, 23, 42, 0.08)",
      },
    },
  },
  plugins: [],
};

export default config;
