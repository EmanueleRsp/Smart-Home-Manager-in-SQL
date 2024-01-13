USE smart_home;
SET SESSION max_execution_time = 10000;
SET SQL_SAFE_UPDATES = 0;
-- ================================================================================ --
--                             Domande di sicurezza                                 --
-- ================================================================================ --       
INSERT INTO DomandaSicurezza (Testo)
VALUES ('Il nome del tuo primo ragazzo/a?'),
	   ('La tua squadra del cuore?'),
       ('Il nome del tuo professore di matematica alle superiori?'),
       ('Il nome del tuo primo animale?'),
       ('Qual era il cognome da nubile di tua madre?'),
       ('Qual era il nome della scuola elementare?'),
       ('La tua città preferita?'),
       ('Il tuo primo lavoro svolto?'),
       ('Qual è il tuo libro per bambini preferito?'),
       ('Qual è il tuo colore preferito?'),
       ('Il tuo migliore amico delle medie?');

-- ================================================================================ --
--                          Documento, utente e account                             --
-- ================================================================================ --       
INSERT INTO Documento (Tipologia, NumeroDocumento, Scadenza, EnteRilascio)
VALUES	('Carta identità', '123456', '2022-08-08', 'Comune di Roma'),
        ('Carta identità', '654321', '2022-08-08', 'Comune di Lignano'),
        ('Patente', '585786', '2022-08-08', 'Motorizzazione di Livorno'),
        ('Passaporto', '258147', '2023-03-15', 'Questura di Milano'),
        ('Patente', '258507', '2023-01-01', 'Motorizzazione di Livorno');
        
INSERT INTO Utente (CodiceFiscale, Nome, Cognome, DataNascita, DataIscrizione, NumTelefono, TipologiaDocumento, NumeroDocumento)
VALUES	('SCTLCA02H64H501V', 'Vittorio', 'Scotti', '2001-03-11', '2021-06-11', '+39 366 345 2333', 'Carta identità', '123456'),
		('SCVHCA06H64H501V', 'Marco', 'Rossi', '1976-04-15', '2021-06-09', '+39 366 345 2231', 'Carta identità' , '654321'),
        ('SGGLCA02901H54CF', 'Francesco', 'Rossi', '1990-01-15', '2021-07-01', '+39 331 345 2563', 'Patente' , '585786'),
        ('NNPV2A02H64H5EFF', 'Anna', 'Rossi', '2001-03-11', '2021-09-11', '+39 342 155 2133', 'Passaporto', '258147'),
        ('LCPNCA045HPI501V', 'Lucia', 'Pina', '1970-09-20', '2021-05-23', '+39 368 841 3212', 'Patente', '258507');

INSERT INTO Account (NomeUtente, Password, DomandaSicurezza, RispostaSicurezza, Utente)
VALUES	('Scotti01', 'buonasera!', 1, 'Ludovica','SCTLCA02H64H501V' ),
		('Markus', '15041976', 3, 'Rossi', 'SCVHCA06H64H501V'),
        ('Kekko', '15011990', 1, 'Lucia', 'SGGLCA02901H54CF'),
        ('AnnA_', 'password', 4, 'Bob', 'NNPV2A02H64H5EFF'),
        ('Lucy70', 'NonSoCosaMettere', 2, 'Juventus', 'LCPNCA045HPI501V');
        
-- ================================================================================ --
--                                Stanza e Accesso                                  --
-- ================================================================================ --       
INSERT INTO Stanza (Nome, Piano, Larghezza, Lunghezza, Altezza)
VALUES ('Salotto', 0, 7, 4, 2.5),
	   ('Cucina', 0, 4, 3, 2.5),
       ('Camera', 1, 4, 3, 2.5),
       ('Camera', 1, 3, 2, 2.5),
	   ('Bagno', 0, 5.5, 4, 2.5),
       ('Corridoio', 1, 5.5, 4, 2.5),
       ('Terrazzo', 1, 5.5, 4, null),
	   ('Corridoio', 0, 5, 3, 2.5);
       
