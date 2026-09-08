#!/usr/bin/env python3
"""Dataset histórico de la Copa Mundial (1930–2022).

Llena las tablas del modelo entidad-relación que hasta ahora solo tenían datos
del Mundial 2026: sedes históricas, fases, partidos, partido_equipo,
edicion_sede, edicion_equipo, jugadores y edicion_jugador.

Cobertura de partidos:
  · La fase final completa de las 22 ediciones (semifinales cuando existieron,
    tercer lugar y final).
  · La ronda final completa de Brasil 1950, que no tuvo eliminatorias.
  · El torneo ampliado de México 1970 (fase de grupos y cuartos).
  · Todas las eliminatorias de Qatar 2022 (octavos y cuartos).

En un torneo que se juega en sede neutral no hay local ni visitante reales; en
los partidos de eliminación se registra primero al equipo que ganó o avanzó.
La hora exacta de los partidos antiguos no forma parte del dataset, así que
`fecha_hora` usa una marca convencional de 15:00 UTC para cumplir el NOT NULL.

Salidas:
  data_build/partidos_historicos.json
  src/lib/data/partidosHistoricos.ts
  supabase/migrations/20260908120008_seed_historico.sql
"""
import json
import os

B = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HORA_CONVENCIONAL = "15:00:00+00"

# ---------------------------------------------------------------- EDICIONES
# anio -> fecha de inicio oficial del torneo (necesaria para RN05)
INICIOS = {
    1930: "1930-07-13", 1934: "1934-05-27", 1938: "1938-06-04",
    1950: "1950-06-24", 1954: "1954-06-16", 1958: "1958-06-08",
    1962: "1962-05-30", 1966: "1966-07-11", 1970: "1970-05-31",
    1974: "1974-06-13", 1978: "1978-06-01", 1982: "1982-06-13",
    1986: "1986-05-31", 1990: "1990-06-08", 1994: "1994-06-17",
    1998: "1998-06-10", 2002: "2002-05-31", 2006: "2006-06-09",
    2010: "2010-06-11", 2014: "2014-06-12", 2018: "2018-06-14",
    2022: "2022-11-20",
}

ORDEN_FASE = {
    "Fase de Grupos": 1, "Ronda Final": 2, "Octavos de Final": 3,
    "Cuartos de Final": 4, "Semifinal": 5, "Tercer Lugar": 6, "Final": 7,
}

# Selecciones desaparecidas que hacen falta para los partidos históricos y que
# no están en el catálogo de las 211 miembros actuales de la FIFA.
EQUIPOS_HISTORICOS = [
    ("Checoslovaquia", "TCH", "UEFA", "🇨🇿"),
    ("URSS", "URS", "UEFA", "🇷🇺"),
    ("Yugoslavia", "YUG", "UEFA", "🇷🇸"),
]

