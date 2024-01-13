USE smart_home;
SET @@SESSION.group_concat_max_len = 150000;
-- show variables;
SET SQL_SAFE_UPDATES = 0;

-- ================================================ --
--                      Indice                      --
-- ================================================ --   
-- 1) Individuazione Items e Transazioni
-- 		1.1 Creazione tabella Transazione (rig. 34)
-- 		1.2 Popolamento tabella Transazione	(rig. 65)		
-- 2) Function e procedure di utilità
-- 		2.1 Elimina(int k): Procedura per eliminare tabelle superflue (rig. 111)
--      2.2 GetC(int k): Funzione per trovare Ck (rig. 143)
--  	2.3 GetL(int k): Funzione per trovare Lk (rig. 266)
-- 		2.4 N_to_A(int k): Funzione di utilità per GetRules (rig. 291)
--  	2.5 GetRules(int k): Procedura per trovare le regole forti (rig. 346)						
-- 3) Stored Procedure Apriori(int max)	(rig. 638)			
-- 4) Test SP Apriori (rig. 755)	

-- Parametri per Apriori:
SET @Confidence = 0.7;
SET @Support = 0.004;

-- Parametri per definire le transazioni:
set @min_length = 2;
set @span = 20;

-- ================================================================================ --
--            1)        Individuazione di items e transazioni                       --
-- ================================================================================ --   

-- -----------------------------------------
--     Creazione tabella Transazione
-- -----------------------------------------
-- Preparazione degli attributi items della tabella Transazione.
-- Transazione = insieme di dispositivi (items) usati da uno stesso account
-- nell'intervallo di tempo [RI.Inizio - @span, RI.Inizio + @span], 
-- dove RI.Inizio è l'istante di avviamento di un'interazione con un dispositivo.

SELECT GROUP_CONCAT(
					CONCAT('`D', ID, '`', ' INT DEFAULT 0') ORDER BY ID
				   ) INTO @disp_list
FROM Dispositivo;

set @disp_list = concat('CREATE TABLE Transazione(',
						  ' ID INT AUTO_INCREMENT PRIMARY KEY, ', 
                            @disp_list, 
						  ' )engine = InnoDB default charset = latin1;');
                          
-- Creazione della tabella Transazione, avente attributi 
--       +------+------+------+---   ---+------+
--       |  ID  |  D1  |  D2  |   ...   |  Dn  |
--       +------+------+------+---   ---+------+
-- ID = identificatore della transazione;
-- D[i] = attributo binario che identifica la presenza o meno
-- dell'i-esimo item nella transazione.

DROP TABLE IF EXISTS Transazione;
PREPARE create_table_Transazione FROM @disp_list;
EXECUTE create_table_Transazione;


-- -----------------------------------------
--     Popolamento tabella Transazione
-- -----------------------------------------

WITH transazioni AS ( 
	SELECT RI.Dispositivo, 
		   RI.Inizio, 
		   COUNT(DISTINCT RI2.Dispositivo) AS num_disp, -- Numero items della transazione
		   GROUP_CONCAT(DISTINCT RI2.Dispositivo) AS lista -- Lista degli items della transazione
	FROM Interazione RI 
		 LEFT OUTER JOIN
		 Interazione RI2 ON (RI2.Inizio BETWEEN (RI.Inizio - INTERVAL @span MINUTE) AND (RI.Inizio + INTERVAL @span MINUTE)
							 AND RI2.Account = RI.Account) -- Interazioni dello stesso account durante l'intervallo di transazione 
	GROUP BY RI.Dispositivo, RI.Inizio, RI.Account
	),
presenza_dispositivi as (
	SELECT Dispositivo, Inizio, ID,
		   IF(FIND_IN_SET(ID, lista) > 0, 1, 0) AS presenza
	FROM transazioni 
		 CROSS JOIN
         Dispositivo
    WHERE num_disp >= @min_length -- Scartare transazioni contenenti un solo item (avendo impostato @min_lenght = 2)
	),
