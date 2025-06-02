--- Progetto BD 23-24 (9 o 12 CFU)
--- GRUPPO 36
--- Virginia Passalacqua 5473700
--- Venturini Flavio     5667103
--- Muceku Denis         4801139

--- PARTE 2 
/* il file deve essere file SQL ... cio� formato solo testo e apribili ed eseguibili in pgAdmin */

/*************************************************************************************************************************************************************************/
--1a. Schema
/*************************************************************************************************************************************************************************/ 


/* inserire qui i comandi SQL per la creazione dello schema logico della base di dati in accordo allo schema relazionale ottenuto alla fine della fase di progettazione logica, per la porzione necessaria per i punti successivi (cio� le tabelle coinvolte dalle interrogazioni nel carico di lavoro, nella definizione della vista, nelle interrogazioni, in funzioni, procedure e trigger). Lo schema dovr� essere comprensivo dei vincoli esprimibili con check. */

DROP SCHEMA IF EXISTS Unige_Social_Sport CASCADE;
CREATE SCHEMA Unige_Social_Sport;
SET search_path TO Unige_Social_Sport;

CREATE TABLE categorie
(sport VARCHAR(30) CONSTRAINT Csport PRIMARY KEY,
 regolamento TEXT CONSTRAINT Creg NOT NULL,
 numero_giocatori SMALLINT CONSTRAINT Cngioc NOT NULL CHECK ( numero_giocatori > 0 ),
 foto BYTEA CONSTRAINT Cfoto NOT NULL);

CREATE TABLE utenti
(matricola INT CONSTRAINT Umat PRIMARY KEY,
 username VARCHAR(30) CONSTRAINT Uuser NOT NULL UNIQUE,
 password VARCHAR(30) CONSTRAINT Upass NOT NULL,
 nome VARCHAR(30) CONSTRAINT Unome NOT NULL,
 cognome VARCHAR(30) CONSTRAINT Ucogn NOT NULL,
 anno_nascita SMALLINT CONSTRAINT Uanasc NOT NULL CHECK ( anno_nascita >= 1920 AND anno_nascita <= EXTRACT(YEAR FROM CURRENT_DATE) - 18 ),
 luogo_nascita VARCHAR(30) CONSTRAINT Ulnasc NOT NULL,
 foto BYTEA CONSTRAINT Ufoto NOT NULL,
 telefono VARCHAR(15) CONSTRAINT Utel NOT NULL,
 corso VARCHAR(50) CONSTRAINT Ucorso NOT NULL,
 affidabile BOOLEAN CONSTRAINT Uaff NOT NULL DEFAULT TRUE);

CREATE TABLE utenti_premium
(matricola INT CONSTRAINT UPmat PRIMARY KEY REFERENCES utenti ON DELETE CASCADE ON UPDATE CASCADE);

CREATE TABLE impianti
(nome VARCHAR(40) CONSTRAINT Inome PRIMARY KEY,
 via VARCHAR(50) CONSTRAINT Ivia NOT NULL,
 telefono VARCHAR(15) CONSTRAINT Itel NOT NULL,
 email VARCHAR(50) CONSTRAINT Iemail NOT NULL CHECK ( email LIKE '%_@_%_._%'),
 latitudine DOUBLE PRECISION CONSTRAINT Ilat NOT NULL,
 longitudine DOUBLE PRECISION CONSTRAINT Ilon NOT NULL,
 UNIQUE (latitudine,longitudine));

CREATE TABLE eventi
(id_evento INT CONSTRAINT Eev PRIMARY KEY,
 data_inizio TIMESTAMP CONSTRAINT EdatI NOT NULL CHECK ( data_inizio > CURRENT_TIMESTAMP ),
 data_fine TIMESTAMP CONSTRAINT EdatF NOT NULL CHECK ( data_inizio < data_fine ),
 stato CHAR(6) CONSTRAINT Estato NOT NULL CHECK ( stato IN  ('APERTO','CHIUSO') ) DEFAULT ('APERTO'),
 sport VARCHAR(30) CONSTRAINT Esport NOT NULL REFERENCES categorie ON DELETE CASCADE ON UPDATE CASCADE ,
 impianto VARCHAR(40) CONSTRAINT Eimp NOT NULL REFERENCES impianti ON DELETE CASCADE ON UPDATE CASCADE,
 organizzatore INT CONSTRAINT Eorg NOT NULL REFERENCES utenti_premium ON DELETE CASCADE ON UPDATE CASCADE ,
 limite_disiscriz SMALLINT CONSTRAINT Eldis NOT NULL CHECK ( limite_disiscriz >=0 AND limite_disiscriz < EXTRACT(DAY FROM (data_inizio - CURRENT_TIMESTAMP))));

CREATE TABLE iscrizioni
(matricola INT CONSTRAINT Imat REFERENCES utenti ON DELETE CASCADE ON UPDATE CASCADE ,
 id_evento INT CONSTRAINT iev REFERENCES eventi ON DELETE CASCADE ON UPDATE CASCADE ,
 data TIMESTAMP CONSTRAINT Idat NOT NULL DEFAULT CURRENT_TIMESTAMP,
 ruolo VARCHAR(20),
 squadra NUMERIC(1) CONSTRAINT Isq CHECK ( squadra IS NULL OR (squadra = 1 OR squadra = 2)),
 stato VARCHAR(10) CONSTRAINT Ista NOT NULL CHECK ( stato IN ('CONFERMATO','RIFIUTATO','IN ATTESA') ) DEFAULT ('IN ATTESA'),
 qualità VARCHAR(9) CONSTRAINT Iqua NOT NULL CHECK ( qualità IN ('GIOCATORE','ARBITRO')),
 PRIMARY KEY (matricola,id_evento),
 CHECK ( (qualità = 'GIOCATORE' AND squadra IS NOT NULL) OR (qualità = 'ARBITRO' AND ruolo IS NULL AND squadra IS NULL )));

CREATE TABLE squadre
(id_squadra INT CONSTRAINT Ssq PRIMARY KEY,
 nome VARCHAR(30) CONSTRAINT Snome NOT NULL,
 colore_maglia VARCHAR(20) CONSTRAINT Scm NOT NULL,
 giocatori_min SMALLINT CONSTRAINT Sgmn NOT NULL CHECK ( giocatori_min > 0 ),
 giocatori_max SMALLINT CONSTRAINT Sgmx NOT NULL CHECK ( giocatori_max >= giocatori_min ),
 note TEXT,
 definita BOOLEAN CONSTRAINT Sdef NOT NULL DEFAULT FALSE,
 descrizione TEXT CONSTRAINT Sdes NOT NULL,
 creatore INT CONSTRAINT Scre NOT NULL REFERENCES utenti_premium ON DELETE CASCADE ON UPDATE CASCADE);

CREATE TABLE candidature
(matricola INT CONSTRAINT Cmat REFERENCES utenti ON  DELETE CASCADE ON UPDATE CASCADE,
 id_squadra INT CONSTRAINT Csq REFERENCES squadre ON DELETE CASCADE ON UPDATE CASCADE,
 data DATE CONSTRAINT Cdat NOT NULL DEFAULT CURRENT_TIMESTAMP,
 ruolo VARCHAR(20),
 stato VARCHAR(10) CONSTRAINT Csta NOT NULL CHECK ( stato IN ('CONFERMATO','RIFIUTATO','IN ATTESA') ) DEFAULT ('IN ATTESA'),
 PRIMARY KEY (matricola,id_squadra));

CREATE TABLE tornei
(id_torneo INT CONSTRAINT Ttor PRIMARY KEY,
 descrizione TEXT CONSTRAINT Tdesc NOT NULL,
 modalità VARCHAR(20) CONSTRAINT Tmod NOT NULL CHECK ( modalità IN ('ELIMINAZIONE DIRETTA','GIRONI ALL ITALIANA','MISTA')),
 sponsor TEXT,
 premi TEXT,
 restrizioni TEXT,
 organizzatore INT CONSTRAINT Torg NOT NULL REFERENCES utenti_premium ON DELETE CASCADE ON UPDATE CASCADE);

CREATE TABLE evento_a_squadre
(id_evento INT CONSTRAINT EASev PRIMARY KEY REFERENCES eventi ON DELETE CASCADE ON UPDATE CASCADE,
 id_torneo INT CONSTRAINT EAStor REFERENCES tornei ON DELETE CASCADE ON UPDATE CASCADE,
 prima_squadra INT CONSTRAINT EASsq1 NOT NULL REFERENCES squadre ON DELETE CASCADE ON UPDATE CASCADE,
 seconda_squadra INT CONSTRAINT EASsq2 NOT NULL REFERENCES squadre ON DELETE CASCADE ON UPDATE CASCADE CHECK ( seconda_squadra <> prima_squadra ),
 fase VARCHAR(20) CONSTRAINT EASfase CHECK ( (id_torneo IS NULL AND fase IS NULL) OR (id_torneo IS NOT NULL AND fase IS NOT NULL)));

