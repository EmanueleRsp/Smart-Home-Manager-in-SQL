USE smart_home;

-- ================================================================================ --
--                                   OPERAZIONE 1                                   --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS DailyDeviceRanking;
DELIMITER $$
CREATE PROCEDURE DailyDeviceRanking(IN _data DATE)
BEGIN
	DECLARE limite DATETIME;
    
    IF _data > CURRENT_DATE THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La data inserita è maggiore della data corrente.';
    ELSEIF _data = CURRENT_DATE THEN
		SET limite = CONCAT(CURRENT_DATE, '', CURRENT_TIME);
	ELSE
		SET limite = CONCAT(ADDDATE(_data, 1), ' 00:00:00');
	END IF;
    
    
	WITH Durata_Interazioni AS (
		SELECT Dispositivo, CodR, TIMEDIFF(IF(Fine IS NULL, limite, Fine), Inizio) as Durata
        FROM Interazione
        WHERE DATE(Inizio) = _data),
        
	Consumi_Interazioni AS (
        SELECT DI.Dispositivo, DI.CodR, ROUND(HOUR(DI.Durata) + MINUTE(DI.Durata)/60, 3) as Consumo
        FROM Durata_Interazioni DI NATURAL JOIN Livello L),
        
	Consumi_Dispositivi AS (
		SELECT D.ID, D.Nome, D.TipoConsumo as Tipologia, SUM(CI.Consumo) as ConsumoGiornaliero
        FROM Consumi_Interazioni CI RIGHT OUTER JOIN Dispositivo D on CI.Dispositivo = D.ID
        WHERE D.TipoConsumo <> 'Non interrompibile'
        GROUP BY D.ID)
        
    SELECT ID, Nome, Tipologia, IF(ConsumoGiornaliero IS NULL, 0, ConsumoGiornaliero) as ConsumoGiornaliero_kW, RANK() OVER (ORDER BY ConsumoGiornaliero DESC) as Posizione
    FROM Consumi_Dispositivi;
    
END $$
DELIMITER ;

-- ================================================================================ --
--                                   OPERAZIONE 2                                   --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS StartRoomIllumination;
DELIMITER $$
CREATE PROCEDURE StartRoomIllumination(IN _stanza INT, 
									   IN _intensità INT, 
                                       IN _temperatura INT)
BEGIN
	DECLARE min_int INT;
	DECLARE min_temp INT;
    DECLARE max_temp INT;
    DECLARE luce INT;
    DECLARE imp_temp INT;
    DECLARE imp_int INT;
    
	DECLARE finito INT DEFAULT 0;
	DECLARE cursore_luci CURSOR FOR (SELECT ID, MinIntensità, MinTempColore, MaxTempColore
									 FROM ElementoLuce
                                     WHERE Stanza = _stanza);
	DECLARE CONTINUE HANDLER FOR NOT FOUND
		SET finito = 1;
	
    IF _stanza <= 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Il codice della stanza deve essere un valore strettamente positivo.';
    ELSEIF _intensità < 1 OR _intensità > 100 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'L''intensità da impostare deve essere un valore compreso tra 1 e 100.';	
	ELSEIF  _temperatura < 2600 OR _temperatura > 8000 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La temperatura da impostare deve essere un valore compreso tra 2600 e 8000.';	
	END IF;
    
    OPEN cursore_luci;
    loop_label: LOOP        
		FETCH cursore_luci INTO luce, min_int, min_temp, max_temp;
		IF finito = 1 THEN
			LEAVE loop_label;
		END IF;
		
        IF _intensità < min_int THEN
			SET imp_int = min_int;
		ELSE 
			SET imp_int = _intensità;
		END IF;
        
        IF _temperatura <= min_temp THEN
			SET imp_temp = min_temp;
		ELSEIF _temperatura >= max_temp THEN
			SET imp_temp = max_temp;
		ELSE
			SET imp_temp = _temperatura;
		END IF;

		INSERT INTO ImpostazioneLuce (ElementoLuce, Inizio, TempColore, Intensità)
        VALUES (luce, CURRENT_TIMESTAMP, imp_temp, imp_int);
        
    END LOOP;
    CLOSE cursore_luci;
    