record_transazione AS (
	SELECT Dispositivo, 
		   Inizio, 
		   GROUP_CONCAT(presenza ORDER BY ID) AS elenco
	FROM presenza_dispositivi 
    GROUP BY Inizio, Dispositivo
	)
SELECT GROUP_CONCAT(CONCAT('(null,', elenco, ')') ) INTO @inserimento
FROM record_transazione;

SET @inserimento = CONCAT('INSERT INTO Transazione VALUES ', @inserimento, ';');
-- select LENGTH(@inserimento); --  Verifica delle dimensioni adeguate per group_concat_max_length
PREPARE Populate_Transazione FROM @inserimento;
EXECUTE Populate_Transazione;

/* -- Debug: Viene mostrata la tabella Transazione popolata
TABLE Transazione; */


-- ================================================================================ --
--                      2) FUNCTIONS E PROCEDURE DI UTILITA'                        --
-- ================================================================================ --  

-- ------------------------------------------
--  Elimina(k): procedura che elimina
--  le tabelle superflue (tutte tranne Rules)
-- ------------------------------------------
DROP PROCEDURE IF EXISTS Elimina;
DELIMITER $$
CREATE PROCEDURE Elimina(IN k INT)
BEGIN
	DECLARE i INT DEFAULT 1;
    
    DROP TABLE IF EXISTS tmp_list;
    DROP TABLE IF EXISTS Items;
    DROP TABLE IF EXISTS Combinazioni;
    DROP TABLE IF EXISTS Transazione;
    DROP VIEW IF EXISTS tmp_Lk;
    
    WHILE i <= k DO
		SET @drop_tab = concat('DROP TABLE IF EXISTS C', i, ';');
        PREPARE dropC FROM @drop_tab;
        EXECUTE dropC;
        
		SET @drop_tab = concat('DROP TABLE IF EXISTS L', i, ';');
        PREPARE dropL FROM @drop_tab;
        EXECUTE dropL;
        
        SET i = i + 1;
	END WHILE;
    
END $$
DELIMITER ;


-- -----------------------------------
--  GetC(k): Funzione per trovare C[k]
-- -----------------------------------
-- La tabella C[k] ha attributi
-- +---------+---------+---   ---+---------+-----------+
-- |  Item1  |  Item2  |   ...   |  ItemK  |  Support  |
-- +---------+---------+---   ---+---------+-----------+