# ------------------------------------------------------------------ PARTIDOS
# (anio, fecha, ganador/local, goles, goles, rival, fase, estadio, ciudad,
#  pais, grupo, nota)
P = [
 # ---------------------------------------------------------- Uruguay 1930
 (1930,"1930-07-26","Argentina",6,1,"Estados Unidos","Semifinal","Estadio Centenario","Montevideo","Uruguay",None,None),
 (1930,"1930-07-27","Uruguay",6,1,"Yugoslavia","Semifinal","Estadio Centenario","Montevideo","Uruguay",None,None),
 (1930,"1930-07-30","Uruguay",4,2,"Argentina","Final","Estadio Centenario","Montevideo","Uruguay",None,"Primera final de la historia del torneo"),
 # ------------------------------------------------------------ Italia 1934
 (1934,"1934-06-03","Italia",1,0,"Austria","Semifinal","Stadio San Siro","Milán","Italia",None,None),
 (1934,"1934-06-03","Checoslovaquia",3,1,"Alemania","Semifinal","Stadio Giovanni Berta","Florencia","Italia",None,None),
 (1934,"1934-06-07","Alemania",3,2,"Austria","Tercer Lugar","Stadio Giorgio Ascarelli","Nápoles","Italia",None,None),
 (1934,"1934-06-10","Italia",2,1,"Checoslovaquia","Final","Stadio Nazionale PNF","Roma","Italia",None,"Tiempo suplementario"),
 # ----------------------------------------------------------- Francia 1938
 (1938,"1938-06-16","Italia",2,1,"Brasil","Semifinal","Stade Vélodrome","Marsella","Francia",None,None),
 (1938,"1938-06-16","Hungría",5,1,"Suecia","Semifinal","Parc des Princes","París","Francia",None,None),
 (1938,"1938-06-19","Brasil",4,2,"Suecia","Tercer Lugar","Parc Lescure","Burdeos","Francia",None,None),
 (1938,"1938-06-19","Italia",4,2,"Hungría","Final","Stade Olympique de Colombes","Colombes","Francia",None,None),
 # ------------------------------------------------------------ Brasil 1950
 (1950,"1950-07-09","Brasil",7,1,"Suecia","Ronda Final","Estadio Maracaná","Río de Janeiro","Brasil",None,None),
 (1950,"1950-07-09","Uruguay",2,2,"España","Ronda Final","Estadio Pacaembú","São Paulo","Brasil",None,None),
 (1950,"1950-07-13","Brasil",6,1,"España","Ronda Final","Estadio Maracaná","Río de Janeiro","Brasil",None,None),
 (1950,"1950-07-13","Uruguay",3,2,"Suecia","Ronda Final","Estadio Pacaembú","São Paulo","Brasil",None,None),
 (1950,"1950-07-16","Suecia",3,1,"España","Ronda Final","Estadio Pacaembú","São Paulo","Brasil",None,None),
 (1950,"1950-07-16","Uruguay",2,1,"Brasil","Ronda Final","Estadio Maracaná","Río de Janeiro","Brasil",None,"Partido decisivo: el «Maracanazo»"),
 # ------------------------------------------------------------- Suiza 1954
 (1954,"1954-06-30","Alemania",6,1,"Austria","Semifinal","Estadio St. Jakob","Basilea","Suiza",None,None),
 (1954,"1954-06-30","Hungría",4,2,"Uruguay","Semifinal","Estadio La Pontaise","Lausana","Suiza",None,None),
 (1954,"1954-07-03","Austria",3,1,"Uruguay","Tercer Lugar","Estadio Hardturm","Zúrich","Suiza",None,None),
 (1954,"1954-07-04","Alemania",3,2,"Hungría","Final","Estadio Wankdorf","Berna","Suiza",None,"El «Milagro de Berna»"),
 # ------------------------------------------------------------ Suecia 1958
 (1958,"1958-06-24","Brasil",5,2,"Francia","Semifinal","Estadio Råsunda","Solna","Suecia",None,None),
 (1958,"1958-06-24","Suecia",3,1,"Alemania","Semifinal","Nya Ullevi","Gotemburgo","Suecia",None,None),
 (1958,"1958-06-28","Francia",6,3,"Alemania","Tercer Lugar","Nya Ullevi","Gotemburgo","Suecia",None,None),
 (1958,"1958-06-29","Brasil",5,2,"Suecia","Final","Estadio Råsunda","Solna","Suecia",None,"Debut mundialista de Pelé como campeón"),
 # ------------------------------------------------------------- Chile 1962
 (1962,"1962-06-13","Brasil",4,2,"Chile","Semifinal","Estadio Nacional de Chile","Santiago","Chile",None,None),
 (1962,"1962-06-13","Checoslovaquia",3,1,"Yugoslavia","Semifinal","Estadio Sausalito","Viña del Mar","Chile",None,None),
 (1962,"1962-06-16","Chile",1,0,"Yugoslavia","Tercer Lugar","Estadio Nacional de Chile","Santiago","Chile",None,None),
 (1962,"1962-06-17","Brasil",3,1,"Checoslovaquia","Final","Estadio Nacional de Chile","Santiago","Chile",None,None),
 # -------------------------------------------------------- Inglaterra 1966
 (1966,"1966-07-25","Inglaterra",2,1,"Portugal","Semifinal","Estadio de Wembley","Londres","Inglaterra",None,None),
 (1966,"1966-07-25","Alemania",2,1,"URSS","Semifinal","Goodison Park","Liverpool","Inglaterra",None,None),
 (1966,"1966-07-28","Portugal",2,1,"URSS","Tercer Lugar","Estadio de Wembley","Londres","Inglaterra",None,None),
 (1966,"1966-07-30","Inglaterra",4,2,"Alemania","Final","Estadio de Wembley","Londres","Inglaterra",None,"Tiempo suplementario"),
 # ------------------------------------------------------------ México 1970
 (1970,"1970-05-31","México",0,0,"URSS","Fase de Grupos","Estadio Azteca","Ciudad de México","México","1",None),
 (1970,"1970-06-02","Bélgica",3,0,"El Salvador","Fase de Grupos","Estadio Azteca","Ciudad de México","México","1",None),
 (1970,"1970-06-02","Uruguay",2,0,"Israel","Fase de Grupos","Estadio Cuauhtémoc","Puebla","México","2",None),
 (1970,"1970-06-03","Brasil",4,1,"Checoslovaquia","Fase de Grupos","Estadio Jalisco","Guadalajara","México","3",None),
 (1970,"1970-06-03","Inglaterra",1,0,"Rumania","Fase de Grupos","Estadio Jalisco","Guadalajara","México","3",None),
 (1970,"1970-06-03","Perú",3,2,"Bulgaria","Fase de Grupos","Estadio Nou Camp","León","México","4",None),
 (1970,"1970-06-06","México",4,0,"El Salvador","Fase de Grupos","Estadio Azteca","Ciudad de México","México","1",None),
 (1970,"1970-06-07","Brasil",1,0,"Inglaterra","Fase de Grupos","Estadio Jalisco","Guadalajara","México","3",None),
 (1970,"1970-06-10","Italia",0,0,"Israel","Fase de Grupos","Estadio Cuauhtémoc","Puebla","México","2",None),
 (1970,"1970-06-11","Alemania",3,1,"Perú","Fase de Grupos","Estadio Nou Camp","León","México","4",None),
 (1970,"1970-06-14","Brasil",4,2,"Perú","Cuartos de Final","Estadio Jalisco","Guadalajara","México",None,None),
 (1970,"1970-06-14","Italia",4,1,"México","Cuartos de Final","Estadio Azteca","Ciudad de México","México",None,None),
 (1970,"1970-06-14","Alemania",3,2,"Inglaterra","Cuartos de Final","Estadio Nou Camp","León","México",None,"Tiempo suplementario"),
 (1970,"1970-06-14","Uruguay",1,0,"URSS","Cuartos de Final","Estadio Azteca","Ciudad de México","México",None,"Tiempo suplementario"),
 (1970,"1970-06-17","Italia",4,3,"Alemania","Semifinal","Estadio Azteca","Ciudad de México","México",None,"El «Partido del Siglo»"),
 (1970,"1970-06-17","Brasil",3,1,"Uruguay","Semifinal","Estadio Jalisco","Guadalajara","México",None,None),
 (1970,"1970-06-20","Alemania",1,0,"Uruguay","Tercer Lugar","Estadio Azteca","Ciudad de México","México",None,None),
 (1970,"1970-06-21","Brasil",4,1,"Italia","Final","Estadio Azteca","Ciudad de México","México",None,"Brasil se queda con la Copa Jules Rimet"),
 # ---------------------------------------------------------- Alemania 1974
 (1974,"1974-07-06","Polonia",1,0,"Brasil","Tercer Lugar","Olympiastadion","Múnich","Alemania",None,None),
 (1974,"1974-07-07","Alemania",2,1,"Países Bajos","Final","Olympiastadion","Múnich","Alemania",None,"Sin semifinales: el torneo tuvo segunda fase de grupos"),
 # --------------------------------------------------------- Argentina 1978
 (1978,"1978-06-24","Brasil",2,1,"Italia","Tercer Lugar","Estadio Monumental","Buenos Aires","Argentina",None,None),
 (1978,"1978-06-25","Argentina",3,1,"Países Bajos","Final","Estadio Monumental","Buenos Aires","Argentina",None,"Tiempo suplementario"),
 # ------------------------------------------------------------ España 1982
 (1982,"1982-07-08","Italia",2,0,"Polonia","Semifinal","Camp Nou","Barcelona","España",None,None),
 (1982,"1982-07-08","Alemania",3,3,"Francia","Semifinal","Estadio Ramón Sánchez Pizjuán","Sevilla","España",None,"Alemania ganó 5-4 en penales"),
 (1982,"1982-07-10","Polonia",3,2,"Francia","Tercer Lugar","Estadio José Rico Pérez","Alicante","España",None,None),
 (1982,"1982-07-11","Italia",3,1,"Alemania","Final","Estadio Santiago Bernabéu","Madrid","España",None,None),
 # ------------------------------------------------------------ México 1986
 (1986,"1986-06-25","Argentina",2,0,"Bélgica","Semifinal","Estadio Azteca","Ciudad de México","México",None,None),
 (1986,"1986-06-25","Alemania",2,0,"Francia","Semifinal","Estadio Jalisco","Guadalajara","México",None,None),
 (1986,"1986-06-28","Francia",4,2,"Bélgica","Tercer Lugar","Estadio Cuauhtémoc","Puebla","México",None,"Tiempo suplementario"),
 (1986,"1986-06-29","Argentina",3,2,"Alemania","Final","Estadio Azteca","Ciudad de México","México",None,None),
 # ------------------------------------------------------------- Italia 1990
 (1990,"1990-07-03","Argentina",1,1,"Italia","Semifinal","Stadio San Paolo","Nápoles","Italia",None,"Argentina ganó 4-3 en penales"),
 (1990,"1990-07-04","Alemania",1,1,"Inglaterra","Semifinal","Stadio delle Alpi","Turín","Italia",None,"Alemania ganó 4-3 en penales"),
 (1990,"1990-07-07","Italia",2,1,"Inglaterra","Tercer Lugar","Stadio San Nicola","Bari","Italia",None,None),
 (1990,"1990-07-08","Alemania",1,0,"Argentina","Final","Stadio Olimpico","Roma","Italia",None,None),
 # ----------------------------------------------------- Estados Unidos 1994
 (1994,"1994-07-13","Italia",2,1,"Bulgaria","Semifinal","Giants Stadium","East Rutherford","Estados Unidos",None,None),
 (1994,"1994-07-13","Brasil",1,0,"Suecia","Semifinal","Rose Bowl","Pasadena","Estados Unidos",None,None),
 (1994,"1994-07-16","Suecia",4,0,"Bulgaria","Tercer Lugar","Rose Bowl","Pasadena","Estados Unidos",None,None),
 (1994,"1994-07-17","Brasil",0,0,"Italia","Final","Rose Bowl","Pasadena","Estados Unidos",None,"Brasil ganó 3-2 en penales"),
 # ----------------------------------------------------------- Francia 1998
 (1998,"1998-07-07","Brasil",1,1,"Países Bajos","Semifinal","Stade Vélodrome","Marsella","Francia",None,"Brasil ganó 4-2 en penales"),
 (1998,"1998-07-08","Francia",2,1,"Croacia","Semifinal","Stade de France","Saint-Denis","Francia",None,None),
 (1998,"1998-07-11","Croacia",2,1,"Países Bajos","Tercer Lugar","Parc des Princes","París","Francia",None,None),
 (1998,"1998-07-12","Francia",3,0,"Brasil","Final","Stade de France","Saint-Denis","Francia",None,None),
 # ---------------------------------------------------- Corea del Sur 2002
 (2002,"2002-06-25","Alemania",1,0,"Corea del Sur","Semifinal","Estadio Mundialista de Seúl","Seúl","Corea del Sur",None,None),
 (2002,"2002-06-26","Brasil",1,0,"Türkiye","Semifinal","Estadio Mundialista de Saitama","Saitama","Japón",None,None),
 (2002,"2002-06-29","Türkiye",3,2,"Corea del Sur","Tercer Lugar","Estadio Mundialista de Daegu","Daegu","Corea del Sur",None,None),
 (2002,"2002-06-30","Brasil",2,0,"Alemania","Final","Estadio Internacional de Yokohama","Yokohama","Japón",None,"Primer Mundial organizado por dos países"),
 # ---------------------------------------------------------- Alemania 2006
 (2006,"2006-07-04","Italia",2,0,"Alemania","Semifinal","Signal Iduna Park","Dortmund","Alemania",None,"Tiempo suplementario"),
 (2006,"2006-07-05","Francia",1,0,"Portugal","Semifinal","Allianz Arena","Múnich","Alemania",None,None),
 (2006,"2006-07-08","Alemania",3,1,"Portugal","Tercer Lugar","Gottlieb-Daimler-Stadion","Stuttgart","Alemania",None,None),
 (2006,"2006-07-09","Italia",1,1,"Francia","Final","Olympiastadion","Berlín","Alemania",None,"Italia ganó 5-3 en penales"),
 # --------------------------------------------------------- Sudáfrica 2010
 (2010,"2010-07-06","Países Bajos",3,2,"Uruguay","Semifinal","Cape Town Stadium","Ciudad del Cabo","Sudáfrica",None,None),
 (2010,"2010-07-07","España",1,0,"Alemania","Semifinal","Moses Mabhida","Durban","Sudáfrica",None,None),
 (2010,"2010-07-10","Alemania",3,2,"Uruguay","Tercer Lugar","Nelson Mandela Bay","Puerto Elizabeth","Sudáfrica",None,None),
 (2010,"2010-07-11","España",1,0,"Países Bajos","Final","Soccer City","Johannesburgo","Sudáfrica",None,"Tiempo suplementario"),
 # ------------------------------------------------------------ Brasil 2014
 (2014,"2014-07-08","Alemania",7,1,"Brasil","Semifinal","Estadio Mineirão","Belo Horizonte","Brasil",None,"El «Mineirazo»"),
 (2014,"2014-07-09","Argentina",0,0,"Países Bajos","Semifinal","Arena Corinthians","São Paulo","Brasil",None,"Argentina ganó 4-2 en penales"),
 (2014,"2014-07-12","Países Bajos",3,0,"Brasil","Tercer Lugar","Estadio Nacional Mané Garrincha","Brasilia","Brasil",None,None),
 (2014,"2014-07-13","Alemania",1,0,"Argentina","Final","Estadio Maracaná","Río de Janeiro","Brasil",None,"Tiempo suplementario"),
 # ------------------------------------------------------------- Rusia 2018
 (2018,"2018-07-10","Francia",1,0,"Bélgica","Semifinal","Estadio Krestovski","San Petersburgo","Rusia",None,None),
 (2018,"2018-07-11","Croacia",2,1,"Inglaterra","Semifinal","Estadio Luzhnikí","Moscú","Rusia",None,"Tiempo suplementario"),
 (2018,"2018-07-14","Bélgica",2,0,"Inglaterra","Tercer Lugar","Estadio Krestovski","San Petersburgo","Rusia",None,None),
 (2018,"2018-07-15","Francia",4,2,"Croacia","Final","Estadio Luzhnikí","Moscú","Rusia",None,None),
 # ------------------------------------------------------------- Qatar 2022
 (2022,"2022-12-03","Países Bajos",3,1,"Estados Unidos","Octavos de Final","Estadio Internacional Jalifa","Rayán","Qatar",None,None),
 (2022,"2022-12-03","Argentina",2,1,"Australia","Octavos de Final","Estadio Ahmad bin Ali","Rayán","Qatar",None,None),
 (2022,"2022-12-04","Francia",3,1,"Polonia","Octavos de Final","Estadio Al Thumama","Doha","Qatar",None,None),
 (2022,"2022-12-04","Inglaterra",3,0,"Senegal","Octavos de Final","Estadio Al Bayt","Jor","Qatar",None,None),
 (2022,"2022-12-05","Croacia",1,1,"Japón","Octavos de Final","Estadio Al Janoub","Wakrah","Qatar",None,"Croacia ganó 3-1 en penales"),
 (2022,"2022-12-05","Brasil",4,1,"Corea del Sur","Octavos de Final","Estadio 974","Doha","Qatar",None,None),
 (2022,"2022-12-06","Marruecos",0,0,"España","Octavos de Final","Estadio Ciudad de la Educación","Rayán","Qatar",None,"Marruecos ganó 3-0 en penales"),
 (2022,"2022-12-06","Portugal",6,1,"Suiza","Octavos de Final","Estadio Lusail","Lusail","Qatar",None,None),
 (2022,"2022-12-09","Croacia",1,1,"Brasil","Cuartos de Final","Estadio Ciudad de la Educación","Rayán","Qatar",None,"Croacia ganó 4-2 en penales"),
 (2022,"2022-12-09","Argentina",2,2,"Países Bajos","Cuartos de Final","Estadio Lusail","Lusail","Qatar",None,"Argentina ganó 4-3 en penales"),
 (2022,"2022-12-10","Marruecos",1,0,"Portugal","Cuartos de Final","Estadio Al Thumama","Doha","Qatar",None,"Primera selección africana en semifinales"),
 (2022,"2022-12-10","Francia",2,1,"Inglaterra","Cuartos de Final","Estadio Al Bayt","Jor","Qatar",None,None),
 (2022,"2022-12-13","Argentina",3,0,"Croacia","Semifinal","Estadio Lusail","Lusail","Qatar",None,None),
 (2022,"2022-12-14","Francia",2,0,"Marruecos","Semifinal","Estadio Al Bayt","Jor","Qatar",None,None),
 (2022,"2022-12-17","Croacia",2,1,"Marruecos","Tercer Lugar","Estadio Internacional Jalifa","Rayán","Qatar",None,None),
 (2022,"2022-12-18","Argentina",3,3,"Francia","Final","Estadio Lusail","Lusail","Qatar",None,"Argentina ganó 4-2 en penales"),
]