CREATE TABLE esiti
(id_evento INT CONSTRAINT ESev PRIMARY KEY REFERENCES eventi ON DELETE CASCADE ON UPDATE CASCADE,
 punti_squadra_1 SMALLINT CONSTRAINT ESpun1 NOT NULL CHECK ( punti_squadra_1 >= 0 ),
 punti_squadra_2 SMALLINT CONSTRAINT ESpun2 NOT NULL CHECK ( punti_squadra_2 >= 0 ));

CREATE TABLE valutazioni
(matricola INT CONSTRAINT Vmat REFERENCES utenti ON DELETE CASCADE ON UPDATE CASCADE,
 votato INT CONSTRAINT Vvot REFERENCES utenti ON DELETE CASCADE ON UPDATE CASCADE CHECK ( votato <> matricola ),
 id_evento INT CONSTRAINT Vev REFERENCES esiti ON DELETE CASCADE ON UPDATE CASCADE,
 data DATE CONSTRAINT Vdat NOT NULL DEFAULT CURRENT_DATE,
 punteggio SMALLINT CONSTRAINT Vpun NOT NULL CHECK ( punteggio BETWEEN 0 AND 10),
 commento TEXT,
 PRIMARY KEY (matricola,votato,id_evento));

CREATE TABLE statistiche
(id_evento INT CONSTRAINT STev REFERENCES esiti ON DELETE CASCADE ON UPDATE CASCADE,
 matricola INT CONSTRAINT STmat REFERENCES utenti ON DELETE CASCADE ON UPDATE CASCADE,
 punti SMALLINT CONSTRAINT STpun NOT NULL CHECK ( punti >= 0 ),
 affidabilità VARCHAR(12) CONSTRAINT STaff NOT NULL CHECK ( affidabilità IN ('IN ORARIO','IN RITARDO','SOSTITUZIONE','NO SHOW') ),
 CHECK ( (affidabilità = 'NO SHOW' OR affidabilità = 'SOSTITUZIONE') AND punti = 0 OR (affidabilità= 'IN ORARIO' OR affidabilità='IN RITARDO')),
 PRIMARY KEY (id_evento,matricola));


-- </> FUNZIONI PER IL CORRETTO FUNZIONAMENTO DELLO SCHEMA CON EVENTUALI TRIGGER (alcune potrebbero essere riportate più avanti nelle richieste specifiche)


-- FUNZIONE + TRIGGER per controlli su iscrizioni
CREATE OR REPLACE FUNCTION prevent_iscriz() RETURNS trigger AS
$prevent_iscriz$
BEGIN
IF NEW.stato IN ('CONFERMATO','RIFIUTATO')
THEN
    RAISE EXCEPTION 'l''iscrizione ha bisogno di un approvazione prima di essere accettata/rifiutata';
END IF;
IF (SELECT stato
    FROM Unige_Social_Sport.eventi
    WHERE id_evento = NEW.id_evento) = 'CHIUSO'
THEN
    RAISE EXCEPTION 'L''iscrizione non può essere effettuata su un evento chiuso';
END IF;
IF NEW.qualità='ARBITRO' AND (SELECT COUNT(matricola)
                              FROM unige_social_sport.iscrizioni
                              WHERE id_evento=NEW.id_evento AND qualità='ARBITRO' AND stato='CONFERMATO') >= 1
THEN
    RAISE EXCEPTION 'è già presente un arbitro per questo evento';
END IF;
IF (SELECT COUNT(matricola) FROM unige_social_sport.iscrizioni
                            WHERE id_evento=NEW.id_evento AND squadra = NEW.squadra AND qualità = 'GIOCATORE' AND stato='CONFERMATO') >= (SELECT numero_giocatori/2
                                                                                                                                          FROM unige_social_sport.categorie JOIN unige_social_sport.eventi e on categorie.sport = e.sport
                                                                                                                                          WHERE e.id_evento=NEW.id_evento)
THEN
    RAISE EXCEPTION 'La squadra scelta è già al completo';
END IF;
RETURN NEW;
END;
$prevent_iscriz$ language plpgsql;

CREATE OR REPLACE TRIGGER prevent_iscriz_trigger
BEFORE INSERT OR UPDATE ON iscrizioni
FOR EACH ROW WHEN ( NEW.stato != 'RIFIUTATO' ) EXECUTE FUNCTION prevent_iscriz();


-- FUNZIONE + TRIGGER per controlli su eventi
CREATE OR REPLACE FUNCTION check_state_events() RETURNS TRIGGER AS
$check_state_events$
BEGIN
IF ((((SELECT COUNT(matricola)
       FROM Unige_Social_Sport.iscrizioni I
       WHERE NEW.id_evento=I.id_evento AND I.stato='CONFERMATO' AND I.qualità='GIOCATORE') != (SELECT numero_giocatori
                                                                                               FROM Unige_Social_Sport.categorie C
                                                                                               WHERE NEW.sport=C.sport))) AND NOT EXISTS(SELECT E.id_evento
                                                                                                                                         FROM eventi E JOIN evento_a_squadre EAS on E.id_evento = EAS.id_evento))
THEN
    RAISE EXCEPTION 'Un evento non può essere chiuso se non si è raggiunto il numero dei giocatori specificato nella categoria corrispondente oppure non è associato ad un torneo';
END IF;
RETURN NEW;
END
$check_state_events$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER check_state_events_trigger
BEFORE INSERT OR UPDATE ON eventi
FOR EACH ROW WHEN ( NEW.stato = 'CHIUSO' ) EXECUTE FUNCTION check_state_events();


-- FUNZIONE + TRIGGER per controlli su inserimento/modifica per eventi a squadre formate (singoli o tornei)
CREATE OR REPLACE FUNCTION check_team_events() RETURNS TRIGGER AS
$check_team_events$
BEGIN
IF EXISTS(SELECT E.id_evento
          FROM eventi E JOIN iscrizioni I on E.id_evento = I.id_evento
          WHERE E.id_evento=NEW.id_evento)
THEN
    RAISE EXCEPTION 'L''evento inserito è considerato singolo e non inseribile in un torneo/partita a squadre';
end if;
IF ((SELECT COUNT(matricola)
     FROM squadre s JOIN candidature c on s.id_squadra = c.id_squadra
     WHERE stato='CONFERMATO' AND C.id_squadra=NEW.prima_squadra) <= (SELECT COUNT(numero_giocatori)
                                                                      FROM categorie JOIN eventi ON categorie.sport = eventi.sport
                                                                      WHERE eventi.id_evento=NEW.id_evento))
THEN
    RAISE EXCEPTION 'La prima squadra non ha abbastanza giocatori per partecipare all''evento';
end if;
IF ((SELECT COUNT(matricola)
     FROM squadre s JOIN candidature c on s.id_squadra = c.id_squadra
     WHERE stato='CONFERMATO' AND C.id_squadra=NEW.seconda_squadra) <= (SELECT COUNT(numero_giocatori)
                                                                        FROM categorie JOIN eventi ON categorie.sport = eventi.sport
                                                                        WHERE eventi.id_evento=NEW.id_evento))
THEN
    RAISE EXCEPTION 'La seconda squadra non ha abbastanza giocatori per partecipare all''evento';
END IF;
ALTER TABLE eventi DISABLE trigger check_state_events_trigger;
UPDATE eventi
SET stato='CHIUSO'
WHERE id_evento=NEW.id_evento;
ALTER TABLE eventi ENABLE TRIGGER check_state_events_trigger;
RETURN NEW;
end
$check_team_events$ language plpgsql;

CREATE OR REPLACE TRIGGER check_team_events_trigger
BEFORE INSERT OR UPDATE ON evento_a_squadre
FOR EACH ROW EXECUTE FUNCTION check_team_events();


-- FUNZIONE + TRIGGER per controlli su candidature
CREATE OR REPLACE FUNCTION prevent_cand() RETURNS trigger AS
$prevent_cand$
BEGIN
IF current_user != (SELECT username
                    FROM squadre JOIN utenti_premium UP on UP.matricola = squadre.creatore JOIN utenti U on U.matricola = UP.matricola
                    WHERE NEW.id_squadra=id_squadra) AND NEW.stato IN ('CONFERMATO','RIFIUTATO')
THEN
    RAISE EXCEPTION 'la candidatura ha bisogno di un approvazione prima di essere accettata/rifiutata';
