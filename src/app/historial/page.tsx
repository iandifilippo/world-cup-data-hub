import type { Metadata } from "next";

import { HistorialClient } from "@/components/HistorialClient";
import { AvisoOrigen, Encabezado } from "@/components/Piezas";
import { getEdiciones, getPartidosHistoricos } from "@/lib/queries";

export const metadata: Metadata = { title: "Historial de Mundiales" };

export default async function PaginaHistorial() {
  const [ediciones, partidos] = await Promise.all([
    getEdiciones(),
    getPartidosHistoricos(),
  ]);

  return (
    <>
      <Encabezado
        titulo="Historial de Mundiales"
        descripcion="Consulta todas las ediciones de la Copa Mundial de la FIFA."
      />
      <AvisoOrigen origen={ediciones.origen} />
      <HistorialClient ediciones={ediciones.datos} partidos={partidos.datos} />
    </>
  );
}
