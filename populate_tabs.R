library("RPostgreSQL") 
library(tidyverse)
# drv <- dbDriver("PostgreSQL")
# con <- dbConnect(drv, dbname = "lezioni_23_24") 
# dbGetQuery(con, "SET search_path TO stazionirifornimento;")

# populate table "azienda"
set.seed(7)
v_nomi <- readLines("nomi.txt")
v_cognomi <- readLines("cognomi.txt")
v_comuni <- readLines("ComuniFVG.txt")
v_responsabile <- data.frame(nome=sample(v_nomi, 8, replace = T), cognome=sample(v_cognomi, 8, replace = T))
v_responsabile <- unite(v_responsabile, responsabile, nome, cognome, sep=" ") 
v_responsabile <- as.vector(v_responsabile)
azienda_df <- data.frame(codice = sample(1:99, 8, replace=F),
                          responsabile = v_responsabile,
                          comune = sample(v_comuni, 8, replace = T))
azienda_df

# dbWriteTable(con, 
#              name="azienda", 
#              value=azienda_df, 
#              append = T, 
#             row.names=F)

# populate table "stazione di rifornimento"
set.seed(7)
v_comuni <- readLines("ComuniFVG.txt")
v_latitudini <- readLines("Latitudini.txt")
v_longitudini <- readLines("Longitudini.txt")
stazione_di_rifornimento_df <- data.frame(codice = sample(100:1000, 500, replace=F),
                                          comune = sample(v_comuni, 500, replace = T),
                                          latitudine = sample(v_latitudini,500,replace=T),
                                          longitudine = sample(v_longitudini, 500, replace=T),
                                          codiceAzienda = sample(azienda_df$codice, 500, replace=T))
stazione_di_rifornimento_df

#populate table "carburante"
carburante_df <- data.frame(tipo = c("benzina", "gasolio", "gas"),
                            numeroDiPompe = c("800", "550", "150")) # poche di gas 
carburante_df

# populate table "pompa"
set.seed(7)
v_benzina <- array()
for(i in 1:800){
  v_benzina[[i]] <- "benzina"
}

v_gasolio <- array()
for(i in 1:550){
  v_gasolio[[i]] <- "gasolio"
}
v_gas <- array()
for(i in 1:150){
  v_gas[[i]] <- "gas"
}
pompa_benzina_df <- data.frame(numero = sample(1:9,800,replace=T),
                               codiceStazione = sample(stazione_di_rifornimento_df$codice, 800, replace = T), 
                               tipiCarburante = v_benzina)
pompa_gasolio_df <- data.frame(numero = sample(1:9,550,replace=T),
                               codiceStazione = sample(stazione_di_rifornimento_df$codice, 550, replace = T), 
                               tipiCarburante = v_gasolio)
pompa_gas_df <- data.frame(numero = sample(1:9,150,replace=T),
                               codiceStazione = sample(stazione_di_rifornimento_df$codice, 150, replace = T), 
                               tipiCarburante = v_gas)
pompa_df <- merge(pompa_benzina_df,pompa_gasolio_df, all=TRUE)
pompa_df <- merge(pompa_df, pompa_gas_df, all=TRUE)

#populate table "tipo1"
set.seed(7)
v_lettere <- readLines("Lettere.txt")
v_giorni <- readLines("Giorni.txt")
v_anno <- readLines("AnniLavorativi.txt") #in età lavorativa tra 1961 e 2006
v_cf <- data.frame(lettera1=sample(v_lettere, 10000, replace = T), lettera2=sample(v_lettere, 10000, replace = T),
                   lettera3=sample(v_lettere, 10000, replace = T), lettera4=sample(v_lettere, 10000, replace = T), 
                   lettera5=sample(v_lettere, 10000, replace = T), lettera6=sample(v_lettere, 10000, replace = T), 
                   anni=sample(v_anno, 10000, replace=T), lettera7=sample(v_lettere, 10000, replace = T), 
                   giorni=sample(v_giorni,10000,replace=T), lettera8=sample(v_lettere, 10000, replace = T),
                   numero1=sample(0:9,10000,replace=T), numero2=sample(0:9,10000,replace=T), numero3=sample(0:9,10000,replace=T),
                   lettera9=sample(v_lettere, 10000, replace = T))
v_cf <- unite(v_cf, cf, lettera1,lettera2,lettera3,lettera4,lettera5,lettera6,anni,lettera7,giorni,lettera8,
              numero1,numero2,numero3,lettera9, sep="") 