END $$
DELIMITER ;

-- ================================================================================ --
--                                   OPERAZIONE 3                                   --
-- ================================================================================ --
DROP TRIGGER IF EXISTS RefreshInterazioniDispositivi;
CREATE TRIGGER RefreshInterazioniDispositivi
AFTER INSERT ON Interazione
FOR EACH ROW
	UPDATE Account
    SET Interazioni = Interazioni +1
    WHERE NomeUtente = NEW.Account;
    
DROP TRIGGER IF EXISTS RefreshInterazioniClimatizzatore;
CREATE TRIGGER RefreshInterazioniClimatizzatore
AFTER INSERT ON ImpostazioneClima
FOR EACH ROW
	UPDATE Account
    SET Interazioni = Interazioni +1
    WHERE NomeUtente = NEW.Account;

DROP EVENT IF EXISTS FlushInterazioni;
CREATE EVENT FlushInterazioni
ON SCHEDULE EVERY 1 MONTH
STARTS '2022-01-01 00:00:00'
DO
	UPDATE Account
    SET Interazioni = 0;

DROP PROCEDURE IF EXISTS InterationAccountRanking;
DELIMITER $$
CREATE PROCEDURE InterationAccountRanking()
BEGIN
	
    SELECT NomeUtente, Interazioni, Rank() OVER (ORDER BY Interazioni DESC) as Posizione
    FROM Account;
    
END $$
DELIMITER ;

-- ================================================================================ --
--                                   OPERAZIONE 4                                   --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS  PercentualeUtilizzo;
DELIMITER $$
CREATE PROCEDURE PercentualeUtilizzo(IN _dispositivo INT, IN _mese INT, IN _anno INT)
BEGIN 
	
    IF _mese < 1 OR _mese > 12 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Il mese deve essere compreso tra 1 (Gennaio) e 12 (Dicembre).';
    ELSEIF _anno > YEAR(CURRENT_DATE) OR (_anno = YEAR(CURRENT_DATE) AND _mese > MONTH(CURRENT_DATE))THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La data inserita è maggiore di quella corrente.';	
	ELSEIF NOT EXISTS (SELECT *
					   FROM Dispositivo
                       WHERE ID = _dispositivo) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'L''ID inserito non corrisponde ad alcun dispositivo.';	
	END IF;
    
    WITH Intervalli_Interazioni AS (SELECT I.Dispositivo, I.Account, I.Inizio, IF(I.Fine IS NULL, 
																					IF(MONTH(CURRENT_DATE) = _mese AND YEAR(CURRENT_DATE) = _anno,
                                                                                       CURRENT_TIMESTAMP(),
                                                                                       CONCAT(IF(_mese <> 12, 
																							     '_anno, ''-'', _mese + 1', 
																								 '_anno + 1, ''01'' '), 
																								 '-01 00:00:00')), 
																					IF(MONTH(I.Fine) = _mese AND YEAR(I.fine) = _anno, 
																					   IF(MONTH(CURRENT_DATE) = _mese AND YEAR(CURRENT_DATE) = _anno,
																						  CURRENT_TIMESTAMP(),
                                                                                          I.Fine),
																					   CONCAT(IF(_mese <> 12, 
																							     '_anno, ''-'', _mese + 1', 
																								 '_anno + 1, ''01'' '), 
																								 '-01 00:00:00'))) as Fine
								   FROM Interazione I
								   WHERE I.Dispositivo = _dispositivo AND 
										 MONTH(I.Inizio) = _mese AND
										 YEAR(I.Inizio) = _anno ),
		 Durata_interazioni AS (SELECT II.Dispositivo, II.Account, TIMESTAMPDIFF(SECOND, II.Inizio, II.Fine) as Durata
								FROM Intervalli_Interazioni II),
		 Totale_interazioni AS (SELECT SUM(Durata) AS Totale
								FROM Durata_interazioni), 
		 Utilizzo_Account AS (SELECT Account, SUM(Durata) AS Totale_Relativo
							  FROM Durata_interazioni
                              GROUP BY Account),
		 Percentuale_Utilizzi AS (SELECT UA.Account, (ROUND(UA.Totale_Relativo / TI.Totale, 4) * 100) as Percentuale
								  FROM Utilizzo_Account UA CROSS JOIN Totale_interazioni TI)
    SELECT A.NomeUtente, ROUND(IF(PU.Percentuale IS NULL, 0.00, PU.Percentuale), 2) as Percentuale_Utilizzo
    FROM Percentuale_Utilizzi PU RIGHT OUTER JOIN Account A ON PU.Account = A.NomeUtente;
    
