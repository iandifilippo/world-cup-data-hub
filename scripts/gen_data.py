#!/usr/bin/env python3
"""Genera todos los datasets del World Cup Data Hub (JSON) a partir de datos curados."""
import json, os, random, unicodedata

random.seed(2026)
OUT = os.path.join(os.path.dirname(__file__), "..", "data_build")
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------- EDICIONES
# año, sede(pais), equipos, campeon, subcampeon, goleador, goles, asist_total, prom, partidos
EDICIONES = [
 (1930,"Uruguay","Uruguay",13,"Uruguay","Argentina","Guillermo Stábile",8,590549,32808,18),
 (1934,"Italia","Italia",16,"Italia","Checoslovaquia","Oldřich Nejedlý",5,363000,21353,17),
 (1938,"Francia","Francia",15,"Italia","Hungría","Leônidas",7,375700,20872,18),
 (1950,"Brasil","Brasil",13,"Uruguay","Brasil","Ademir",9,1045246,47511,22),
 (1954,"Suiza","Suiza",16,"Alemania","Hungría","Sándor Kocsis",11,768607,29562,26),
 (1958,"Suecia","Suecia",16,"Brasil","Suecia","Just Fontaine",13,819810,23423,35),
 (1962,"Chile","Chile",16,"Brasil","Checoslovaquia","Garrincha",4,893172,27912,32),
 (1966,"Inglaterra","Inglaterra",16,"Inglaterra","Alemania","Eusébio",9,1563135,48848,32),
 (1970,"México","México",16,"Brasil","Italia","Gerd Müller",10,1673975,52312,32),
 (1974,"Alemania","Alemania",16,"Alemania","Países Bajos","Grzegorz Lato",7,1865753,49099,38),
 (1978,"Argentina","Argentina",16,"Argentina","Países Bajos","Mario Kempes",6,1545791,40679,38),
 (1982,"España","España",24,"Italia","Alemania","Paolo Rossi",6,2109723,40572,52),
 (1986,"México","México",24,"Argentina","Alemania","Gary Lineker",6,2394031,46039,52),
 (1990,"Italia","Italia",24,"Alemania","Argentina","Salvatore Schillaci",6,2516215,48389,52),
 (1994,"Estados Unidos","Estados Unidos",24,"Brasil","Italia","Oleg Salenko",6,3587538,68991,52),
 (1998,"Francia","Francia",32,"Francia","Brasil","Davor Šuker",6,2785100,43517,64),
 (2002,"Corea del Sur y Japón","Corea del Sur",32,"Brasil","Alemania","Ronaldo",8,2705197,42269,64),
 (2006,"Alemania","Alemania",32,"Italia","Francia","Miroslav Klose",5,3359439,52491,64),
 (2010,"Sudáfrica","Sudáfrica",32,"España","Países Bajos","Thomas Müller",5,3178856,49670,64),
 (2014,"Brasil","Brasil",32,"Alemania","Argentina","James Rodríguez",6,3429873,53591,64),
 (2018,"Rusia","Rusia",32,"Francia","Croacia","Harry Kane",6,3031768,47371,64),
 (2022,"Qatar","Qatar",32,"Argentina","Francia","Kylian Mbappé",8,3404252,53191,64),
]