v_cf <- v_cf$cf
v_telefono <- data.frame(cifra1=sample(0:9,10000,replace=T), 
                         cifra2=sample(0:9,10000,replace=T), 
                         cifra3=sample(0:9,10000,replace=T),
                         cifra4=sample(0:9,10000,replace=T),
                         cifra5=sample(0:9,10000,replace=T), 
                         cifra6=sample(0:9,10000,replace=T), 
                         cifra7=sample(0:9,10000,replace=T),
                         cifra8=sample(0:9,10000,replace=T),
                         cifra9=sample(0:9,10000,replace=T), 
                         cifra10=sample(0:9,10000,replace=T))
v_telefono <- unite(v_telefono, telefono, cifra1,cifra2,cifra3,cifra4,cifra5,cifra6,cifra7,cifra8,cifra9,cifra10, sep="") 
v_telefono <- v_telefono$telefono

tipo1_df <- data.frame(CF = sample(v_cf,400,replace=F),
                       telefono = sample(v_telefono,400,replace=F),
                       residenza = sample(v_comuni, 400, replace = T), 
                       nome=sample(v_nomi, 400, replace = T), 
                       cognome=sample(v_cognomi, 400, replace = T),
                       codiceAzienda = sample(azienda_df$codice, 400, replace=T),
                       codiceStazione = sample(stazione_di_rifornimento_df$codice, 400, replace = T))
tipo1_df


#populate table "tipo2"

tipo2_df <- data.frame(CF = sample(v_cf,600,replace=F),
                       telefono = sample(v_telefono,600,replace=F),
                       residenza = sample(v_comuni, 600, replace = T), 
                       nome=sample(v_nomi, 600, replace = T), 
                       cognome=sample(v_cognomi, 600, replace = T),
                       codiceAzienda = sample(azienda_df$codice, 600, replace=T),
                       codiceStazione = sample(stazione_di_rifornimento_df$codice, 600, replace = T))
tipo2_df

# populate table "piano_di_lavoro_settimanale"
piano_di_lavoro_settimanale_df <- data.frame(numero=sample(1:52,31200,replace=T)) # 52 settimane in un anno
piano_di_lavoro_settimanale_df

# populate table "piano_di_lavoro_giornaliero"
v_giorno <- readLines("Giornate.txt")
piano_di_lavoro_giornaliero_df <- data.frame(giorno = sample(v_giorno, 4200, replace=T), 
                                             CFDipendente = sample(tipo2_df$cf, 4200, replace=T),
                                             codiceAzienda = sample(azienda_df$codice, 4200, replace=T)) # 52 settimane in un anno
piano_di_lavoro_giornaliero_df

#populate table "fornisce"
v_capacitàMassima <- c(sample(50000:60000, 1500, replace=T))
v_quantitàDisponibile <- array()
for(i in 1:1500){
  j <- v_capacitàMassima[i]
  v_quantitàDisponibile[i] <- sample(1:j)
}
fornisce_df <- data.frame(codiceStazione = sample(stazione_di_rifornimento_df$codice, 1500, replace = T),
                          tipoCarburante = unite(tipocarbutante, v_benzina, v_gasolio, v_gas),
                          capacitàMassima = v_capacitàMassima,
                          quantitàDisponibile = v_quantitàDisponibile
                          )
fornisce_df

#populate table "eroga"
eroga_df <- data.frame(tipoCarburante = sample(carburante_df$tipo, 1500, replace = T),
                       numeroPompa = sample(pompa_df$numero, 1500, replace=T),
                       codiceStazione = sample(stazione_di_rifornimento_df$codice, 1500, replace=T))
eroga_df

#populate table "dispone_di"
dispone_di_df <- data.frame(codiceStazione = sample(stazione_di_rifornimento_df$codice, 1280, replace=T),
                            numeroPompa = sample(pompa_df$numero, 1280, replace=T))
dispone_di_df

#populate table "caso_particolare_di"
caso_particolare_di_df <- data.frame(numeroSettimana = sample(piano_di_lavoro_settimanale_df$numero, 4200, replace=T),
                                     giorno = sample(piano_di_lavoro_giornaliero_df$giorno, 4200, replace=T),
                                     CFDipendente = sample(tipo2_df$cf, 4200, replace=T),
                                     codiceAzienda = sample(azienda_df$codice, 4200, replace=T))
caso_particolare_di_df
