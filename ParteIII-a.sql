--- Progetto BD 23-24 (12 CFU)
--- 36
--- Nomi e matricole componenti
-- Virginia Passalacqua	5473700
-- Flavio Venturini 	5667103
-- Denis Muceku 		4801139 

--- PARTE III 
/* il file deve essere file SQL ... cio� formato solo testo e apribili ed eseguibili in pgAdmin */



/*************************************************************************************************************************************************************************/ 
--1b. Schema per popolamento in the large
/*************************************************************************************************************************************************************************/ 


/* per ogni relazione R coinvolta nel carico di lavoro, inserire qui i comandi SQL per creare una nuova relazione R_CL con schema equivalente a R ma senza vincoli di chiave primaria, secondaria o esterna e con eventuali attributi dummy */
/* se si opera con lo schema del template 2 già creato si possono usare i seguenti comandi, si vedano quelli commentati subito sotto altrimenti */
SET search_path TO Unige_Social_Sport;

CREATE OR REPLACE TABLE cl_utenti (LIKE utenti);
CREATE OR REPLACE TABLE cl_iscrizioni (LIKE iscrizioni);
/* Comandi analoghi ma che hanno inclusa la cancellazione dello schema qualora già esistesse e la sua ricreazione  */
/* DROP SCHEMA IF EXISTS Unige_Social_Sport CASCADE;
CREATE SCHEMA Unige_Social_Sport;
SET search_path TO Unige_Social_Sport;
CREATE TABLE cl_utenti
(matricola INT ,
 username VARCHAR(30) CONSTRAINT Uuser NOT NULL,
 password VARCHAR(30) CONSTRAINT Upass NOT NULL,
 nome VARCHAR(30) CONSTRAINT Unome NOT NULL,
 cognome VARCHAR(30) CONSTRAINT Ucogn NOT NULL,
 anno_nascita SMALLINT CONSTRAINT Uanasc NOT NULL,
 luogo_nascita VARCHAR(30) CONSTRAINT Ulnasc NOT NULL,
 foto BYTEA CONSTRAINT Ufoto NOT NULL,
 telefono VARCHAR(15) CONSTRAINT Utel NOT NULL,
 corso VARCHAR(50) CONSTRAINT Ucorso NOT NULL,
 affidabile BOOLEAN CONSTRAINT Uaff NOT NULL);

CREATE TABLE cl_iscrizioni
(matricola INT,
 id_evento INT,
 data TIMESTAMP CONSTRAINT Idat NOT NULL DEFAULT CURRENT_TIMESTAMP,
 ruolo VARCHAR(20),
 squadra NUMERIC(1),
 stato VARCHAR(10) CONSTRAINT Ista NOT NULL,
 qualità VARCHAR(9) CONSTRAINT Iqua NOT NULL
 ); */


/*************************************************************************************************************************************************************************/
--1c. Carico di lavoro
/*************************************************************************************************************************************************************************/ 


/*************************************************************************************************************************************************************************/ 
/* Q1: Query con singola selezione e nessun join */
/*************************************************************************************************************************************************************************/ 


/* inserire qui i comandi SQL per la creazione della query, in modo da visualizzarne piane di esecuzione e tempi di esecuzione */ 

EXPLAIN ANALYZE SELECT nome || ' ' || cognome AS nominativo
FROM cl_utenti
WHERE corso='Informatica';


/*************************************************************************************************************************************************************************/ 
/* Q2: Query con condizione di selezione complessa e nessun join */
/*************************************************************************************************************************************************************************/ 


/* inserire qui i comandi SQL per la creazione della query, in modo da visualizzarne piane di esecuzione e tempi di esecuzione */ 
EXPLAIN ANALYZE SELECT nome || ' ' || cognome
FROM cl_utenti
WHERE (corso='Informatica' OR corso='Economia') AND anno_nascita BETWEEN 1970 AND 1990;

/*************************************************************************************************************************************************************************/ 
/* Q3: Query con almeno un join e almeno una condizione di selezione */
/*************************************************************************************************************************************************************************/ 


/* inserire qui i comandi SQL per la creazione della query, in modo da visualizzarne piani di esecuzione e tempi di esecuzione */ 
EXPLAIN ANALYZE SELECT nome || ' ' || cognome, id_evento
FROM cl_utenti U JOIN cl_iscrizioni I ON U.matricola=I.matricola
WHERE corso='Ingegneria' AND qualità='ARBITRO'


/*************************************************************************************************************************************************************************/
--1e. Schema fisico
/*************************************************************************************************************************************************************************/ 


/* inserire qui i comandi SQL per cancellare tutti gli indici gi� esistenti per le tabelle coinvolte nel carico di lavoro */

DROP INDEX IF EXISTS idx_corso;
DROP INDEX IF EXISTS idx_anno_n;
DROP INDEX IF EXISTS idx_mat_isc;

