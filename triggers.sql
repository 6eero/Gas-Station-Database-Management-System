--------------------------------
--												    --
-- 					TRIGGER 					--
--												    --
--------------------------------


-- TRIGGER #1:  un dipendente di tipo 1 deve lavorare presso stazioni di rifornimento solo appartenenti all’azienda per cui lavora

CREATE OR REPLACE FUNCTION verifica_dipendenti()
RETURNS trigger 
language plpgsql as 
$$
BEGIN
	PERFORM * FROM TIPO1, STAZIONE_DI_RIFORNIMENTO AS STAZIONE
		WHERE new.codiceStazione = codice AND new.codiceAzienda <> STAZIONE.codiceAzienda;
	IF FOUND
	THEN
		RAISE NOTICE 'dipendente lavora per una stazione non di proprietà dell’azienda per cui lavora';
	ELSE
		RETURN new;
	END IF;
END;
$$;

create trigger controllo_dipendenti
	before insert or update on TIPO1
	for each row
	execute procedure verifica_dipendenti();


-- TRIGGER #2:  un dipendente di tipo 2 deve lavorare presso stazioni di rifornimento solo appartenenti all’azienda per cui lavora

CREATE OR REPLACE FUNCTION verifica_dipendenti_tipo2()
RETURNS trigger 
language plpgsql as 
$$
BEGIN
	PERFORM * FROM TIPO2, PIANO_DI_LAVORO_GIORNALIERO AS PLG, STAZIONE_DI_RIFORNIMENTO AS STAZIONE
		WHERE STAZIONE.codice = PLG.codiceStazione AND new.codiceAzienda <> STAZIONE.codiceAzienda;
	IF FOUND
	THEN
		RAISE NOTICE 'dipendente lavora per una stazione non di proprietà dell’azienda per cui lavora';
	ELSE
		RETURN new;
	END IF;
END;
$$;

create trigger controllo_dipendenti_tipo2
	before insert or update on TIPO2
	for each row
	execute procedure verifica_dipendenti_tipo2();
