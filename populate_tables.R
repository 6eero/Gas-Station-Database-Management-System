library("RPostgreSQL")
library(tidyverse)
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname = "fuelstationdatabase") 
dbGetQuery(con, "SET search_path TO fuelstationdatabase;")

# populate table "azienda"
set.seed(7)
v_nomi <- readLines("./nomi.txt")
v_cognomi <- readLines("./cognomi.txt")
v_comuni <- readLines("./ComuniFVG.txt")
v_responsabile <- data.frame(nome=sample(v_nomi, 8, replace = T), cognome=sample(v_cognomi, 8, replace = T))
v_responsabile <- unite(v_responsabile, responsabile, nome, cognome, sep=" ") 
v_responsabile <- as.vector(v_responsabile)
azienda_df <- data.frame(codice = sample(1:99, 8, replace=F),
                          responsabile = v_responsabile,
                          comune = sample(v_comuni, 8, replace = T))
# azienda_df
dbWriteTable(con, 
              name="azienda", 
              value=azienda_df, 
              append = T, 
              row.names=F)

# populate table "stazione di rifornimento"
# codiceazienda chiave esterna verso azienda
temp_azienda <- dbGetQuery(con, "SELECT codice FROM AZIENDA;")
temp_azienda <- temp_azienda$codice
#ogni azienda dispone di almeno una stazione
v_codiciAzienda <- sample(temp_azienda, 8, replace=F)
v_codiciAzienda1 <- sample(temp_azienda, 492, replace=T)
stazione_di_rifornimento.codiceazienda <- c(v_codiciAzienda, v_codiciAzienda1)
v_latitudini <- readLines("./latitudini.txt")
v_longitudini <- readLines("./longitudini.txt")
stazione_di_rifornimento_df <- data.frame(codice = sample(100:1000, 500, replace=F),
                                          comune = sample(v_comuni, 500, replace = T),
                                          latitudine = sample(v_latitudini,500,replace=T),
                                          longitudine = sample(v_longitudini, 500, replace=T),
                                          codiceazienda = stazione_di_rifornimento.codiceazienda)
#stazione_di_rifornimento_df

dbWriteTable(con, 
             name="stazione_di_rifornimento", 
             value=stazione_di_rifornimento_df, 
             append = T, 
             row.names=F)

#populate table "carburante"
carburante_df <- data.frame(tipo = c("benzina", "diesel", "gas"),
                            numerodipompe = c("800", "550", "150")) # poche di gas 
#carburante_df
dbWriteTable(con, 
             name="carburante", 
             value=carburante_df, 
             append = T, 
             row.names=F)

# populate table "pompa"
v_benzina <- array()
for(i in 1:800){
  v_benzina[[i]] <- "benzina"
}

v_diesel <- array()
for(i in 1:550){
  v_diesel[[i]] <- "diesel"
}
v_gas <- array()
for(i in 1:150){
  v_gas[[i]] <- "gas"
}

temp_stazione <- dbGetQuery(con, "SELECT codice FROM STAZIONE_DI_RIFORNIMENTO;")
temp_stazione <- temp_stazione$codice
# ogni stazione dispone di almeno una pompa
v_codiciStazione <- sample(temp_stazione, 500, replace=F)
#800 pompe di benzina
pompa_benzina.codicestazione <- c(v_codiciStazione,sample(temp_stazione, 300, replace=T))
pompa_diesel.codicestazione <- sample(temp_stazione, 550, replace=T)
pompa_gas.codicestazione <- sample(temp_stazione, 150, replace=T)

pompa_benzina_df <- data.frame(numero = sample(1:800,800,replace=F),
                               codicestazione = pompa_benzina.codicestazione, 
                               tipocarburante = v_benzina)
pompa_diesel_df <- data.frame(numero = sample(801:1351,550,replace=F),
                               codicestazione = pompa_diesel.codicestazione, 
                               tipocarburante = v_diesel)
pompa_gas_df <- data.frame(numero = sample(1352:1900,150,replace=F),
                               codicestazione = pompa_gas.codicestazione, 
                               tipocarburante = v_gas)