/* inserire qui i comandi SQL perla creazione dello schema fisico della base di dati in accordo al risultato della fase di progettazione fisica per il carico di lavoro. */

CREATE INDEX idx_corso ON cl_utenti USING HASH (corso);

CREATE INDEX idx_anno_n ON cl_utenti(anno_nascita);
CLUSTER cl_utenti USING idx_anno_n;

CREATE INDEX idx_mat_isc ON cl_iscrizioni(matricola);
CLUSTER cl_iscrizioni USING idx_mat_isc;




/*************************************************************************************************************************************************************************/ 
--2. Controllo dell'accesso 
/*************************************************************************************************************************************************************************/ 

/* inserire qui i comandi SQL per la definizione della politica di controllo dell'accesso della base di dati  (definizione ruoli, gerarchia, definizione utenti, assegnazione privilegi) in modo che, dopo l'esecuzione di questi comandi, 
le operazioni corrispondenti ai privilegi delegati ai ruoli e agli utenti sia correttamente eseguibili. */

--CREAZIONE DEL RUOLO UTENTI_SEMPLICI CON RELATIVI PERMESSI
CREATE ROLE UTENTI_SEMPLICI;
set search_path to Unige_Social_Sport;
GRANT ALL ON valutazioni TO UTENTI_SEMPLICI;
GRANT INSERT ON iscrizioni, candidature TO UTENTI_SEMPLICI;
GRANT SELECT ON impianti, categorie, eventi, squadre, tornei, statistiche, iscrizioni, evento_a_squadre TO UTENTI_SEMPLICI;
GRANT EXECUTE ON FUNCTION disiscriz TO UTENTI_SEMPLICI; 
GRANT EXECUTE ON FUNCTION level TO UTENTI_SEMPLICI; 
GRANT USAGE ON SCHEMA unige_social_sport TO UTENTI_SEMPLICI;

--CREAZIONE DEL RUOLO UTENTI_PREMIUM CON RELATIVI PERMESSI
CREATE ROLE UTENTI_PREMIUM;
GRANT SELECT ON utenti, utenti_premium TO UTENTI_PREMIUM;
GRANT ALL ON Unige_Social_Sport.eventi, Unige_Social_Sport.squadre, Unige_Social_Sport.tornei, evento_a_squadre, esiti, statistiche TO UTENTI_PREMIUM;
GRANT SELECT, UPDATE, INSERT ON iscrizioni, candidature TO UTENTI_PREMIUM;
GRANT EXECUTE ON FUNCTION Unige_Social_Sport.appr_iscriz TO UTENTI_PREMIUM;
GRANT EXECUTE ON FUNCTION Unige_Social_Sport.level TO UTENTI_PREMIUM;
GRANT EXECUTE ON FUNCTION Unige_Social_Sport.disiscriz TO UTENTI_PREMIUM;
GRANT EXECUTE ON FUNCTION Unige_Social_Sport.appr_cand TO UTENTI_PREMIUM;

--CREAZIONE DEL RUOLO GESTORE_IMPIANTI CON RELATIVI PERMESSI
CREATE ROLE GESTORE_IMPIANTI;
GRANT ALL PRIVILEGES ON Unige_Social_Sport.impianti TO GESTORE_IMPIANTI;
GRANT SELECT ON categorie, eventi, tornei, evento_a_squadre TO GESTORE_IMPIANTI;
GRANT UPDATE ON eventi TO GESTORE_IMPIANTI; 
GRANT SELECT ON programma TO GESTORE_IMPIANTI  WITH GRANT OPTION;
GRANT USAGE ON SCHEMA unige_social_sport TO GESTORE_IMPIANTI;

--CREAZIONE DEL RUOLO ADMIN CON RELATIVI PERMESSI
CREATE ROLE ADMIN;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Unige_Social_Sport TO ADMIN  WITH GRANT OPTION;
GRANT ALL ON programma TO ADMIN  WITH GRANT OPTION;
GRANT USAGE ON SCHEMA Unige_Social_Sport TO ADMIN WITH GRANT OPTION;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA unige_social_sport TO ADMIN WITH GRANT OPTION;

-- DEFINIZIONE DELLA GERARCHIA DEI VARI RUOLI
GRANT UTENTI_SEMPLICI TO UTENTI_PREMIUM;
GRANT UTENTI_PREMIUM TO ADMIN;
GRANT GESTORE_IMPIANTI TO ADMIN;

-- CREAZIONE DEI VARI USER E RELATIVA ASSEGNAZIONE AL RISPETTIVO RUOLO
CREATE USER Anna;
GRANT ADMIN TO Anna;

CREATE USER Giovanni;
GRANT GESTORE_IMPIANTI TO Giovanni;

CREATE USER Sandro;
GRANT UTENTI_SEMPLICI TO Sandro;

CREATE USER Pietro;
GRANT UTENTI_PREMIUM TO Pietro;