INSERT INTO Accesso (Tipologia, Orientamento, Verso1, Verso2)
VALUES ('Porta', 'S', 1, null),
	   ('Porta', 'S', 1, 8),
       ('Porta', 'S', 1, 2),
       ('Porta', 'E', 8, 5),
       ('Porta', 'O', 8, 2),
       ('Finestra', 'E', 1, null),
	   ('Finestra', 'O', 1, null),
       ('Finestra', 'O', 2, null),
       ('Finestra', 'S', 5, null),
       ('Porta', 'N', 6, 3),
       ('Porta', 'E', 6, 4),
       ('Portafinestra', 'N', 3, 7),
       ('Portafinestra', 'E', 4, 7),
	   ('Finestra', 'O', 3, null),
       ('Finestra', 'E', 4, null);

-- ================================================================================ --
--                            Smart Plug e Dispositivo                              --
-- ================================================================================ --            
INSERT INTO SmartPlug (Stanza)
VALUES (1), (2), (3), (4), (1),
	   (3), (5), (2), (6), (5),
	   (5), (2), (2), (8), (8), 
       (2), (2), (7), (1), (6);
       
INSERT INTO Dispositivo (Nome, TipoConsumo, SmartPlug)
VALUES ('Televisore', 'Fisso', 1),
	   ('Televisore', 'Fisso', 2),
	   ('Televisore', 'Fisso', 3),
	   ('Televisore', 'Fisso', 4),
	   ('Computer', 'Fisso', 6),
       ('Frigorifero', 'Fisso', 8),
       ('Telefono', 'Fisso', 14),
       ('Macchina caffè', 'Fisso', 13),
       ('Ventilatore', 'Variabile', 5),
       ('Asciugacapelli', 'Variabile', 7),
       ('Stufa', 'Variabile', 9),
       ('Aspirapolvere', 'Variabile', 15),
       ('Forno', 'Variabile', 16),
       ('Microonde', 'Variabile', 17),
	   ('Asciugatrice', 'Non interrompibile', 10),
       ('Lavatrice', 'Non interrompibile', 11),
	   ('Lavastoviglie', 'Non interrompibile', 12);


-- ================================================================================ --
--                        Regolazione, Livello e Programma                          --
-- ================================================================================ --            
INSERT INTO Regolazione (Dispositivo, CodR)
VALUES (1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1), (7, 1), (8, 1),
	   (9, 1), (9, 2), (9, 3), (9, 4),
	   (10, 1), (10, 2),
	   (11, 1), (11, 2), (11, 3),
	   (12, 1), (12, 2), (12, 3),
	   (13, 1), (13, 2), (13, 3),
	   (14, 1), (14, 2),
	   (15, 1), (15, 2), (15, 3), 
       (16, 1), (16, 2), (16, 3), (16, 4),
       (17, 1), (17, 2), (17, 3), (17, 4), (17, 5);
       
INSERT INTO Livello (Dispositivo, CodR, Livello, Potenza)
VALUES (1, 1, null, 0.300), 
	   (2, 1, null, 0.200), 
       (3, 1, null, 0.090), 
       (4, 1, null, 0.150), 
       (5, 1, null, 0.150), 
       (6, 1, null, 0.250), 
       (7, 1, null, 0.010), 
       (8, 1, null, 1.250),
	   (9, 1, 'Piano', 0.020), (9, 2, 'Moderato', 0.035), (9, 3, 'Forte', 0.050), (9, 4, 'Vento siberiano', 0.070),
	   (10, 1, 'Cold', 1.200), (10, 2, 'Hot', 1.500), 
	   (11, 1, 'Una piastra', 0.700), (11, 2, 'Due piastre', 1.000), (10, 3, 'Tre piastre', 1.300),
	   (12, 1, 'Tappeti', 1.200), (12, 2, 'Regular', 2.000),
	   (13, 1, 'Ventilato', 1.000), (13, 2, 'Pizza', 2.300), (13, 3, 'Grill', 2.800),
	   (14, 1, 'Heat', 0.450), (14, 2, 'Cook', 0.600);

INSERT INTO Programma (Dispositivo, CodR, Nome, Durata, Potenza)
VALUES (15, 1, 'Cotone', 40, 2.000), (15, 2, 'Sintetici', 30, 2.100), (15, 3, 'ECO', 70, 0.900),
       (16, 1, 'Normale', 45, 2.000), (16, 2, 'Prelavaggio', 15, 1.800), (16, 3, 'Delicati', 50, 2.100), (16, 4, '90 gradi', 50, 2.500),
       (17, 1, 'Normale', 80, 1.800), (17, 2, 'Cristalli', 80, 2.300), (17, 3, 'Breve', 30, 1.700), (17, 4, 'ECO', 90, 1.200),  (17, 5, 'Intensivo', 80, 2.500);