# ----------------------------------------------------------------- JUGADORES
# Goleador de cada edición: (anio, nombre, seleccion, posicion)
GOLEADORES = [
 (1930,"Guillermo Stábile","Argentina","Delantero"),
 (1934,"Oldřich Nejedlý","Checoslovaquia","Delantero"),
 (1938,"Leônidas","Brasil","Delantero"),
 (1950,"Ademir","Brasil","Delantero"),
 (1954,"Sándor Kocsis","Hungría","Delantero"),
 (1958,"Just Fontaine","Francia","Delantero"),
 (1962,"Garrincha","Brasil","Delantero"),
 (1966,"Eusébio","Portugal","Delantero"),
 (1970,"Gerd Müller","Alemania","Delantero"),
 (1974,"Grzegorz Lato","Polonia","Delantero"),
 (1978,"Mario Kempes","Argentina","Delantero"),
 (1982,"Paolo Rossi","Italia","Delantero"),
 (1986,"Gary Lineker","Inglaterra","Delantero"),
 (1990,"Salvatore Schillaci","Italia","Delantero"),
 (1994,"Oleg Salenko","Rusia","Delantero"),
 (1998,"Davor Šuker","Croacia","Delantero"),
 (2002,"Ronaldo","Brasil","Delantero"),
 (2006,"Miroslav Klose","Alemania","Delantero"),
 (2010,"Thomas Müller","Alemania","Delantero"),
 (2014,"James Rodríguez","Colombia","Centrocampista"),
 (2018,"Harry Kane","Inglaterra","Delantero"),
 (2022,"Kylian Mbappé","Francia","Delantero"),
]

