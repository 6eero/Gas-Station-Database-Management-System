CREATE SCHEMA fuelstationdatabase;
SET SEARCH_PATH TO fuelstationdatabase;

CREATE DOMAIN dom_codice_azienda AS integer
	CHECK(VALUE BETWEEN 1 AND 99);

CREATE DOMAIN dom_codice_stazione AS integer
	CHECK(VALUE BETWEEN 100 AND 1000);

CREATE DOMAIN dom_quantita_serbatoio AS integer
	CHECK(VALUE BETWEEN 0 AND 80000);

CREATE DOMAIN dom_numero_settimana AS INTEGER
	CHECK(VALUE BETWEEN 1 AND 52);

CREATE DOMAIN dom_cf_persona AS char(16);

CREATE TABLE AZIENDA(
	codice dom_codice_azienda PRIMARY KEY,
	responsabile varchar(52) NOT NULL,
	comune varchar(30) NOT NULL
);

CREATE TABLE STAZIONE_DI_RIFORNIMENTO(
	codice dom_codice_stazione PRIMARY KEY,
	comune varchar(30) NOT NULL,
	latitudine char(5) NOT NULL,
	longitudine char(5) NOT NULL,
	codiceAzienda dom_codice_azienda NOT NULL,
	foreign key (codiceAzienda) REFERENCES AZIENDA(codice) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE POMPA(
	numero int,
	codiceStazione dom_codice_stazione,
	tipoCarburante varchar(10) NOT NULL,
	foreign key (codiceStazione) REFERENCES STAZIONE_DI_RIFORNIMENTO(codice) ON UPDATE CASCADE ON DELETE CASCADE,
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
	codiceAzienda dom_codice_azienda NOT NULL,
	codiceStazione dom_codice_stazione NOT NULL,
	foreign key (codiceAzienda) REFERENCES AZIENDA(codice) ON UPDATE CASCADE ON DELETE CASCADE,
	foreign key (codiceStazione) REFERENCES STAZIONE_DI_RIFORNIMENTO(codice) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE TIPO2(
	CF dom_cf_persona PRIMARY KEY,
	telefono char(10) NOT NULL,
	residenza varchar(40) NOT NULL,
	nome varchar(27) NOT NULL, 
	cognome varchar(24) NOT NULL, 
	codiceAzienda dom_codice_azienda NOT NULL,
	foreign key (codiceAzienda) REFERENCES AZIENDA(codice) ON UPDATE CASCADE ON DELETE CASCADE
); 

CREATE TABLE PIANO_DI_LAVORO_SETTIMANALE(
	numeroSettimana dom_numero_settimana PRIMARY KEY
);

CREATE TABLE PIANO_DI_LAVORO_GIORNALIERO(
	giorno varchar(9),
	CFDipendente dom_cf_persona NOT NULL,
	codiceStazione dom_codice_stazione NOT NULL,
	numeroSettimana dom_numero_settimana NOT NULL,
	foreign key (CFDipendente) REFERENCES TIPO2(CF) ON UPDATE CASCADE ON DELETE CASCADE, 
	foreign key (codiceStazione) REFERENCES STAZIONE_DI_RIFORNIMENTO(codice) ON UPDATE CASCADE ON DELETE CASCADE, 
	foreign key (numeroSettimana)  REFERENCES PIANO_DI_LAVORO_SETTIMANALE(numeroSettimana) ON DELETE CASCADE,
	PRIMARY KEY (giorno, CFDipendente, codiceStazione)
);

CREATE TABLE FORNISCE(
	quantitaDisponibile dom_quantita_serbatoio NOT NULL,
	capacitaMassima dom_quantita_serbatoio NOT NULL,
	tipoCarburante varchar(10) NOT NULL,
	codiceStazione dom_codice_stazione NOT NULL,
	foreign key (codiceStazione) REFERENCES STAZIONE_DI_RIFORNIMENTO(codice) ON DELETE CASCADE,
	foreign key (tipoCarburante) REFERENCES CARBURANTE(tipo) ON UPDATE CASCADE ON DELETE CASCADE,
	PRIMARY KEY (codiceStazione, tipoCarburante),
	CONSTRAINT quantita CHECK (quantitaDisponibile <= capacitaMassima) 
);

CREATE TABLE EROGA(
	tipoCarburante varchar(10),
	numeroPompa int,
	codiceStazione dom_codice_stazione,
	foreign key (tipoCarburante) REFERENCES CARBURANTE(tipo) ON DELETE CASCADE, 
	foreign key (numeroPompa,codiceStazione) REFERENCES POMPA(numero,codiceStazione) ON DELETE CASCADE, 
	PRIMARY KEY (tipoCarburante, numeroPompa, codiceStazione)
);


--------------------------------------------------
--												--
-- 					TRIGGER 					--
--												--
--------------------------------------------------




-- TRIGGER #1:  un dipendente di tipo 1 deve lavorare presso 
-- stazioni di rifornimento solo appartenenti all'azienda per 
-- cui lavora

CREATE OR REPLACE FUNCTION verifica_dipendenti()
RETURNS trigger 
language plpgsql as 
$$
BEGIN
PERFORM * FROM AZIENDA AS A WHERE A.codice = old.codiceazienda;
IF FOUND 
THEN
	PERFORM * FROM TIPO1 AS T1, STAZIONE_DI_RIFORNIMENTO AS STAZIONE
                        WHERE new.codiceStazione = STAZIONE.codice AND
                              new.codiceAzienda <> STAZIONE.codiceAzienda;
	IF FOUND
	THEN
		RAISE NOTICE 'dipendente lavora per una stazione non di proprieta di azienda per cui lavora';
		RETURN null;
	ELSE
		RETURN new;
	END IF;
ELSE
	RETURN new;
END IF;
END;
$$;

create trigger controllo_dipendenti
	before insert or update on TIPO1
	for each row
	execute procedure verifica_dipendenti();

-- TRIGGER #2:  un dipendente di tipo 2 deve lavorare presso 
-- stazioni di rifornimento solo appartenenti all'azienda 
-- per cui lavora

CREATE OR REPLACE FUNCTION verifica_dipendenti_tipo2()
RETURNS trigger 
language plpgsql as 
$$
BEGIN
PERFORM * FROM AZIENDA AS A WHERE A.codice = old.codiceazienda;
IF FOUND
THEN
	PERFORM * FROM TIPO2, PIANO_DI_LAVORO_GIORNALIERO AS PLG, STAZIONE_DI_RIFORNIMENTO AS STAZIONE
		  WHERE STAZIONE.codice = PLG.codiceStazione AND
	                new.codiceAzienda <> STAZIONE.codiceAzienda;
	IF FOUND
	THEN
		RAISE NOTICE 'dipendente lavora per una stazione non di proprieta di azienda per cui lavora';
		RETURN null;
	ELSE
		RETURN new;
	END IF;
ELSE 
	RETURN new;
END IF;
END;
$$;

create trigger controllo_dipendenti_tipo2
	before insert or update on TIPO2
	for each row
	execute procedure verifica_dipendenti_tipo2();




-- TRIGGER #3:  codifica il vincolo (2, N) 
-- nella relazione tipo2-HA-piano_di_lavoro_giornaliero
-- ci devono essere almeno 2 stazioni diverse nel 
-- piano di lavoro giornaliero per ogni dipendente

-- se elimino un piano di lavoro da piano di lavoro giornaliero 

CREATE OR REPLACE FUNCTION verifica_vincolo_stazioni_multiple()
RETURNS trigger 
language plpgsql as 
$$
declare
numstazioni integer;
pianistaz integer;
telefono1 char(10);
residenza1 varchar(40);
nome1 varchar(27);
cognome1 varchar(24);
codiceAzienda1 dom_codice_azienda;
codiceStazione1 dom_codice_stazione;
BEGIN
	SELECT count(DISTINCT codiceStazione) into numstazioni from PIANO_DI_LAVORO_GIORNALIERO AS PLG where PLG.CFDipendente=old.CFDipendente group by CFDipendente;
	SELECT count(*) into pianistaz from PIANO_DI_LAVORO_GIORNALIERO AS PLG WHERE PLG.codiceStazione=old.codiceStazione and PLG.CFDipendente=old.CFDipendente group by CFDipendente,codiceStazione;
	IF numstazioni<2 or (numstazioni=2 and pianistaz<2)
	THEN
		RAISE NOTICE 'Il dipendente lavora in UNA SOLA stazione, trasferisci da tipo2 a tipo1';
		PERFORM * from tipo2 where cf=old.cfdipendente;
		if found then 
			select telefono into telefono1 from tipo2 where old.CFDipendente=cf; 
			select residenza into residenza1 from tipo2 where old.CFDipendente=cf;
			select nome into nome1 from tipo2 where old.CFDipendente=cf;
			select cognome into cognome1 from tipo2 where old.CFDipendente=cf;
			select codiceAzienda into codiceAzienda1 from tipo2 where old.CFDipendente=cf;
			select codiceStazione into codiceStazione1 from piano_di_lavoro_giornaliero where old.CFDipendente=CFdipendente and codiceStazione<>old.codiceStazione;
			delete from tipo2 where old.CFDipendente=cf;
			perform * from tipo1 where cf=old.cfdipendente;
			if not found then 
				insert into TIPO1(CF,telefono,residenza,nome,cognome,codiceAzienda,codiceStazione) values (old.CFDipendente,telefono1,residenza1,nome1,cognome1,codiceAzienda1,codiceStazione1);
			end if;
			perform * from PIANO_DI_LAVORO_GIORNALIERO where CFDipendente=old.CFDipendente and codicestazione<>old.codiceStazione;
			if found then 
				delete from PIANO_DI_LAVORO_GIORNALIERO where CFDipendente=old.CFDipendente and codicestazione<>old.codiceStazione; 
			end if;
			return null;
		else 
			return old;
		END IF;
	ELSE
		RETURN old;
	END IF;
END;
$$;

create trigger controllo_stazioni_multiple_piano
	before delete on PIANO_DI_LAVORO_GIORNALIERO
	for each row
	execute procedure verifica_vincolo_stazioni_multiple();


-- se aggiorno stazioni presso cui lavora nel piano 

CREATE OR REPLACE FUNCTION verifica_vincolo_stazioni_multiple_update()
RETURNS trigger 
language plpgsql as 
$$
declare
numstazioni integer;
pianistaz integer;
telefono1 char(10);
residenza1 varchar(40);
nome1 varchar(27);
cognome1 varchar(24);
codiceAzienda1 dom_codice_azienda;
codiceStazione1 dom_codice_stazione;
BEGIN
	SELECT count(DISTINCT codicestazione) into numstazioni from PIANO_DI_LAVORO_GIORNALIERO AS PLG where PLG.CFDipendente=new.CFDipendente group by CFDipendente;
	SELECT count(*) into pianistaz from PIANO_DI_LAVORO_GIORNALIERO AS PLG WHERE PLG.codiceStazione=new.codiceStazione and PLG.CFDipendente=new.CFDipendente
	group by CFDipendente,codiceStazione;
	IF numstazioni<=2
	THEN 
		RAISE NOTICE 'Il dipendente lavora in UNA SOLA stazione, trasferisci da tipo2 a tipo1';
		PERFORM * from tipo2 where cf=new.cfdipendente;
	if found then 
			select telefono into telefono1 from tipo2 where new.CFDipendente=cf; 
			select residenza into residenza1 from tipo2 where new.CFDipendente=cf;
			select nome into nome1 from tipo2 where new.CFDipendente=cf;
			select cognome into cognome1 from tipo2 where new.CFDipendente=cf;
			select codiceAzienda into codiceAzienda1 from tipo2 where new.CFDipendente=cf;
			select codiceStazione into codiceStazione1 from piano_di_lavoro_giornaliero where new.CFDipendente=CFdipendente and codiceStazione=new.codiceStazione;
			delete from tipo2 where new.CFDipendente=cf;
			perform * from tipo1 where cf=new.cfdipendente;
			if not found then 
				insert into TIPO1(CF,telefono,residenza,nome,cognome,codiceAzienda,codiceStazione) values (new.CFDipendente,telefono1,residenza1,nome1,cognome1,codiceAzienda1,codiceStazione1);
			end if;
			perform * from PIANO_DI_LAVORO_GIORNALIERO where CFDipendente=new.CFDipendente and codicestazione<>new.codiceStazione;
			if found then 
				delete from PIANO_DI_LAVORO_GIORNALIERO where CFDipendente=new.CFDipendente and codicestazione<>new.codiceStazione; 
			end if;
			return null;
		else 
			return new;
		END IF;
	ELSE
		RETURN new;
	END IF;
END;
$$;

create trigger controllo_stazioni_multiple_piano_update
	before update on PIANO_DI_LAVORO_GIORNALIERO
	for each row when (new.codiceStazione <> old.codiceStazione)
	execute procedure verifica_vincolo_stazioni_multiple_update();

-- TRIGGER #4 stazione rifornimento non deve fornire carburante
-- non erogato da una sua pompa

-- insert or update on FORNISCE
CREATE OR REPLACE FUNCTION verifica_vincolo_carburante()
RETURNS trigger 
language plpgsql as 
$$
BEGIN
	PERFORM * FROM EROGA, POMPA where new.codiceStazione=eroga.codiceStazione and POMPA.codiceStazione=EROGA.codiceStazione and new.tipoCarburante=EROGA.tipoCarburante;
	IF NOT FOUND THEN
		RAISE NOTICE 'non deve fornire carburante non erogato da una sua pompa';
		RETURN NULL;
	ELSE RETURN new;
	END IF;
END;
$$;

create trigger controllo_carburante
	before insert or update on FORNISCE
	for each row
	execute procedure verifica_vincolo_carburante();

-- delete on EROGA
CREATE OR REPLACE FUNCTION verifica_vincolo_carburante_delete()
RETURNS trigger 
language plpgsql as 
$$
BEGIN
	PERFORM * FROM STAZIONE_DI_RIFORNIMENTO AS S where S.codice=old.codiceStazione; 
	IF FOUND THEN 
		PERFORM * FROM FORNISCE where old.codiceStazione=FORNISCE.codiceStazione and old.tipoCarburante=FORNISCE.tipoCarburante;
		IF FOUND THEN
			RAISE NOTICE 'non deve fornire carburante non erogato da una sua pompa';
			RETURN NULL;
		ELSE 
			RETURN old;
		END IF;
	ELSE 	
		RETURN old;
	END IF;
END;
$$;

create trigger controllo_carburante_delete
	before delete on EROGA
	for each row
	execute procedure verifica_vincolo_carburante_delete();

-- update tipoCarburante on EROGA 
CREATE OR REPLACE FUNCTION verifica_vincolo_carburante_update()
RETURNS trigger 
language plpgsql as 
$$
BEGIN
	PERFORM * FROM FORNISCE where new.codiceStazione=FORNISCE.codiceStazione and new.tipoCarburante=FORNISCE.tipoCarburante;
	IF NOT FOUND THEN
		RAISE NOTICE 'non deve fornire carburante non erogato da una sua pompa';
		RETURN NULL;
	ELSE RETURN new;
	END IF;
END;
$$;

create trigger controllo_carburante_update
	before update on EROGA
	for each row when (new.tipoCarburante <> old.tipoCarburante)
	execute procedure verifica_vincolo_carburante_update();

-- TRIGGER #5 dipendente tipo 2 non può spostarsi da una stazione 
-- all'altra in uno stesso giorno

CREATE OR REPLACE FUNCTION verifica_giorno()
RETURNS trigger 
language plpgsql as 
$$
BEGIN
	PERFORM * FROM PIANO_DI_LAVORO_GIORNALIERO AS PDG where new.CFDipendente=PDG.CFDipendente AND new.giorno=PDG.giorno AND old.codiceStazione<>PDG.codiceStazione;
	IF FOUND THEN
		RAISE NOTICE 'non deve lavorare per una stazione differente nello stesso giorno';
		RETURN NULL;
	ELSE RETURN new;
	END IF;
END;
$$;

-- insert or update codiceStazione in PIANO_DI_LAVORO_GIORNALIERO
create trigger controllo_giorno
	before insert on PIANO_DI_LAVORO_GIORNALIERO
	for each row
	execute procedure verifica_giorno();

create trigger controllo_giorno_update
	before update on PIANO_DI_LAVORO_GIORNALIERO
	for each row when (new.codiceStazione <> old.codiceStazione)
	execute procedure verifica_giorno();


-- Vincoli lato 1,N su 1

-- TRIGGER #6: azienda lato N - stazione di rifornimento lato 1
-- ogni azienda possiede almeno una stazione di rifornimento

CREATE or REPLACE FUNCTION verifica_cardinalita_azienda()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM AZIENDA AS A, STAZIONE_DI_RIFORNIMENTO AS S1 WHERE A.codice=S1.codiceAzienda and A.codice=old.codiceAzienda;
	IF FOUND THEN 
		PERFORM * FROM STAZIONE_DI_RIFORNIMENTO AS S WHERE S.codiceAzienda=old.codiceAzienda and S.codice <> old.codice;
		if NOT FOUND then 
			RAISE NOTICE 'ogni azienda possiede almeno una stazione di rifornimento';
			RETURN NULL;
		else 
			RETURN old;
		end if;
	ELSE 	
		RETURN old;
	END IF;
END;
$$;

create trigger controllo_cardinalita_azienda
before delete on STAZIONE_DI_RIFORNIMENTO
for each row execute procedure verifica_cardinalita_azienda();

CREATE or REPLACE FUNCTION verifica_cardinalita_azienda_update()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM AZIENDA AS A, STAZIONE_DI_RIFORNIMENTO AS S1 WHERE A.codice=S1.codiceAzienda and A.codice=old.codiceAzienda;
	IF FOUND THEN 
		PERFORM * FROM STAZIONE_DI_RIFORNIMENTO AS S WHERE S.codiceAzienda=old.codiceAzienda and S.codice <> new.codice;
		if NOT FOUND then 
			RAISE NOTICE 'ogni azienda possiede almeno una stazione di rifornimento';
			RETURN NULL;
		else 
			RETURN new;
		end if;
	ELSE 
		return new;
	END IF;
END;
$$;

create trigger controllo_cardinalita_azienda_update
before update on STAZIONE_DI_RIFORNIMENTO
for each row when (new.codiceAzienda <> old.codiceAzienda)
execute procedure verifica_cardinalita_azienda_update();


-- TRIGGER #7: stazione lato N - piano di lavoro lato 1
-- ogni stazione possiede almeno un piano di lavoro giornaliero 

CREATE or REPLACE FUNCTION verifica_cardinalita_stazione()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM STAZIONE_DI_RIFORNIMENTO AS S, PIANO_DI_LAVORO_GIORNALIERO AS PDG1 where S.codice=PDG1.codiceStazione and PDG1.codiceStazione=old.codiceStazione;
	if FOUND then 
		PERFORM * FROM PIANO_DI_LAVORO_GIORNALIERO AS PDG WHERE PDG.codiceStazione=old.codiceStazione AND (PDG.CFDipendente<>old.CFDipendente OR PDG.giorno<>old.giorno);
		if NOT FOUND then 
			RAISE NOTICE 'ogni stazione possiede almeno un piano di lavoro giornaliero ';
			RETURN null;
		else 
			RETURN old;
		end if;
	else 
	RETURN old;
	end if;
END;
$$;

create trigger controllo_cardinalita_stazione
before delete on PIANO_DI_LAVORO_GIORNALIERO
for each row execute procedure verifica_cardinalita_stazione();

CREATE or REPLACE FUNCTION verifica_cardinalita_stazione_update()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM STAZIONE_DI_RIFORNIMENTO AS S, PIANO_DI_LAVORO_GIORNALIERO AS PDG1 where S.codice=PDG1.codiceStazione and PDG1.codiceStazione=old.codiceStazione;
	IF FOUND THEN 
	    PERFORM * FROM PIANO_DI_LAVORO_GIORNALIERO AS PDG WHERE PDG.codiceStazione=old.codiceStazione AND (PDG.CFDipendente<>old.CFDipendente OR PDG.giorno<>old.giorno);
		if NOT FOUND then 
			RAISE NOTICE 'ogni stazione possiede almeno un piano di lavoro giornaliero ';
			RETURN NULL;
		else 
		RETURN new;
		end if;
	else 
		RETURN new;
	end if;
END;
$$;

create trigger controllo_cardinalita_stazione_update
before update on PIANO_DI_LAVORO_GIORNALIERO
for each row when (new.codiceStazione <> old.codiceStazione)
execute procedure verifica_cardinalita_stazione_update();

-- TRIGGER #8: stazione lato N, tipo1 lato 1
-- ogni stazione presenta almeno un dipendente di tipo1

CREATE or REPLACE FUNCTION verifica_cardinalita_stazione_dip()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM STAZIONE_DI_RIFORNIMENTO AS S1, TIPO1 AS T1 WHERE S1.codice=old.codiceStazione AND T1.codiceStazione=S1.codice;
	IF FOUND THEN 
		PERFORM * FROM TIPO1 AS T WHERE T.CF<>old.CF and T.codiceStazione=old.codiceStazione;
		if NOT FOUND then 
			RAISE NOTICE 'ogni stazione presenta almeno un dipendente di tipo1';
			RETURN NULL;
		else 
			RETURN old;
		end if;
	ELSE 
		return old;
	END IF; 
END;
$$;

create trigger controllo_cardinalita_stazione_dip
before delete on TIPO1
for each row execute procedure verifica_cardinalita_stazione_dip();

CREATE or REPLACE FUNCTION verifica_cardinalita_stazione_dip_update()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM STAZIONE_DI_RIFORNIMENTO AS S1, TIPO1 AS T1 WHERE S1.codice=old.codiceStazione AND T1.codiceStazione=S1.codice;
	IF FOUND THEN 
    	PERFORM * FROM TIPO1 AS T WHERE T.CF<>new.CF and T.codiceStazione=old.codiceStazione;
		if NOT FOUND then 
			RAISE NOTICE 'ogni stazione presenta almeno un dipendente di tipo1 ';
			RETURN NULL;
		else 
			RETURN new;
		end if;
	else 
		return new;
	end if;
END;
$$;

create trigger controllo_cardinalita_stazione_dip_update
before update on TIPO1
for each row when (new.codiceStazione <> old.codiceStazione)
execute procedure verifica_cardinalita_stazione_dip_update();

-- TRIGGER #9: azienda lato N - tipo1 lato 1
-- Ogni azienda ha almeno un dipendente tipo1 che lavora per essa

CREATE or REPLACE FUNCTION verifica_cardinalita_azienda_tipo1()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM AZIENDA AS A, TIPO1 AS T1 WHERE A.codice=T1.codiceAzienda and A.codice=old.codiceAzienda;
	IF FOUND THEN 
		PERFORM * FROM TIPO1 AS T WHERE T.CF<>old.CF and T.codiceAzienda=old.codiceAzienda;
		if NOT FOUND then 
			RAISE NOTICE 'ogni azienda ha almeno un dipendente tipo1 che lavora per essa';
			RETURN NULL;
		else 
			RETURN old;
		end if;
	ELSE 
		RETURN old;
	END IF;
END;
$$;

create trigger controllo_cardinalita_azienda_tipo1
before delete on TIPO1
for each row execute procedure verifica_cardinalita_azienda_tipo1();

CREATE or REPLACE FUNCTION verifica_cardinalita_azienda_tipo1_update()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM AZIENDA AS A, TIPO1 AS T1 WHERE A.codice=T1.codiceAzienda and A.codice=old.codiceAzienda;
	IF FOUND THEN 
    	PERFORM * FROM TIPO1 AS T WHERE T.CF<>new.CF and T.codiceAzienda=old.codiceAzienda;
		if NOT FOUND then 
			RAISE NOTICE 'ogni azienda ha almeno un dipendente tipo1 che lavora per essa';
			RETURN NULL;
		else 
			RETURN new;
		end if;
	ELSE
		RETURN new;
	END IF;
END;
$$;

create trigger controllo_cardinalita_azienda_tipo1_update
before update on TIPO1
for each row when (new.codiceAzienda <> old.codiceAzienda)
execute procedure verifica_cardinalita_azienda_tipo1_update();


-- TRIGGER #10: azienda lato N - tipo2 lato 1
-- Ogni azienda ha almeno un dipendente tipo2 che lavora per essa

CREATE or REPLACE FUNCTION verifica_cardinalita_azienda_tipo2()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM AZIENDA AS A, TIPO2 AS T2 WHERE A.codice=T2.codiceAzienda and A.codice=old.codiceAzienda;
	IF FOUND THEN 
		PERFORM * FROM TIPO2 AS T WHERE T.CF<>old.CF and T.codiceAzienda=old.codiceAzienda;
		if NOT FOUND then 
			RAISE NOTICE 'ogni azienda ha almeno un dipendente tipo2 che lavora per essa';
			RETURN NULL;
		else 
			RETURN old;
		end if;
	ELSE 
		RETURN old;
	END IF;
END;
$$;

create trigger controllo_cardinalita_azienda_tipo2
before delete on TIPO2
for each row execute procedure verifica_cardinalita_azienda_tipo2();

CREATE or REPLACE FUNCTION verifica_cardinalita_azienda_tipo2_update()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM AZIENDA AS A, TIPO2 AS T2 WHERE A.codice=T2.codiceAzienda and A.codice=old.codiceAzienda;
	IF FOUND THEN 
    	PERFORM * FROM TIPO2 AS T WHERE T.CF<>new.CF and T.codiceAzienda=old.codiceAzienda;
		if NOT FOUND then 
			RAISE NOTICE 'ogni azienda ha almeno un dipendente tipo2 che lavora per essa';
			RETURN NULL;
		else 
			RETURN new;
		end if;
	ELSE 	
		RETURN new;
	END IF;
END;
$$;

create trigger controllo_cardinalita_azienda_tipo2_update
before update on TIPO2
for each row when (new.codiceAzienda <> old.codiceAzienda)
execute procedure verifica_cardinalita_azienda_tipo2_update();

-- TRIGGER #11: stazione lato N - pompa lato 1
-- Ogni stazione dispone di almeno una pompa

CREATE or REPLACE FUNCTION verifica_cardinalita_stazione_pompa()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM STAZIONE_DI_RIFORNIMENTO AS S, POMPA AS P1 WHERE S.codice=P1.codiceStazione AND S.codice=old.codiceStazione;
	IF FOUND THEN
		PERFORM * FROM POMPA AS P WHERE P.numero<>old.numero and P.codiceStazione=old.codiceStazione;
		if NOT FOUND then 
			RAISE NOTICE 'ogni stazione dispone di almeno una pompa';
			RETURN NULL;
		else 
			RETURN old;
		end if;
	ELSE 	
		RETURN old;
	END IF;
END;
$$;

create trigger controllo_cardinalita_stazione_pompa
before delete on POMPA
for each row execute procedure verifica_cardinalita_stazione_pompa();

CREATE or REPLACE FUNCTION verifica_cardinalita_stazione_pompa_update()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM STAZIONE_DI_RIFORNIMENTO AS S, POMPA AS P1 WHERE S.codice=P1.codiceStazione AND S.codice=old.codiceStazione;
	IF FOUND THEN
    	PERFORM * FROM POMPA AS P WHERE P.numero<>new.numero and P.codiceStazione=old.codiceStazione;
		if NOT FOUND then 
			RAISE NOTICE 'ogni stazione disponde di almeno una pompa';
			RETURN NULL;
		else 
			RETURN new;
		end if;
	ELSE 
		return new;
	end if;
END;
$$;

create trigger controllo_cardinalita_stazione_pompa_update
before update on POMPA 
for each row when (new.codiceStazione<>old.codiceStazione)
execute procedure verifica_cardinalita_stazione_pompa_update();

-- TRIGGER #12: piano_di_lavoro_settimanale lato N - piano_di_lavoro_giornaliero lato 1
-- Ogni pds dispone di almeno un pdg

CREATE or REPLACE FUNCTION verifica_cardinalita_pds()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM PIANO_DI_LAVORO_SETTIMANALE AS PDS, PIANO_DI_LAVORO_GIORNALIERO AS PDG1 where PDS.numeroSettimana=PDG1.numeroSettimana and PDG1.numeroSettimana=old.numeroSettimana;
	if FOUND then 
		PERFORM * FROM PIANO_DI_LAVORO_GIORNALIERO AS PDG WHERE PDG.numeroSettimana=old.numeroSettimana AND (PDG.CFDipendente<>old.CFDipendente OR PDG.giorno<>old.giorno OR PDG.codiceStazione<>old.codiceStazione);
		if NOT FOUND then 
			RAISE NOTICE 'ogni piano di lavoro settimanale possiede almeno un piano di lavoro giornaliero ';
			RETURN null;
		else 
			RETURN old;
		end if;
	else 
	RETURN old;
	end if;
END;
$$;

create trigger controllo_cardinalita_pds
before delete on PIANO_DI_LAVORO_GIORNALIERO
for each row execute procedure verifica_cardinalita_pds();

CREATE or REPLACE FUNCTION verifica_cardinalita_pds_update()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM PIANO_DI_LAVORO_SETTIMANALE AS PDS, PIANO_DI_LAVORO_GIORNALIERO AS PDG1 where PDS.numeroSettimana=PDG1.numeroSettimana and PDG1.numeroSettimana=old.numeroSettimana;
	IF FOUND THEN 
	    PERFORM * FROM PIANO_DI_LAVORO_GIORNALIERO AS PDG WHERE PDG.numeroSettimana=old.numeroSettimana AND (PDG.CFDipendente<>old.CFDipendente OR PDG.giorno<>old.giorno OR PDG.codiceStazione<>old.codiceStazione);
		if NOT FOUND then 
			RAISE NOTICE 'ogni piano di lavoro settimanale possiede almeno un piano di lavoro giornaliero ';
			RETURN NULL;
		else 
		RETURN new;
		end if;
	else 
		RETURN new;
	end if;
END;
$$;

create trigger controllo_cardinalita_pds_update
before update on PIANO_DI_LAVORO_GIORNALIERO
for each row when (new.numeroSettimana <> old.numeroSettimana)
execute procedure verifica_cardinalita_pds_update();

-- TRIGGER #13
-- stazione almeno un tipo di carburante (se elimino o update in fornisce)

CREATE or REPLACE FUNCTION verifica_cardinalita_fornisce_carburante()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM STAZIONE_DI_RIFORNIMENTO AS S, FORNISCE AS F, CARBURANTE AS T where S.codice=F.codiceStazione and F.tipoCarburante=T.tipo and F.tipoCarburante=old.tipoCarburante;
	if FOUND then 
		PERFORM * FROM FORNISCE AS F1 WHERE old.tipoCarburante <> F1.tipoCarburante AND F1.codiceStazione=old.codiceStazione;
		if NOT FOUND then 
			RAISE NOTICE 'ogni stazione fornisce almeno un tipo di carburante';
			RETURN null;
		else 
			RETURN old;
		end if;
	else 
	RETURN old;
	end if;
END;
$$;

create trigger controllo_cardinalita_fornisce_carburante
before delete on FORNISCE
for each row execute procedure verifica_cardinalita_fornisce_carburante();


CREATE or REPLACE FUNCTION verifica_cardinalita_fornisce_carburante_update()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM STAZIONE_DI_RIFORNIMENTO AS S, FORNISCE AS F, CARBURANTE AS T where S.codice=F.codiceStazione and F.tipoCarburante=T.tipo and F.codiceStazione=old.codiceStazione;
	if FOUND then 
		PERFORM * FROM FORNISCE AS F1 WHERE new.tipoCarburante <> F1.tipoCarburante AND F1.codiceStazione=old.codiceStazione;
		if NOT FOUND then 
			RAISE NOTICE 'ogni stazione fornisce almeno un tipo di carburante';
			RETURN null;
		else 
			RETURN new;
		end if;
	else 
	RETURN new;
	end if;
END;
$$;

create trigger controllo_cardinalita_fornisce_carburante_update
before update on FORNISCE
for each row when (new.codiceStazione <> old.codiceStazione)
execute procedure verifica_cardinalita_fornisce_carburante_update();

-- pompa eroga almeno un tipo di carburante (se elimino o update eroga problema)


CREATE or REPLACE FUNCTION verifica_cardinalita_eroga_carburante()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM POMPA AS P, EROGA AS E, CARBURANTE AS T where P.numero=E.numeroPompa and E.codiceStazione=P.codiceStazione and E.tipoCarburante=T.tipo and T.tipo=old.tipoCarburante;
	if FOUND then 
		PERFORM * FROM EROGA AS E1 WHERE E1.tipoCarburante <> old.tipoCarburante AND (E1.numeroPompa=old.numeroPompa and E1.codiceStazione=old.codiceStazione);
		if NOT FOUND then 
			RAISE NOTICE 'ogni pompa eroga almeno un tipo di carburante';
			RETURN null;
		else 
			RETURN old;
		end if;
	else 
	RETURN old;
	end if;
END;
$$;

create trigger controllo_cardinalita_eroga_carburante
before delete on EROGA
for each row execute procedure verifica_cardinalita_eroga_carburante();


CREATE or REPLACE FUNCTION verifica_cardinalita_eroga_carburante_update()
RETURNS trigger
language plpgsql as
$$
BEGIN
	PERFORM * FROM POMPA AS P, EROGA AS E, CARBURANTE AS T where P.numero=E.numeroPompa and E.codiceStazione=P.codiceStazione and E.tipoCarburante=T.tipo and T.tipo=old.tipoCarburante;
	if FOUND then 
		PERFORM * FROM EROGA AS E1 WHERE new.tipoCarburante <> E1.tipoCarburante AND (E1.numeroPompa=old.numeroPompa AND E1.codiceStazione=old.codiceStazione);
		if NOT FOUND then 
			RAISE NOTICE 'ogni pompa eroga almeno un tipo di carburante';
			RETURN null;
		else 
			RETURN new;
		end if;
	else 
	RETURN new;
	end if;
END;
$$;

create trigger controllo_cardinalita_eroga_carburante_update
before update on EROGA
for each row when (new.codiceStazione <> old.codiceStazione or new.numeroPompa <> old.numeroPompa)
execute procedure verifica_cardinalita_eroga_carburante_update();

-- TRIGGER #14
-- numero pompe in carburante consistenti con pompe presenti

create or replace function verifica_numeropompe()
RETURNS trigger
language plpgsql as
$$
declare 
n integer;
BEGIN
	SELECT count(*) into n from POMPA as P where P.tipoCarburante=old.tipoCarburante;
	update CARBURANTE set numeroDiPompe=n where tipo=old.tipoCarburante;
	RETURN old;
END;
$$;

create or replace function verifica_numeropompe_insorupdate()
RETURNS trigger
language plpgsql as
$$
declare 
n integer;
BEGIN
	SELECT count(*) into n from POMPA as P where P.tipoCarburante=new.tipoCarburante;
	update CARBURANTE set numeroDiPompe=n where tipo=new.tipoCarburante;
	RETURN new;
END;
$$;

create trigger controlla_numeropompe 
after delete on POMPA
for each row execute procedure verifica_numeropompe();

create trigger controlla_numeropompe_insorupdate
after insert or update on POMPA
for each row execute procedure verifica_numeropompe_insorupdate();