END IF;
IF (SELECT definita
    FROM Unige_Social_Sport.squadre
    WHERE id_squadra = NEW.id_squadra) = TRUE AND (current_user != (SELECT username
                                                                    FROM squadre JOIN utenti_premium ON squadre.creatore = utenti_premium.matricola JOIN utenti ON utenti_premium.matricola = utenti.matricola
                                                                    WHERE id_squadra=NEW.id_squadra) OR (SELECT COUNT(matricola)
                                                                                                         FROM candidature
                                                                                                         WHERE id_squadra=NEW.id_squadra AND stato='CONFERMATO') < (SELECT giocatori_min
                                                                                                                                                                    FROM squadre
                                                                                                                                                                    WHERE id_squadra=NEW.id_squadra))
THEN
    RAISE EXCEPTION 'Non ci sono le condizioni necessarie per cambiare lo stato della squadra in definita';
END IF;
RETURN NEW;
END
$prevent_cand$ language plpgsql;

CREATE OR REPLACE TRIGGER prevent_cand_trigger
BEFORE INSERT OR UPDATE ON candidature
FOR EACH ROW WHEN ( NEW.stato != 'RIFIUTATO' ) EXECUTE FUNCTION prevent_cand();



-- FUNZIONE per l'approvazione di un iscrizione (evento, utente, CONFERMATO/RIFIUTATO)
CREATE OR REPLACE FUNCTION appr_iscriz(event INT,mat INT, stat VARCHAR(10)) RETURNS TEXT AS
$appr_iscriz$
DECLARE
    nominativo VARCHAR(61);
BEGIN
IF current_user != (SELECT username
                    FROM utenti U JOIN utenti_premium UP on U.matricola = UP.matricola JOIN eventi E on UP.matricola = E.organizzatore
                    WHERE id_evento=event)
THEN
RAISE EXCEPTION 'Non sei l''organizzatore dell''evento';
END IF;
IF stat NOT IN ('CONFERMATO','RIFIUTATO') OR (mat,event) NOT IN (SELECT matricola,id_evento FROM iscrizioni)
THEN
    RAISE EXCEPTION 'Errore di inserimento dati!';
END IF;
IF (SELECT stato
    FROM iscrizioni
    WHERE matricola=mat AND id_evento=event) IN ('CONFERMATO','RIFIUTATO')
THEN
    RAISE EXCEPTION 'è già stata espresso un esito per questa iscrizione';
END IF;
ALTER TABLE iscrizioni DISABLE TRIGGER prevent_iscriz_trigger;
UPDATE iscrizioni
SET stato=stat
WHERE matricola=mat AND id_evento=event;
ALTER TABLE iscrizioni ENABLE TRIGGER prevent_iscriz_trigger;
IF (SELECT COUNT(matricola)
    FROM Unige_Social_Sport.iscrizioni
    WHERE stato='CONFERMATO' AND id_evento=event AND qualità='GIOCATORE') = (SELECT numero_giocatori
                                                                             FROM Unige_Social_Sport.categorie JOIN Unige_Social_Sport.eventi E on categorie.sport = E.sport
                                                                             WHERE E.id_evento=event)
THEN
    UPDATE eventi
    SET stato='CHIUSO'
    WHERE eventi.id_evento=event;
    RAISE NOTICE 'L''evento % ha raggiunto i partecipanti necessari e verrà chiuso', event;
    UPDATE iscrizioni
    SET stato='RIFIUTATO'
    WHERE id_evento=event AND stato='IN ATTESA';
    RAISE NOTICE 'Iscrizioni in stato di attesa relative a tale evento verranno rifiutate';
END IF;
nominativo = (SELECT nome || ' ' || cognome FROM utenti WHERE matricola=mat);
RETURN 'L''utente ' || nominativo || ' è stato/a ' || stat || ' per l''evento ' || event;
END
$appr_iscriz$ LANGUAGE plpgsql;


-- FUNZIONE per la cancellazione degli eventi "scaduti"
-- ovvero quelli che sono ancora in stato APERTO e la data è recente rispetto al tempo attuale
CREATE OR REPLACE FUNCTION delete_old_events() RETURNS INT[] AS
$delete_old_events$
DECLARE
    deleted_eventi INT[];
BEGIN
DELETE FROM eventi
WHERE stato = 'APERTO' AND CURRENT_TIMESTAMP > data_inizio
RETURNING id_evento INTO deleted_eventi;
RETURN deleted_eventi;
END
$delete_old_events$ LANGUAGE plpgsql;


-- FUNZIONE per disiscriversi da un evento (evento, utente, sostituto/NULL)
CREATE OR REPLACE FUNCTION disiscriz(event INT, mat INT, sos INT) RETURNS TEXT AS
$disiscriz$
DECLARE
    richiedente VARCHAR(61);
    sostituto VARCHAR(61);
BEGIN
IF current_user != (SELECT username
                    FROM utenti
                    WHERE matricola=mat)
THEN
    RAISE EXCEPTION 'La tua matricola non corrisponde';
END IF;
sos := COALESCE(sos,0);
RAISE NOTICE '%',sos;
IF event NOT IN (SELECT id_evento
                 FROM iscrizioni
                 WHERE id_evento=event) OR mat NOT IN (SELECT matricola
                                                       FROM iscrizioni
                                                       WHERE event=id_evento AND matricola=mat) OR (sos NOT IN (SELECT matricola
                                                                                                                FROM iscrizioni
                                                                                                                WHERE event=id_evento AND matricola=sos) AND sos!=0)
THEN
    RAISE EXCEPTION 'Errore in inserimento dati';
END IF;
IF (SELECT stato
    FROM iscrizioni
    WHERE matricola=mat AND id_evento=event) != 'CONFERMATO'
THEN
    RAISE EXCEPTION 'Devi essere confermato all''evento per disiscriverti';
END IF;
IF (SELECT stato
    FROM eventi
    WHERE id_evento=event) = 'CHIUSO'
THEN
    RAISE EXCEPTION 'Non si possono effettuare disiscrizioni su eventi chiusi';
end if;
IF (SELECT stato
    FROM iscrizioni
    WHERE matricola=sos AND id_evento=event) IN ('CONFERMATO','RIFIUTATO')
THEN
    RAISE EXCEPTION 'Il sostituto deve essere un utente che è in attesa';
END IF;
IF ((SELECT data_inizio
     FROM eventi WHERE id_evento=event) < CURRENT_TIMESTAMP + (SELECT limite_disiscriz
                                                               FROM eventi
                                                               WHERE id_evento=event) * INTERVAL '1 day') AND sos!=0
THEN
    RAISE EXCEPTION 'Il tempo utile per disiscriversi è terminato, indicare un sostituto';
END IF;
IF (SELECT qualità
    FROM iscrizioni
    WHERE id_evento=event AND matricola=mat) = 'ARBITRO' AND (SELECT qualità
                                                              FROM iscrizioni
                                                              WHERE id_evento=event AND matricola=sos) != 'ARBITRO'
THEN
    RAISE EXCEPTION 'La tua qualità è ARBITRO ma quella indicata nel sostituto è GIOCATORE';
END IF;
ALTER TABLE iscrizioni DISABLE TRIGGER prevent_iscriz_trigger;
DELETE FROM iscrizioni
WHERE matricola=mat AND id_evento=event;
ALTER TABLE iscrizioni ENABLE TRIGGER prevent_iscriz_trigger;
IF sos != 0
THEN
    richiedente = (SELECT nome || ' ' || cognome AS nominativo
                   FROM utenti
                   WHERE matricola=mat);
    sostituto = (SELECT nome || ' ' || cognome AS nominativo
                 FROM utenti
                 WHERE matricola=sos);
    RETURN 'L''utente ' || richiedente || ' è stato sostituito da ' || sostituto || ' per l''evento ' || event;
END IF;
richiedente = (SELECT nome || ' ' || cognome AS nominativo
               FROM utenti
               WHERE matricola=mat);
RETURN 'L''utente ' || richiedente || ' si è disiscritto dall''evento ' || event;
END
$disiscriz$ language plpgsql;


-- FUNZIONE per l'approvazione delle candidature (squadra, utente, CONFERMATO/RIFIUTATO)
CREATE OR REPLACE FUNCTION appr_cand(sq INT,mat INT, stat VARCHAR(10)) RETURNS TEXT AS
$appr_iscriz$
DECLARE
    nominativo VARCHAR(61);
BEGIN
IF current_user != (SELECT username
                    FROM utenti U JOIN utenti_premium UP on U.matricola = UP.matricola JOIN squadre S on UP.matricola = S.creatore
                    WHERE id_squadra=sq)
THEN
    RAISE EXCEPTION 'Non sei il creatore della squadra';
END IF;
IF stat NOT IN ('CONFERMATO','RIFIUTATO') OR (mat,sq) NOT IN (SELECT matricola,id_squadra
                                                              FROM candidature)
THEN
    RAISE EXCEPTION 'Errore di inserimento dati';
