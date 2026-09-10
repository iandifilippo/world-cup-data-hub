import type { SVGProps } from "react";

type Props = SVGProps<SVGSVGElement>;

const base = {
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 1.7,
  strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const,
  viewBox: "0 0 24 24",
};

export function IconoTrofeo(props: Props) {
  return (
    <svg {...base} {...props}>
      <path d="M7 4h10v5a5 5 0 0 1-10 0V4Z" />
      <path d="M17 5h2.5a.5.5 0 0 1 .5.5V7a3 3 0 0 1-3 3" />
      <path d="M7 5H4.5a.5.5 0 0 0-.5.5V7a3 3 0 0 0 3 3" />
      <path d="M12 14v3M9 20h6M10 17h4l.5 3h-5l.5-3Z" />
    </svg>
  );
}

export function IconoBalon(props: Props) {
  return (
    <svg {...base} {...props}>
      <circle cx="12" cy="12" r="9" />
      <path d="m12 7 3.2 2.3-1.2 3.7h-4l-1.2-3.7L12 7Z" />
      <path d="M12 3.2V7M4.4 9.6 8 9.9M19.6 9.6 16 9.9M7.2 19.4 10 13M16.8 19.4 14 13" />
    </svg>
  );
}

export function IconoSelecciones(props: Props) {
  return (
    <svg {...base} {...props}>
      <circle cx="9" cy="8" r="3.2" />
      <path d="M3.5 19a5.5 5.5 0 0 1 11 0" />
      <path d="M16 5.6a3.2 3.2 0 0 1 0 4.9M17.5 14.2A5.5 5.5 0 0 1 20.5 19" />
    </svg>
  );
}

export function IconoCalendario(props: Props) {
  return (
    <svg {...base} {...props}>
      <rect x="3" y="5" width="18" height="16" rx="2.5" />
      <path d="M3 10h18M8 3v4M16 3v4" />
      <path d="M7.5 14h1.5M11.5 14H13M15.5 14H17M7.5 17.5h1.5M11.5 17.5H13" />
    </svg>
  );
}

export function IconoHistorial(props: Props) {
  return (
    <svg {...base} {...props}>
      <path d="M6 3h9l4 4v14a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1Z" />
      <path d="M14 3v5h5M8.5 12.5h7M8.5 16h7" />
    </svg>
  );
}

export function IconoRanking(props: Props) {
  return (
    <svg {...base} {...props}>
      <path d="M4 20V11M10 20V5M16 20v-6M22 20H2" />
      <path d="M22 20v-9" />
    </svg>
  );
}

export function IconoInicio(props: Props) {
  return (
    <svg {...base} {...props}>
      <path d="m3.5 11 8.5-7 8.5 7" />
      <path d="M5.5 9.6V20h13V9.6" />
      <path d="M10 20v-5.5h4V20" />
    </svg>
  );
}

export function IconoBuscar(props: Props) {
  return (
    <svg {...base} {...props}>
      <circle cx="11" cy="11" r="6.5" />
      <path d="m16 16 4 4" />
    </svg>
  );
}

export function IconoAsistencia(props: Props) {
  return (
    <svg {...base} {...props}>
      <path d="M3 17.5 8.5 11l4 3.5L21 6" />
      <path d="M16.5 6H21v4.5" />
    </svg>
  );
}

export function IconoEstadio(props: Props) {
  return (
    <svg {...base} {...props}>
      <ellipse cx="12" cy="9" rx="9" ry="4.2" />
      <path d="M3 9v5.5c0 2.3 4 4.2 9 4.2s9-1.9 9-4.2V9" />
      <path d="M8.5 11.4v4M15.5 11.4v4" />
    </svg>
  );
}

export function IconoCerrar(props: Props) {
  return (
    <svg {...base} {...props}>
      <path d="m6 6 12 12M18 6 6 18" />
    </svg>
  );
}

export function IconoFlecha(props: Props) {
  return (
    <svg {...base} {...props}>
      <path d="M4 12h15M13 6l6 6-6 6" />
    </svg>
  );
}

export function IconoPaleta(props: Props) {
  return (
    <svg {...base} {...props}>
      <path d="M12 3a9 9 0 0 0 0 18c.9 0 1.6-.7 1.6-1.6 0-.4-.2-.8-.4-1.1-.3-.3-.4-.7-.4-1.1 0-.9.7-1.6 1.6-1.6H16a5 5 0 0 0 5-5c0-4.1-4-7.6-9-7.6Z" />
      <circle cx="7.7" cy="11.5" r="1" fill="currentColor" stroke="none" />
      <circle cx="10.4" cy="7.7" r="1" fill="currentColor" stroke="none" />
      <circle cx="15" cy="8.2" r="1" fill="currentColor" stroke="none" />
      <circle cx="17.4" cy="12" r="1" fill="currentColor" stroke="none" />
    </svg>
  );
}

export function IconoBaseDatos(props: Props) {
  return (
    <svg {...base} {...props}>
      <ellipse cx="12" cy="6" rx="7.5" ry="3.2" />
      <path d="M4.5 6v12c0 1.8 3.4 3.2 7.5 3.2s7.5-1.4 7.5-3.2V6" />
      <path d="M4.5 12c0 1.8 3.4 3.2 7.5 3.2s7.5-1.4 7.5-3.2" />
    </svg>
  );
}

export function IconoMas(props: Props) {
  return (
    <svg {...base} {...props}>
      <path d="M12 5v14M5 12h14" />
    </svg>
  );
}

export function IconoCopiar(props: Props) {
  return (
    <svg {...base} {...props}>
      <rect x="9" y="9" width="11" height="11" rx="2" />
      <path d="M15 6.5V5a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1v9a1 1 0 0 0 1 1h1.5" />
    </svg>
  );
}

export function IconoPaloma(props: Props) {
  return (
    <svg {...base} {...props}>
      <path d="m4.5 12.5 5 5 10-11" />
    </svg>
  );
}

export function IconoTabla(props: Props) {
  return (
    <svg {...base} {...props}>
      <rect x="3" y="4" width="18" height="16" rx="2" />
      <path d="M3 9.5h18M9 9.5V20M3 15h18" />
    </svg>
  );
}

export function IconoAdvertencia(props: Props) {
  return (
    <svg {...base} {...props}>
      <path d="M12 4.5 21 19.5H3L12 4.5Z" />
      <path d="M12 10v4M12 16.8v.2" />
    </svg>
  );
}
