import type { Metadata } from "next";

import { AvisoOrigen, Encabezado } from "@/components/Piezas";
import { RankingClient } from "@/components/RankingClient";
import { getCalendario, getRanking } from "@/lib/queries";

export const metadata: Metadata = { title: "Ranking FIFA" };

export default async function PaginaRanking() {
  const [ranking, calendario] = await Promise.all([getRanking(), getCalendario()]);

  return (
    <>
      <Encabezado
        titulo="Ranking FIFA comparativo"
        descripcion="Explora y compara los rankings FIFA de 2022 y 2026."
      />
      <AvisoOrigen origen={ranking.origen} />
      <RankingClient ranking={ranking.datos} calendario={calendario.datos} />
    </>
  );
}