pompa_df <- merge(pompa_benzina_df,pompa_diesel_df, all=TRUE)
pompa_df <- merge(pompa_df, pompa_gas_df, all=TRUE)

dbWriteTable(con, 
             name="pompa", 
             value=pompa_df, 
             append = T, 
             row.names=F)

#populate table "tipo1"
v_lettere <- readLines("./lettere.txt")
v_giorni <- readLines("./giorni.txt")
v_anno <- readLines("./AnniLavorativi.txt") #in età lavorativa tra 1961 e 2006
v_cf <- data.frame(lettera1=sample(v_lettere, 50000, replace = T), lettera2=sample(v_lettere, 50000, replace = T),
                   lettera3=sample(v_lettere, 50000, replace = T), lettera4=sample(v_lettere, 50000, replace = T), 
                   lettera5=sample(v_lettere, 50000, replace = T), lettera6=sample(v_lettere, 50000, replace = T), 
                   anni=sample(v_anno, 50000, replace=T), lettera7=sample(v_lettere, 50000, replace = T), 
                   giorni=sample(v_giorni,50000,replace=T), lettera8=sample(v_lettere, 50000, replace = T),
                   numero1=sample(0:9,50000,replace=T), numero2=sample(0:9,50000,replace=T), numero3=sample(0:9,50000,replace=T),
                   lettera9=sample(v_lettere, 50000, replace = T))
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
temp_tipo1_df <- dbGetQuery(con, "SELECT codice,codiceazienda FROM STAZIONE_DI_RIFORNIMENTO LIMIT 8;")
temp1_tipo1_df <- dbGetQuery(con, "SELECT codice,codiceazienda from STAZIONE_DI_RIFORNIMENTO OFFSET 16 LIMIT 392;")
v_codiciAzienda_tipo1 <- temp_tipo1_df$codiceazienda
v_codiciAzienda1_tipo1 <- temp1_tipo1_df$codiceazienda
tipo1.codiceazienda <- c(v_codiciAzienda_tipo1, v_codiciAzienda1_tipo1)
v_codicestazione_tipo1 <- temp_tipo1_df$codice
v_codicestazione1_tipo1 <- temp1_tipo1_df$codice
tipo1.codicestazione <- c(v_codicestazione_tipo1, v_codicestazione1_tipo1)
v_codiciAzienda_tipo2 <- temp_tipo1_df$codiceazienda
temp_tipo2_df <- dbGetQuery(con, "SELECT codice,codiceazienda FROM STAZIONE_DI_RIFORNIMENTO OFFSET 16 LIMIT 392;")
temp1_tipo2_df <- dbGetQuery(con, "SELECT codice,codiceazienda from STAZIONE_DI_RIFORNIMENTO OFFSET 300 LIMIT 200;")
v_codiciAzienda1_tipo2 <- temp_tipo2_df$codiceazienda
v_codiciAzienda2_tipo2 <- temp1_tipo2_df$codiceazienda
tipo2.codiceazienda <- c(v_codiciAzienda_tipo2, c(v_codiciAzienda1_tipo2, v_codiciAzienda2_tipo2))

tipo1_df <- data.frame(cf= sample(v_cf,400,replace=F),
                       telefono = sample(v_telefono,400,replace = F),
                       residenza = sample(v_comuni, 400, replace = T), 
                       nome = sample(v_nomi, 400, replace = T), 
                       cognome = sample(v_cognomi, 400, replace = T),
                       codiceazienda = tipo1.codiceazienda,
                       codicestazione = tipo1.codicestazione)

# tipo1_df
dbWriteTable(con, 
             name="tipo1", 
             value=tipo1_df, 
             append = T, 
             row.names=F)

#populate table "tipo2"
temp_cf_tipo2 <- dbGetQuery(con, "SELECT cf FROM TIPO1;")
temp_cf_tipo2 <- temp_cf_tipo2$cf
v_cf <- setdiff(v_cf,temp_cf_tipo2)

tipo2_df <- data.frame(cf= sample(v_cf,600,replace=F),
                       telefono = sample(v_telefono,600,replace=F),
                       residenza = sample(v_comuni, 600, replace = T), 
                       nome=sample(v_nomi, 600, replace = T), 
                       cognome=sample(v_cognomi, 600, replace = T),
                       codiceazienda = tipo2.codiceazienda)