END IF;
IF (SELECT stato
    FROM candidature
    WHERE matricola=mat AND id_squadra=sq) IN ('CONFERMATO','RIFIUTATO')
THEN
    RAISE EXCEPTION 'è già stata espresso un esito per questa iscrizione';
END IF;
ALTER TABLE candidature DISABLE TRIGGER prevent_cand_trigger;
UPDATE candidature
SET stato=stat
WHERE matricola=mat AND id_squadra=sq;
ALTER TABLE candidature ENABLE TRIGGER prevent_cand_trigger;
IF (SELECT COUNT(matricola)
    FROM Unige_Social_Sport.candidature
    WHERE stato='CONFERMATO' AND id_squadra=sq) = (SELECT giocatori_max
                                                   FROM Unige_Social_Sport.squadre
                                                   WHERE id_squadra=sq)
THEN
    UPDATE squadre
    SET definita=TRUE
    WHERE id_squadra=sq;
    RAISE NOTICE 'La squadra % ha raggiunto i partecipanti massimi', sq;
    UPDATE candidature
    SET stato='RIFIUTATO'
    WHERE id_squadra=sq AND stato='IN ATTESA';
    RAISE NOTICE 'Candidature in stato di attesa relative a tale squadra verranno rifiutate';
END IF;
nominativo = (SELECT nome || ' ' || cognome
              FROM utenti
              WHERE matricola=mat);
RETURN 'L''utente ' || nominativo || ' è stato/a ' || stat || ' per la squadra ' || sq;
END
$appr_iscriz$ LANGUAGE plpgsql;

/*************************************************************************************************************************************************************************/ 
--1b. Popolamento 
/*************************************************************************************************************************************************************************/ 


/* inserire qui i comandi SQL per il popolamento 'in piccolo' di tale base di dati (utile per il test dei vincoli e delle operazioni in parte 2.) */