END $$
DELIMITER ;

-- ================================================================================ --
--                                   OPERAZIONE 5                                   --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS ConsumoMensileStanze;
DELIMITER $$
CREATE PROCEDURE ConsumoMensileStanze(IN _mese INT, IN _anno INT)
BEGIN 
	
    IF _mese < 1 OR _mese > 12 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Il mese deve essere compreso tra 1 (Gennaio) e 12 (Dicembre).';
    ELSEIF _anno > YEAR(CURRENT_DATE) OR (_anno = YEAR(CURRENT_DATE) AND _mese > MONTH(CURRENT_DATE))THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La data inserita è maggiore di quella corrente.';	
	END IF;
    
    WITH Intervalli_Illuminazioni AS (SELECT I.ElementoLuce, I.Inizio, IF(I.Fine IS NULL, 
																  IF(MONTH(CURRENT_DATE) = _mese AND YEAR(CURRENT_DATE) = _anno,
                                                                     CURRENT_TIMESTAMP(),
                                                                     CONCAT(IF(_mese <> 12, 
																	 '_anno, ''-'', _mese + 1', 
																	 '_anno + 1, ''01'' '), 
																	 '-01 00:00:00')), 
																 IF(MONTH(I.Fine) = _mese AND YEAR(I.fine) = _anno, 
																	IF(MONTH(CURRENT_DATE) = _mese AND YEAR(CURRENT_DATE) = _anno,
																	   CURRENT_TIMESTAMP(),
                                                                       I.Fine),
																	   CONCAT(IF(_mese <> 12, 
																		         '_anno, ''-'', _mese + 1', 
																				 '_anno + 1, ''01'' '), 
																				 '-01 00:00:00'))) as Fine
								   FROM ImpostazioneLuce I
								   WHERE MONTH(I.Inizio) = _mese AND
										 YEAR(I.Inizio) = _anno ),
		 Consumi_impostazioni AS (SELECT II.ElementoLuce, EL.Stanza, (TIMESTAMPDIFF(MINUTE, II.Inizio, II.Fine) / 60 * EL.Potenza) as Consumo
								  FROM Intervalli_Illuminazioni II INNER JOIN ElementoLuce EL ON II.ElementoLuce = EL.ID)
		 SELECT S.ID, IF(CI.Stanza IS NULL, 0.000, ROUND(SUM(CI.Consumo), 3)) as Consumo_Mensile_kW
         FROM Consumi_impostazioni CI RIGHT OUTER JOIN Stanza S ON CI.Stanza = S.ID
         GROUP BY S.ID;
		 
END $$
DELIMITER ;