# Planteles completos de las dos ediciones cargadas en detalle.
PLANTELES = {
 1970: [("México","1"),("URSS","1"),("Bélgica","1"),("El Salvador","1"),
        ("Uruguay","2"),("Italia","2"),("Suecia","2"),("Israel","2"),
        ("Brasil","3"),("Inglaterra","3"),("Rumania","3"),("Checoslovaquia","3"),
        ("Alemania","4"),("Perú","4"),("Bulgaria","4"),("Marruecos","4")],
 2022: [("Qatar","A"),("Ecuador","A"),("Senegal","A"),("Países Bajos","A"),
        ("Inglaterra","B"),("Irán","B"),("Estados Unidos","B"),("Gales","B"),
        ("Argentina","C"),("Arabia Saudita","C"),("México","C"),("Polonia","C"),
        ("Francia","D"),("Australia","D"),("Dinamarca","D"),("Túnez","D"),
        ("España","E"),("Costa Rica","E"),("Alemania","E"),("Japón","E"),
        ("Bélgica","F"),("Canadá","F"),("Marruecos","F"),("Croacia","F"),
        ("Brasil","G"),("Serbia","G"),("Suiza","G"),("Camerún","G"),
        ("Portugal","H"),("Ghana","H"),("Uruguay","H"),("Corea del Sur","H")],
}

