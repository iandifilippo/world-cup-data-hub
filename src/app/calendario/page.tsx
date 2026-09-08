import type { Metadata } from "next";

import { CalendarioClient } from "@/components/CalendarioClient";
import { AvisoOrigen, Encabezado } from "@/components/Piezas";
import { getCalendario } from "@/lib/queries";

export const metadata: Metadata = { title: "Calendario 2026" };

export default async function PaginaCalendario() {
  const { datos, origen } = await getCalendario();

  return (
    <>
      <Encabezado
        titulo="Calendario Mundial 2026"
        descripcion="Consulta los partidos programados para el Mundial 2026."
      />
      <AvisoOrigen origen={origen} />
      <CalendarioClient partidos={datos} />
    </>
  );
}
