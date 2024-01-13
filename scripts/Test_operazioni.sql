USE smart_home;
SET SQL_SAFE_UPDATES = 0;

-- ================= --
-- 	TEST OPERAZIONI	 --
-- ================= --

-- ----------------------------------------------- --
-- OPERAZIONE 1: DailyDeviceRanking(IN _data DATE)
-- Classifica giornaliera dispositivi fissi o variabili per consumi

CALL DailyDeviceRanking('2022-01-15');


-- ------------------------------------------------------------------------------------------- --
-- OPERAZIONE 2: StartRoomIllumination(IN _stanza INT, IN _intensità INT, IN _temperatura INT)
-- Avviare tutti gli elementi d’illuminazione in una stanza

-- Vengono spente tutte le luci per verificare poi che siano state accese solo quelle stabilite
UPDATE impostazioneluce
SET Fine = current_timestamp()
WHERE Fine IS null;

CALL StartRoomIllumination(4, 90, 4000);

-- Si verifica l'accensione delle luci volute
SELECT *
FROM impostazioneluce
WHERE Fine IS NULL;


-- ----------------------------------------- --
-- OPERAZIONE 3: InterationAccountRanking()
-- Classifica mensile account per interazioni con dispositivi e climatizzatori nel mese corrente

CALL InterationAccountRanking();


-- ----------------------------------------------------------------------------------- --
-- OPERAZIONE 4: PercentualeUtilizzo(IN _dispositivo INT, IN _mese INT, IN _anno INT)
-- Percentuale di utilizzo di un dispositivo da parte di ogni utente

CALL PercentualeUtilizzo(05, 01, 2022);


-- --------------------------------------------------------------- --
-- OPERAZIONE 5: ConsumoMensileStanze(IN _mese INT, IN _anno INT)
-- Consumo mensile degli elementi d’illuminazione per stanza

CALL ConsumoMensileStanze(01, 2022);


-- -------------------------------------------------------------------------- --
-- OPERAZIONE 6: ConsumoCondizionatore(IN _climatizzatore INT, IN _data DATE)
-- Consumo giornaliero di un condizionatore

CALL ConsumoCondizionatore(02, '2022-01-15');


-- ---------------------------------- --
-- OPERAZIONE 7: ProduzionePannelli()
-- Produzione energetica giornaliera

CALL ProduzionePannelli();


-- ------------------------------- --
-- OPERAZIONE 8: ElementiAccesi()
-- Elenco di tutti gli elementi dell’abitazione attualmente in funzione

CALL ElementiAccesi();