# Campeón y subcampeón de cada edición, para que toda edición tenga equipos
# asociados aunque solo se hayan cargado sus partidos de fase final.
FINALISTAS = {
 1930:("Uruguay","Argentina"), 1934:("Italia","Checoslovaquia"),
 1938:("Italia","Hungría"), 1950:("Uruguay","Brasil"),
 1954:("Alemania","Hungría"), 1958:("Brasil","Suecia"),
 1962:("Brasil","Checoslovaquia"), 1966:("Inglaterra","Alemania"),
 1970:("Brasil","Italia"), 1974:("Alemania","Países Bajos"),
 1978:("Argentina","Países Bajos"), 1982:("Italia","Alemania"),
 1986:("Argentina","Alemania"), 1990:("Alemania","Argentina"),
 1994:("Brasil","Italia"), 1998:("Francia","Brasil"),
 2002:("Brasil","Alemania"), 2006:("Italia","Francia"),
 2010:("España","Países Bajos"), 2014:("Alemania","Argentina"),
 2018:("Francia","Croacia"), 2022:("Argentina","Francia"),
}


def q(v):
    """Literal SQL."""
    if v is None:
        return "null"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return str(v)
    return "'" + str(v).replace("'", "''") + "'"


def catalogo_equipos():
    """Nombres de selección disponibles en src/lib/data/equipos.ts."""
    ruta = os.path.join(B, "src", "lib", "data", "equipos.ts")
    s = open(ruta, encoding="utf-8").read()
    i = s.index("EQUIPOS: Equipo[] = ") + len("EQUIPOS: Equipo[] = ")
    j = s.index("];", i) + 1
    return {e["nombre_equipo"] for e in json.loads(s[i:j])}


