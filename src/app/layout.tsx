import type { Metadata } from "next";
import type { ReactNode } from "react";

import "./globals.css";
import { BarraLateral, BarraSuperior } from "@/components/Navegacion";
import { SCRIPT_PALETA } from "@/lib/paletas";

export const metadata: Metadata = {
  title: {
    default: "World Cup Data Hub",
    template: "%s · World Cup Data Hub",
  },
  description:
    "Consulta y relaciona en un solo lugar la historia de la Copa Mundial de Fútbol (1930–2022), el Ranking FIFA y el calendario del Mundial 2026.",
};

export default function RootLayout({
  children,
}: Readonly<{ children: ReactNode }>) {
  return (
    // El script de la paleta escribe data-paleta en <html> antes de hidratar,
    // por eso se silencia el aviso de discrepancia.
    <html lang="es" suppressHydrationWarning>
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Manrope:wght@600;700;800&display=swap"
          rel="stylesheet"
        />
        {/* Aplica la paleta guardada antes del primer pintado: sin esto se vería
            un parpadeo con los colores por defecto en cada carga. */}
        <script dangerouslySetInnerHTML={{ __html: SCRIPT_PALETA }} />
      </head>
      <body>
        <a
          href="#contenido"
          className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-50 focus:rounded-lg focus:bg-azul focus:px-4 focus:py-2 focus:text-azul-contraste"
        >
          Saltar al contenido
        </a>
        <div className="flex min-h-screen items-start">
          <BarraLateral />
          <div className="flex min-h-screen min-w-0 flex-1 flex-col">
            <BarraSuperior />
            <main id="contenido" className="flex-1 px-5 py-6 sm:px-8 sm:py-8">
              <div className="mx-auto w-full max-w-6xl">{children}</div>
            </main>
            <footer className="border-t border-gris-borde px-5 py-5 text-xs text-gris-texto sm:px-8">
              World Cup Data Hub · Proyecto académico de Front-End · Datos
              históricos 1930–2022, Ranking FIFA y Mundial 2026.
            </footer>
          </div>
        </div>
      </body>
    </html>
  );
}