-- ================================================================================ --
--                                   OPERAZIONE 6                                   --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS ConsumoCondizionatore;
DELIMITER $$
CREATE PROCEDURE ConsumoCondizionatore(IN _climatizzatore INT, IN _data DATE)
BEGIN
	DECLARE _inizio DATETIME;
    DECLARE _fine DATETIME;
    DECLARE _temperatura DOUBLE;
    DECLARE _potenza DOUBLE;
    DECLARE _stanza INT;
    DECLARE periodo_accensione INT DEFAULT 0;
    DECLARE periodo_parziale INT DEFAULT 0;
    
    DECLARE finito INT DEFAULT 0;
    DECLARE impostazioni_clima CURSOR FOR (SELECT Inizio, Fine, Temperatura
										   FROM ImpostazioneClima
                                           WHERE Climatizzatore = _climatizzatore AND
												 (DATE(Inizio) = _data OR DATE(Fine) = _data));
	DECLARE CONTINUE HANDLER FOR NOT FOUND
		SET finito = 1;
        
	IF _data > CURRENT_DATE THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La data non può essere maggiore di quella odierna.';
	ELSEIF NOT EXISTS (SELECT *
					   FROM Climatizzatore
                       WHERE ID = _climatizzatore) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Il codice climatizzatore inserito non è valido.';
	END IF;
    
    SELECT Stanza, Potenza INTO _stanza, _potenza
	FROM Climatizzatore
    WHERE ID = _climatizzatore;
    
	OPEN impostazioni_clima;
    loop_label: LOOP
    
		FETCH impostazioni_clima INTO _inizio, _fine, _temperatura;
		IF finito = 1 THEN
			LEAVE loop_label;
		END IF;
		
        IF _data = CURRENT_DATE AND ( _fine IS NULL OR _fine > CURRENT_TIMESTAMP) THEN
			SET _fine = CURRENT_TIMESTAMP;
		ELSEIF _fine IS NULL OR DATE(_fine) > _data THEN
			SET _fine = CONCAT(_data + INTERVAL 1 DAY, ' 00:00:00');
        END IF;
        
        IF DATE(_inizio) < _data THEN
			SET _inizio = CONCAT(_data, ' 00:00:00');
		END IF;
        
        SET periodo_parziale = (
        WITH Temperature_data AS (SELECT Istante, Temperatura, LEAD(Istante) OVER (ORDER BY Istante) as Successivo
								  FROM TemperaturaInterna
                                  WHERE Stanza = _stanza AND 
										DATE(Istante) = _data),
			 Temperature_target AS (SELECT IF(Istante < _inizio, _inizio, Istante) as a, IF(Successivo IS NULL OR Successivo > _fine, _fine, Successivo) as b
									FROM Temperature_data
                                    WHERE Istante < _fine AND
										  (Istante >= _inizio OR (Istante < _inizio AND (Successivo IS NULL OR Successivo > _inizio))) AND
                                          Temperatura <> _temperatura)
		SELECT SUM(TIMESTAMPDIFF(SECOND, a, b))
        FROM  Temperature_target);
        
        SET periodo_accensione = periodo_accensione + IF(periodo_parziale IS NOT NULL, periodo_parziale, 0);
        
    END LOOP;
    CLOSE impostazioni_clima;
    
    SELECT ROUND(periodo_accensione / 3600 * _potenza, 3) as Consumo_kW;
    
END $$
DELIMITER ;

-- ================================================================================ --
--                                   OPERAZIONE 7                                   --
-- ================================================================================ --
DROP TRIGGER IF EXISTS RefreshProduzioneIrraggiamentoPannelli;
CREATE TRIGGER RefreshProduzioneIrraggiamentoPannelli
AFTER INSERT ON Irraggiamento
FOR EACH ROW
	UPDATE PannelloFotovoltaico
    SET ProduzioneGiornaliera = ROUND(ProduzioneGiornaliera + IrraggiamentoAttuale * MaxPotenzaProd / 3, 3),
		IrraggiamentoAttuale = NEW.Percentuale;

