import type { Metadata } from "next";

import { HistorialClient } from "@/components/HistorialClient";
import { AvisoOrigen, Encabezado } from "@/components/Piezas";
import { PARTIDOS_HISTORICOS } from "@/lib/data/partidosHistoricos";
import { getEdiciones } from "@/lib/queries";

export const metadata: Metadata = { title: "Historial de Mundiales" };

export default async function PaginaHistorial() {
  const { datos, origen } = await getEdiciones();

  return (
    <>
      <Encabezado
        titulo="Historial de Mundiales"
        descripcion="Consulta todas las ediciones de la Copa Mundial de la FIFA."
      />
      <AvisoOrigen origen={origen} />
      <HistorialClient ediciones={datos} partidos={PARTIDOS_HISTORICOS} />
    </>
  );
}
