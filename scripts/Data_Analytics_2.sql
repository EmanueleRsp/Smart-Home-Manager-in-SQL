USE smart_home;
SET SQL_SAFE_UPDATES = 0;

-- ================================= --
-- 		VARIABILI DI SUPPORTO 	     --
-- ================================= --
-- Utilizzo la variabile @tempo in sostituzione di 
-- CURRENT_TIME() + INTERVAL 1 HOUR per la creazione del suggerimento
SET @tempo = '2022-01-01 06:00:00';

-- Valore per definire l'intervallo 
-- [potenza_ultima_rilevazione - variance ; potenza_ultima_rilevazione + variance]
SET @variance = 50;

-- Tempo massimo di risposta per un suggerimento.
SET @response_time_limit = 60;

-- Utilizzo la variabile @tempo_risposta in sostituzione di 
-- CURRENT_TIME() per il tempo di risposta al suggerimento.
-- Per un corretto funzionamento impostare 
-- @tempo_risposta >= @tempo - INTERVAL 1 HOUR (a cui equivalrebbe CURRENT_TIME())
SET @tempo_risposta = @tempo - INTERVAL 10 MINUTE;

-- Minuti per definire l'intervallo [TIME(@tempo) - @span, TIME(@tempo) + @span]
SET @span = 45;