ediciones = []
for i,(anio,sede,pais,eq,camp,sub,gol,goles,at,prom,pj) in enumerate(EDICIONES, start=1):
    ediciones.append({
        "id_edicion": i,
        "nombre_edicion": f"{pais} {anio}",
        "anio": anio,
        "sede": sede,
        "pais_sede": pais,
        "equipos": eq,
        "campeon": camp,
        "subcampeon": sub,
        "goleador": gol,
        "goles_goleador": goles,
        "asistencia_total": at,
        "promedio_asistencia": prom,
        "partidos": pj,
        "decada": (anio // 10) * 10,
    })

# ---------------------------------------------------------------- EQUIPOS (211 miembros FIFA)
# (nombre, codigo, confederacion, emoji)
EQUIPOS = [
 ("Argentina","ARG","CONMEBOL","🇦🇷"),("Brasil","BRA","CONMEBOL","🇧🇷"),("Uruguay","URU","CONMEBOL","🇺🇾"),
 ("Colombia","COL","CONMEBOL","🇨🇴"),("Chile","CHI","CONMEBOL","🇨🇱"),("Perú","PER","CONMEBOL","🇵🇪"),
 ("Ecuador","ECU","CONMEBOL","🇪🇨"),("Paraguay","PAR","CONMEBOL","🇵🇾"),("Bolivia","BOL","CONMEBOL","🇧🇴"),
 ("Venezuela","VEN","CONMEBOL","🇻🇪"),
 ("Francia","FRA","UEFA","🇫🇷"),("Inglaterra","ENG","UEFA","🏴󠁧󠁢󠁥󠁮󠁧󠁿"),("Bélgica","BEL","UEFA","🇧🇪"),
 ("Países Bajos","NED","UEFA","🇳🇱"),("Portugal","POR","UEFA","🇵🇹"),("España","ESP","UEFA","🇪🇸"),
 ("Italia","ITA","UEFA","🇮🇹"),("Alemania","GER","UEFA","🇩🇪"),("Croacia","CRO","UEFA","🇭🇷"),
 ("Dinamarca","DEN","UEFA","🇩🇰"),("Suiza","SUI","UEFA","🇨🇭"),("Austria","AUT","UEFA","🇦🇹"),
 ("Ucrania","UKR","UEFA","🇺🇦"),("Suecia","SWE","UEFA","🇸🇪"),("Polonia","POL","UEFA","🇵🇱"),
 ("Gales","WAL","UEFA","🏴󠁧󠁢󠁷󠁬󠁳󠁿"),("Serbia","SRB","UEFA","🇷🇸"),("Türkiye","TUR","UEFA","🇹🇷"),
 ("Escocia","SCO","UEFA","🏴󠁧󠁢󠁳󠁣󠁴󠁿"),("Hungría","HUN","UEFA","🇭🇺"),("Noruega","NOR","UEFA","🇳🇴"),
 ("República Checa","CZE","UEFA","🇨🇿"),("Grecia","GRE","UEFA","🇬🇷"),("Rumania","ROU","UEFA","🇷🇴"),
 ("Eslovaquia","SVK","UEFA","🇸🇰"),("Eslovenia","SVN","UEFA","🇸🇮"),("Irlanda","IRL","UEFA","🇮🇪"),
 ("Irlanda del Norte","NIR","UEFA","🏴"),("Islandia","ISL","UEFA","🇮🇸"),("Finlandia","FIN","UEFA","🇫🇮"),
 ("Bosnia y Herzegovina","BIH","UEFA","🇧🇦"),("Albania","ALB","UEFA","🇦🇱"),("Macedonia del Norte","MKD","UEFA","🇲🇰"),
 ("Georgia","GEO","UEFA","🇬🇪"),("Israel","ISR","UEFA","🇮🇱"),("Bulgaria","BUL","UEFA","🇧🇬"),
 ("Montenegro","MNE","UEFA","🇲🇪"),("Bielorrusia","BLR","UEFA","🇧🇾"),("Armenia","ARM","UEFA","🇦🇲"),
 ("Luxemburgo","LUX","UEFA","🇱🇺"),("Kosovo","KVX","UEFA","🇽🇰"),("Azerbaiyán","AZE","UEFA","🇦🇿"),
 ("Kazajistán","KAZ","UEFA","🇰🇿"),("Estonia","EST","UEFA","🇪🇪"),("Letonia","LVA","UEFA","🇱🇻"),
 ("Lituania","LTU","UEFA","🇱🇹"),("Chipre","CYP","UEFA","🇨🇾"),("Islas Feroe","FRO","UEFA","🇫🇴"),
 ("Moldavia","MDA","UEFA","🇲🇩"),("Malta","MLT","UEFA","🇲🇹"),("Andorra","AND","UEFA","🇦🇩"),
 ("Gibraltar","GIB","UEFA","🇬🇮"),("Liechtenstein","LIE","UEFA","🇱🇮"),("San Marino","SMR","UEFA","🇸🇲"),
 ("Rusia","RUS","UEFA","🇷🇺"),
 ("Estados Unidos","USA","CONCACAF","🇺🇸"),("México","MEX","CONCACAF","🇲🇽"),("Canadá","CAN","CONCACAF","🇨🇦"),
 ("Costa Rica","CRC","CONCACAF","🇨🇷"),("Panamá","PAN","CONCACAF","🇵🇦"),("Jamaica","JAM","CONCACAF","🇯🇲"),
 ("Honduras","HON","CONCACAF","🇭🇳"),("El Salvador","SLV","CONCACAF","🇸🇻"),("Guatemala","GUA","CONCACAF","🇬🇹"),
 ("Curazao","CUW","CONCACAF","🇨🇼"),("Haití","HAI","CONCACAF","🇭🇹"),("Trinidad y Tobago","TRI","CONCACAF","🇹🇹"),
 ("Surinam","SUR","CONCACAF","🇸🇷"),("Guyana","GUY","CONCACAF","🇬🇾"),("Nicaragua","NCA","CONCACAF","🇳🇮"),
 ("República Dominicana","DOM","CONCACAF","🇩🇴"),("Cuba","CUB","CONCACAF","🇨🇺"),("Antigua y Barbuda","ATG","CONCACAF","🇦🇬"),
 ("San Cristóbal y Nieves","SKN","CONCACAF","🇰🇳"),("Belice","BLZ","CONCACAF","🇧🇿"),("Bermudas","BER","CONCACAF","🇧🇲"),
 ("Granada","GRN","CONCACAF","🇬🇩"),("San Vicente y las Granadinas","VIN","CONCACAF","🇻🇨"),("Barbados","BRB","CONCACAF","🇧🇧"),
 ("Puerto Rico","PUR","CONCACAF","🇵🇷"),("Santa Lucía","LCA","CONCACAF","🇱🇨"),("Dominica","DMA","CONCACAF","🇩🇲"),
 ("Montserrat","MSR","CONCACAF","🇲🇸"),("Islas Caimán","CAY","CONCACAF","🇰🇾"),("Bahamas","BAH","CONCACAF","🇧🇸"),
 ("Aruba","ARU","CONCACAF","🇦🇼"),("Islas Vírgenes de EE. UU.","VIR","CONCACAF","🇻🇮"),("Islas Vírgenes Británicas","VGB","CONCACAF","🇻🇬"),
 ("Anguila","AIA","CONCACAF","🇦🇮"),("Islas Turcas y Caicos","TCA","CONCACAF","🇹🇨"),
 ("Marruecos","MAR","CAF","🇲🇦"),("Senegal","SEN","CAF","🇸🇳"),("Egipto","EGY","CAF","🇪🇬"),
 ("Argelia","ALG","CAF","🇩🇿"),("Nigeria","NGA","CAF","🇳🇬"),("Costa de Marfil","CIV","CAF","🇨🇮"),
 ("Túnez","TUN","CAF","🇹🇳"),("Camerún","CMR","CAF","🇨🇲"),("Malí","MLI","CAF","🇲🇱"),
 ("Ghana","GHA","CAF","🇬🇭"),("Sudáfrica","RSA","CAF","🇿🇦"),("Burkina Faso","BFA","CAF","🇧🇫"),
 ("RD del Congo","COD","CAF","🇨🇩"),("Cabo Verde","CPV","CAF","🇨🇻"),("Guinea","GUI","CAF","🇬🇳"),
 ("Gabón","GAB","CAF","🇬🇦"),("Zambia","ZAM","CAF","🇿🇲"),("Angola","ANG","CAF","🇦🇴"),
 ("Uganda","UGA","CAF","🇺🇬"),("Benín","BEN","CAF","🇧🇯"),("Guinea Ecuatorial","EQG","CAF","🇬🇶"),
 ("Mozambique","MOZ","CAF","🇲🇿"),("Madagascar","MAD","CAF","🇲🇬"),("Mauritania","MTN","CAF","🇲🇷"),
 ("Zimbabue","ZIM","CAF","🇿🇼"),("Namibia","NAM","CAF","🇳🇦"),("Kenia","KEN","CAF","🇰🇪"),
 ("Libia","LBY","CAF","🇱🇾"),("Togo","TOG","CAF","🇹🇬"),("Sierra Leona","SLE","CAF","🇸🇱"),
 ("Congo","CGO","CAF","🇨🇬"),("Sudán","SDN","CAF","🇸🇩"),("Comoras","COM","CAF","🇰🇲"),
 ("Malaui","MWI","CAF","🇲🇼"),("Tanzania","TAN","CAF","🇹🇿"),("Ruanda","RWA","CAF","🇷🇼"),
 ("Níger","NIG","CAF","🇳🇪"),("Guinea-Bisáu","GNB","CAF","🇬🇼"),("Burundi","BDI","CAF","🇧🇮"),
 ("Etiopía","ETH","CAF","🇪🇹"),("Liberia","LBR","CAF","🇱🇷"),("Botsuana","BOT","CAF","🇧🇼"),
 ("Lesoto","LES","CAF","🇱🇸"),("Suazilandia","SWZ","CAF","🇸🇿"),("Chad","CHA","CAF","🇹🇩"),
 ("Gambia","GAM","CAF","🇬🇲"),("Sudán del Sur","SSD","CAF","🇸🇸"),("Yibuti","DJI","CAF","🇩🇯"),
 ("Somalia","SOM","CAF","🇸🇴"),("Mauricio","MRI","CAF","🇲🇺"),("Santo Tomé y Príncipe","STP","CAF","🇸🇹"),
 ("Seychelles","SEY","CAF","🇸🇨"),("Eritrea","ERI","CAF","🇪🇷"),("República Centroafricana","CTA","CAF","🇨🇫"),
 ("Japón","JPN","AFC","🇯🇵"),("Irán","IRN","AFC","🇮🇷"),("Corea del Sur","KOR","AFC","🇰🇷"),
 ("Australia","AUS","AFC","🇦🇺"),("Qatar","QAT","AFC","🇶🇦"),("Arabia Saudita","KSA","AFC","🇸🇦"),
 ("Irak","IRQ","AFC","🇮🇶"),("Uzbekistán","UZB","AFC","🇺🇿"),("Emiratos Árabes Unidos","UAE","AFC","🇦🇪"),
 ("Jordania","JOR","AFC","🇯🇴"),("Omán","OMA","AFC","🇴🇲"),("Baréin","BHR","AFC","🇧🇭"),
 ("China","CHN","AFC","🇨🇳"),("Siria","SYR","AFC","🇸🇾"),("Palestina","PLE","AFC","🇵🇸"),
 ("Vietnam","VIE","AFC","🇻🇳"),("Kirguistán","KGZ","AFC","🇰🇬"),("India","IND","AFC","🇮🇳"),
 ("Tailandia","THA","AFC","🇹🇭"),("Líbano","LBN","AFC","🇱🇧"),("Tayikistán","TJK","AFC","🇹🇯"),
 ("Corea del Norte","PRK","AFC","🇰🇵"),("Malasia","MAS","AFC","🇲🇾"),("Baréin B","BAN","AFC","🇧🇩"),
 ("Filipinas","PHI","AFC","🇵🇭"),("Turkmenistán","TKM","AFC","🇹🇲"),("Hong Kong","HKG","AFC","🇭🇰"),
 ("Kuwait","KUW","AFC","🇰🇼"),("Myanmar","MYA","AFC","🇲🇲"),("Indonesia","IDN","AFC","🇮🇩"),
 ("Yemen","YEM","AFC","🇾🇪"),("Afganistán","AFG","AFC","🇦🇫"),("Singapur","SGP","AFC","🇸🇬"),
 ("Maldivas","MDV","AFC","🇲🇻"),("Nepal","NEP","AFC","🇳🇵"),("Camboya","CAM","AFC","🇰🇭"),
 ("Chinese Taipei","TPE","AFC","🇹🇼"),("Mongolia","MNG","AFC","🇲🇳"),("Laos","LAO","AFC","🇱🇦"),
 ("Macao","MAC","AFC","🇲🇴"),("Brunéi","BRU","AFC","🇧🇳"),("Timor Oriental","TLS","AFC","🇹🇱"),
 ("Pakistán","PAK","AFC","🇵🇰"),("Sri Lanka","SRI","AFC","🇱🇰"),("Guam","GUM","AFC","🇬🇺"),
 ("Bután","BHU","AFC","🇧🇹"),
 ("Nueva Zelanda","NZL","OFC","🇳🇿"),("Nueva Caledonia","NCL","OFC","🇳🇨"),("Islas Salomón","SOL","OFC","🇸🇧"),
 ("Fiyi","FIJ","OFC","🇫🇯"),("Tahití","TAH","OFC","🇵🇫"),("Vanuatu","VAN","OFC","🇻🇺"),
 ("Papúa Nueva Guinea","PNG","OFC","🇵🇬"),("Samoa","SAM","OFC","🇼🇸"),("Islas Cook","COK","OFC","🇨🇰"),
 ("Tonga","TGA","OFC","🇹🇴"),("Samoa Americana","ASA","OFC","🇦🇸"),
]

# Fix: reemplazar entrada erronea
EQUIPOS = [e for e in EQUIPOS if e[1] != "BAN"] + [("Bangladés","BAN","AFC","🇧🇩")]

equipos = []
for i,(nom,cod,conf,fl) in enumerate(EQUIPOS, start=1):
    equipos.append({"equipo_id": i, "nombre_equipo": nom, "codigo_pais": cod,
                    "confederacion": conf, "bandera": fl})

print("TOTAL EQUIPOS:", len(equipos))

# ---------------------------------------------------------------- RANKING 2022 / 2026
# Anclas tomadas de los mockups oficiales del proyecto
ANCLA_2026 = {"ARG":1855.0,"FRA":1842.0,"BRA":1821.0,"ENG":1798.0,"BEL":1765.0,
              "NED":1742.0,"POR":1739.0,"COL":1678.9}
ANCLA_2022 = {"ARG":1843.7,"FRA":1823.4,"BRA":1837.6,"ENG":1793.2,"BEL":1816.7,
              "NED":1679.4,"POR":1676.6,"COL":1621.4}

ORDEN_2026 = ["ARG","FRA","BRA","ENG","BEL","NED","POR","ESP","ITA","GER","CRO","COL",
 "URU","USA","MEX","MAR","SUI","DEN","JPN","IRN","KOR","SEN","AUT","UKR","SWE","POL",
 "WAL","AUS","SRB","TUR","PER","ECU","CHI","EGY","ALG","NGA","CIV","TUN","CMR","CAN",
 "QAT","KSA","CRC","SCO","HUN","NOR","CZE","GRE","RUS","PAR","VEN","BOL","GHA","MLI",
 "RSA","IRQ","UZB","UAE","JAM","PAN","ROU","SVK","SVN","IRL","ISL","FIN","BIH","ALB",
 "MKD","GEO","ISR","BUL","MNE","NZL","BFA","COD","CPV","GUI","GAB","ZAM","ANG","JOR",
 "OMA","BHR","CHN","SYR","PLE","VIE","HON","SLV","GUA","CUW","HAI","TRI","BLR","ARM",
 "LUX","KVX","AZE","KAZ","EST","LVA","LTU","CYP","FRO","MDA","MLT","AND","GIB","LIE",
 "SMR","NIR","UGA","BEN","EQG","MOZ","MAD","MTN","ZIM","NAM","KEN","LBY","TOG","SLE",
 "CGO","SDN","COM","MWI","TAN","RWA","NIG","GNB","BDI","ETH","LBR","BOT","LES","SWZ",
 "CHA","GAM","SSD","DJI","SOM","MRI","STP","SEY","ERI","CTA","KGZ","IND","THA","LBN",
 "TJK","PRK","MAS","BAN","PHI","TKM","HKG","KUW","MYA","IDN","YEM","AFG","SGP","MDV",
 "NEP","CAM","TPE","MNG","LAO","MAC","BRU","TLS","PAK","SRI","GUM","BHU","NCL","SOL",
 "FIJ","TAH","VAN","PNG","SAM","COK","TGA","ASA","SUR","GUY","NCA","DOM","CUB","ATG",
 "SKN","BLZ","BER","GRN","VIN","BRB","PUR","LCA","DMA","MSR","CAY","BAH","ARU","VIR",
 "VGB","AIA","TCA"]

by_code = {e["codigo_pais"]: e for e in equipos}
faltantes = [c for c in by_code if c not in ORDEN_2026]
ORDEN_2026 = ORDEN_2026 + faltantes
ORDEN_2026 = [c for c in ORDEN_2026 if c in by_code]
assert len(ORDEN_2026) == len(equipos), (len(ORDEN_2026), len(equipos))

N_TOTAL = 211

# Perfil real del ranking FIFA: muy plano arriba, caída fuerte en la cola.
# Los primeros puntos de anclaje son los que aparecen en los mockups del proyecto.
CURVA = [(1,1855.0),(2,1842.0),(3,1821.0),(4,1798.0),(5,1765.0),(6,1742.0),(7,1739.0),
         (12,1678.9),(20,1600.0),(30,1545.0),(50,1462.0),(75,1380.0),(100,1300.0),
         (125,1225.0),(150,1140.0),(175,1035.0),(200,900.0),(211,780.0)]

def interp(pos):
    """Interpolación lineal por tramos sobre la curva de referencia."""
    for i in range(len(CURVA) - 1):
        x0, y0 = CURVA[i]
        x1, y1 = CURVA[i + 1]
        if x0 <= pos <= x1:
            t = (pos - x0) / (x1 - x0)
            return y0 + t * (y1 - y0)
    return CURVA[-1][1]

def monotonizar(filas):
    """Garantiza puntos estrictamente decrecientes al subir de posición."""
    filas.sort(key=lambda r: r["posicion"])
    for i in range(1, len(filas)):
        if filas[i]["puntos"] >= filas[i - 1]["puntos"]:
            filas[i]["puntos"] = round(filas[i - 1]["puntos"] - 0.4, 2)
    return filas

# ---- Ciclo 2026
ranking = []
filas_2026 = []
for pos, cod in enumerate(ORDEN_2026, start=1):
    pts = ANCLA_2026.get(cod, round(interp(pos) + random.uniform(-2.5, 2.5), 2))
    filas_2026.append({"ciclo": 2026, "posicion": pos, "codigo_pais": cod,
                       "puntos": round(pts, 2), "partidos_evaluados": 27})
ranking += monotonizar(filas_2026)

# ---- Ciclo 2022: mismo universo, orden desplazado.
# Las posiciones ancladas provienen de la columna "POS. ANTERIOR" de los mockups.
ANCLA_POS_2022 = {"ARG":1,"FRA":2,"BRA":3,"BEL":4,"ENG":5,"POR":7,"NED":8,"COL":17}
ANCLA_PTS_2022 = {"ARG":1843.7,"COL":1621.4}

libres = [c for c in ORDEN_2026 if c not in ANCLA_POS_2022]
# desplazamiento controlado: cada selección se mueve como máximo 6 puestos
libres_ordenados = sorted(libres, key=lambda c: ORDEN_2026.index(c) + random.uniform(-6, 6))
orden_2022 = [None] * len(ORDEN_2026)
for cod, pos in ANCLA_POS_2022.items():
    orden_2022[pos - 1] = cod
it = iter(libres_ordenados)
for i in range(len(orden_2022)):
    if orden_2022[i] is None:
        orden_2022[i] = next(it)

filas_2022 = []
for pos, cod in enumerate(orden_2022, start=1):
    pts = ANCLA_PTS_2022.get(cod, round(interp(pos) * 0.9955 + random.uniform(-2.5, 2.5), 2))
    filas_2022.append({"ciclo": 2022, "posicion": pos, "codigo_pais": cod,
                       "puntos": round(pts, 2), "partidos_evaluados": 25})
ranking += monotonizar(filas_2022)

# ---------------------------------------------------------------- SEDES 2026
SEDES = [
 ("Estadio Azteca","Ciudad de México","México",87523),
 ("Estadio BBVA","Monterrey","México",53500),
 ("Estadio Akron","Guadalajara","México",48071),
 ("BC Place","Vancouver","Canadá",54500),
 ("BMO Field","Toronto","Canadá",45500),
 ("MetLife Stadium","Nueva York / Nueva Jersey","Estados Unidos",82500),
 ("AT&T Stadium","Dallas","Estados Unidos",80000),
 ("NRG Stadium","Houston","Estados Unidos",72220),
 ("Arrowhead Stadium","Kansas City","Estados Unidos",76416),
 ("Levi's Stadium","San Francisco Bay Area","Estados Unidos",68500),
 ("SoFi Stadium","Los Ángeles","Estados Unidos",70240),
 ("Lumen Field","Seattle","Estados Unidos",69000),
 ("Mercedes-Benz Stadium","Atlanta","Estados Unidos",71000),
 ("Hard Rock Stadium","Miami","Estados Unidos",65326),
 ("Gillette Stadium","Boston","Estados Unidos",65878),
 ("Lincoln Financial Field","Filadelfia","Estados Unidos",69796),
]
sedes = [{"id_sede": i, "nombre_estadio": n, "ciudad": c, "pais": p, "capacidad": cap}
         for i,(n,c,p,cap) in enumerate(SEDES, start=1)]

# ---------------------------------------------------------------- CALENDARIO 2026 (104 partidos)
CLASIFICADOS = [
 ["México","Canadá","Noruega","Uzbekistán"],
 ["España","Marruecos","Escocia","Curazao"],
 ["Argentina","Australia","Egipto","Panamá"],
 ["Brasil","Corea del Sur","Costa de Marfil","Austria"],
 ["Francia","Japón","Senegal","Jordania"],
 ["Estados Unidos","Croacia","Túnez","Nueva Zelanda"],
 ["Inglaterra","Irán","Argelia","Paraguay"],
 ["Portugal","Ecuador","Sudáfrica","Catar" ],
 ["Países Bajos","Colombia","Ghana","Arabia Saudita"],
 ["Bélgica","Uruguay","Cabo Verde","Haití"],
 ["Alemania","Suiza","Nigeria","Jamaica"],
 ["Italia","Dinamarca","Camerún","Honduras"],
]
CLASIFICADOS[7][3] = "Qatar"

GRUPOS = "ABCDEFGHIJKL"
FASES = ["Fase de Grupos","Dieciseisavos de Final","Octavos de Final",
         "Cuartos de Final","Semifinal","Tercer Lugar","Final"]

partidos = []
pid = 0
num = 0

def add(fecha, hora, local, visitante, sede_id, fase, grupo=None):
    global pid, num
    pid += 1; num += 1
    partidos.append({
        "id_partido": pid, "numero_partido": num,
        "fecha": fecha, "hora": hora,
        "equipo_local": local, "equipo_visitante": visitante,
        "id_sede": sede_id, "fase": fase, "grupo": grupo,
        "goles_local": None, "goles_visitante": None,
    })

HORAS = ["12:00","15:00","18:00","21:00"]
# 12 grupos x 6 partidos = 72. Orden: jornada -> par -> grupo (A..L)
# de modo que los 12 primeros partidos son el debut de cada grupo.
pares = [(0,1),(2,3),(0,2),(1,3),(0,3),(1,2)]
BASE_DIA = {0: 11, 1: 17, 2: 23}
sede_i = 0
for jornada in range(3):
    base = BASE_DIA[jornada]
    for par in range(2):
        a, b = pares[jornada * 2 + par]
        for g in range(12):
            dia = base + (g // 2)
            hora = HORAS[par * 2 + (g % 2)]
            add(f"2026-06-{dia:02d}", hora,
                CLASIFICADOS[g][a], CLASIFICADOS[g][b],
                (sede_i % 16) + 1, FASES[0], GRUPOS[g])
            sede_i += 1

# Dieciseisavos (16), Octavos (8), Cuartos (4), Semis (2), 3er lugar (1), Final (1)
placeholder = lambda et, n: f"{et} {n}"
llaves = [
 (FASES[1], 16, ["2026-06-28","2026-06-29","2026-06-30","2026-07-01","2026-07-02","2026-07-03"]),
 (FASES[2],  8, ["2026-07-04","2026-07-05","2026-07-06","2026-07-07"]),
 (FASES[3],  4, ["2026-07-09","2026-07-10","2026-07-11"]),
 (FASES[4],  2, ["2026-07-14","2026-07-15"]),
 (FASES[5],  1, ["2026-07-18"]),
 (FASES[6],  1, ["2026-07-19"]),
]
etq = {FASES[1]:"1º/2º Grupo", FASES[2]:"Ganador D", FASES[3]:"Ganador O",
       FASES[4]:"Ganador C", FASES[5]:"Perdedor SF", FASES[6]:"Ganador SF"}
for fase, n, fechas in llaves:
    for k in range(n):
        add(fechas[k % len(fechas)], HORAS[k % 4],
            placeholder(etq[fase], 2*k+1), placeholder(etq[fase], 2*k+2),
            (sede_i % 16) + 1, fase, None)
        sede_i += 1

# La final se juega en el MetLife Stadium
partidos[-1]["id_sede"] = 6
partidos[-1]["hora"] = "15:00"
partidos[-2]["id_sede"] = 14

print("TOTAL PARTIDOS 2026:", len(partidos))
assert len(partidos) == 104, len(partidos)

# ---------------------------------------------------------------- OUTPUT
data = {"ediciones": ediciones, "equipos": equipos, "ranking": ranking,
        "sedes": sedes, "partidos_2026": partidos}
for k, v in data.items():
    with open(os.path.join(OUT, f"{k}.json"), "w", encoding="utf-8") as f:
        json.dump(v, f, ensure_ascii=False, indent=1)
    print(f"{k}: {len(v)} filas")