# tipo2_df

dbWriteTable(con, 
             name="tipo2", 
             value=tipo2_df, 
             append = T, 
             row.names=F)

# populate table "piano_di_lavoro_settimanale"
v_piano_di_lavoro_s <- sample(1:52,52,replace=F)
pds.numerosettimana <- v_piano_di_lavoro_s
piano_di_lavoro_settimanale_df <- data.frame(numerosettimana=pds.numerosettimana) # 52 settimane in un anno
# piano_di_lavoro_settimanale_df

dbWriteTable(con, 
             name="piano_di_lavoro_settimanale", 
             value=piano_di_lavoro_settimanale_df, 
             append = T, 
             row.names=F)

# populate table "piano_di_lavoro_giornaliero"
v_giorno <- readLines("Giornate.txt")
temp_azienda_stazione <- dbGetQuery(con, "SELECT cf, codice FROM (SELECT T.cf, S.codice, ROW_NUMBER() OVER (PARTITION BY T.cf) AS row_num
    FROM tipo2 AS T JOIN stazione_di_rifornimento AS S ON T.codiceazienda = S.codiceazienda) AS subquery WHERE row_num <= 7;")
pdg.cf <- temp_azienda_stazione$cf
pdg.codicestazione <-  temp_azienda_stazione$codice
temp_settimana <- dbGetQuery(con, "SELECT numerosettimana FROM PIANO_DI_LAVORO_SETTIMANALE;")
temp_settimana <- temp_settimana$numerosettimana
pdg.numerosettimana <- c(v_piano_di_lavoro_s, sample(temp_settimana,4148,replace=T))
piano_di_lavoro_giornaliero_df <- data.frame(giorno = v_giorno, 
                                             cfdipendente = pdg.cf,
                                             codicestazione = pdg.codicestazione,
                                             numerosettimana = pdg.numerosettimana) # 52 settimane in un anno
# piano_di_lavoro_giornaliero_df

dbWriteTable(con, 
             name="piano_di_lavoro_giornaliero", 
             value=piano_di_lavoro_giornaliero_df, 
             append = T, 
             row.names=F)

#populate table "eroga"
temp_pompa_df <- dbGetQuery(con, "SELECT numero,codicestazione,tipocarburante from POMPA;")
temp_pompa.codicestazione <- temp_pompa_df$codicestazione
temp_pompa.numero <- temp_pompa_df$numero
temp_pompa.tipocarburante <- temp_pompa_df$tipocarburante
# eroga.codicestazione <- sample(temp_stazione, 1500, replace=T)
eroga_df <- data.frame(tipocarburante = temp_pompa.tipocarburante,
                       numeropompa = temp_pompa.numero,
                       codicestazione = temp_pompa.codicestazione)
# eroga_df

dbWriteTable(con, 
             name="eroga", 
             value=eroga_df, 
             append = T, 
             row.names=F)

#populate table "fornisce"
temp_fornisce <- dbGetQuery(con, "SELECT codicestazione,tipocarburante FROM POMPA GROUP BY codicestazione,tipocarburante;")
fornisce.codicestazione <- temp_fornisce$codicestazione
fornisce.tipocarburante <- temp_fornisce$tipocarburante
n <- dim(temp_fornisce) #array con numero tuple 
n <- n[1] # numero tuple
v_capacitamassima <- c(sample(50000:60000, n, replace=T))
v_quantitadisponibile <- array()
for(i in 1:n){
  j <- v_capacitamassima[i]
  v_quantitadisponibile[i] <- sample(1:j,1)
}
fornisce_df <- data.frame(codicestazione = fornisce.codicestazione,
                          tipocarburante = fornisce.tipocarburante,
                          capacitamassima = v_capacitamassima,
                          quantitadisponibile = v_quantitadisponibile
                          )
#fornisce_df
dbWriteTable(con, 
             name="fornisce", 
             value=fornisce_df, 
             append = T, 
             row.names=F)