DROP EVENT IF EXISTS FlushProduzionePannelli;
CREATE EVENT FlushProduzionePannelli
ON SCHEDULE EVERY 1 DAY
STARTS '2022-01-01 00:00:00'
DO
	UPDATE PannelloFotovoltaico
    SET ProduzioneGiornaliera = 0;

DROP PROCEDURE IF EXISTS ProduzionePannelli;
CREATE PROCEDURE ProduzionePannelli()
    SELECT ID, ProduzioneGiornaliera
    FROM PannelloFotovoltaico;

-- ================================================================================ --
--                                   OPERAZIONE 8                                   --
-- ================================================================================ --
DROP PROCEDURE IF EXISTS CreaEventoStato;
DELIMITER $$
CREATE PROCEDURE CreaEventoStato(IN _elemento VARCHAR(15), IN _id INT, IN _inizio DATETIME, IN _stato VARCHAR(3))
BEGIN

	SET @event_state = CONCAT(' DROP EVENT IF EXISTS ', _elemento, '_', _inizio, '_', _stato, ';',
							  ' CREATE EVENT ', _elemento,'_', _inizio, '_', _stato,
                              ' ON SCHEDULE AT ', _inizio, ' DO ',
							  '		UPDATE ', _elemento,
							  '		SET Stato = ''', _stato, '''',
							  ' 	WHERE ID = NEW.', _id, ';');
	PREPARE sql_statement FROM @event_state;
    EXECUTE sql_statement;
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS SetStatoLuceDef;		
DELIMITER $$
CREATE TRIGGER SetStatoLuceDef
AFTER INSERT ON ImpostazioneLuce
FOR EACH ROW
BEGIN
	
    IF NEW.Inizio <= CURRENT_TIMESTAMP THEN
		UPDATE ElementoLuce
        SET Stato = 'ON'
        WHERE ID = NEW.ElementoLuce;
	ELSEIF NEW.Inizio > CURRENT_TIMESTAMP THEN
		CALL CreaEventoStato('ElementoLuce', NEW.ElementoLuce, NEW.Inizio, 'ON');
	END IF;
    
    IF NEW.Fine IS NOT NULL AND NEW.Fine <= CURRENT_TIMESTAMP THEN
		UPDATE ElementoLuce
        SET Stato = 'OFF'
        WHERE ID = NEW.ElementoLuce;
	ELSEIF NEW.Fine IS NOT NULL AND NEW.Fine > CURRENT_TIMESTAMP THEN
		CALL CreaEventoStato('ElementoLuce', NEW.ElementoLuce, NEW.Fine, 'OFF');
	END IF;
    
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS SetStatoLuceIndef;		
DELIMITER $$
CREATE TRIGGER SetStatoLuceIndef
BEFORE UPDATE ON ImpostazioneLuce
FOR EACH ROW
BEGIN
	
    IF NEW.TempColore <> OLD.TempColore OR 
       NEW.Intensità <> OLD.Intensità OR 
       OLD.Fine IS NOT NULL OR 
       NEW.Fine IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Non è possibile modificare le impostazioni con tali valori.';
	ELSEIF NEW.Fine <= CURRENT_TIMESTAMP THEN
		UPDATE ElementoLuce
        SET Stato = 'OFF'
        WHERE ID = NEW.ElementoLuce;
	ELSEIF NEW.Fine > CURRENT_TIMESTAMP THEN
		CALL CreaEventoStato('ElementoLuce', NEW.ElementoLuce, NEW.Fine, 'OFF');
	END IF;
    
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS SetStatoDispositivoDef;		
DELIMITER $$
CREATE TRIGGER SetStatoDispositivoDef
AFTER INSERT ON Interazione
FOR EACH ROW
BEGIN
	
    IF NEW.Inizio <= CURRENT_TIMESTAMP THEN
		UPDATE Dispositivo
        SET Stato = 'ON'
        WHERE ID = NEW.Dispositivo;
	ELSEIF NEW.Inizio > CURRENT_TIMESTAMP THEN
		CALL CreaEventoStato('Dispositivo', NEW.Dispositivo, NEW.Inizio, 'ON');
	END IF;
    
    IF NEW.Fine IS NOT NULL AND NEW.Fine <= CURRENT_TIMESTAMP THEN
		UPDATE Dispositivo
        SET Stato = 'OFF'
        WHERE ID = NEW.Dispositivo;
	ELSEIF NEW.Fine IS NOT NULL AND NEW.Fine > CURRENT_TIMESTAMP THEN
		CALL CreaEventoStato('Dispositivo', NEW.Dispositivo, NEW.Fine, 'OFF');
	END IF;
    
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS SetStatoDispositivoIndef;		
DELIMITER $$
CREATE TRIGGER SetStatoDispositivoIndef
BEFORE UPDATE ON Interazione
FOR EACH ROW
BEGIN
	
    IF OLD.Fine IS NOT NULL OR 
       NEW.Fine IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Non è possibile modificare le impostazioni con tali valori.';
	ELSEIF NEW.Fine <= CURRENT_TIMESTAMP THEN
		UPDATE Dispositivo
        SET Stato = 'OFF'
        WHERE ID = NEW.Dispositivo;
	ELSEIF NEW.Fine > CURRENT_TIMESTAMP THEN
		CALL CreaEventoStato('Dispositivo', NEW.Dispositivo, NEW.Fine, 'OFF');
	END IF;
    
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS SetStatoClimatizzatoreDef;		
DELIMITER $$
CREATE TRIGGER SetStatoClimatizzatoreDef
AFTER INSERT ON ImpostazioneClima
FOR EACH ROW
BEGIN
	
    IF NEW.Inizio <= CURRENT_TIMESTAMP THEN
		UPDATE Climatizzatore
        SET Stato = 'ON'
        WHERE ID = NEW.Climatizzatore;
	ELSEIF NEW.Inizio > CURRENT_TIMESTAMP THEN
		CALL CreaEventoStato('Climatizzatore', NEW.Climatizzatore, NEW.Inizio, 'ON');
	END IF;
    
    IF NEW.Fine IS NOT NULL AND NEW.Fine <= CURRENT_TIMESTAMP THEN
		UPDATE Climatizzatore
        SET Stato = 'OFF'
        WHERE ID = NEW.Climatizzatore;
	ELSEIF NEW.Fine IS NOT NULL AND NEW.Fine > CURRENT_TIMESTAMP THEN
		CALL CreaEventoStato('Climatizzatore', NEW.Climatizzatore, NEW.Fine, 'OFF');
	END IF;
    
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS SetStatoClimatizzatoreIndef;		
DELIMITER $$
CREATE TRIGGER SetStatoClimatizzatoreIndef
BEFORE UPDATE ON ImpostazioneClima
FOR EACH ROW
BEGIN
	
    IF NEW.Temperatura <> OLD.Temperatura OR 
       OLD.Fine IS NOT NULL OR 
       NEW.Fine IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Non è possibile modificare le impostazioni con tali valori.';
	ELSEIF NEW.Fine <= CURRENT_TIMESTAMP THEN
		UPDATE Climatizzatore
        SET Stato = 'OFF'
        WHERE ID = NEW.Climatizzatore;
	ELSEIF NEW.Fine > CURRENT_TIMESTAMP THEN
		CALL CreaEventoStato('Climatizzatore', NEW.Climatizzatore, NEW.Fine, 'OFF');
	END IF;
    
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS ElementiAccesi;
DELIMITER $$
CREATE PROCEDURE ElementiAccesi()
BEGIN
	
    SELECT ID, Stato
    FROM Dispositivo
    WHERE Stato = 'ON';
    
    SELECT ID, Stato
    FROM Climatizzatore
    WHERE Stato = 'ON';
    
    SELECT ID, Stato
    FROM ElementoLuce
    WHERE Stato = 'ON';
    
END $$
DELIMITER ;