-- ================================================================================ --
--                                  Interazione                                     --
-- ================================================================================ --          
DROP PROCEDURE IF EXISTS popolamento_RegistroInterazioni;
DELIMITER $$
CREATE PROCEDURE popolamento_RegistroInterazioni(IN _inizio DATETIME, IN _fine DATETIME)
BEGIN
	DECLARE dispositivo INT;
    DECLARE tipo VARCHAR(18);
    DECLARE tempo DATETIME;
    DECLARE num_regolazioni INT;
    DECLARE regolazione INT;
    DECLARE rand_username VARCHAR(20);
    DECLARE fine DATETIME;
    
	DECLARE finito INT DEFAULT 0;
	DECLARE cursore_disp CURSOR FOR (SELECT D.ID, D.TipoConsumo
									 FROM Dispositivo D);
	DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET finito = 1;
    
    OPEN cursore_disp;
    loop_label: LOOP
		FETCH cursore_disp INTO dispositivo, tipo;
		IF finito = 1 THEN
			LEAVE loop_label;
		END IF;

		SELECT COUNT(*) INTO num_regolazioni
        FROM Regolazione R
        WHERE R.Dispositivo = dispositivo;
	
        -- imposto il primo inizio alle 6 del mattino 
		SET tempo = CONCAT(DATE(_inizio), ' 06:00:00');
        
		-- per ogni dispositivo si popola da inizio a fine
		WHILE tempo <= _fine 
		DO	
			-- prendo un account a caso
			SELECT A.NomeUtente INTO rand_username
			FROM Account A
			ORDER BY RAND()
            LIMIT 1;
            
			-- imposto una fine random tra 10 e 60 minuti dopo l'inizio
			SET fine = tempo + INTERVAL (10 + RAND()*(60-10)) MINUTE;
					
			IF Tipo = 'Fisso' THEN
				INSERT INTO Interazione(Dispositivo, CodR, Inizio, Fine, Account)
				VALUES (dispositivo, 1, tempo, fine, rand_username);
                
			ELSEIF Tipo = 'Variabile' THEN 
				INSERT INTO Interazione(Dispositivo, CodR, Inizio, Fine, Account)
				VALUES (dispositivo, FLOOR(1+RAND()*(num_regolazioni+1)), tempo, fine, rand_username);
                
			ELSEIF Tipo = 'Non Interrompibile' THEN
				SELECT P.CodR, (tempo + INTERVAL (P.Durata) MINUTE) INTO regolazione, fine
                FROM Programma P
                WHERE P.Dispositivo = dispositivo
                ORDER BY RAND()
                LIMIT 1;
                
				INSERT INTO Interazione(Dispositivo, CodR, Inizio, Fine, Account)
				VALUES (dispositivo, regolazione, tempo, fine, rand_username);
			END IF;
			
            -- aggiornamento prossimo inizio
            IF DAY(tempo) < DAY(fine) THEN
				SET tempo = CONCAT(DATE(fine), ' 06:00:00');
			END IF;
			SET tempo = fine + INTERVAL RAND()*6 HOUR;
            IF DAY(tempo) > DAY(fine) THEN
				SET tempo = CONCAT(DATE(tempo), ' 06:00:00');
            END IF;
		END WHILE;
    END LOOP;
    CLOSE cursore_disp;
END $$
DELIMITER ;

-- Popolo gennaio 2022 ed elimino la stored procedure
CALL popolamento_RegistroInterazioni('2022-01-01 00:00:00', '2022-01-31 00:00:00');
DROP PROCEDURE popolamento_RegistroInterazioni;

-- ================================================================================ --
--               Pannello fotovoltaico, Fascia oraria e Irraggiamento               --
-- ================================================================================ --            
INSERT INTO PannelloFotovoltaico (MaxPotenzaProd)
VALUES (0.330),
	   (0.300),
	   (0.450),
	   (0.400),
	   (0.285),
	   (0.350),
	   (0.335),
	   (0.390),
	   (0.385),
	   (0.410),
	   (0.380),
	   (0.400);
       