DROP FUNCTION IF EXISTS GetC;
DELIMITER $$
CREATE FUNCTION GetC(k INT)
RETURNS TEXT DETERMINISTIC
BEGIN
	DECLARE i INT DEFAULT 1;
    DECLARE combination_select TEXT DEFAULT '';
	DECLARE vertical_no_rep TEXT DEFAULT '';
    DECLARE horizontal_no_rep_select TEXT DEFAULT '';
	DECLARE count_support TEXT DEFAULT '';
    DECLARE count_support_where TEXT DEFAULT '';
    DECLARE result TEXT DEFAULT '';
    
    -- Lo scopo è generare le combinazioni tra i (k-1)-LargeItemset precedenti,
    -- verticalizzare il tutto in modo da eliminare ogni ripetizione da ciascuna
    -- combinazione creata e dopodiché rendere gli elementi di nuovo pivot riportandoli
    -- in orizzontale.
    
	WHILE i < k DO
		SET vertical_no_rep = CONCAT(vertical_no_rep,
												 'SELECT ID1, ID2, ID 
												  FROM combination 
												  INNER JOIN
												  Dispositivo D ON(D.ID = Item', i,') 
                                                  UNION '
												 );
		
		-- Select di combination (prima parte: seleziono gli attributi Item[i] di a)
        SET combination_select = CONCAT(combination_select, 'a.Item', i,', ');
        
		-- Trasformo il formato delle combinazioni da verticale a orizzontale
        SET horizontal_no_rep_select = CONCAT(horizontal_no_rep_select, 'MAX(CASE WHEN rownum = ', i,' THEN ID END) as Item', i, ', ');
        
		-- Where di support_transactions, l'item deve essere uguale a uno di quelli della combinazione in questione
        SET count_support_where = CONCAT(count_support_where, 'Item = Item', i, ' OR ');
        
        SET i = i + 1;
	END WHILE;

	-- Ultimo elemento di horizontal_no_rep_select (i = k)
	SET horizontal_no_rep_select = CONCAT(horizontal_no_rep_select, 'MAX(CASE WHEN rownum = ', i,' THEN ID END) as Item', i);
    
    -- Ultimo elemento di support_transactions_where (i = k)
	SET count_support_where = CONCAT(count_support_where, 'Item = Item', i);
     
    SET i = 1;
	WHILE i < k-1 DO
    
        -- Si completa vertical_no_rep joinando ogni elemento di b con Dispositivo
		SET vertical_no_rep = CONCAT(vertical_no_rep,
												 'SELECT ID1, ID2, ID 
												  FROM combination 
												  INNER JOIN
												  Dispositivo D ON(D.ID = Item',i,'Join)
                                                  UNION '
												 );
                                                 
		-- Select di combination (seconda parte: si selezionano gli Item[i] di b e sono rinominati Item[i]Join)
        SET combination_select = CONCAT(combination_select, 'b.Item', i,' AS Item', i,'Join, ');   
        
		SET i = i + 1;
	END WHILE;
    
	-- Si completa il select di combination
    SET combination_select = CONCAT(combination_select, 'b.Item', i,' AS Item', i,'Join, a.ID AS ID1, b.ID AS ID2');
    
    -- Ultimo elemento di vertical_without_repetition (i = k-1)
	SET vertical_no_rep = CONCAT(vertical_no_rep,
											 'SELECT ID1, ID2, ID 
											  FROM combination 
											  INNER JOIN
											  Dispositivo D ON(D.ID = Item',i,'Join)'
											 );
	-- numero di transazioni che hanno tutti gli Item della combinazione										
	SET count_support = CONCAT('SELECT COUNT(*)
								FROM (
									  SELECT ID
									  FROM Items
									  WHERE ', count_support_where, '
									  GROUP BY ID
									  HAVING COUNT(*) = ', k,') AS Z'
							  );
	
    -- Risultato finale
	SET result = CONCAT(
						'WITH combination AS 
                        (
							SELECT ', combination_select,'
							FROM L',(k-1),' a 
								 INNER JOIN
								 L',(k-1),' b ON(a.ID < b.ID)  
						), 
                        vertical_no_rep AS
                        (', vertical_no_rep,'), 
						horizontal_no_rep AS
                        (
							SELECT DISTINCT ', horizontal_no_rep_select, '
                            FROM (
								  SELECT *,
									@row:=if(@prev=CONCAT(ID1, ID2), @row,0) + 1 as rownum,
									@prev:= CONCAT(ID1, ID2)
								  FROM vertical_no_rep, (SELECT @row:=0, @prev:=null) AS R
								  ORDER BY ID1, ID2, ID
								  ) AS S
						    GROUP BY ID1, ID2 
							HAVING MAX(rownum) = ', k,'
                        )
                        SELECT *, ('
							   , count_support, ') / (SELECT COUNT(*) FROM Items) AS Support
                        FROM horizontal_no_rep;'
					   );
	RETURN result;
END $$
DELIMITER ;

-- -----------------------------------
--  GetL(k): Funzione per trovare L[k]
-- -----------------------------------
DROP FUNCTION IF EXISTS GetL;
DELIMITER $$
CREATE FUNCTION GetL(k INT)
RETURNS TEXT DETERMINISTIC
BEGIN
	DECLARE item_list TEXT DEFAULT '';
	DECLARE i INT DEFAULT 1;
    
    -- Creo la lista degli items
    WHILE i < k DO
		SET item_list = CONCAT(item_list, 'Item', i, ', ');		-- Da i = 1 
		SET i = i + 1;											-- A  i = k-1
    END WHILE;
    SET item_list = CONCAT(item_list, 'Item', i);				-- i = k
    
	RETURN CONCAT(
				   'SELECT ', item_list,', ROW_NUMBER() OVER (ORDER BY ', item_list,') AS ID ',
				   'FROM C', k,
				   ' WHERE Support > @Support');		-- Seleziono i k-LargeItemset
END $$
DELIMITER ;

-- -----------------------------------------------
--  N_to_A(k): function di utilità per GetRules(k)
-- -----------------------------------------------
-- 	Associa una stringa letterale a k in maniera biunivoca.
DROP FUNCTION IF EXISTS N_to_A;
DELIMITER $$
CREATE FUNCTION N_to_A(k INT)
RETURNS TEXT DETERMINISTIC
BEGIN
	DECLARE result TEXT DEFAULT '';
    DECLARE potenza INT DEFAULT 10;
    DECLARE valore_num INT;
    DECLARE valore_char CHAR;
    
    loop_label: LOOP
    
    SET valore_num = FLOOR((K % potenza) / potenza * 10);
    
    IF k < potenza / 10 THEN 
		LEAVE loop_label;
	END IF;
    
    CASE 	-- Ad ogni cifra di k si associa una corrispondente lettera alfabetica
    WHEN valore_num = 0 THEN
		SET valore_char = 'o';
    WHEN valore_num = 1 THEN
		SET valore_char = 'a';
    WHEN valore_num = 2 THEN
		SET valore_char = 'b';
    WHEN valore_num = 3 THEN
		SET valore_char = 'c';
    WHEN valore_num = 4 THEN
		SET valore_char = 'd';
    WHEN valore_num = 5 THEN
		SET valore_char = 'e';
    WHEN valore_num = 6 THEN
		SET valore_char = 'f';
    WHEN valore_num = 7 THEN
		SET valore_char = 'g';
    WHEN valore_num = 8 THEN
		SET valore_char = 'h';
    WHEN valore_num = 9 THEN
		SET valore_char = 'i';
	END CASE;
	
    SET result = CONCAT(valore_char, result),
		potenza = potenza * 10;
    
    END LOOP;
    
    RETURN result;
    
END $$
DELIMITER ;

-- ----------------------------------------------------
--  GetRules(k): procedura per trovare le regole forti
-- ----------------------------------------------------
DROP PROCEDURE IF EXISTS GetRules;
DELIMITER $$
CREATE PROCEDURE GetRules(IN k INT)
BEGIN
	DECLARE s INT;
	DECLARE a INT;
	DECLARE b INT;
    DECLARE num_comb INT;
	DECLARE foundY INT;
	DECLARE foundX INT;
	DECLARE ItemY TEXT DEFAULT '';
	DECLARE ItemX TEXT DEFAULT '';
	DECLARE dim_X INT;
    DECLARE dim_Y INT;
    DECLARE X TEXT DEFAULT '';
    DECLARE Y TEXT DEFAULT '';
    DECLARE i INT;
    DECLARE j INT;
    DECLARE comb_select TEXT DEFAULT '';
    DECLARE comb_from TEXT DEFAULT '';
    DECLARE comb_concat TEXT DEFAULT '';
    DECLARE vertical_qry TEXT DEFAULT '';
    DECLARE horizontal_select TEXT DEFAULT '';
    DECLARE lista_concat TEXT DEFAULT '';
    DECLARE X_list TEXT DEFAULT '';
    DECLARE Y_list TEXT DEFAULT '';
	DECLARE X_on TEXT DEFAULT '';
    DECLARE Y_on TEXT DEFAULT '';
    DECLARE X_supp DOUBLE;
    DECLARE Y_supp DOUBLE;
    DECLARE k_supp DOUBLE;
    DECLARE confidence DOUBLE;
    DECLARE id INT;
    
	DECLARE finito INT DEFAULT 0;
    DECLARE cursor_Lk CURSOR FOR SELECT * FROM tmp_Lk;
    DECLARE CONTINUE HANDLER FOR NOT FOUND 
		SET finito = 1;
        
	-- Creazione della view dinamica per il cursore
	SET @v = CONCAT('CREATE OR REPLACE VIEW tmp_Lk AS
					 SELECT ID
                     FROM L', k, ';');
    PREPARE stm FROM @v;
    EXECUTE stm;		
    
    OPEN cursor_Lk;
	loop_label: LOOP
     	FETCH cursor_Lk INTO id;
        IF finito = 1 THEN
			LEAVE loop_label;
		END IF;
        
		-- Prendo il supporto della riga joinando Lk con Ck
			SET @k = CONCAT('SELECT Support INTO @k_supp
							 FROM L', k,'
								  NATURAL JOIN
                                  C', k,'
							 WHERE ID =', id);
		PREPARE ksupp FROM @k;
		EXECUTE ksupp;
        
        -- ------------------------
        --  Creazione combinazioni
        -- ------------------------
        -- Per trovare le combinazioni tra gli elementi dei k-Itemset
        -- Creo uno spazio di k dimensioni tramite k cross join della
        -- tabella tmp_list ed eliminando le combinazioni superflue 
        -- con un metodo simile a quello utilizzato per trovare gli item
        -- di C[k].

		DROP TABLE IF EXISTS tmp_list;		-- Creo tmp_list
		CREATE TABLE tmp_list(
			ID INT PRIMARY KEY
            )engine = InnoDB default charset = latin1;        
        
		SET a = 1;
        WHILE a <= k DO		-- Popolo tmp_list
			INSERT INTO tmp_list
            VALUES (a);
            SET a = a + 1;
		END WHILE;
        -- DEBUG: if k = 3 then table tmp_list; end if;
            
        SET dim_X = 1;
        WHILE dim_X <= k/2 DO 
			SET dim_Y = k - dim_X;
                				
            SET comb_select = '';
            SET comb_from = '';
            SET comb_concat = '';
            SET vertical_qry = '';
            SET horizontal_select = '';
            SET lista_concat = '';
            
            -- Preparazione della query per trovare le combinazioni di elementi
			SET b = 1;
            WHILE b < dim_X DO
            
				-- Prima parte del select della CTE comb
				SET comb_select = CONCAT(comb_select, ' ', N_to_A(b),'.ID as ID', b, ', ');
                
				-- Prima parte del from della CTE comb
                SET comb_from = CONCAT(comb_from, ' tmp_list as ', N_to_A(b),' CROSS JOIN');
                
				-- Prima parte del select della CTE combination
                SET comb_concat = CONCAT(comb_concat, ' ID', b, ', ');
                
				-- Prima parte della CTE vertical
                SET vertical_qry = CONCAT(vertical_qry, 'SELECT C.ID, TL.ID as IDnum ',
												'FROM combination C ',
														'INNER JOIN tmp_list TL ON(C.ID', b, ' = TL.ID)',
												' UNION ');
				
				-- Prima parte del select della query principale
				SET horizontal_select = CONCAT(horizontal_select, 'MAX(CASE WHEN rownum = ', b,' THEN IDnum END) as ID', b, ', ');
                
				-- Prima parte della lista da inserire in @X_list
                SET lista_concat = CONCAT(lista_concat, '''Item'', ID', b, ','', '''', '''' ,'',');
                
                SET b = b + 1;
			END WHILE;
                
			-- Parte finale del select della CTE comb
			SET comb_select = CONCAT(comb_select, ' ', N_to_A(b),'.ID as ID', b);
			
			-- Parte finale del from della CTE comb
            SET comb_from = CONCAT(comb_from, ' tmp_list as ', N_to_A(b));        
			
			-- Parte finale del select della CTE combination
            SET comb_concat = CONCAT('CONCAT(', comb_concat, ' ID', b, ' ) as ID');
			
			-- Parte finale della CTE vertical
            SET vertical_qry = CONCAT(vertical_qry, 'SELECT C.ID, TL.ID as IDnum ',
											'FROM combination C ',
													'INNER JOIN tmp_list TL ON(C.ID', b, ' = TL.ID)');
			
			-- Parte finale del select della query principale
            SET horizontal_select = CONCAT(horizontal_select, 'MAX(CASE WHEN rownum = ', b,' THEN IDnum END) as ID', b);
			
			-- Parte finale della lista da inserire in @X_list
            SET lista_concat = CONCAT(lista_concat, '''Item'', ID', b);
			
            -- Query risultante: i record generati sono 
            -- tutte le possibili combinazioni di X composti da dim_X elementi
            SET @comb = CONCAT( 
				'WITH comb as ('
						'SELECT ', comb_select,
						' FROM ', comb_from, '), '
					 'combination as ('
						'SELECT *, ', comb_concat,
						' FROM comb), '
					 'vertical as (',
						vertical_qry, ')',
					' SELECT DISTINCT ', horizontal_select,
					' FROM ( SELECT *, '
								'@row:=if(@prev= ID, @row,0) + 1 as rownum,
									@prev:= ID '
						     'FROM vertical, (SELECT @row:=0, @prev:=null) AS R '
                             'ORDER BY ID, IDnum) as S'
                     ' GROUP BY ID '
					 ' HAVING MAX(rownum) = ', dim_X
						  );
                
                -- Creazione della tabella Combinazioni come risultato della query precedente
                DROP TABLE IF EXISTS Combinazioni;          
				SET @comb = CONCAT( 'CREATE TABLE Combinazioni as (', @comb, '); '); 
				PREPARE comb_exe FROM @comb;
                EXECUTE comb_exe;
                -- DEBUG: if K = 2 and dim_X = 1 then select @comb; end if;
                
                -- Aggiungo un indice nella tabella Combinazioni 
                -- in modo da semplificare i passi successivi
                ALTER TABLE Combinazioni
                ADD ID INT AUTO_INCREMENT PRIMARY KEY;
                -- DEBUG: if dim_X >= 2 then table Combinazioni; end if;
                
                -- Per ogni combinazione trovata creo le liste di X ed Y con cui comporre la regola
                SET i = 1;
                SET num_comb = (SELECT COUNT(*) FROM Combinazioni);
                WHILE i <= num_comb DO
                
				SET @X_list = '', X_on = '';
				SET Y_list = '', Y_on = '';
				-- DEBUG: if dim_X >= 2 then select lista_concat; end if;

				-- Lista degli item di X
                SET @lista_X = CONCAT( 'SELECT CONCAT(', lista_concat,') INTO @X_list '
								 'FROM Combinazioni'
                                 ' WHERE ID = ', i, ';');
				PREPARE X_exe FROM @lista_X;
                EXECUTE X_exe;
                
				SET s = 1;
                SET foundX = 0;
                SET j = 1;
				WHILE j <= k DO 
					SET itemX = CONCAT('Item', j);
					IF FIND_IN_SET(itemX, @X_list) > 0 THEN 		-- Sono quelli che compaiono in X
						IF foundX = 1 THEN 
                            SET X_on = CONCAT(X_on, ' AND '); 
                            END IF;
						SET foundX = 1;
						SET X_on = CONCAT(X_on, 'L.Item', j, ' = C.Item', s);
                        SET s = s + 1;
                    END IF;
                    SET j = j + 1;
				END WHILE;
                
				-- Lista degli item di Y
				SET s = 1;
                SET foundY = 0;
                SET j = 1;
				WHILE j <= k DO 
					SET itemY = CONCAT('Item', j);
					IF FIND_IN_SET(itemY, @X_list) = 0 THEN 		-- Sono quelli che non compaiono in X
						IF foundY = 1 THEN 
							SET Y_list = CONCAT(Y_list, ','', '','); 
                            SET Y_on = CONCAT(Y_on, ' AND '); 
                            END IF;
						SET foundY = 1;
						SET Y_list = CONCAT(Y_list, 'Item', j);
						SET Y_on = CONCAT(Y_on, 'L.Item', j, ' = C.Item', s);
						SET s = s + 1;
                    END IF;
                    SET j = j + 1;
				END WHILE;
                -- DEBUG: if dim_X >= 2 then select @X_list, Y_list, k, dim_X, i, id; end if;
				
                -- ----------------------
				--     Set di X e Y
                
				-- Si setta X
				SET @set_X = CONCAT('SELECT CONCAT(', @X_list,') INTO @X
									 FROM L', k,' a
									 WHERE a.ID =', id);
				PREPARE set_X FROM @set_X;
				EXECUTE set_X;
                
				-- Si setta Y
				SET @set_Y = CONCAT('SELECT CONCAT(', Y_list,') INTO @Y
									 FROM L', k,' a
									 WHERE a.ID =', id);
				PREPARE set_Y FROM @set_Y;
				EXECUTE set_Y;
                
				-- ------------------------
				--  Calcolo Supporti X e Y
                
				-- Supporto di X
				SET @Xsupp = CONCAT('SELECT Support INTO @X_supp
									 FROM L', k,' L
										  INNER JOIN
										  C', dim_X,' C ON ', X_on,' 
									 WHERE ID =', id);
				PREPARE Xsupp FROM @Xsupp;
				EXECUTE Xsupp;

				-- Supporto di Y
				SET @Ysupp = CONCAT('SELECT Support INTO @Y_supp
									 FROM L', k,' L
										  INNER JOIN
										  C', dim_Y,' C ON ', Y_on,'
									 WHERE ID =', id);
				PREPARE Ysupp FROM @Ysupp;
				EXECUTE Ysupp;
                
				-- Calcolo conf(X->Y) e inserimento della regola X->Y
				SET confidence = @k_supp / @X_supp;
				INSERT IGNORE INTO Rules
				VALUES	(@X, @Y, confidence);
                
				-- Calcolo conf(Y->X) e inserimento della regola X->Y
				SET confidence = @k_supp / @Y_supp;
				INSERT IGNORE INTO Rules
				VALUES	(@Y, @X, confidence);
                
                SET i = i+1;
                END WHILE;

            SET dim_X = dim_X + 1;
		END WHILE;
        
    END LOOP;
    CLOSE cursor_Lk;
END $$
DELIMITER ;


-- ================================================================================ --
--                        3) STORED PROCEDURE Apriori(max)                          --
-- ================================================================================ --  
DROP PROCEDURE IF EXISTS Apriori;
DELIMITER $$
CREATE PROCEDURE Apriori(IN max INT) -- Max = passaggi massimi da fare
BEGIN
	DECLARE k INT DEFAULT 2;
    DECLARE i INT DEFAULT 2;

	-- Tabella Items(ID, Item): utile a calcolare più velocemente il supporto
	SELECT GROUP_CONCAT( 
						CONCAT('SELECT ID, ', ID,' as Item ' 
							   'FROM Transazione ',
							   'WHERE D', ID, '<> 0') 
						SEPARATOR ' UNION ') INTO @items
	FROM Dispositivo;

	set @items = concat('create table Items as ',
										@items, ';');
                                        
	DROP TABLE IF EXISTS Items;
	PREPARE create_table_Items FROM @items;
	EXECUTE create_table_Items;
    
    /* -- Debug: Viene mostrata la tabella Items
    table Items; */
    
    -- Creazione tabella C1(Item1, Support)
    DROP TABLE IF EXISTS C1;
    CREATE TABLE C1 AS
    SELECT Item AS Item1, COUNT(*) / (SELECT COUNT(*) FROM Transazione) AS Support 	-- Sono calcolati i support di ogni 1-Itemset
    FROM Items
    GROUP BY Item;
    
	-- Creazione tabella L1(Item1, Support, ID)
    DROP TABLE IF EXISTS L1;
    CREATE TABLE L1 AS
    SELECT *, ROW_NUMBER() OVER(ORDER BY Item1) AS ID 	-- Viene reso individuabile ogni record tramite un ID
    FROM C1
    WHERE Support > @Support; 	-- Sono inseriti solo gli 1-LargeItemset
    
    -- LOOP da k = 2 fino a max, per creare le tabelle C[k] e L[k]
    -- Se L[k] è vuota anche le successive tabelle lo saranno,
    -- dunque si può terminare anticipatamente il loop in tal caso
    loop_label: LOOP
		IF k > max THEN
			LEAVE loop_label;
		END IF;
        
		SET @dropCk = concat('DROP TABLE IF EXISTS C', k, ';');
		SET @getCk = concat('CREATE TABLE C',k,' AS ', GetC(k));
		SET @dropLk = concat('DROP TABLE IF EXISTS L', k, ';');
		SET @getLk = concat('CREATE TABLE L',k,' AS ', GetL(k));

        -- Creo la tabella C[k]
        PREPARE DropCk FROM @dropCk;
        EXECUTE DropCk;
        PREPARE GetCk FROM @getCk;
        EXECUTE GetCk;
        
        -- Creo la tabella L[k]
		PREPARE DropLk FROM @dropLk;
        EXECUTE DropLk;
        PREPARE GetLk FROM @getLk;
        EXECUTE GetLk;
        
        /* -- Debug: Mostra le tabelle C[k], L[k] di ogni passo
		SET @debugCk = concat('TABLE C',k,' ;');        
        PREPARE debugCk FROM @debugCk;
        EXECUTE debugCk;
   		SET @DebugLk = concat('TABLE L',k,' ;');
        PREPARE DebugLk FROM @DebugLk;
        EXECUTE DebugLk; */
        
        -- Controllo se L[k] è vuoto.
        SET @Control = CONCAT('SELECT EXISTS (SELECT 1 FROM L', k,') INTO @empty;');
        PREPARE Control FROM @Control;
        EXECUTE Control;
        IF @empty = 0 THEN
			LEAVE loop_label;
		END IF;
        
		SET k = k + 1;
    END LOOP;
    
    -- Creazione tabella Rules(X, Y, Confidence)
    DROP TABLE IF EXISTS Rules;
    CREATE TABLE Rules(
		X				VARCHAR(100) NOT NULL,
        Y				VARCHAR(100) NOT NULL,
        Confidence		DOUBLE NOT NULL,
        PRIMARY KEY(X, Y)
    )ENGINE = InnoDB DEFAULT CHARSET = latin1;
    
    -- Si calcolano le regole per ciascun i-LargeItemset
    WHILE i < k DO
		CALL GetRules(i);
        SET i = i + 1;
	END WHILE;
    
	 -- Debug: Viene mostrata la tabella delle regole trovate assieme al numero totale trovato.
    TABLE Rules; 
    SELECT COUNT(*) FROM Rules; 
    
    -- Vengono eliminate le regole non forti
    -- E' mostrata la tabella risultante delle regole forti
    DELETE FROM Rules
    WHERE Confidence < @Confidence;
    TABLE Rules;
    
    -- Elimino tutte le tabelle create tranne Rules
    CALL Elimina(max);
    
END $$
DELIMITER ;

-- ================================ --
--       4) TEST SP Apriori         --
-- ================================ --
-- Si considera il numero di dispositivi come numero massimo di passaggi per la procedura
CALL Apriori((SELECT COUNT(*)
			  FROM Dispositivo));