-- Inserimento UTENTI
INSERT INTO utenti (matricola, username, password, nome, cognome, anno_nascita, luogo_nascita, foto, telefono, corso, affidabile)
VALUES
(1, 'postgres', 'password1', 'Mario', 'Rossi', 2003, 'Imperia', decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'), '3330123456', 'Informatica', FALSE),
(2, 'giuseppe_verdi', 'password2', 'Giuseppe', 'Verdi', 1998, 'Genova', decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'), '3330123457', 'Architettura', FALSE),
(3, 'anna_bianchi', 'password3', 'Anna', 'Bianchi', 1996, 'La Spezia', decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'), '3330123458', 'Lettere', TRUE),
(4, 'carlo_rossi', 'password4', 'Carlo', 'Rossi', 1999, 'Genova', decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'), '3330123459', 'Medicina', FALSE),
(5, 'maria_russo', 'password5', 'Maria', 'Russo', 2002, 'Genova', decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'), '3330123460', 'Economia', TRUE),
(6, 'luigi_ferrari', 'password6', 'Luigi', 'Ferrari', 1994, 'Savona', decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'), '3330123461', 'Ingegneria', TRUE),
(7, 'laura_esposito', 'password7', 'Laura', 'Esposito', 1995, 'Imperia', decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'), '3330123462', 'Medicina', TRUE),
(8, 'paolo_galli', 'password8', 'Paolo', 'Galli', 1997, 'Genova', decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'), '3330123463', 'Economia', FALSE),
(9, 'francesca_conti', 'password9', 'Francesca', 'Conti', 1993, 'La Spezia', decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'), '3330123464', 'Giurisprudenza', TRUE),
(10, 'giovanni_pellegrini', 'password10', 'Giovanni', 'Pellegrini', 1996, 'La Spezia', decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'), '3330123465', 'Informatica', TRUE),
(11, 'elena_gatti', 'password11', 'Elena', 'Gatti', 2003, 'Genova', decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'), '3330123466', 'Chimica', TRUE),
(12, 'andrea_rossi', 'password12', 'Andrea', 'Rossi', 1998, 'Genova', decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'), '3330123467', 'Architettura', TRUE),
(13, 'silvia_ferrari', 'password13', 'Silvia', 'Ferrari', 2000, 'Genova', decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'), '3330123468', 'Informatica', TRUE),
(14, 'luca_bianchi', 'password14', 'Luca', 'Bianchi', 2001, 'Genova', decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'), '3330123469', 'Economia', TRUE),
(15, 'valeria_romano', 'password15', 'Valeria', 'Romano', 1999, 'Genova', decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'), '3330123470', 'Medicina', TRUE),
(16, 'fabio_ferrara', 'password16', 'Fabio', 'Ferrara', 1994, 'Savona', decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'), '3330123475', 'Ingegneria', TRUE);


-- Inserimento CATEGORIE
INSERT INTO categorie (sport, regolamento, numero_giocatori, foto)
VALUES
('Calcio a 5','Regolamento Calcio',10, decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex')),
('Basket','Regolamento Basket',10, decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex')),
('Beach Volley','Regolamento Pallavolo',4, decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex')),
('Tennis','Regolamento Tennis',4, decode('89504E470D0A1A0A0000000D4948445200000001000000010100000000907C3B6100000001004944415478DA63EC7806000000060049454E44AE426082', 'hex'));


-- Inserimento UTENTI PREMIUM
INSERT INTO utenti_premium (matricola)
VALUES
(1),
(4),
(9),
(14),
(15);


-- Inserimento IMPIANTI
INSERT INTO impianti (nome, via, telefono, email, latitudine, longitudine)
VALUES
('Centro Sportivo Aurora', 'Via Garibaldi 10', '0123456789', 'centrosportivo@gmail.com', 45.46427, 9.18951),
('Palazzetto dello Sport Centrale', 'Via Roma 20', '9876543210', 'palazzettosport@gmail.com', 41.89474, 12.47563),
('Campo Sportivo Vittoria', 'Via dei Pini 5', '0365124789', 'campotennispiscina@gmail.com', 44.40565, 8.94625),
('Club Sport Riviera', 'Via Europa 15', '0365478912', 'clubsport@gmail.com', 51.50735, -0.12776);


-- Inserimento EVENTI
INSERT INTO eventi (id_evento, data_inizio, data_fine, sport, impianto, organizzatore, limite_disiscriz) VALUES
(1, '2024-09-01 9:00:00', '2024-09-1 10:00:00', 'Basket', 'Centro Sportivo Aurora', 1, 5),
(2, '2024-09-05 14:35:00', '2024-09-05 16:00:00', 'Calcio a 5', 'Palazzetto dello Sport Centrale', 1, 6),
(3, '2024-09-08 10:00:00', '2024-09-08 11:30:00', 'Beach Volley', 'Campo Sportivo Vittoria', 1, 8),
(4, '2024-09-15 15:30:00', '2024-09-15 17:00:00', 'Tennis', 'Club Sport Riviera', 1, 7),
(5, '2024-09-18 09:00:00', '2024-09-18 10:15:00', 'Tennis', 'Centro Sportivo Aurora', 1, 5),
(6, '2024-09-21 10:30:00', '2024-09-21 12:00:00', 'Tennis', 'Palazzetto dello Sport Centrale', 1, 3);


-- Inserimento ISCRIZIONI (ARBITRI)
INSERT INTO iscrizioni (matricola, id_evento, qualità) VALUES
(16,1,'ARBITRO'),
(13,2,'ARBITRO'),
(14,3,'ARBITRO'),
(15,2,'ARBITRO'),
(10,3,'ARBITRO');


-- Inserimento ISCRIZIONI (GIOCATORI)
INSERT INTO iscrizioni (matricola, id_evento, squadra, qualità) VALUES
-- evento 1 --> Basket
(1, 1, 1, 'GIOCATORE'),
(2, 1, 1, 'GIOCATORE'),
(3, 1, 1, 'GIOCATORE'),
(4, 1, 1, 'GIOCATORE'),
(5, 1, 1, 'GIOCATORE'),
(6, 1, 1, 'GIOCATORE'),
(7, 1, 2, 'GIOCATORE'),
(8, 1, 2, 'GIOCATORE'),
(9, 1, 2, 'GIOCATORE'),
(10, 1, 2, 'GIOCATORE'),
(11, 1, 2, 'GIOCATORE'),
(12, 1, 2, 'GIOCATORE'),
(13, 1, 2, 'GIOCATORE'),
-- evento 2 --> Calcio a 5
(1, 2, 1, 'GIOCATORE'),
(2, 2, 1, 'GIOCATORE'),
(3, 2, 2, 'GIOCATORE'),
(4, 2, 1, 'GIOCATORE'),
(5, 2, 1, 'GIOCATORE'),
(6, 2, 2, 'GIOCATORE'),
(7, 2, 2, 'GIOCATORE'),
(8, 2, 2, 'GIOCATORE'),
(9, 2, 1, 'GIOCATORE'),
(10, 2, 2, 'GIOCATORE'),
-- evento 3 --> Beach Volley
(1,3,1,'GIOCATORE'),
(2,3,1,'GIOCATORE'),
(3,3,2,'GIOCATORE'),
(4,3,2,'GIOCATORE'),
(12,3,1,'GIOCATORE'),
-- evento 4 --> Tennis
(1,4,1,'GIOCATORE'),
(2,4,1,'GIOCATORE'),
(3,4,2,'GIOCATORE'),
(4,4,2,'GIOCATORE');


-- Conferma degli arbitri per eventi 1,2,3
-- le matricole in attesa 13 e 14 vengono automaticamente rifiutate
-- poichè è già presente un arbitro confermato
SELECT appr_iscriz(1,16,'CONFERMATO');
SELECT appr_iscriz(2,15,'CONFERMATO');
SELECT appr_iscriz(3,10,'CONFERMATO');


-- Evento 1 --> Basket (10 giocatori richiesti)
SELECT appr_iscriz(1,1,'CONFERMATO');
SELECT appr_iscriz(1,2,'CONFERMATO');
SELECT appr_iscriz(1,3,'RIFIUTATO');
SELECT appr_iscriz(1,4,'CONFERMATO');
SELECT appr_iscriz(1,5,'CONFERMATO');
SELECT appr_iscriz(1,6,'CONFERMATO');
SELECT appr_iscriz(1,7,'CONFERMATO');
SELECT appr_iscriz(1,8,'CONFERMATO');
SELECT appr_iscriz(1,9,'CONFERMATO');
SELECT appr_iscriz(1,10,'CONFERMATO');

-- l'utente 1 richiede la disiscrizione non specificando nessun sostituto
-- in quanto esso sia ancora nel tempo limite di disiscrizione
SELECT disiscriz(1,1,NULL);

SELECT appr_iscriz(1,11,'CONFERMATO');
SELECT appr_iscriz(1,13,'CONFERMATO');
-- la matricola in attesa 12 viene automaticamente rifiutata,
-- in quanto l'evento ha raggiunto i giocatori necessari


-- Evento 2 --> Calcio a 5 (10 giocatori richiesti)
SELECT appr_iscriz(2,1,'CONFERMATO');
SELECT appr_iscriz(2,2,'CONFERMATO');
SELECT appr_iscriz(2,3,'CONFERMATO');
SELECT appr_iscriz(2,4,'CONFERMATO');
SELECT appr_iscriz(2,5,'CONFERMATO');
SELECT appr_iscriz(2,6,'CONFERMATO');
SELECT appr_iscriz(2,7,'CONFERMATO');
SELECT appr_iscriz(2,8,'CONFERMATO');
SELECT appr_iscriz(2,9,'CONFERMATO');
SELECT appr_iscriz(2,10,'CONFERMATO');
-- tutte le iscrizioni fatte a tale evento vengono confermate


-- Evento 3 --> Beach Volley (4 giocatori richiesti)
SELECT appr_iscriz(3,1,'CONFERMATO');
SELECT appr_iscriz(3,2,'CONFERMATO');
SELECT appr_iscriz(3,3,'CONFERMATO');
SELECT appr_iscriz(3,4,'CONFERMATO');
-- la matricola in attesa 12 viene automaticamente rifiutata,
-- in quanto l'evento ha raggiunto i giocatori necessari


-- Evento 4 --> Tennis (4 giocatori richiesti)
SELECT appr_iscriz(4,1,'CONFERMATO');
SELECT appr_iscriz(4,2,'CONFERMATO');
SELECT appr_iscriz(4,3,'CONFERMATO');
SELECT appr_iscriz(4,4,'CONFERMATO');
-- tutte le iscrizioni fatte a tale evento vengono confermate


-- Inserimento SQUADRE
INSERT INTO squadre (id_squadra, nome, colore_maglia, giocatori_min, giocatori_max, definita, descrizione, creatore) VALUES
(1, 'Team A', 'Red', 2, 4, FALSE, 'description for Team A', 1),
(2, 'Team B', 'Blue', 2, 4, FALSE, 'description for Team B', 1),
(3, 'Team C', 'Green', 2, 4, FALSE, 'description for Team C', 1),
(4, 'Team D', 'Yellow', 2, 4, FALSE, 'description for Team D', 1);


-- Inserimento CANDIDATURE
INSERT INTO candidature (matricola, id_squadra) VALUES
-- squadra 1
(1,1),
(2,1),
(3,1),
(4,1),
(5,1),
-- squadra 2
(5,2),
(6,2),
(7,2),
(8,2),
(9,2),
-- squadra 3
(9,3),
(10,3),
(11,3),
(12,3),
-- squadra 4
(13,4),
(14,4),
(15,4),
(16,4);


-- Squadra 1
SELECT appr_cand(1,1,'CONFERMATO');
SELECT appr_cand(1,2,'CONFERMATO');
SELECT appr_cand(1,3,'CONFERMATO');
SELECT appr_cand(1,5,'RIFIUTATO');
SELECT appr_cand(1,4,'CONFERMATO');
-- tutti gli utenti che hanno richiesto candidatura hanno una risposta


-- Squadra 2
SELECT appr_cand(2,5,'CONFERMATO');
SELECT appr_cand(2,6,'CONFERMATO');
SELECT appr_cand(2,7,'CONFERMATO');
SELECT appr_cand(2,8,'CONFERMATO');
-- la matricola in attesa 9 viene automaticamente rifiutata
-- in quanto la squadra ha raggiunto i giocatori massimi indicati


-- Squadra 3
SELECT appr_cand(3,9,'CONFERMATO');
SELECT appr_cand(3,10,'CONFERMATO');
SELECT appr_cand(3,11,'CONFERMATO');
SELECT appr_cand(3,12,'CONFERMATO');
-- tutti gli utenti che hanno richiesto candidatura hanno una risposta


-- Squadra 4
SELECT appr_cand(4,13,'CONFERMATO');
SELECT appr_cand(4,14,'CONFERMATO');
SELECT appr_cand(4,15,'CONFERMATO');
SELECT appr_cand(4,16,'CONFERMATO');


-- Inserimento TORNEI
INSERT INTO tornei (id_torneo, descrizione, modalità, organizzatore) VALUES
(1,'Torneo Tennis','ELIMINAZIONE DIRETTA',1);


-- Inserimento EVENTO_A_SQUADRE
INSERT INTO evento_a_squadre (id_evento, id_torneo, prima_squadra, seconda_squadra, fase) VALUES
-- è riferito al torneo 1
(5,1,1,2,'FINALE'),
-- non è riferito a nessun torneo
(6,null,3,4,null);


-- Inserimento ESITI
INSERT INTO esiti (id_evento, punti_squadra_1, punti_squadra_2) VALUES
(1,62,55),
(2,4,5),
(3,2,1),
(4,3,2),
(5,2,3),
(6,1,3);


-- Inserimento STATISTICHE
INSERT INTO statistiche (id_evento, matricola, punti, affidabilità) VALUES
(1,1,0,'SOSTITUZIONE'),
(1,2,15,'IN RITARDO'),
(2,8,1,'IN RITARDO'),
(3,4,20,'IN RITARDO'),
(4,4,6,'IN RITARDO'),
(5,4,0,'NO SHOW');


-- Inserimento VALUTAZIONI
INSERT INTO valutazioni (matricola, votato, id_evento, punteggio) VALUES
(1,6,1,6),
(3,6,1,8),
(1,3,4,10),
(2,3,4,10),
(4,3,4,10),
(1,3,5,10),
(2,3,5,10),
(4,3,5,10),
(5,3,5,10),
(6,3,5,10),
(7,3,5,10),
(8,3,5,10);

/*************************************************************************************************************************************************************************/ 
--2. Vista
/* Vista Programma che per ogni impianto e mese riassume tornei e eventi che si svolgono in tale impianto, evidenziando in particolare per ogni categoria il numero di tornei, il numero di eventi, il numero di partecipanti coinvolti e di quanti diversi corsi di studio, la durata totale (in termini di minuti) di utilizzo e la percentuale di utilizzo rispetto alla disponibilit� complessiva (minuti totali nel mese in cui l�impianto � utilizzabile) */
/*************************************************************************************************************************************************************************/ 


/* inserire qui i comandi SQL per la creazione della vista senza rimuovere la specifica nel commento precedente */

/* ~ NOTE
 - Assumiamo che in un impianto non ci possano essere due eventi sovrapposti in stato CHIUSO
 - Assumiamo che come partecipanti ad un evento si intenda anche l'ARBITRO  */

CREATE OR REPLACE VIEW Programma AS
SELECT I.nome,
       EXTRACT(MONTH FROM data_inizio) AS mese,
       E.sport,
       COUNT(DISTINCT E.id_evento) AS numero_eventi,
       COUNT(DISTINCT EAS.id_torneo) AS numero_tornei,
       COUNT(U.matricola) AS numero_partecipanti,
       COUNT(DISTINCT U.corso) AS numero_corsi_coinvolti,
       ROUND(SUM(DISTINCT(EXTRACT(EPOCH FROM(E.data_fine - E.data_inizio)))/60)) AS minuti_utilizzo,
       ROUND(SUM(DISTINCT(EXTRACT(EPOCH FROM(E.data_fine - E.data_inizio))/60)) / (SELECT SUM(EXTRACT(EPOCH FROM(data_fine - data_inizio))/60)
                                                                                   FROM eventi JOIN impianti I2 ON eventi.impianto = I2.nome
                                                                                   WHERE I2.nome=I.nome) * 100,2) || '%' AS precentuale_utilizzo
FROM eventi E JOIN categorie C on E.sport = C.sport JOIN impianti I on I.nome = E.impianto LEFT JOIN evento_a_squadre EAS on E.id_evento = EAS.id_evento JOIN (SELECT E.id_evento,U1.matricola,U1.corso
                                                                                                                                                               FROM utenti U1 JOIN iscrizioni ISC on U1.matricola = ISC.matricola JOIN eventi E on E.id_evento = ISC.id_evento
                                                                                                                                                               WHERE ISC.stato='CONFERMATO'
                                                                                                                                                               UNION
                                                                                                                                                               SELECT E.id_evento,U2.matricola,U2.corso
                                                                                                                                                               FROM utenti U2 JOIN candidature CA on U2.matricola = CA.matricola JOIN squadre S on CA.id_squadra = S.id_squadra JOIN evento_a_squadre EASC on S.id_squadra = EASC.prima_squadra OR S.id_squadra = EASC.seconda_squadra JOIN eventi E on E.id_evento = EASC.id_evento
                                                                                                                                                               WHERE CA.stato='CONFERMATO') U ON U.id_evento=E.id_evento
WHERE E.stato = 'CHIUSO'
GROUP BY I.nome, mese, E.sport;

/*************************************************************************************************************************************************************************/ 
--3. Interrogazioni
/*************************************************************************************************************************************************************************/ 

/*************************************************************************************************************************************************************************/ 
/* 3a: Determinare gli utenti che si sono candidati come giocatori e non sono mai stati accettati e quelli che sono stati accettati tutte le volte che si sono candidati */
/*************************************************************************************************************************************************************************/ 


/* inserire qui i comandi SQL per la creazione della query senza rimuovere la specifica nel commento precedente */ 

/* ~ NOTE
   - come candidature ad eventi intendiamo sono singole iscrizioni ad essi (quindi non consideriamo la parte delle squadre)
   - Non consideriamo gli utenti che sono in attesa di una approvazione  */

SELECT DISTINCT U.matricola, U.nome || ' ' || U.cognome AS nominativo
FROM utenti U JOIN iscrizioni I on U.matricola = I.matricola
WHERE stato='CONFERMATO' AND qualità='GIOCATORE' AND NOT EXISTS(SELECT U2.matricola
                                                                FROM utenti U2 JOIN iscrizioni I2 on U2.matricola = I2.matricola
                                                                WHERE U.matricola=U2.matricola AND I2.stato='RIFIUTATO' AND I2.qualità='GIOCATORE')
UNION
SELECT DISTINCT U.matricola, U.nome || ' ' || U.cognome AS nominativo
FROM utenti U JOIN iscrizioni I on U.matricola = I.matricola
WHERE stato='RIFIUTATO' AND qualità='GIOCATORE' AND NOT EXISTS(SELECT U2.matricola
                                                               FROM utenti U2 JOIN iscrizioni I2 on U2.matricola = I2.matricola
                                                               WHERE U.matricola=U2.matricola AND I2.stato='CONFERMATO' AND I2.qualità='GIOCATORE');

/*************************************************************************************************************************************************************************/ 
/* 3b: determinare gli utenti che hanno partecipato ad almeno un evento di ogni categoria */
/*************************************************************************************************************************************************************************/ 


/* inserire qui i comandi SQL per la creazione della query senza rimuovere la specifica nel commento precedente */ 

SELECT DISTINCT U.matricola, U.nome || ' ' || U.cognome AS nominativo
FROM (SELECT E1.id_evento,U1.matricola,U1.nome,U1.cognome
      FROM utenti U1 JOIN iscrizioni ISC on U1.matricola = ISC.matricola JOIN eventi E1 on ISC.id_evento = E1.id_evento
      WHERE ISC.stato='CONFERMATO'
      UNION
      SELECT E2.id_evento,U2.matricola,U2.nome,U2.cognome
      FROM utenti U2 JOIN candidature CA on U2.matricola = CA.matricola JOIN squadre S on CA.id_squadra = S.id_squadra JOIN evento_a_squadre EASC on S.id_squadra = EASC.prima_squadra OR S.id_squadra = EASC.seconda_squadra JOIN eventi E2 on EASC.id_evento = E2.id_evento
      WHERE CA.stato='CONFERMATO') U JOIN eventi E ON U.id_evento=E.id_evento JOIN categorie C on E.sport = C.sport
WHERE E.stato='CHIUSO'
GROUP BY matricola,nominativo
HAVING COUNT(DISTINCT C.sport) = (SELECT COUNT(sport)
                                  FROM categorie);

/*************************************************************************************************************************************************************************/ 
/* 3c: determinare per ogni categoria il corso di laurea pi� attivo in tale categoria, cio� quello i cui studenti hanno partecipato al maggior numero di eventi (singoli o all�interno di tornei) di tale categoria */
/*************************************************************************************************************************************************************************/ 


/* inserire qui i comandi SQL per la creazione della query senza rimuovere la specifica nel commento precedente */ 

SELECT E.sport, U.corso
FROM (SELECT E1.id_evento,U1.matricola,U1.corso
      FROM utenti U1 JOIN iscrizioni ISC on U1.matricola = ISC.matricola JOIN eventi E1 on ISC.id_evento = E1.id_evento
      WHERE ISC.stato='CONFERMATO'
      UNION
      SELECT E2.id_evento,U2.matricola,U2.corso
      FROM utenti U2 JOIN candidature CA on U2.matricola = CA.matricola JOIN squadre S on CA.id_squadra = S.id_squadra JOIN evento_a_squadre EASC on S.id_squadra = EASC.prima_squadra OR S.id_squadra = EASC.seconda_squadra JOIN eventi E2 on EASC.id_evento = E2.id_evento
      WHERE CA.stato='CONFERMATO') U JOIN eventi E ON U.id_evento=E.id_evento
GROUP BY sport, corso
HAVING COUNT(*) >= ALL (SELECT COUNT(*)
                        FROM (SELECT E1_S.id_evento,U1_S.matricola,U1_S.corso
                              FROM utenti U1_S JOIN iscrizioni ISC_S on U1_S.matricola = ISC_S.matricola JOIN eventi E1_S on ISC_S.id_evento = E1_S.id_evento
                              WHERE ISC_S.stato='CONFERMATO'
                              UNION
                              SELECT E2_S.id_evento,U2_S.matricola,U2_S.corso
                              FROM utenti U2_S JOIN candidature CA_S on U2_S.matricola = CA_S.matricola JOIN squadre S_S on CA_S.id_squadra = S_S.id_squadra JOIN evento_a_squadre EASC_S on S_S.id_squadra = EASC_S.prima_squadra OR S_S.id_squadra = EASC_S.seconda_squadra JOIN eventi E2_S on EASC_S.id_evento = E2_S.id_evento
                              WHERE CA_S.stato='CONFERMATO') U_S JOIN eventi E_S ON U_S.id_evento=E_S.id_evento
                        WHERE E.sport=E_S.sport
                        GROUP BY E.sport,U_S.corso);

/*************************************************************************************************************************************************************************/ 
--4. Funzioni
/*************************************************************************************************************************************************************************/ 

/*************************************************************************************************************************************************************************/ 
/* 4a: funzione che effettua la conferma di un giocatore quale componente di una squadra, realizzando gli opportuni controlli */
/*************************************************************************************************************************************************************************/ 


/* inserire qui i comandi SQL per la creazione della funzione senza rimuovere la specifica nel commento precedente */ 

/* ~ NOTE
   - abbiamo aggiunto anche un trigger per facilitare l'implementazione e assicurare consistenza nei dati  */

-- FUNZIONE + TRIGGER per controlli su candidature
CREATE OR REPLACE FUNCTION prevent_cand() RETURNS trigger AS
$prevent_cand$
BEGIN
IF current_user != (SELECT username
                    FROM squadre JOIN utenti_premium UP on UP.matricola = squadre.creatore JOIN utenti U on U.matricola = UP.matricola
                    WHERE NEW.id_squadra=id_squadra) AND NEW.stato IN ('CONFERMATO','RIFIUTATO')
THEN
    RAISE EXCEPTION 'la candidatura ha bisogno di un approvazione prima di essere accettata/rifiutata';
END IF;
IF (SELECT definita
    FROM Unige_Social_Sport.squadre
    WHERE id_squadra = NEW.id_squadra) = TRUE AND (current_user != (SELECT username
                                                                    FROM squadre JOIN utenti_premium ON squadre.creatore = utenti_premium.matricola JOIN utenti ON utenti_premium.matricola = utenti.matricola
                                                                    WHERE id_squadra=NEW.id_squadra) OR (SELECT COUNT(matricola)
                                                                                                         FROM candidature
                                                                                                         WHERE id_squadra=NEW.id_squadra AND stato='CONFERMATO') < (SELECT giocatori_min
                                                                                                                                                                    FROM squadre
                                                                                                                                                                    WHERE id_squadra=NEW.id_squadra))
THEN
    RAISE EXCEPTION 'Non ci sono le condizioni necessarie per cambiare lo stato della squadra in definita';
END IF;
RETURN NEW;
END
$prevent_cand$ language plpgsql;

CREATE OR REPLACE TRIGGER prevent_cand_trigger
BEFORE INSERT OR UPDATE ON candidature
FOR EACH ROW WHEN ( NEW.stato != 'RIFIUTATO' ) EXECUTE FUNCTION prevent_cand();


-- FUNZIONE per l'approvazione delle candidature (squadra, utente, CONFERMATO/RIFIUTATO)
CREATE OR REPLACE FUNCTION appr_cand(sq INT,mat INT, stat VARCHAR(10)) RETURNS TEXT AS
$appr_iscriz$
DECLARE
    nominativo VARCHAR(61);
BEGIN
IF current_user != (SELECT username
                    FROM utenti U JOIN utenti_premium UP on U.matricola = UP.matricola JOIN squadre S on UP.matricola = S.creatore
                    WHERE id_squadra=sq)
THEN
    RAISE EXCEPTION 'Non sei il creatore della squadra';
END IF;
IF stat NOT IN ('CONFERMATO','RIFIUTATO') OR (mat,sq) NOT IN (SELECT matricola,id_squadra
                                                              FROM candidature)
THEN
    RAISE EXCEPTION 'Errore di inserimento dati';
END IF;
IF (SELECT stato
    FROM candidature
    WHERE matricola=mat AND id_squadra=sq) IN ('CONFERMATO','RIFIUTATO')
THEN
    RAISE EXCEPTION 'è già stata espresso un esito per questa iscrizione';
END IF;
ALTER TABLE candidature DISABLE TRIGGER prevent_cand_trigger;
UPDATE candidature
SET stato=stat
WHERE matricola=mat AND id_squadra=sq;
ALTER TABLE candidature ENABLE TRIGGER prevent_cand_trigger;
IF (SELECT COUNT(matricola)
    FROM Unige_Social_Sport.candidature
    WHERE stato='CONFERMATO' AND id_squadra=sq) = (SELECT giocatori_max
                                                   FROM Unige_Social_Sport.squadre
                                                   WHERE id_squadra=sq)
THEN
    UPDATE squadre
    SET definita=TRUE
    WHERE id_squadra=sq;
    RAISE NOTICE 'La squadra % ha raggiunto i partecipanti massimi', sq;
    UPDATE candidature
    SET stato='RIFIUTATO'
    WHERE id_squadra=sq AND stato='IN ATTESA';
    RAISE NOTICE 'Candidature in stato di attesa relative a tale squadra verranno rifiutate';
END IF;
nominativo = (SELECT nome || ' ' || cognome
              FROM utenti
              WHERE matricola=mat);
RETURN 'L''utente ' || nominativo || ' è stato/a ' || stat || ' per la squadra ' || sq;
END
$appr_iscriz$ LANGUAGE plpgsql;

/*************************************************************************************************************************************************************************/ 
/* 4b1: funzione che dato un giocatore ne calcoli il livello */

/* 4b2: funzione corrispondente alla seguente query parametrica: data una categoria e un corso di studi, determinare la frazione di partecipanti a eventi di quella categoria di genere femminile sul totale dei partecipanti provenienti da quel corso di studi */
/*************************************************************************************************************************************************************************/ 


/* inserire qui i comandi SQL per la creazione della funzione lasciando la specifica nel commento precedente corrispondente alla funzione realizzata tra le due alternative proposte per b., a seconda che il livello del giocatore sia memorizzato o meno */ 

/* ~ NOTE
   ■ il calcolo del livello è strutturato nel seguente modo (partendo da 60 e non scendendo mai sotto di esso) :
   1) percentuale delle partite giocate per tale categorie (peso 20%)
   2) percentuale delle partite vinte per tale categoria (peso 30%)
   3) media valutazione per tale categoria (peso 30%)
   4) percentuale presenza in orario sulle partite giocate per tale categoria (peso 20%)

   - Nel conteggio delle partite giocate per un giocatore in una categoria abbiamo commentato il controllo
     sul fatto che la data attuale deve aver superato quella dell'evento ma per facilitare prove/controlli
     lo abbiamo lasciato così  */

-- FUNZIONE per il calcolo del livello per categoria (utente, categoria)
CREATE OR REPLACE FUNCTION level(mat INT, sp VARCHAR(30)) RETURNS SMALLINT AS
$level$
DECLARE
    tot_eventi SMALLINT;    -- eventi totali nel database per la categoria specificata
    part_gioc SMALLINT;     -- le partite giocate dalla matricola inserita per tale categoria
    n_vittorie SMALLINT;    -- numero di vittorie della matricola nella categoria
    aff SMALLINT;           -- numero di volte che l'utente non è arrivato in orario (no show, sostit, in ritardo)
BEGIN
IF mat NOT IN (SELECT matricola
               FROM utenti)
 OR sp NOT IN (SELECT sport
               FROM categorie)
THEN
    RAISE EXCEPTION 'Errore di inserimento dei dati';
END IF;
tot_eventi = (SELECT COUNT(id_evento)
              FROM eventi
              WHERE sport=sp);
part_gioc = (SELECT COUNT(DISTINCT E.id_evento)
             FROM eventi E JOIN iscrizioni I on E.id_evento = I.id_evento JOIN utenti U on U.matricola = I.matricola
             WHERE I.stato='CONFERMATO' AND E.stato='CHIUSO' AND U.matricola=mat AND /*data_fine<CURRENT_TIMESTAMP AND*/ sport=sp) + (SELECT COUNT(DISTINCT E.id_evento)
                                                                                                                                      FROM eventi E JOIN evento_a_squadre EAS on E.id_evento = EAS.id_evento JOIN squadre S on S.id_squadra = EAS.prima_squadra OR S.id_squadra = EAS.seconda_squadra JOIN candidature C on S.id_squadra = C.id_squadra JOIN utenti U on U.matricola = C.matricola
                                                                                                                                      WHERE sport=sp);
aff = (SELECT COUNT(DISTINCT eventi.id_evento)
       FROM statistiche JOIN eventi ON eventi.id_evento=statistiche.id_evento
       WHERE affidabilità <> 'IN ORARIO' AND matricola=mat AND sport=sp);
n_vittorie = (SELECT COUNT(DISTINCT esiti.id_evento)
              FROM esiti JOIN eventi ON eventi.id_evento=esiti.id_evento JOIN iscrizioni I on eventi.id_evento = I.id_evento
              WHERE punti_squadra_1>punti_squadra_2 AND I.stato='CONFERMATO' AND sport=sp AND squadra=1 AND matricola=mat)
            +(SELECT COUNT(DISTINCT esiti.id_evento)
              FROM esiti JOIN eventi ON eventi.id_evento=esiti.id_evento JOIN iscrizioni I on eventi.id_evento = I.id_evento
              WHERE punti_squadra_1<punti_squadra_2 AND I.stato='CONFERMATO' AND sport=sp AND squadra=2 AND matricola=mat)
            +(SELECT COUNT(DISTINCT esiti.id_evento)
              FROM esiti JOIN eventi ON eventi.id_evento=esiti.id_evento JOIN evento_a_squadre EAS on eventi.id_evento = EAS.id_evento JOIN squadre S1 on S1.id_squadra = EAS.prima_squadra JOIN candidature C on S1.id_squadra = C.id_squadra
              WHERE C.stato='CONFERMATO' AND punti_squadra_1>punti_squadra_2 AND sport=sp AND matricola=mat)
            +(SELECT COUNT(DISTINCT esiti.id_evento)
              FROM esiti JOIN eventi ON eventi.id_evento=esiti.id_evento JOIN evento_a_squadre EAS on eventi.id_evento = EAS.id_evento JOIN squadre S2 on S2.id_squadra = EAS.seconda_squadra JOIN candidature C on S2.id_squadra = C.id_squadra
              WHERE C.stato='CONFERMATO' AND punti_squadra_1<punti_squadra_2 AND sport=sp AND matricola=mat);
RETURN (((((COALESCE((SELECT AVG(punteggio) * 0.8
                      FROM valutazioni V
                      JOIN utenti U ON V.matricola = U.matricola JOIN eventi ON eventi.id_evento=V.id_evento
                      WHERE votato = mat AND affidabile = TRUE AND sport=sp), 0))
        +(COALESCE((SELECT AVG(punteggio) * 0.2
                   FROM valutazioni V
                   JOIN utenti U ON V.matricola = U.matricola JOIN eventi ON eventi.id_evento=V.id_evento
                   WHERE votato = mat AND affidabile = FALSE AND sport=sp), 0))
        / 10 * 30)
+ (CASE WHEN tot_eventi=0 THEN 0 ELSE (part_gioc/tot_eventi)*20 END)
+ (CASE WHEN part_gioc=0 THEN 0 ELSE (n_vittorie/part_gioc)*30 END)
+ (CASE WHEN part_gioc=0 THEN 0 ELSE ((part_gioc-aff)/part_gioc)*20 END))/100) * 40) + 60;
END
$level$ language plpgsql;

-- Esempi
SELECT level(3,'Tennis');
SELECT level(4,'Tennis');

/*************************************************************************************************************************************************************************/ 
--5. Trigger
/*************************************************************************************************************************************************************************/ 

/*************************************************************************************************************************************************************************/ 
/* 5a: trigger per la verifica del vincolo che non � possibile iscriversi a eventi chiusi e che lo stato di un evento sportivo diventa CHIUSO quando si raggiunge un numero di giocatori pari a quello previsto dalla categoria */
/*************************************************************************************************************************************************************************/ 


/* inserire qui i comandi SQL per la creazione del trigger senza rimuovere la specifica nel commento precedente */ 

/* ~ NOTE
   - l'update sullo stato dell'evento a chiuso viene effettuato con la funzione di approvazione
     riportata nella creazione dello schema logico alla riga 290
 */

-- FUNZIONE + TRIGGER per controlli su iscrizioni
CREATE OR REPLACE FUNCTION prevent_iscriz() RETURNS trigger AS
$prevent_iscriz$
BEGIN
IF NEW.stato IN ('CONFERMATO','RIFIUTATO')
THEN
    RAISE EXCEPTION 'l''iscrizione ha bisogno di un approvazione prima di essere accettata/rifiutata';
END IF;
IF (SELECT stato
    FROM Unige_Social_Sport.eventi
    WHERE id_evento = NEW.id_evento) = 'CHIUSO'
THEN
    RAISE EXCEPTION 'L''iscrizione non può essere effettuata su un evento chiuso';
END IF;
IF NEW.qualità='ARBITRO' AND (SELECT COUNT(matricola)
                              FROM unige_social_sport.iscrizioni
                              WHERE id_evento=NEW.id_evento AND qualità='ARBITRO' AND stato='CONFERMATO') >= 1
THEN
    RAISE EXCEPTION 'è già presente un arbitro per questo evento';
END IF;
IF (SELECT COUNT(matricola) FROM unige_social_sport.iscrizioni
                            WHERE id_evento=NEW.id_evento AND squadra = NEW.squadra AND qualità = 'GIOCATORE' AND stato='CONFERMATO') >= (SELECT numero_giocatori/2
                                                                                                                                          FROM unige_social_sport.categorie JOIN unige_social_sport.eventi e on categorie.sport = e.sport
                                                                                                                                          WHERE e.id_evento=NEW.id_evento)
THEN
    RAISE EXCEPTION 'La squadra scelta è già al completo';
END IF;
RETURN NEW;
END;
$prevent_iscriz$ language plpgsql;

CREATE OR REPLACE TRIGGER prevent_iscriz_trigger
BEFORE INSERT OR UPDATE ON iscrizioni
FOR EACH ROW WHEN ( NEW.stato != 'RIFIUTATO' ) EXECUTE FUNCTION prevent_iscriz();

/*************************************************************************************************************************************************************************/ 
/* 5b1: trigger che gestisce la sede di un evento: se la sede � disponibile nel periodo di svolgimento dell�evento la sede viene confermata altrimenti viene individuata una sede alternativa: tra gli impianti disponibili nel periodo di svolgimento dell�evento si seleziona quello meno utilizzato nel mese in corso (vedi vista Programma) */

/* 5b2: trigger per il mantenimento dell�attributo derivato livello */
/*************************************************************************************************************************************************************************/ 


/* inserire qui i comandi SQL per la creazione del trigger lasciando la specifica nel commento precedente corrispondente al trigger realizzato tra le due alternative proposte per b., a seconda che il livello del giocatore sia memorizzato o meno */ 

/* ~ NOTE
   - Assumiamo che due eventi APERTI possano essere nello stesso impianto nello stesso momento  */

-- FUNZIONE + TRIGGER per gestire eventi sovrapposti nello stesso impianto
CREATE OR REPLACE function check_imp() RETURNS TRIGGER AS
$check_imp$
DECLARE
    imp VARCHAR(40); -- Variabile che si salva l'eventuale nuovo impianto disponibile
BEGIN
-- (1) Verifichiamo che non esistano eventi chiusi sovrapposti per lo stesso impianto inserito
IF EXISTS(SELECT impianto
          FROM Unige_Social_Sport.eventi
          WHERE data_inizio < NEW.data_fine AND NEW.data_inizio < eventi.data_fine AND NEW.id_evento != eventi.id_evento AND impianto = NEW.impianto AND stato = 'CHIUSO')
THEN
    -- se (1)=TRUE --> (2) Verifichiamo se per il mese corrente ci siano impianti non utilizzati
    imp = (SELECT nome
           FROM Unige_Social_Sport.impianti I
           WHERE nome NOT IN (SELECT nome
                              FROM Unige_social_sport.programma
                              WHERE mese = EXTRACT(MONTH FROM NEW.data_inizio))
           LIMIT 1);
    IF imp IS NULL
    THEN
        -- se (2)=FALSE --> (3) Cerchiamo l'impianto meno utilizzato nel mese corrente
        imp = (SELECT nome
               FROM Unige_Social_Sport.programma P JOIN eventi E on P.sport = E.sport
               WHERE nome != NEW.impianto AND mese = EXTRACT(MONTH FROM NEW.data_inizio) AND NOT EXISTS(SELECT eventi.impianto
                                                                                                        FROM Unige_Social_Sport.eventi
                                                                                                        WHERE impianto = E.impianto AND data_inizio < NEW.data_fine AND NEW.data_inizio < eventi.data_fine)
                                                                                                        GROUP BY nome,mese HAVING SUM(minuti_utilizzo) <= ALL (SELECT SUM(minuti_utilizzo) AS utilizzo
                                                                                                                                                               FROM Unige_Social_Sport.programma P
                                                                                                                                                               GROUP BY nome
                                                                                                                                                               ORDER BY utilizzo)
                                                                                                        LIMIT 1);
    END IF;
    IF imp IS NULL
    THEN
        -- se (3)=FALSE --> Non essendoci impianti disponibile per tale periodo lo eliminiamo
        DELETE FROM Unige_Social_Sport.eventi
        WHERE id_evento=NEW.id_evento;
        RAISE EXCEPTION 'L''impianto insierito non è disponibile e non sono stati trovati altri impianti che lo sostituiscano per il periodo indicato!';
    ELSE
        -- se (3)=TRUE --> Aggiorniamo l'impianto con quello trovato
        UPDATE Unige_Social_Sport.eventi
        SET impianto = imp
        WHERE id_evento=NEW.id_evento;
        RAISE NOTICE 'L''impianto inserito non è disponibile per il periodo indicato, l''evento è stato spostato all''impianto %', imp;
    END IF;
END IF;
RETURN NULL;
END
$check_imp$ language plpgsql;

CREATE OR REPLACE TRIGGER check_imp_trigger
AFTER INSERT OR UPDATE ON eventi
FOR EACH ROW EXECUTE FUNCTION check_imp();

-- Esempio l'evento 6 si sovrappone con 5
UPDATE eventi
SET data_inizio = '2024-09-17 9:00:00' , impianto = 'Centro Sportivo Aurora'
WHERE id_evento=6;

SELECT impianto FROM eventi WHERE id_evento=6;
