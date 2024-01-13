SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS smart_home;
CREATE DATABASE smart_home; 
USE smart_home;

-- ================= --
-- 	    Account      --
-- ================= --
DROP TABLE IF EXISTS Account;
CREATE TABLE Account(
    NomeUtente 		 	VARCHAR(20) NOT NULL,
    Password 		 	VARCHAR(20) NOT NULL,
							CHECK(LENGTH(password)>=8),
    DomandaSicurezza 	INTEGER NOT NULL,
    RispostaSicurezza 	VARCHAR(20) NOT NULL, 
    Utente 				VARCHAR(16) NOT NULL,
    Interazioni 		INTEGER NOT NULL DEFAULT 0,
							CHECK (Interazioni >= 0),
    PRIMARY KEY(NomeUtente),
    
    FOREIGN KEY(DomandaSicurezza) REFERENCES DomandaSicurezza(ID),
    FOREIGN KEY(Utente) REFERENCES Utente(CodiceFiscale)

)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================ --
-- 	    Utente      --
-- ================ --
DROP TABLE IF EXISTS Utente;
CREATE TABLE Utente(
    CodiceFiscale 		VARCHAR(16) NOT NULL, 
    Nome 				VARCHAR(20) NOT NULL, 
    Cognome 			VARCHAR(20) NOT NULL, 
    DataNascita 		DATE NOT NULL,
    DataIscrizione 		DATE NOT NULL,
    NumTelefono 		VARCHAR(20) NOT NULL, 
    TipologiaDocumento 	VARCHAR(30) NOT NULL,
    NumeroDocumento 	VARCHAR(20) NOT NULL,
    PRIMARY KEY(CodiceFiscale),
    
	FOREIGN KEY(TipologiaDocumento, NumeroDocumento) REFERENCES Documento(Tipologia, NumeroDocumento)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- 	   Documento     --
-- ================= --
DROP TABLE IF EXISTS Documento;
CREATE TABLE Documento(
    Tipologia 			VARCHAR(20) NOT NULL,
							CHECK (Tipologia IN('Carta identità', 'Passaporto', 'Patente')),
    NumeroDocumento 	VARCHAR(20) NOT NULL, 
    EnteRilascio 		VARCHAR(40) NOT NULL, 
    Scadenza 			DATE NOT NULL,
    PRIMARY KEY(Tipologia, NumeroDocumento)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- DomandaSicurezza  --
-- ================= --
DROP TABLE IF EXISTS DomandaSicurezza;
CREATE TABLE DomandaSicurezza(
    ID 			INTEGER NOT NULL AUTO_INCREMENT, 
    Testo 		VARCHAR(100) NOT NULL,
    PRIMARY KEY(ID)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- 	    Stanza       --
-- ================= --
DROP TABLE IF EXISTS Stanza;
CREATE TABLE Stanza(
    ID 				INTEGER NOT NULL AUTO_INCREMENT, 
    Nome 			VARCHAR(20) NOT NULL, 
    Piano 			DOUBLE, 
    Larghezza 		DOUBLE, 
						CHECK (Larghezza > 0),
    Lunghezza 		DOUBLE, 
						CHECK (Lunghezza > 0),
    Altezza 		DOUBLE,
						CHECK (Altezza > 0),
    PRIMARY KEY(ID)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- 	    Accesso      --
-- ================= --
DROP TABLE IF EXISTS Accesso;
CREATE TABLE Accesso(
    ID 				INTEGER NOT NULL AUTO_INCREMENT, 
    Tipologia 		VARCHAR(13) NOT NULL, 
						CHECK (Tipologia IN('Finestra', 'Porta', 'Portafinestra')),
    Orientamento 	VARCHAR(2), 
						CHECK (Orientamento IN('S', 'SO', 'O', 'NO', 'N', 'NE', 'E', 'SE')),
    Verso1 			INTEGER NOT NULL, 
    Verso2 			INTEGER,
    PRIMARY KEY(ID),
    
	FOREIGN KEY(Verso1) REFERENCES Stanza(ID),
    FOREIGN KEY(Verso2) REFERENCES Stanza(ID)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- 	   SmartPlug     --
-- ================= --
DROP TABLE IF EXISTS SmartPlug;
CREATE TABLE SmartPlug(
    ID 				INTEGER NOT NULL AUTO_INCREMENT, 
    Stanza 			INTEGER NOT NULL,
    PRIMARY KEY(ID),
    
	FOREIGN KEY(Stanza) REFERENCES Stanza(ID)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- 	  Dispositivo    --
-- ================= --
DROP TABLE IF EXISTS Dispositivo;
CREATE TABLE Dispositivo(
    ID 				INTEGER NOT NULL AUTO_INCREMENT, 
    Nome 			VARCHAR(20) NOT NULL, 
    TipoConsumo 	VARCHAR(18) NOT NULL, 
						CHECK (TipoConsumo IN('Fisso', 'Variabile', 'Non interrompibile')),
    SmartPlug 		INTEGER NOT NULL REFERENCES SmartPlug(ID), 
    Stato 			VARCHAR(3) NOT NULL DEFAULT 'OFF',
						CHECK (Stato IN('ON', 'OFF')),
    PRIMARY KEY(ID),
    
    FOREIGN KEY(SmartPlug) REFERENCES SmartPlug(ID)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- 	  Regolazione    --
-- ================= --
DROP TABLE IF EXISTS Regolazione;
CREATE TABLE Regolazione(
    Dispositivo 		INTEGER NOT NULL, 
    CodR 				INTEGER NOT NULL,
    PRIMARY KEY(Dispositivo, CodR),
    
    FOREIGN KEY(Dispositivo) REFERENCES Dispositivo(ID)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================ --
-- 	   Livello      --
-- ================ --
DROP TABLE IF EXISTS Livello;
CREATE TABLE Livello(
    Dispositivo 	INTEGER NOT NULL, 
    CodR 			INTEGER NOT NULL, 
    Livello 		VARCHAR(20),
    Potenza 		DOUBLE NOT NULL,
						CHECK (Potenza > 0),
    PRIMARY KEY(Dispositivo, CodR),
    
    FOREIGN KEY(Dispositivo, CodR) REFERENCES Regolazione(Dispositivo, CodR)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- 	   Programma     --
-- ================= --
DROP TABLE IF EXISTS Programma;
CREATE TABLE Programma(
    Dispositivo 	INTEGER NOT NULL, 
    CodR 			INTEGER NOT NULL, 
    Nome 			VARCHAR(20), 
    Durata 			INTEGER NOT NULL, 
						CHECK (Durata > 0),
    Potenza 		DOUBLE NOT NULL
						CHECK (Potenza > 0),
    PRIMARY KEY(Dispositivo, CodR),
    
    FOREIGN KEY(Dispositivo, CodR) REFERENCES Regolazione(Dispositivo, CodR)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- 	  Interazione    --
-- ================= --
DROP TABLE IF EXISTS Interazione;
CREATE TABLE Interazione(
    Dispositivo 		INTEGER NOT NULL, 
    CodR	 			INTEGER NOT NULL, 
    Inizio 				DATETIME NOT NULL,
    Fine 				DATETIME, 
							CHECK (Fine > Inizio),
    Account 			VARCHAR(20) NOT NULL,
    PRIMARY KEY(Dispositivo, CodR, Inizio),
    
    FOREIGN KEY(Dispositivo, CodR) REFERENCES Regolazione(Dispositivo, CodR),
        FOREIGN KEY(Account) REFERENCES Account(NomeUtente)

)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================ --
-- 	 FasciaOraria   --
-- ================ --
DROP TABLE IF EXISTS FasciaOraria;
CREATE TABLE FasciaOraria(
    Inizio 			INTEGER(2) NOT NULL, 
						CHECK (Inizio BETWEEN 0 AND 23),
    UtilizzoEnergia VARCHAR(3) NOT NULL, 
						CHECK (UtilizzoEnergia IN('IN', 'OUT')),
    Prezzo 			DOUBLE NOT NULL, 
						CHECK (Prezzo > 0),
    Account 		VARCHAR(20) NOT NULL,
    PRIMARY KEY(Inizio),
    
    FOREIGN KEY(Account) REFERENCES Account(NomeUtente)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- 	 Irraggiamento   --
-- ================= --
DROP TABLE IF EXISTS Irraggiamento;
CREATE TABLE Irraggiamento(
    PannelloFotovoltaico 	INTEGER NOT NULL, 
    Istante 				DATETIME NOT NULL, 
    Percentuale				DOUBLE NOT NULL DEFAULT 0, 
								CHECK (Percentuale BETWEEN 0 AND 100),
    FasciaOraria 			INTEGER NOT NULL,
    PRIMARY KEY(PannelloFotovoltaico, Istante),
    
    FOREIGN KEY (PannelloFotovoltaico) REFERENCES PannelloFotovoltaico(ID),
    FOREIGN KEY (FasciaOraria) REFERENCES FasciaOraria(Inizio)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ======================== --
--   PannelloFotovoltaico   --
-- ======================== --
DROP TABLE IF EXISTS PannelloFotovoltaico;
CREATE TABLE PannelloFotovoltaico(
    ID 						INTEGER NOT NULL AUTO_INCREMENT,
    MaxPotenzaProd 			DOUBLE NOT NULL, 
								CHECK (MaxPotenzaProd > 0),
    ProduzioneGiornaliera 	DOUBLE NOT NULL DEFAULT 0, 
								CHECK (ProduzioneGiornaliera >= 0),
    IrraggiamentoAttuale 	DOUBLE NOT NULL DEFAULT 0,
   								CHECK (IrraggiamentoAttuale BETWEEN 0 AND 100),
    PRIMARY KEY(ID)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================ --
-- 	 Suggerimento   --
-- ================ --
DROP TABLE IF EXISTS Suggerimento;
CREATE TABLE Suggerimento(
    Istante 		DATETIME NOT NULL, 
    Dispositivo 	INTEGER NOT NULL, 
    CodR 			INTEGER NOT NULL, 
    Account 		VARCHAR(20), 
    Risposta 		VARCHAR(2),
						CHECK (Risposta IN('SI', 'NO')),
    PRIMARY KEY(Istante),
    
    FOREIGN KEY(Dispositivo, CodR) REFERENCES Regolazione(Dispositivo, CodR),
    FOREIGN KEY(Account) REFERENCES Account(NomeUtente)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ====================== --
--   TemperaturaInterna   --
-- ====================== --
DROP TABLE IF EXISTS TemperaturaInterna;
CREATE TABLE TemperaturaInterna(
    Stanza 			INTEGER NOT NULL, 
    Istante 		DATETIME NOT NULL, 
    Temperatura 	DOUBLE NOT NULL,
    PRIMARY KEY(Stanza, Istante),
    
    FOREIGN KEY(Stanza) REFERENCES Stanza(ID)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================== --
-- 	  ElementoLuce    --
-- ================== --
DROP TABLE IF EXISTS ElementoLuce;
CREATE TABLE ElementoLuce(
    ID 				INTEGER NOT NULL AUTO_INCREMENT, 
    Potenza 		DOUBLE NOT NULL, 
						CHECK (Potenza > 0),
    MinIntensità 	INTEGER NOT NULL, 
						CHECK (MinIntensità BETWEEN 1 AND 100),
    MinTempColore 	INTEGER NOT NULL, 
						CHECK (MinTempColore BETWEEN 2600 AND 8000),
    MaxTempColore 	INTEGER NOT NULL, 
						CHECK (MaxTempColore BETWEEN MinTempColore AND 8000),
    Stanza 			INTEGER NOT NULL,
    Stato 			VARCHAR(3) NOT NULL DEFAULT 'OFF',
						CHECK (Stato IN('ON', 'OFF')),
    PRIMARY KEY(ID),
    
    FOREIGN KEY(Stanza) REFERENCES Stanza(ID)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ==================== --
-- 	 ImpostazioneLuce   --
-- ==================== --
DROP TABLE IF EXISTS ImpostazioneLuce;
CREATE TABLE ImpostazioneLuce(
    ElementoLuce 		INTEGER NOT NULL AUTO_INCREMENT, 
    Inizio 				DATETIME NOT NULL,
    Fine 				DATETIME, 
							CHECK (Fine > Inizio),
    TempColore 			INTEGER NOT NULL, 
    Intensità 			INTEGER NOT NULL,
    PRIMARY KEY(ElementoLuce, Inizio),
    
    FOREIGN KEY(ElementoLuce) REFERENCES ElementoLuce(ID)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================ --
-- 	   Generale     --
-- ================ --
DROP TABLE IF EXISTS Generale;
CREATE TABLE Generale(
    ElementoLuce 		INTEGER NOT NULL, 
    Inizio 				DATETIME NOT NULL, 
    Predefinito 		INTEGER NOT NULL,
    PRIMARY KEY(ElementoLuce, Inizio, Predefinito),
    
    FOREIGN KEY(ElementoLuce, Inizio) REFERENCES ImpostazioneLuce(ElementoLuce, Inizio),
    FOREIGN KEY(Predefinito) REFERENCES Predefinito(ID)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================ --
-- 	 Predefinito    --
-- ================ --
DROP TABLE IF EXISTS Predefinito;
CREATE TABLE Predefinito(
    ID 				INTEGER NOT NULL AUTO_INCREMENT, 
    TempColore 		INTEGER NOT NULL, 
						CHECK (TempColore BETWEEN 2600 AND 8000),
    Intensità 		INTEGER NOT NULL DEFAULT 100,
						CHECK (Intensità BETWEEN 1 AND 100),
    PRIMARY KEY(ID)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================== --
-- 	 Climatizzatore   --
-- ================== --
DROP TABLE IF EXISTS Climatizzatore;
CREATE TABLE Climatizzatore(
    ID 				INTEGER NOT NULL AUTO_INCREMENT, 
    Potenza 		DOUBLE NOT NULL, 
						CHECK (Potenza > 0),
    Stanza 			INTEGER NOT NULL,
    Stato 			VARCHAR(3) NOT NULL DEFAULT 'OFF',
						CHECK (Stato IN('ON', 'OFF')),
    PRIMARY KEY(ID),
    
	FOREIGN KEY(Stanza) REFERENCES Stanza(ID)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ===================== --
-- 	 ImpostazioneClima   --
-- ===================== --
DROP TABLE IF EXISTS ImpostazioneClima;
CREATE TABLE ImpostazioneClima(
    Climatizzatore 		INTEGER NOT NULL, 
    Inizio 				DATETIME NOT NULL,
    Fine 				DATETIME, 
							CHECK (Fine > Inizio),
    Umidità 			INTEGER, 
							CHECK (Umidità BETWEEN 0 AND 100),
    Temperatura 		DOUBLE NOT NULL, 
    Account 			VARCHAR(20) NOT NULL,
    PRIMARY KEY(Climatizzatore, Inizio),
    
    FOREIGN KEY(Climatizzatore) REFERENCES Climatizzatore(ID),
	FOREIGN KEY(Account) REFERENCES Account(NomeUtente)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- 	   Schedule      --
-- ================= --
DROP TABLE IF EXISTS Schedule;
CREATE TABLE Schedule(
    Climatizzatore 	INTEGER NOT NULL, 
    Inizio 			DATETIME NOT NULL, 
    Ricorrenza 		INTEGER NOT NULL,
    PRIMARY KEY(Climatizzatore, Inizio, Ricorrenza),
    
    FOREIGN KEY(Climatizzatore, Inizio) REFERENCES ImpostazioneClima(Climatizzatore, Inizio),
    FOREIGN KEY(Ricorrenza) REFERENCES Ricorrenza(ID)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;

-- ================= --
-- 	  Ricorrenza     --
-- ================= --
DROP TABLE IF EXISTS Ricorrenza;
CREATE TABLE Ricorrenza(
    ID 					INTEGER AUTO_INCREMENT, 
    Temperatura 		INTEGER NOT NULL, 
    Umidità 			INTEGER, 
							CHECK (Umidità BETWEEN 0 AND 100),
    Orario 				TIME NOT NULL, 
    GiornoMese 			INTEGER, 
							CHECK (GiornoMese BETWEEN 1 AND 31),
    Mese 				INTEGER, 
							CHECK (Mese BETWEEN 1 AND 12),
    GiornoSettimana 	INTEGER, 
							CHECK (GiornoSettimana BETWEEN 0 AND 6),
    Attiva 				VARCHAR(3) NOT NULL DEFAULT 'ON',
							CHECK (Attiva IN('ON', 'OFF')),
    PRIMARY KEY(ID)
)ENGINE = InnoDB DEFAULT CHARSET = latin1;


-- ========================================================== --
-- 				VINCOLI GENERICI AGGIUNTIVI				      --
-- ========================================================== --

-- In Utente, DataNascita deve essere minore o uguale della data D'ISCRIZIONE – 14 anni al momento dell’iscrizione 
DROP TRIGGER IF EXISTS ControlloNascita;
DELIMITER $$
CREATE TRIGGER ControlloNascita
BEFORE INSERT ON Utente
FOR EACH ROW
BEGIN
	
    IF (NEW.DataNascita > NEW.DataIscrizione - INTERVAL 14 YEAR) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'L''età minima per registrare un account è di 14 anni';
    END IF;
    
    IF NEW.DataIscrizione IS NULL THEN
		SET NEW.DataIscrizione = CURRENT_DATE();
    END IF;
    
END $$
DELIMITER ;

-- In Documento, Scadenza deve essere maggiore della data corrente al momento dell’inserimento
DROP TRIGGER IF EXISTS ControlloDocumento;
DELIMITER $$
CREATE TRIGGER ControlloDocumento
BEFORE INSERT ON Documento
FOR EACH ROW
BEGIN
	
    IF (NEW.Scadenza <= CURRENT_DATE) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Impossibile registrare documento scaduto o in scadenza oggi.';
    END IF;
    
END $$
DELIMITER ;

-- In Livello, possono essere registrati livelli solo per dispositivi di TipoConsumo Fisso o Variabile
DROP TRIGGER IF EXISTS ControlloLivello;
DELIMITER $$
CREATE TRIGGER ControlloLivello
BEFORE INSERT ON Livello
FOR EACH ROW
BEGIN
	
    IF ( SELECT D.TipoConsumo
		 FROM Dispositivo D
         WHERE D.ID = NEW.Dispositivo ) = 'Non interrompibile' 
	THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Non possono essere inseriti livelli per dispositivi Non interrompibili.';
    END IF;
    
END $$
DELIMITER ;

-- In Programma, possono essere registrati programmi solo per dispositivi di TipoConsumo Non interrompibile
DROP TRIGGER IF EXISTS ControlloProgramma;
DELIMITER $$
CREATE TRIGGER ControlloProgramma
BEFORE INSERT ON Programma
FOR EACH ROW
BEGIN
	
    IF ( SELECT D.TipoConsumo
		 FROM Dispositivo D
         WHERE D.ID = NEW.Dispositivo ) <> 'Non interrompibile' 
	THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Non possono essere creati programmi per dispositivi a consumo fisso o variabile.';
    END IF;
    
END $$
DELIMITER ;

-- In Interazione, Inizio deve essere maggiore o uguale a Fine dell'operazione precedente sullo stesso dispositivo,
-- per interazioni il cui avvio non è programmato in futuro
DROP TRIGGER IF EXISTS ControlloInizioInterazione;
DELIMITER $$
CREATE TRIGGER ControlloInizioInterazione
BEFORE INSERT ON Interazione
FOR EACH ROW
BEGIN

	IF NEW.Inizio < (
			SELECT I.Fine
            FROM Interazione I
            WHERE I.Dispositivo = NEW.Dispositivo AND I.Inizio <= CURRENT_TIMESTAMP()
            ORDER BY I.Fine DESC
            LIMIT 1
    )
    THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Questo dispositivo è attualmente in uso.';
    END IF;
	
END $$
DELIMITER ;

-- In ImpostazioneLuce, Inizio deve essere maggiore o uguale a Fine dell'operazione precedente sullo stesso elemento luce
DROP TRIGGER IF EXISTS ControlloInizioLuce;
DELIMITER $$
CREATE TRIGGER ControlloInizioLuce
BEFORE INSERT ON ImpostazioneLuce
FOR EACH ROW
BEGIN

	IF NEW.Inizio < (
			SELECT I.Fine
            FROM ImpostazioneLuce I
            WHERE I.ElementoLuce = NEW.ElementoLuce
            ORDER BY I.Fine DESC
            LIMIT 1
    )
    THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Questo elemento luce è attualmente in uso';
    END IF;
	
END $$
DELIMITER ;

-- In ImpostazioneClima, Inizio deve essere maggiore o uguale a Fine dell'operazione precedente sullo stesso climatizzatore
DROP TRIGGER IF EXISTS ControlloInizioClimatizzatore;
DELIMITER $$
CREATE TRIGGER ControlloInizioClimatizzatore
BEFORE INSERT ON ImpostazioneClima
FOR EACH ROW
BEGIN

	IF NEW.Inizio < (
			SELECT MAX(I.Fine)
            FROM ImpostazioneClima I
            WHERE I.Climatizzatore = NEW.Climatizzatore ) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Questo climatizzatore è attualmente in uso';
    END IF;
	
END $$
DELIMITER ;

-- In Ricorrenza, non possono essere presenti ricorrenze con stessi valori su GiornoMese, GiornoSettimana, Mese
DROP TRIGGER IF EXISTS ControlloRicorrenze;
DELIMITER $$
CREATE TRIGGER ControlloRicorrenze
BEFORE INSERT ON Ricorrenza
FOR EACH ROW
BEGIN

	IF EXISTS (
			SELECT *
            FROM Ricorrenza R
            WHERE R.GiornoMese = NEW.GiornoMese AND
				  R.Giornosettimana = NEW.GiornoSettimana AND
                  R.Mese = NEW.Mese
    )
    THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La ricorrenza è già stata inserita.';
    END IF;
	
END $$
DELIMITER ;