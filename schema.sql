-- CREATE SCHEMA stazione;
-- SET SEARCH_PATH TO stazione;


--------------------------------------------------
--                                              --
--                      SQL                     --
--                                              --
--------------------------------------------------


CREATE DOMAIN dom_quantita_serbatoio AS integer
   CHECK(VALUE BETWEEN 0 AND 80000);


CREATE DOMAIN dom_numero_settimana AS INTEGER
   CHECK(VALUE BETWEEN 1 AND 52);


CREATE DOMAIN dom_cf_persona AS char(16);


CREATE TABLE AZIENDA(
   codice varchar(3) PRIMARY KEY,
   responsabile varchar(52) NOT NULL,
   comune varchar(30) NOT NULL
);


CREATE TABLE STAZIONE_DI_RIFORNIMENTO(
   codice char(3) PRIMARY KEY,
   comune varchar(30) NOT NULL,
   latitudine char(5) NOT NULL,
   longitudine char(5) NOT NULL,
   codiceAzienda varchar(3) NOT NULL,
   foreign key (codiceAzienda) REFERENCES AZIENDA(codice) ON UPDATE CASCADE ON DELETE SET NULL
);


CREATE TABLE POMPA(
   numero int,
   codiceStazione char(3),
   tipoCarburante varchar(10) NOT NULL,
   foreign key (codiceStazione) REFERENCES STAZIONE_DI_RIFORNIMENTO(codice) ON UPDATE CASCADE ON DELETE SET NULL,
   PRIMARY KEY (numero, codiceStazione)
);


CREATE TABLE CARBURANTE(
   tipo varchar(10) PRIMARY KEY,
   numeroDiPompe int NOT NULL
);


CREATE TABLE TIPO1(
   CF dom_cf_persona  PRIMARY KEY,
   telefono char(10) NOT NULL,
   residenza varchar(40) NOT NULL,
   nome varchar(27) NOT NULL,
   cognome varchar(24) NOT NULL,
   codiceAzienda varchar(3) NOT NULL,
   codiceStazione char(3) NOT NULL,
   foreign key (codiceAzienda) REFERENCES AZIENDA(codice) ON UPDATE CASCADE ON DELETE SET NULL,
   foreign key (codiceStazione) REFERENCES STAZIONE_DI_RIFORNIMENTO(codice) -- ON UPDATE differite ON DELETE differite
);


CREATE TABLE TIPO2(
   CF dom_cf_persona PRIMARY KEY,
   telefono char(10) NOT NULL,
   residenza varchar(40) NOT NULL,
   nome varchar(27) NOT NULL,
   cognome varchar(24) NOT NULL,
   codiceAzienda varchar(3) NOT NULL,
   foreign key (codiceAzienda) REFERENCES AZIENDA(codice) ON UPDATE CASCADE ON DELETE SET NULL
);


CREATE TABLE PIANO_DI_LAVORO_SETTIMANALE(
   numeroSettimana dom_numero_settimana PRIMARY KEY
);


CREATE TABLE PIANO_DI_LAVORO_GIORNALIERO(
   giorno varchar(9),
   CFDipendente dom_cf_persona NOT NULL,
   codiceStazione char(3) NOT NULL,
   numeroSettimana dom_numero_settimana NOT NULL,
   foreign key (CFDipendente) REFERENCES TIPO2(CF) ON DELETE CASCADE,
   foreign key (codiceStazione) REFERENCES STAZIONE_DI_RIFORNIMENTO(codice) ON DELETE CASCADE,
   foreign key (numeroSettimana)  REFERENCES PIANO_DI_LAVORO_SETTIMANALE(numeroSettimana) ON UPDATE CASCADE,
   PRIMARY KEY (giorno, CFDipendente, codiceStazione)
);


CREATE TABLE FORNISCE(
   quantitaDisponibile dom_quantita_serbatoio NOT NULL,
   capacitaMassima dom_quantita_serbatoio NOT NULL,
   tipoCarburante varchar(10) NOT NULL,
   codiceStazione char(3) NOT NULL,
   foreign key (codiceStazione) REFERENCES STAZIONE_DI_RIFORNIMENTO(codice) ON DELETE CASCADE,
   foreign key (tipoCarburante) REFERENCES CARBURANTE(tipo) ON UPDATE CASCADE ON DELETE CASCADE,
   PRIMARY KEY (codiceStazione, tipoCarburante),
   CONSTRAINT quantita CHECK (quantitaDisponibile <= capacitaMassima) -- da controllare
);


CREATE TABLE EROGA(
   tipoCarburante varchar(10),
   numeroPompa int,
   codiceStazione char(3),
   foreign key (tipoCarburante) REFERENCES CARBURANTE(tipo) ON DELETE CASCADE,
   foreign key (numeroPompa,codiceStazione) REFERENCES POMPA(numero,codiceStazione) ON DELETE CASCADE,
   PRIMARY KEY (tipoCarburante, numeroPompa, codiceStazione)
);


CREATE TABLE DISPONE_DI(
   numeroPompa int,
   codiceStazione char(3),
   foreign key (codiceStazione) REFERENCES STAZIONE_DI_RIFORNIMENTO(codice) ON DELETE CASCADE,
   foreign key (numeroPompa,codiceStazione) REFERENCES POMPA(numero,codiceStazione) ON DELETE CASCADE,
   PRIMARY KEY (codiceStazione, numeroPompa)
);