INSERT INTO FasciaOraria (Inizio, UtilizzoEnergia, Prezzo, Account)
VALUES (7, 'IN', 0.32154, 'Markus'),
	   (13, 'OUT', 0.30856, 'Markus'),
	   (23, 'IN', 0.27862, 'Kekko');

DROP PROCEDURE IF EXISTS popolamento_RegistroIrraggiamento;
DELIMITER $$
CREATE PROCEDURE popolamento_RegistroIrraggiamento(IN _inizio DATETIME, IN _fine DATETIME)
BEGIN
    DECLARE tempo DATETIME;
    DECLARE k DOUBLE;
    DECLARE pannello INT;
    DECLARE irraggiamento_distribuito DOUBLE;
    DECLARE deviazione_standard DOUBLE DEFAULT 3;
    DECLARE media DOUBLE DEFAULT 12;
    DECLARE ora_decimale DOUBLE;
    DECLARE fascia_oraria INT;
    DECLARE num INT;
    DECLARE i INT;
    
    SELECT COUNT(*) INTO num
    FROM pannellofotovoltaico;

    SET k = ROUND((100*(deviazione_standard*SQRT(2*PI()))), 2);

    SET tempo = _inizio;
	
    WHILE tempo <= _fine 
    DO	
		-- seleziono la fascia oraria
        IF HOUR(tempo) NOT BETWEEN (SELECT MIN(FO.Inizio)
									FROM FasciaOraria FO) AND
								   (SELECT MAX(FO.Inizio)
									FROM FasciaOraria FO) THEN
			SET fascia_oraria = (SELECT MAX(FO.Inizio)
							     FROM FasciaOraria FO);
		ELSE
			SELECT FO.Inizio INTO fascia_oraria
			FROM FasciaOraria FO
			WHERE HOUR(tempo) >= FO.Inizio AND 
				  HOUR(tempo) <	(SELECT MIN(F.Inizio)
								 FROM FasciaOraria F
                                 WHERE F.Inizio > FO.Inizio);
		END IF;
        
		SET ora_decimale = HOUR(tempo) + MINUTE(tempo) / 60;
		SET irraggiamento_distribuito = ROUND(((1/(deviazione_standard*SQRT(2*PI()))) * EXP(-(POW(ora_decimale-media, 2)/(2*POW(deviazione_standard, 2))))), 2);
		
        SET i = 1;
        WHILE i <= num DO
		INSERT INTO Irraggiamento(PannelloFotovoltaico, Istante, Percentuale, FasciaOraria)
		VALUES (i, tempo, 
				ROUND(k*irraggiamento_distribuito, 2), 
                fascia_oraria);
		SET i = i + 1;
        END WHILE;
        
		SET tempo = tempo + INTERVAL 20 MINUTE;
    END WHILE;
END $$
DELIMITER ;

-- Popolo gennaio 2022 ed elimino la stored procedure
CALL popolamento_RegistroIrraggiamento('2022-01-01 00:00:00', '2022-01-05 00:00:00');
CALL popolamento_RegistroIrraggiamento('2022-01-05 00:20:00', '2022-01-10 00:00:00');
CALL popolamento_RegistroIrraggiamento('2022-01-10 00:20:00', '2022-01-15 00:00:00');
CALL popolamento_RegistroIrraggiamento('2022-01-15 00:20:00', '2022-01-20 00:00:00');
CALL popolamento_RegistroIrraggiamento('2022-01-20 00:20:00', '2022-01-25 00:00:00');
CALL popolamento_RegistroIrraggiamento('2022-01-25 00:20:00', '2022-01-31 00:00:00');
DROP PROCEDURE popolamento_RegistroIrraggiamento;

-- ================================================================================ --
--                          Elementi e impostazioni luci                            --
-- ================================================================================ --            
INSERT INTO ElementoLuce (Potenza, MinIntensità, MinTempColore, MaxTempColore, Stanza)
VALUES (0.010, 100, 7000, 7000, 1),
	   (0.008, 100, 4000, 5000, 2),
	   (0.020, 1, 2600, 8000, 3),
	   (0.050, 1, 3200, 3200, 4),
	   (0.035, 50, 2900, 4500, 4),
	   (0.040, 70, 3000, 3000, 6),
	   (0.020, 85, 3800, 3800, 7),
	   (0.045, 10, 6700, 6700, 5),
	   (0.010, 100, 5000, 6200, 5),
	   (0.050, 100, 2700, 4000, 8);

