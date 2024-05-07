-- INSERIMENTO
-- 1. Assunzione di un nuovo dipendente all'interno di un'azienda

INSERT INTO TIPO1(cf, telefono, residenza, nome, cognome, codiceAzienda, codiceStazione) VALUES ('PTRPTR85M63G475H', '3692581470', 'Sappada', 'Pietro', 'Pietroschi', 2, 446);


-- CANCELLAZIONE
-- 2. Rimozione di una pompa da una stazione di rifornimento

DELETE FROM POMPA where numero=12;


-- AGGIORNAMENTI
-- 3. Cambiamento dell’azienda proprietaria di una stazione di rifornimento (si suppone che i dipendenti rimangano nella stessa stazione ma cambiano azienda)

UPDATE AZIENDA SET codice=12 where codice=21;

-- 4. Modifica del piano di lavoro giornaliero di un dipendente

UPDATE PIANO_DI_LAVORO_GIORNALIERO SET giorno='Martedì' WHERE cfdipendente='STHIYE72F03P048D' AND codicestazione=547;


-- QUERY SQL
-- 5. Trovare stazione di rifornimento con massimo numero di pompe che erogano gas

CREATE VIEW numero_pompe(codice, N) AS
SELECT S.codice, count(*) AS N 
FROM POMPA AS P, STAZIONE_DI_RIFORNIMENTO AS S
WHERE P.codiceStazione=S.codice and P.tipoCarburante='metano'
GROUP BY S.codice;

SELECT codice
FROM numero_pompe AS NP
WHERE NOT EXISTS (SELECT *
				  FROM numero_pompe as NP2
				  WHERE NP.codice<>NP2.codice AND NP.N<NP2.N);

-- 6. Per ogni comune n° stazioni di rifornimento di una data azienda

SELECT S.comune, S.codiceAzienda, count(*) 
FROM STAZIONE_DI_RIFORNIMENTO AS S
GROUP BY S.comune, S.codiceAzienda;

-- 7. Tutti i dipendenti che lavorano presso una stazione che può erogare un 
-- carburante che ha capacità disponibile almeno 10000 e al massimo 17000

SELECT CF
FROM TIPO1 as T
WHERE EXISTS (SELECT *
       		FROM FORNISCE AS F
        	WHERE F.codiceStazione=T.codiceStazione 
        	AND quantitaDisponibile<=17000 AND quantitaDisponibile>=10000)
UNION 
SELECT T.CF
FROM TIPO2 as T, PIANO_DI_LAVORO_GIORNALIERO AS PDG
WHERE T.CF=PDG.CFDipendente
	AND EXISTS (SELECT *
       			FROM FORNISCE AS F
        		WHERE F.codiceStazione=PDG.codiceStazione 
        		AND quantitaDisponibile<=17000 AND quantitaDisponibile>=10000);

-- 8. Tutti i dipendenti la cui residenza è uguale ad almeno 3 altri
-- dipendenti che lavorano nella stessa azienda

CREATE VIEW DIPENDENTI AS
SELECT CF, residenza, codiceAzienda
FROM TIPO1 
UNION 
SELECT CF, residenza, codiceAzienda
FROM TIPO2;


SELECT CF
FROM DIPENDENTI AS D
WHERE EXISTS (SELECT *
        	 FROM DIPENDENTI AS D1
        	 WHERE D.CF<>D1.CF AND D.residenza=D1.residenza 
             AND D.codiceAzienda=D1.codiceAzienda AND
             EXISTS (SELECT * 
                	FROM DIPENDENTI AS D2
                	WHERE D.CF<>D1.CF AND D1.CF<>D2.CF AND D2.CF<>D.CF 
                    AND D2.codiceAzienda=D.codiceAzienda
                    AND D2.residenza=D.residenza AND 
					EXISTS (SELECT * 
                		FROM DIPENDENTI AS D3
                		WHERE D.CF<>D1.CF AND D1.CF<>D2.CF AND D2.CF<>D.CF AND D3.CF<>D.CF AND 
							D3.CF<>D2.CF AND D3.CF<>D1.CF AND  
                    		D3.codiceAzienda=D.codiceAzienda AND
                    		D3.residenza=D.residenza)));