-- ==================================================== --
-- 		PROCEDURA Ottimizzazione_consumi(tempo)			--
-- ==================================================== --
DROP PROCEDURE IF EXISTS Ottimizzazione_consumi;
delimiter $$
CREATE PROCEDURE Ottimizzazione_consumi()
BEGIN
	DECLARE potenza_dispositivi_attivi DOUBLE DEFAULT 0;
	DECLARE potenza_climatizzatori_attivi DOUBLE DEFAULT 0;
	DECLARE potenza_luci_attive DOUBLE DEFAULT 0;
	DECLARE potenza_attivi DOUBLE DEFAULT 0;
    
	DECLARE potenza_ultima_rilevazione DOUBLE DEFAULT 0;
	DECLARE potenza_prodotta_prevista DOUBLE DEFAULT 0;
    
	DECLARE energia_disponibile DOUBLE DEFAULT 0;

	DECLARE dispositivo_programma INT DEFAULT NULL;
	DECLARE potenza_programma DOUBLE DEFAULT NULL;
    DECLARE durata_programma INT DEFAULT NULL;
	DECLARE codr_programma INT;
    
	-- Calcolo potenza_dispositivi_attivi
	 WITH Interazioni_attive AS (
		 SELECT * 
		 FROM Interazione 
         WHERE @tempo BETWEEN Inizio AND IFNULL(Fine, NOW())
	),
	consumi_attivi AS (
		 SELECT l.Potenza AS ConsumoLivello,
				p.Potenza AS ConsumoProgramma
		 FROM 	Interazioni_attive i
				LEFT OUTER JOIN 
				Livello l USING(Dispositivo, CodR)
				LEFT OUTER JOIN 
				Programma p USING(Dispositivo, CodR)
				LEFT OUTER JOIN 
				Dispositivo d ON i.Dispositivo = d.ID
	)
	SELECT IFNULL(SUM(ConsumoLivello),0) + IFNULL(SUM(ConsumoProgramma),0)
	FROM consumi_attivi
	INTO potenza_dispositivi_attivi;
	-- DEBUG: select potenza_dispositivi_attivi;
    
	-- Calcolo potenza_climatizzatori_attivi
	SELECT IFNULL(SUM(c.Potenza),0) 
	FROM 	ImpostazioneClima ic
			INNER JOIN 
			Climatizzatore c ON ic.Climatizzatore = c.ID
	WHERE @tempo  BETWEEN Inizio AND ifnull(Fine,now())
	INTO potenza_climatizzatori_attivi;
	
    -- Calcolo potenza_luci_attive
	SELECT IFNULL(SUM(el.Potenza),0)
    FROM ElementoLuce el
		 INNER JOIN 
		 ImpostazioneLuce il ON (el.ID = il.ElementoLuce)
    WHERE @tempo  BETWEEN Inizio AND ifnull(Fine,now())
    INTO potenza_luci_attive;
	
	-- Calcolo potenza_attivi
    SET potenza_attivi = potenza_dispositivi_attivi + potenza_climatizzatori_attivi + potenza_luci_attive;

	-- Calcolo potenza_ultima_rilevazione
    WITH massimo AS (SELECT PannelloFotovoltaico as ID, max(Istante) as massimo
					  FROM Irraggiamento
					  WHERE Istante <= @tempo
                      GROUP BY PannelloFotovoltaico) 
     SELECT SUM(Percentuale * MaxPotenzaProd / 100) 
	 FROM Irraggiamento i
		 INNER JOIN 
		 PannelloFotovoltaico pf ON i.PannelloFotovoltaico = pf.ID
	 WHERE i.Istante = ( SELECT m.massimo
						 FROM massimo m
						 WHERE m.ID = pf.ID)
	INTO potenza_ultima_rilevazione;

	-- Calcolo potenza_prodotta_prevista:
    -- Le CTE giorni_target 1, 2 e 3 sono utilizzate per trovare i giorni di irraggiamento simile,
    -- il resto per trovare l'irraggiamento richiesto e calcolarne la media
	 WITH giorni_target_1 AS (
		SELECT DATE(Istante) AS Giorno, PannelloFotovoltaico AS ID, MAX(Istante) AS Ultimo_istante
        FROM Irraggiamento
        WHERE Istante BETWEEN @tempo - INTERVAL 1 MONTH AND @tempo AND
			  TIME(Istante) <= TIME(@tempo)
		GROUP BY DATE(Istante), PannelloFotovoltaico
     ),
     giorni_target_2 AS (
		SELECT Giorno, SUM(I.Percentuale * PF.MaxPotenzaProd / 100) AS Produzione
        FROM giorni_target_1 G1 INNER JOIN Irraggiamento I ON (G1.Ultimo_istante = I.Istante AND G1.ID = I.PannelloFotovoltaico)
			 INNER JOIN PannelloFotovoltaico PF ON (G1.ID = PF.ID)
        GROUP BY Giorno
	),
    giorni_target_3 AS (
		SELECT Giorno
        FROM giorni_target_2
        WHERE Produzione BETWEEN (potenza_ultima_rilevazione - @variance) AND (potenza_ultima_rilevazione + @variance)
	),
     irraggiamenti_target AS (
		 SELECT DATE(i.Istante) AS Giorno,
				TIME(i.Istante) AS Ora,
				i.Percentuale * pf.MaxPotenzaProd / 100 AS Irraggiamento
		 FROM 	Irraggiamento i
				INNER JOIN 
				PannelloFotovoltaico pf ON i.PannelloFotovoltaico = pf.ID
		 WHERE 	i.Istante BETWEEN @tempo - INTERVAL 1 MONTH AND @tempo 
			  	AND HOUR(i.Istante) BETWEEN HOUR(@tempo) AND HOUR(@tempo) + 2 
                AND DATE(i.Istante) IN (SELECT *
									    FROM giorni_target_3)
                
	),
	potenza_produzione_target AS (
		SELECT Giorno, Ora, SUM(Irraggiamento) as Produzione_oraria
		FROM   irraggiamenti_target
		GROUP BY Giorno, Ora
	), 
    media_giorni_target AS (
		SELECT Giorno, AVG(Produzione_oraria) as MediaIrraggiamento
        FROM potenza_produzione_target
        GROUP BY Giorno
    )
	SELECT AVG(MediaIrraggiamento)
	FROM media_giorni_target
	INTO potenza_prodotta_prevista;

	 /* -- DEBUG: valori di output
	 SELECT potenza_dispositivi_attivi,
			potenza_climatizzatori_attivi,
			potenza_luci_attive,
			potenza_attivi,
			potenza_ultima_rilevazione,
			potenza_prodotta_prevista; */

	-- Verifica possibilità di creare suggerimento
	IF (potenza_prodotta_prevista >= potenza_ultima_rilevazione) 
		AND (potenza_ultima_rilevazione >= potenza_attivi) THEN
        
		-- Se le condizioni sono soddisfatte si procede con la creazione del suggerimento.
		SET energia_disponibile = (potenza_prodotta_prevista * 3 + potenza_ultima_rilevazione / 3 - potenza_attivi * 3);
		-- DEBUG:
        -- select energia_disponibile;
                
		-- Ricerca del programma basandosi sulla frequenza in cui questo viene avviato nell'intervallo
        -- [TIME(@tempo) - @span, TIME(@tempo) + @span] e sulla sua potenza, verificando che il relativo
        -- dispositivo non sia già attualmente in funzione.
		WITH frequenza AS (
			SELECT Dispositivo, COUNT(*) as Frequenza
            FROM Interazione
            WHERE Inizio BETWEEN 
				  (@tempo - INTERVAL 1 MONTH - INTERVAL @span MINUTE) 
                  AND @tempo 
                  AND TIME(Inizio) BETWEEN 
                  (TIME(@tempo) - INTERVAL @span MINUTE) 
                  AND (TIME(@tempo) + INTERVAL @span MINUTE )
            GROUP BY Dispositivo
        ),
        ranking AS (
			SELECT D.ID, RANK() over (ORDER BY IFNULL(F.Frequenza, 0)) as Ranking
            FROM frequenza F RIGHT OUTER JOIN Dispositivo D ON (F.Dispositivo = D.ID)
            WHERE D.TipoConsumo = 'Non interrompibile'
		)
        SELECT 	p.Dispositivo,
		 		p.CodR,
				p.Potenza, 
				p.Durata 
		FROM 	Programma p INNER JOIN ranking R ON p.Dispositivo = R.ID
        WHERE p.Potenza <= energia_disponibile / p.Durata * 60 AND
			  NOT EXISTS (SELECT *
						  FROM Interazione I
                          WHERE I.Dispositivo = p.Dispositivo AND I.CodR = p.CodR AND
								I.Inizio <= @tempo AND (I.Fine IS NULL OR I.Fine > @tempo))
		ORDER BY R.Ranking, (p.Potenza * p.Durata / 60) DESC
		LIMIT 1
		INTO 	dispositivo_programma,
				codr_programma,
				potenza_programma, 
				durata_programma;
        
        /* -- DEBUG: Programma selezionato
        select dispositivo_programma,
				codr_programma,
				potenza_programma, 
				durata_programma; */
        
		-- Se l'energia disponibile è maggiore o uguale del consumo del programma da attivare: invio di un suggerimento all'app */
		IF  dispositivo_programma IS NOT NULL THEN 
			INSERT IGNORE INTO Suggerimento (Dispositivo, CodR, Istante)
			VALUES (dispositivo_programma, codr_programma, @tempo); 
		END IF;
        
	 /* -- DEBUG: valori di output per suggerimenti creati
	 SELECT potenza_dispositivi_attivi,
			potenza_climatizzatori_attivi,
			potenza_luci_attive,
			potenza_attivi,
			potenza_ultima_rilevazione,
			potenza_prodotta_prevista,
            energia_disponibile; */
	END IF;
 