DROP PROCEDURE IF EXISTS popolamento_ImpostazioniLuci;
DELIMITER $$
CREATE PROCEDURE popolamento_ImpostazioniLuci(_inizio DATETIME, _fine DATETIME)
BEGIN
    DECLARE tempo DATETIME;
    DECLARE fine DATETIME;
    DECLARE rand_impostazione INT;
	DECLARE luce INT;
    DECLARE intensità_min INT;
    DECLARE temp_min INT;
    DECLARE temp_max INT;
    
    DECLARE finito INT DEFAULT 0;
	DECLARE cursore_luci CURSOR FOR (SELECT EL.ID, EL.MinIntensità, EL.MinTempColore, EL.MaxTempColore
									 FROM ElementoLuce EL );
	DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET finito = 1;
    
    OPEN cursore_luci;
    loop_label: LOOP        
		FETCH cursore_luci INTO luce, intensità_min, temp_min, temp_max;
		IF finito = 1 THEN
			LEAVE loop_label;
		END IF;
        
	-- imposto il primo inizio alle 6 del mattino 
	SET tempo = CONCAT(DATE(_inizio), ' 06:00:00');
    
    WHILE tempo <= _fine 
	DO	
    
    -- imposto una fine random tra 20 e 120 minuti dopo l'inizio
			SET fine = tempo + INTERVAL (20 + RAND()*(120-20)) MINUTE;

			INSERT INTO ImpostazioneLuce (ElementoLuce, Inizio, Fine, TempColore, Intensità)
            VALUES (luce, tempo, fine, 
					FLOOR(RAND()*(temp_max-temp_min+1)+temp_min), 
                    FLOOR(RAND()*(100-intensità_min+1)+intensità_min));
			
            -- aggiornamento prossimo inizio
            IF DAY(tempo) < DAY(fine) THEN
				SET tempo = CONCAT(DATE(fine), ' 06:00:00');
			END IF;
			SET tempo = fine + INTERVAL RAND()*6 HOUR;
            IF DAY(tempo) > DAY(fine) THEN
				SET tempo = CONCAT(DATE(tempo), ' 06:00:00');
			END IF;
    END WHILE;
    END LOOP;
    CLOSE cursore_luci;
END $$
DELIMITER ;

-- Popolo gennaio 2022 ed elimino la stored procedure
CALL popolamento_ImpostazioniLuci('2022-01-01 00:00:00', '2022-01-31 00:00:00');
DROP PROCEDURE popolamento_ImpostazioniLuci;

-- ================================================================================ --
--                                  Predefinito                                     --
-- ================================================================================ --            
INSERT INTO Predefinito (TempColore, Intensità)
VALUES (4500, 70),
	   (3200, 100),
	   (7500, 60),
	   (5000, 35);

-- ================================================================================ --
--                       Climatizzatore e Impostazioni clima                        --
-- ================================================================================ --            
INSERT INTO Climatizzatore (Potenza, Stanza)
VALUES (1.000, 1),
	   (0.700, 2),
	   (0.850, 3),
	   (1.150, 4),
	   (0.600, 5),
	   (0.950, 8);
       