def main():
    disponibles = catalogo_equipos() | {e[0] for e in EQUIPOS_HISTORICOS}

    # --- validación: ninguna selección puede quedar sin fila en `equipos` ---
    usados = set()
    for p in P:
        usados.add(p[2]); usados.add(p[5])
    for _, _, seleccion, _ in GOLEADORES:
        usados.add(seleccion)
    for lista in PLANTELES.values():
        usados.update(n for n, _ in lista)
    for campeon, sub in FINALISTAS.values():
        usados.add(campeon); usados.add(sub)
    faltantes = sorted(usados - disponibles)
    if faltantes:
        raise SystemExit(f"Selecciones sin fila en equipos: {faltantes}")

    # --- sedes históricas (las del Mundial 2026 ya están en el seed 005) ---
    sedes, vistas = [], set()
    for p in P:
        clave = (p[7], p[8])
        if clave not in vistas:
            vistas.add(clave)
            sedes.append((p[7], p[8], p[9]))

    # --- fases realmente usadas por edición ---
    fases = {}
    for p in P:
        fases.setdefault(p[0], set()).add(p[6])

    # --- edicion_sede y edicion_equipo derivados de los partidos ---
    ed_sede, ed_equipo = {}, {}
    for p in P:
        ed_sede.setdefault(p[0], set()).add((p[7], p[8]))
        ed_equipo.setdefault(p[0], {}).setdefault(p[2], None)
        ed_equipo[p[0]].setdefault(p[5], None)
    for anio, (campeon, sub) in FINALISTAS.items():
        ed_equipo.setdefault(anio, {}).setdefault(campeon, None)
        ed_equipo[anio].setdefault(sub, None)
    for anio, _, seleccion, _ in GOLEADORES:      # RN06
        ed_equipo.setdefault(anio, {}).setdefault(seleccion, None)
    for anio, lista in PLANTELES.items():         # con grupo inicial
        for nombre, grupo in lista:
            ed_equipo.setdefault(anio, {})[nombre] = grupo

    # ------------------------------------------------------------- JSON / TS
    partidos = []
    for i, p in enumerate(sorted(P, key=lambda x: (x[0], x[1], ORDEN_FASE[x[6]])), 1):
        partidos.append({
            "id_partido": i, "anio": p[0], "fecha": p[1],
            "equipo_local": p[2], "goles_local": p[3], "goles_visitante": p[4],
            "equipo_visitante": p[5], "fase": p[6],
            "nombre_estadio": p[7], "ciudad": p[8], "nota": p[11],
        })

    os.makedirs(os.path.join(B, "data_build"), exist_ok=True)
    with open(os.path.join(B, "data_build", "partidos_historicos.json"), "w",
              encoding="utf-8") as f:
        json.dump(partidos, f, ensure_ascii=False, indent=1)

    ts = ('// AUTOGENERADO por scripts/gen_historico.py — no editar a mano.\n'
          'import type { PartidoHistoricoDetallado } from "@/lib/types";\n\n'
          "export const PARTIDOS_HISTORICOS: PartidoHistoricoDetallado[] = "
          + json.dumps(partidos, ensure_ascii=False, separators=(",", ":")) + ";\n")
    with open(os.path.join(B, "src", "lib", "data", "partidosHistoricos.ts"), "w",
              encoding="utf-8") as f:
        f.write(ts)

    # ------------------------------------------------------------------- SQL
    o = []
    w = o.append
    w("-- =====================================================================")
    w("-- World Cup Data Hub · 008 · Seed histórico (1930–2022)")
    w("--")
    w("-- Completa las tablas del modelo entidad-relación que el seed 007 solo")
    w("-- llenaba para el Mundial 2026: sedes históricas, fases, partidos,")
    w("-- partido_equipo, edicion_sede, edicion_equipo, jugadores y")
    w("-- edicion_jugador.")
    w("--")
    w(f"-- Cobertura: {len(P)} partidos de las 22 ediciones — la fase final")
    w("-- completa de cada torneo (semifinales donde existieron, tercer lugar y")
    w("-- final), la ronda final de Brasil 1950, el torneo ampliado de México")
    w("-- 1970 y todas las eliminatorias de Qatar 2022. El total oficial de")
    w("-- partidos por edición sigue viviendo en la columna ediciones.partidos.")
    w("--")
    w("-- En sede neutral no hay local ni visitante reales: en los partidos de")
    w("-- eliminación se registra primero al equipo que ganó o avanzó. La hora")
    w("-- exacta de los partidos antiguos no forma parte del dataset, así que")
    w(f"-- fecha_hora usa {HORA_CONVENCIONAL} como marca convencional.")
    w("-- =====================================================================")
    w("")
    w("-- 1) Fecha de inicio de cada edición (la exige RN05 al insertar partidos)")
    w("update ediciones set fecha_inicio = v.inicio::date")
    w("  from (values")
    w(",\n".join(f"    ({a}, '{f}')" for a, f in sorted(INICIOS.items())))
    w("  ) as v(anio, inicio)")
    w(" where ediciones.anio = v.anio and ediciones.fecha_inicio is null;")
    w("")
    w("-- 2) Selecciones desaparecidas que disputaron estas ediciones y que ya")
    w("--    no figuran entre las 211 miembros actuales de la FIFA.")
    w("insert into equipos (nombre_equipo, codigo_pais, confederacion, bandera) values")
    w(",\n".join("  (" + ", ".join(q(x) for x in e) + ")" for e in EQUIPOS_HISTORICOS))
    w("on conflict (codigo_pais) do nothing;")
    w("")
    w(f"-- 3) Sedes históricas ({len(sedes)} estadios). La capacidad queda en null:")
    w("--    no forma parte del dataset para los estadios antiguos.")
    w("insert into sedes (nombre_estadio, ciudad, pais) values")
    w(",\n".join("  (" + ", ".join(q(x) for x in s) + ")" for s in sedes))
    w("on conflict (nombre_estadio, ciudad) do nothing;")
    w("")
    w("-- 4) Sedes habilitadas por edición (RN08)")
    w("insert into edicion_sede (id_edicion, id_sede)")
    w("select e.id_edicion, s.id_sede")
    w("  from (values")
    filas = [(a, n, c) for a, cj in sorted(ed_sede.items()) for n, c in sorted(cj)]
    w(",\n".join("    (" + ", ".join(q(x) for x in f) + ")" for f in filas))
    w("  ) as v(anio, estadio, ciudad)")
    w("  join ediciones e on e.anio = v.anio")
    w("  join sedes s on s.nombre_estadio = v.estadio and s.ciudad = v.ciudad")
    w("on conflict do nothing;")
    w("")
    w("-- 5) Fases de cada edición histórica")
    w("insert into fases (id_edicion, nombre_fase, orden)")
    w("select e.id_edicion, v.fase, v.orden")
    w("  from (values")
    filas = [(a, f, ORDEN_FASE[f])
             for a, fs in sorted(fases.items())
             for f in sorted(fs, key=lambda x: ORDEN_FASE[x])]
    w(",\n".join("    (" + ", ".join(q(x) for x in f) + ")" for f in filas))
    w("  ) as v(anio, fase, orden)")
    w("  join ediciones e on e.anio = v.anio")
    w("on conflict (id_edicion, nombre_fase) do nothing;")
    w("")
    w("-- 6) Selecciones participantes por edición (RN04). Para México 1970 y")
    w("--    Qatar 2022 se registra además el grupo inicial.")
    w("insert into edicion_equipo (id_edicion, equipo_id, grupo_inicial)")
    w("select e.id_edicion, q.equipo_id, v.grupo")
    w("  from (values")
    filas = [(a, n, g) for a, d in sorted(ed_equipo.items()) for n, g in sorted(d.items())]
    w(",\n".join("    (" + ", ".join(q(x) for x in f) + ")" for f in filas))
    w("  ) as v(anio, equipo, grupo)")
    w("  join ediciones e on e.anio = v.anio")
    w("  join equipos q on q.nombre_equipo = v.equipo")
    w("on conflict (id_edicion, equipo_id) do nothing;")
    w("")
    w("-- 7) La nota contextual de un partido (prórroga, penales, apodo del")
    w("--    encuentro) no estaba en el modelo original y es parte del dato.")
    w("alter table partidos add column if not exists nota text;")
    w("comment on column partidos.nota is")
    w("  'Detalle contextual del partido: prórroga, definición por penales o apodo histórico.';")
    w("")
    w("-- La vista de RF05 expone ahora también la fecha suelta y esa nota.")
    w("drop view if exists v_partidos_edicion;")
    w("create view v_partidos_edicion as")
    w("select e.id_edicion,")
    w("       e.anio,")
    w("       p.id_partido,")
    w("       p.numero_partido,")
    w("       p.fecha_hora,")
    w("       (p.fecha_hora at time zone 'UTC')::date       as fecha,")
    w("       f.nombre_fase                                 as fase,")
    w("       coalesce(el.nombre_equipo, p.etiqueta_local)     as equipo_local,")
    w("       coalesce(ev.nombre_equipo, p.etiqueta_visitante) as equipo_visitante,")
    w("       pel.goles                                     as goles_local,")
    w("       pev.goles                                     as goles_visitante,")
    w("       s.nombre_estadio,")
    w("       s.ciudad,")
    w("       p.grupo,")
    w("       p.nota")
    w("  from partidos p")
    w("  join fases f     on f.id_fase = p.id_fase")
    w("  join ediciones e on e.id_edicion = f.id_edicion")
    w("  join sedes s     on s.id_sede = p.id_sede")
    w("  left join partido_equipo pel on pel.id_partido = p.id_partido and pel.tipo = 'local'")
    w("  left join partido_equipo pev on pev.id_partido = p.id_partido and pev.tipo = 'visitante'")
    w("  left join equipos el on el.equipo_id = pel.equipo_id")
    w("  left join equipos ev on ev.equipo_id = pev.equipo_id;")
    w("")
    w("-- La vista se recreó, así que hay que devolverle el security_invoker")
    w("-- que le puso la migración 004 (hereda el RLS de sus tablas base).")
    w("alter view v_partidos_edicion set (security_invoker = on);")
    w("grant select on v_partidos_edicion to anon, authenticated;")
    w("")
    w(f"-- 8) Partidos ({len(P)}) con su fase, sede, marcador y nota")
    w("with datos (anio, numero, fecha, fase, estadio, ciudad, grupo,")
    w("            local, goles_local, visitante, goles_visitante, nota) as (values")

    numeracion = {}
    filas = []
    for p in sorted(P, key=lambda x: (x[0], ORDEN_FASE[x[6]], x[1])):
        clave = (p[0], p[6])
        numeracion[clave] = numeracion.get(clave, 0) + 1
        filas.append((p[0], numeracion[clave], p[1], p[6], p[7], p[8], p[10],
                      p[2], p[3], p[5], p[4], p[11]))
    w(",\n".join(
        "  (" + ", ".join(q(x) for x in f[:2]) + ", " + q(f[2]) + "::date, "
        + ", ".join(q(x) for x in f[3:6]) + ", " + q(f[6]) + "::char(1), "
        + ", ".join(q(x) for x in f[7:]) + ")" for f in filas))
    w("),")
    w("insertados as (")
    w("  insert into partidos (numero_partido, fecha_hora, id_sede, id_fase,")
    w("                        grupo, nota)")
    w("  select d.numero,")
    w(f"         (d.fecha + time '{HORA_CONVENCIONAL[:5]}') at time zone 'UTC',")
    w("         s.id_sede, f.id_fase, d.grupo, d.nota")
    w("    from datos d")
    w("    join ediciones e on e.anio = d.anio")
    w("    join fases f on f.id_edicion = e.id_edicion and f.nombre_fase = d.fase")
    w("    join sedes s on s.nombre_estadio = d.estadio and s.ciudad = d.ciudad")
    w("  on conflict (id_fase, numero_partido) do nothing")
    w("  returning id_partido, id_fase, numero_partido")
    w(")")
    w("-- 9) Equipos y goles de cada partido (RN03: exactamente dos por partido)")
    w("insert into partido_equipo (id_partido, equipo_id, tipo, goles)")
    w("select i.id_partido, q.equipo_id, t.tipo,")
    w("       case t.tipo when 'local' then d.goles_local else d.goles_visitante end")
    w("  from insertados i")
    w("  join fases f on f.id_fase = i.id_fase")
    w("  join ediciones e on e.id_edicion = f.id_edicion")
    w("  join datos d on d.anio = e.anio and d.fase = f.nombre_fase")
    w("               and d.numero = i.numero_partido")
    w("  cross join (values ('local'), ('visitante')) as t(tipo)")
    w("  join equipos q on q.nombre_equipo =")
    w("       case t.tipo when 'local' then d.local else d.visitante end")
    w("on conflict (id_partido, equipo_id) do nothing;")
    w("")
    w("-- 10) Goleadores de cada edición como jugadores del modelo")
    w("insert into jugadores (nombre_completo, posicion, equipo_id)")
    w("select v.nombre, v.posicion, q.equipo_id")
    w("  from (values")
    w(",\n".join("    (" + ", ".join(q(x) for x in (n, p, s)) + ")"
                 for _, n, s, p in GOLEADORES))
    w("  ) as v(nombre, posicion, seleccion)")
    w("  join equipos q on q.nombre_equipo = v.seleccion")
    w(" where not exists (select 1 from jugadores j")
    w("                    where j.nombre_completo = v.nombre);")
    w("")
    w("-- 11) Convocatoria del goleador a su edición (RN06)")
    w("insert into edicion_jugador (id_edicion, id_jugador)")
    w("select e.id_edicion, j.id_jugador")
    w("  from (values")
    w(",\n".join("    (" + ", ".join(q(x) for x in (a, n)) + ")"
                 for a, n, _, _ in GOLEADORES))
    w("  ) as v(anio, nombre)")
    w("  join ediciones e on e.anio = v.anio")
    w("  join jugadores j on j.nombre_completo = v.nombre")
    w("on conflict do nothing;")
    w("")
    w("-- 12) Comprobación de RN03: no debe devolver ninguna fila")
    w("-- select * from fn_auditar_rn03();")
    w("")

    ruta = os.path.join(B, "supabase", "migrations",
                        "20260908120008_seed_historico.sql")
    with open(ruta, "w", encoding="utf-8") as f:
        f.write("\n".join(o))

    print(f"partidos:   {len(P)}")
    print(f"ediciones:  {len(fases)}")
    print(f"sedes:      {len(sedes)}")
    print(f"jugadores:  {len(GOLEADORES)}")
    print(f"edicion_equipo: {sum(len(d) for d in ed_equipo.values())} filas")
    print(f"escrito:    {os.path.relpath(ruta, B)}")


if __name__ == "__main__":
    main()
