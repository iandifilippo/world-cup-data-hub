import Link from "next/link";

export default function NoEncontrado() {
  return (
    <div className="tarjeta px-6 py-16 text-center">
      <p className="cifras text-5xl font-bold tracking-tight text-azul">404</p>
      <h1 className="mt-3 text-xl font-semibold">Esa pantalla no existe</h1>
      <p className="mx-auto mt-2 max-w-md text-sm text-gris-texto">
        La ruta que abriste no corresponde a ninguno de los cuatro módulos de la
        plataforma.
      </p>
      <Link
        href="/"
        className="mt-6 inline-block rounded-lg bg-azul px-4 py-2 text-sm font-semibold text-white transition hover:bg-azul-claro"
      >
        Volver al inicio
      </Link>
    </div>
  );
}
