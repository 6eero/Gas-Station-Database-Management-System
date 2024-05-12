library("RPostgreSQL")
library(tidyverse)
library(ggplot2)
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "fuelstationdatabase") 
dbGetQuery(con, "SET search_path TO fuelstationdatabase;")

# barplot sulla distribuzione delle tipologie di Carburante (ovvero il numeroDiPompe che erogano tale carburante) fornito da ciascuna Azienda 
# correlato alla query 5

ds_grafico1 <- dbGetQuery(con, "SELECT numeroDiPompe, tipo FROM CARBURANTE;")

plot1 <- ggplot(data = ds_grafico1, aes(x=tipo, y=numerodipompe, fill=tipo)) + 
	geom_bar(stat = "identity") +
	scale_fill_manual(values = c("#467F48", "#000000", "#EBD436")) + # benzina verde, gas giallo, diesel nero
	theme_bw() + #sfondo bianco
	theme(legend.position = "none") +
	labs(y= "Numero di Pompe", x = "Tipologia di Carburante",fill = "Tipo")
	
png(file="grafico1.png")
plot1


# barplot sulla quantitàDisponibile di ciascun Carburante diviso per Azienda
# correlato alla query 7

ds_grafico2 <- dbGetQuery(con, "SELECT quantitaDisponibile, codiceAzienda, tipoCarburante FROM FORNISCE AS F, STAZIONE_DI_RIFORNIMENTO AS S WHERE F.codiceStazione = S.codice;")

codice_stringa <- as.character(ds_grafico2$codiceazienda) #rende stringhe i numeri identificativi delle Aziende

plot2 <- ggplot(data = ds_grafico2, aes(x=codice_stringa, y=quantitadisponibile, fill=tipocarburante)) + 
	geom_bar(stat = "identity") +
	scale_y_continuous(
		breaks = waiver(),
		n.breaks = 9 #numero di break sull'asse y
	) +
	scale_fill_manual(values = c("#467F48", "#000000", "#EBD436")) + # benzina verde, gas giallo, diesel nero
	theme_bw() + #sfondo bianco
	labs(y= "Quantità Disponibile", x = "Codice dell'Azienda", fill = "Tipologia di Carburante")

png(file="grafico2.png")
plot2

# boxplot per la distribuzione di dipendenti (Tipo1 e Tipo2) che hanno la residenza nello stesso comune (divisi per Azienda)
# correlato alla query 8

ds_grafico3 <- dbGetQuery(con, "CREATE VIEW DIPENDENTI AS SELECT CF, residenza, codiceAzienda FROM TIPO1 UNION SELECT CF, residenza, codiceAzienda FROM TIPO2; SELECT count(*) AS count, residenza, codiceAzienda FROM DIPENDENTI GROUP BY residenza, codiceAzienda;")

ds_grafico3_1 <- mutate(ds_grafico3, codiceazienda = as.character(codiceazienda)) # modifica i dati per rendere stringhe i numeri identificativi delle Aziende

plot3 <- ggplot(data = ds_grafico3_1, mapping=aes(x=codiceazienda, y=count), fill=codiceazienda) + 
	geom_boxplot(fill = c("#000000", "#283241", "#0A3755", "#0A7D8C", "#BED7ED", "#F064B1", "#FF5A5F", "#C81E23")) +
	stat_summary( # per indicare anche la media
		fun.y=mean, geom="point", shape=4,
		aes(group=1),
		color="orange") +
	theme_bw() + #sfondo bianco
	labs(y= "Numero Residenti nello stesso Comune", x = "Codice dell'Azienda")
	
png(file="grafico3.png")
plot3

dev.off()