DROP PROCEDURE IF EXISTS popolamento_RegistroClima
DELIMITER $$
CREATE PROCEDURE popolamento_RegistroClima(_inizio DATETIME, _fine DATETIME)
BEGIN
	DECLARE climatizzatore INT;
    DECLARE tempo DATETIME;
    DECLARE rand_username VARCHAR(20);
    DECLARE fine DATETIME;
	DECLARE temperatura_max DOUBLE DEFAULT 21.5;
    DECLARE umidità_max INT DEFAULT 70;
	DECLARE temperatura_min DOUBLE DEFAULT 17.0;
    DECLARE umidità_min INT DEFAULT 40;
    
	DECLARE finito INT DEFAULT 0;
	DECLARE cursore_cond CURSOR FOR (SELECT C.ID
									 FROM Climatizzatore C);
	DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET finito = 1;
    
    OPEN cursore_cond;
    loop_label: LOOP
		FETCH cursore_cond INTO climatizzatore;
		IF finito = 1 THEN
			LEAVE loop_label;
		END IF;

		-- imposto il primo inizio alle 6 del mattino 
		SET tempo = CONCAT(DATE(_inizio), ' 06:00:00');
        
		-- Per ogni condizionatore, si popola da inizio a fine
		WHILE tempo <= _fine 
		DO	
			-- prendo un account a caso
			SELECT NomeUtente INTO rand_username
			FROM Account
			ORDER BY RAND()
            LIMIT 1;
            
			-- imposto una fine random tra 120 e 200 minuti dopo l'inizio
			SET fine = tempo + INTERVAL (120 + RAND()*(200-120)) MINUTE;
			INSERT INTO ImpostazioneClima (Climatizzatore, Inizio, Fine, Umidità, Temperatura, Account)
            VALUES (climatizzatore, tempo, fine, 
					ROUND((umidità_min + RAND()*(umidità_max-umidità_min)), 1), 
					ROUND((temperatura_min + RAND()*(temperatura_max-temperatura_min)), 1), 
                    rand_username);
			
            -- aggiornamento prossimo inizio
            IF DAY(tempo) < DAY(fine) THEN
				SET tempo = CONCAT(DATE(fine), ' 06:00:00');
			END IF;
			SET tempo = fine + INTERVAL (5+RAND()*(12-5)) HOUR;
            IF DAY(tempo) > DAY(fine) THEN
				SET tempo = CONCAT(DATE(tempo), ' 06:00:00');
            END IF;
		END WHILE;
    END LOOP;
    CLOSE cursore_cond;
END $$
DELIMITER ;

-- Popolo gennaio 2022 ed elimino la stored procedure
CALL popolamento_RegistroClima('2022-01-01 00:00:00', '2022-01-31 00:00:00');
DROP PROCEDURE popolamento_RegistroClima;