END $$
delimiter ;

-- ============================ --
-- 		TEST DATA_ANALYTICS		--
-- ============================ --
-- Svuoto la tabella Suggerimento:
TRUNCATE TABLE Suggerimento;

 -- Test di chiamata su tutto il mese popolato.
DROP PROCEDURE IF EXISTS test;
DELIMITER $$
CREATE PROCEDURE test(IN _fine DATETIME)
BEGIN
    
	loop_label: LOOP
		IF @tempo >= _fine THEN
			LEAVE loop_label;
		END IF;
        
		CALL Ottimizzazione_consumi();
        
        SET @tempo = @tempo + INTERVAL 1 HOUR + INTERVAL 30 MINUTE;
	END LOOP;
    
END $$
DELIMITER ;

SET @tempo = '2022-01-01 06:00:00'; 
CALL test('2022-01-15 00:00:00'); 
CALL test('2022-01-31 23:59:59'); 

/* -- Test di chiamata singola su uno specifico istante.
SET @tempo = '2022-01-15 09:00:00';
CALL Ottimizzazione_consumi(); */

-- Visione della tabella Suggerimento con i risultati della data analytics
TABLE Suggerimento;

-- ======================================================== --
-- 		TRIGGER DI GESTIONE RISPOSTE AI SUGGERIMENTI		--
-- ======================================================== --
DROP TRIGGER IF EXISTS Gestione_suggerimenti;
DELIMITER $$
CREATE TRIGGER Gestione_suggerimenti
BEFORE UPDATE ON Suggerimento
FOR EACH ROW
BEGIN
	DECLARE Inserimento DATETIME;
	DECLARE Durata INT;
	
    IF TIMESTAMPDIFF(MINUTE, NEW.Istante, @tempo_risposta) > 0 THEN
		SET Inserimento = @tempo_risposta;
	ELSE
		SET Inserimento = NEW.Istante;
	END IF;
    
	IF NEW.Dispositivo IS NULL OR
	   NEW.CodR IS NULL OR
       NEW.Istante IS NULL OR
       OLD.Account IS NOT NULL OR
       OLD.Risposta IS NOT NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Al suggerimento è già stata data risposta.';
        
	ELSEIF NEW.Risposta IS NULL OR
			NEW.Account IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inserire risposta e account con il quale viene data.';
	
    ELSEIF TIMESTAMPDIFF(MINUTE, NEW.Istante, @tempo_risposta) > 60 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'E''possibile rispondere al suggerimento solo entro un''ora dal momento per cui il suggerimento è stato creato.';
        
	ELSEIF NEW.Risposta = 'SI' AND
		   EXISTS (SELECT *
				   FROM Interazione
                   WHERE Dispositivo = NEW.Dispositivo AND
						 Inizio <= Inserimento AND
                         (Fine IS NULL OR Fine > Inserimento)) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Non è possibile avviare il programma poiché il dispositivo è già in funzione.';
	END IF;
    
    SELECT Durata INTO Durata
    FROM Programma
    WHERE Dispositivo = NEW.Dispositivo AND
		  CodR = NEW.CodR;
    
    IF NEW.Risposta = 'SI' THEN
		INSERT INTO Interazione
        VALUES (NEW.Dispositivo, NEW.CodR, Inserimento, Inserimento + INTERVAL Durata MINUTE, NEW.Account);
    END IF;
    
END $$
DELIMITER ;

-- ==================================== --
-- 		TEST RISPOSTA SUGGERIMENTO		--
-- ==================================== --
/* SET @tempo = '2022-01-15 09:00:00'; -- Significa che il suggerimento è stato generato alle 08:00:00
SET @tempo_risposta = @tempo - INTERVAL 10 MINUTE; -- Impostare a seconda di quando si vuol dare la risposta

UPDATE Suggerimento
SET Account = 'Scotti01', Risposta = 'NO'
WHERE Dispositivo = 17 AND CodR = 5 AND Istante = '2022-01-15 09:00:00';

TABLE Suggerimento; */