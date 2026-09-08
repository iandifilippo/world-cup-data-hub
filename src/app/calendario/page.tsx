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
        titulo="Mundial 2026"
        descripcion="Los 104 partidos del Mundial 2026, con el resultado de la fase de eliminación."
      />
      <AvisoOrigen origen={origen} />
      <CalendarioClient partidos={datos} />
    </>
  );
}