-- ================================================================================ --
--                              Temperatura Interna                                 --
-- ================================================================================ --   
truncate table TemperaturaInterna;         
DROP PROCEDURE IF EXISTS popolamento_TemperatureInterne;
DELIMITER $$
CREATE PROCEDURE popolamento_TemperatureInterne(_inizio DATETIME, _fine DATETIME)
BEGIN
    DECLARE tempo DATETIME;
    DECLARE temperatura DOUBLE;
    DECLARE ora_decimale DOUBLE;
    DECLARE stanza INT;
	DECLARE temperatura_distribuita DOUBLE;
	DECLARE media DOUBLE DEFAULT 12;
    DECLARE deviazione_standard DOUBLE DEFAULT 3;
    DECLARE k_meteo DOUBLE;
    DECLARE temp_min_interna DOUBLE DEFAULT 15;
    DECLARE temp_min_esterna DOUBLE DEFAULT 6;
    DECLARE variaz_max_temp_interna DOUBLE DEFAULT 5;
    DECLARE variaz_max_temp_esterna DOUBLE DEFAULT 7;
    DECLARE periodo_riscaldamento INT;
    DECLARE temperatura_iniziale DOUBLE;
    DECLARE temperatura_desiderata DOUBLE;
    DECLARE tempo_iniziale DATETIME;
    DECLARE tempo_fine DATETIME;
    DECLARE temp_interna_default DOUBLE;
    DECLARE x DOUBLE;
    
	DECLARE finito INT DEFAULT 0;
	DECLARE cursore_stanza CURSOR FOR (SELECT S.ID
									   FROM Stanza S);
	DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET finito = 1;
    
    SET k_meteo = ROUND(((deviazione_standard*SQRT(2*PI()))), 2);

    -- per ogni stanza, popolo da inizio a fine 
    OPEN cursore_stanza;
    loop_label: LOOP
		FETCH cursore_stanza INTO stanza;
		IF finito = 1 THEN
			LEAVE loop_label;
		END IF;
        
        IF stanza <> 7 THEN
			SET periodo_riscaldamento = FLOOR(50+RAND()*(70-50+1));
		END IF;
        
        SET tempo = _inizio;
		WHILE tempo <= _fine 
		DO	
			SET ora_decimale = HOUR(tempo) + MINUTE(tempo) / 60;
            
            SET temperatura_distribuita = ROUND(((1/(deviazione_standard*SQRT(2*PI()))) * EXP(-(POW(ora_decimale-media, 2)/(2*POW(deviazione_standard, 2))))), 2);
			SET temp_interna_default = temp_min_interna + variaz_max_temp_interna * k_meteo * temperatura_distribuita;
            
            IF stanza = 7 THEN
				SET temperatura = ROUND(6 + (9 * k_meteo * temperatura_distribuita), 1);
			
            ELSEIF EXISTS ( SELECT *
							 FROM ImpostazioneClima IC
                             WHERE IC.Climatizzatore = (SELECT C.ID FROM Climatizzatore C WHERE C.Stanza = stanza) AND
								   IC.Inizio <= tempo) THEN
				SELECT IC.Inizio, IC.Temperatura, IC.Fine INTO tempo_iniziale, temperatura_desiderata, tempo_fine
				FROM ImpostazioneClima IC
                WHERE IC.Climatizzatore = (SELECT C.ID FROM Climatizzatore C WHERE C.Stanza = stanza) AND
					  IC.Inizio <= tempo
				ORDER BY IC.Inizio DESC
                LIMIT 1;
                
                IF (tempo < tempo_iniziale + INTERVAL periodo_riscaldamento MINUTE) AND
				   (tempo < tempo_fine) THEN
                
					SET x = ((tempo - tempo_iniziale)*1.4)/periodo_riscaldamento;
					SET temperatura_distribuita = ROUND(((1/(0.5*SQRT(2*PI()))) * EXP(-(POW(x-1.4, 2)/(2*POW(0.5, 2))))), 1);
					SET temperatura_iniziale = (SELECT T.Temperatura
												FROM TemperaturaInterna T
												WHERE T.Istante <= tempo_iniziale AND T.Stanza = stanza
												ORDER BY T.Istante DESC
												LIMIT 1);
					SET temperatura = ROUND(((temperatura_distribuita/(SQRT(2/PI()))) * (temperatura_desiderata - temperatura_iniziale) + temperatura_iniziale), 1);
				
				ELSEIF (tempo >= tempo_iniziale + INTERVAL periodo_riscaldamento MINUTE) AND
					   (tempo <= tempo_fine) THEN
					SET temperatura = ROUND(temperatura_desiderata, 1);
                    
				ELSEIF (tempo > tempo_fine)  THEN
				 SELECT TI.Temperatura INTO temperatura_iniziale
				 FROM TemperaturaInterna TI
                 WHERE TI.Istante <= tempo_iniziale AND TI.Stanza = stanza
                 ORDER BY TI.Istante DESC
                 LIMIT 1;
				SET temperatura = ROUND(GREATEST(temperatura_iniziale - 0.3, temp_interna_default), 1);
            
				ELSE
					SET temperatura = ROUND(temp_interna_default, 1);
				END IF;
			ELSE
				SET temperatura = ROUND(temp_interna_default, 1);
			END IF;
			
            INSERT INTO TemperaturaInterna(Stanza, Istante, Temperatura)
			VALUES (stanza, tempo, temperatura);
            
			SET tempo = tempo + INTERVAL 20 MINUTE;
		END WHILE;
	END LOOP;
    CLOSE cursore_stanza;
END $$
DELIMITER ;

-- Popolo gennaio 2022 ed elimino la stored procedure
CALL popolamento_TemperatureInterne('2022-01-01 00:00:00', '2022-01-05 00:00:00');
CALL popolamento_TemperatureInterne('2022-01-05 00:20:00', '2022-01-10 00:00:00');
CALL popolamento_TemperatureInterne('2022-01-10 00:20:00', '2022-01-15 00:00:00');
CALL popolamento_TemperatureInterne('2022-01-15 00:20:00', '2022-01-20 00:00:00');
CALL popolamento_TemperatureInterne('2022-01-20 00:20:00', '2022-01-25 00:00:00');
CALL popolamento_TemperatureInterne('2022-01-25 00:20:00', '2022-01-31 00:00:00');
DROP PROCEDURE popolamento_TemperatureInterne; 
