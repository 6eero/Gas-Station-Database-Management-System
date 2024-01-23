# Gas-Station-Database-Management-System
📊  This project is focused on the practical laboratory component of the database fundamentals course.

# About
Si vuole progettare una base di dati di supporto alla gestione della rete di stazioni per il rifornimento di carburante presenti sul territorio della regione Friuli Venezia Giulia.
Ogni stazione di rifornimento sia identificata univocamente da un codice e sia caratterizzata dall’azienda che la possiede, da una coppia di coordinate geografiche, che identificano la sua posizione, e dal comune di appartenenza. Ogni stazione offra diversi tipi di carburante (benzina, gasolio, gas, ..) e disponga di un certo numero di pompe per l’erogazione del carburante. Si assuma che non necessariamente ogni stazione offra tutti i tipi possibili di carburante. Si vuole tener traccia delle (poche) stazioni che erogano gas. 
Per ogni tipo di carburante disponibile presso una data stazione, si memorizzi la capacità massima del relativo serbatoio e la quantità correntemente disponibile. All’interno di una determinata stazione, ogni pompa sia caratterizzata da un numero (pompa numero 1, pompa numero 2, ..) e sia caratterizzata dal tipo di carburante erogato. 
Ogni azienda sia identificata univocamente da un codice. Di ogni azienda vogliamo memorizzare il responsabile per la regione Friuli Venezia Giulia e il comune ove si trova l’ufficio regionale di riferimento. Si assuma che un’azienda possa possedere più stazioni di rifornimento e che ogni stazione di rifornimento appartenga ad un’unica azienda. 
Ogni azienda disponga di un certo numero di persone che prestano servizio presso le stazioni di rifornimento di sua proprietà. Ogni dipendente di un’azienda sia identificato univocamente dal suo codice fiscale e sia caratterizzato da nome e cognome, residenza e recapito telefonico. Si assuma che un dipendente possa lavorare presso più stazioni di rifornimento dell’azienda. Di ogni dipendente che lavora presso più stazioni, vogliamo memorizzare il piano di lavoro settimanale (si assuma che un dipendente non possa spostarsi da una stazione all’altra in uno stesso giorno della settimana, ma possa lavorare presso stazioni diverse in giorni diversi).
Si definisca uno schema Entità-Relazioni che descriva il contenuto informativo del sistema, illustrando con chiarezza le eventuali assunzioni fatte. Lo schema dovrà essere completato con attributi ragionevoli per ciascuna entità (identificando le possibili chiavi) e relazione. Vanno specificati accuratamente i vincoli di cardinalità e partecipazione di ciascuna relazione. Si definiscono anche eventuali regole aziendali (regole di derivazione e vincoli di integrità) necessarie per codificare alcuni dei requisiti attesi del sistema.


# Components
- ER Diagram([https://wiki.archlinux.org](https://github.com/6eero/Gas-Station-Database-Management-System/blob/main/ER-Schema.png)https://github.com/6eero/Gas-Station-Database-Management-System/blob/main/ER-Schema.png)
- Schema(https://github.com/6eero/Gas-Station-Database-Management-System/blob/main/schema.sql)
- Sample Queries
