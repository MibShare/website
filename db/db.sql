## Crea il database se non esiste
create database if not exists dbMiBShare
    CHARACTER SET =  "utf8"
    COLLATE = "utf8_unicode_ci";

## Selezioniamo il database da usare
use dbMiBShare;

# Creazione dei database
## Utente
### Prima cancello tutte le tabelle connesse che creeranno problemi
drop table if exists possiede;
drop table if exists messaggi;
drop table if exists commitTable;
drop table if exists confrontabili;
drop table if exists fileTable;
drop table if exists token;
### Ora posso cancellare utente e ricrearlo
drop table if exists utente;
create table utente (
    idUtente INTEGER PRIMARY KEY AUTO_INCREMENT,
    ### 255 e' la lunghezza massima di un email
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(15) NOT NULL UNIQUE,
    password VARCHAR(64) NOT NULL,
    salt VARCHAR(32) NOT NULL
);
## Token
create table token (
    idToken INTEGER PRIMARY KEY AUTO_INCREMENT,
    token VARCHAR(32) NOT NULL,
    idUtente INTEGER NOT NULL,
    ### Chiavi esterne
    FOREIGN KEY (idUtente) REFERENCES utente(idUtente)
);
## Messaggi
create table messaggi (
    idMessaggio INTEGER PRIMARY KEY AUTO_INCREMENT,
    messaggio TEXT NOT NULL,
    oneTime BOOLEAN NOT NULL,
    fineMessaggio DATE,
    idUtente INTEGER NOT NULL,
    ### Chiave esterne
    FOREIGN KEY (idUtente) REFERENCES utente(idUtente)
);
## Ruolo
drop table if exists ruolo;
create table ruolo (
    idRuolo INTEGER PRIMARY KEY AUTO_INCREMENT,
    nomeRuolo VARCHAR(15) NOT NULL
);
## Sezione
drop table if exists sezione;
create table sezione (
    idSezione INTEGER PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(30) NOT NULL UNIQUE
);
## Possiede
create table possiede (
    idRuoloPosseduto INTEGER PRIMARY KEY AUTO_INCREMENT,
    idRuolo INTEGER NOT NULL,
    idUtente INTEGER NOT NULL,
    idSezione INTEGER NOT NULL,
    ### Chiavi esterne
    FOREIGN KEY (idRuolo) REFERENCES ruolo(idRuolo),
    FOREIGN KEY (idSezione) REFERENCES sezione(idSezione),
    FOREIGN KEY (idUtente) REFERENCES utente(idUtente)
);
## fileTable
create table fileTable (
    idFile INTEGER PRIMARY KEY AUTO_INCREMENT,
    idUtente INTEGER NOT NULL,
    nDislikes INTEGER NOT NULL,
    nLikes INTEGER NOT NULL,
    path VARCHAR(64) NOT NULL,
    idSezione INTEGER NOT NULL,
    ### Chiavi esterne
    FOREIGN KEY (idUtente) REFERENCES utente(idUtente),
    FOREIGN KEY (idSezione) REFERENCES sezione(idSezione)
);
## Confrontabili
create table confrontabili (
    idConfrontazione INTEGER PRIMARY KEY AUTO_INCREMENT,
    primoFile INTEGER NOT NULL,
    secondoFile INTEGER NOT NULL,
    ### Chiavi esterne
    FOREIGN KEY (primoFile) REFERENCES fileTable(idFile),
    FOREIGN KEY (secondoFile) REFERENCES fileTable(idFile),
    ### Controlli
    CHECK ( primoFile != secondoFile )
);
## CommitTable
create table commitTable (
    idCommit INTEGER PRIMARY KEY AUTO_INCREMENT,
    date DATE NOT NULL,
    idFile INTEGER NOT NULL,
    ### Chiavi esterne
    FOREIGN KEY (idFile) REFERENCES fileTable(idFile)
);

# Utils
## Funzione che crea un salt
DROP FUNCTION IF EXISTS generateRandom;
DELIMITER //
CREATE FUNCTION generateRandom()
    RETURNS varchar(32)
BEGIN
    return MD5(RAND());
end;
//
DELIMITER ;
## Funzione che, data password e salt, restituisce hash256
DROP FUNCTION IF EXISTS getPassword;
DELIMITER //
CREATE FUNCTION getPassword ( salt varchar(32), password varchar(64) )
    RETURNS VARCHAR(64)
BEGIN
    return SHA2(CONCAT(salt, password), 256);
end;
//
DELIMITER ;


# Procedure

## Crea un ruolo
drop procedure if exists crea_ruolo;
DELIMITER
//
CREATE PROCEDURE crea_ruolo (
    PRMRuolo VARCHAR(15)
)
at: BEGIN
    ## Controlliamo se il ruolo esiste, se non creiamolo
    if (select count(*) from ruolo where ruolo.nomeRuolo like PRMRuolo) = 0 THEN
        insert into ruolo(nomeRuolo) Values(PRMRuolo);
    end if;
END
//
DELIMITER ;

## Aggiungi un ruolo ad un utente
/*
    0 -> Username non esistente
    1 -> Ruolo non esistente
    2 -> Sezione non esistente
    3 -> Tutto avvenuto con successo
 */
drop procedure if exists aggiungi_ruolo_sezione;
DELIMITER
//
CREATE PROCEDURE aggiungi_ruolo_sezione (
    PRMUsername VARCHAR(15),
    PRMRuolo VARCHAR(15),
    PRMSezione VARCHAR(30),
    out successo INTEGER
)
ar: BEGIN
    SET @usernameId = (select idUtente from utente where utente.username like PRMUsername);
    ## Controllo se l'email esiste, se si allora ritorno 0
    if @usernameId is null THEN
        SET successo = 0;
        select successo;
        LEAVE ar;
    end if;

    SET @ruoloId = (select idRuolo from ruolo where ruolo.nomeRuolo like PRMRuolo);
    ## Controllo se l'email esiste, se si allora ritorno 0
    if @ruoloId is null THEN
        SET successo = 1;
        select successo;
        LEAVE ar;
    end if;

    SET @sezioneId = (select idSezione from sezione where sezione.nome like PRMSezione);
    ## Controllo se l'email esiste, se si allora ritorno 0
    if @sezioneId is null THEN
        SET successo = 1;
        select successo;
        LEAVE ar;
    end if;

    insert into possiede(idRuolo, idUtente, idSezione)
    values (@ruoloId, @usernameId, @sezioneId);

    SET successo = 3;
    select successo;
END
//
DELIMITER ;

## Creazione di un utente
/*
    Valori di ritorno:
    0 -> email già usata
    1 -> username già usato
    token -> Registrazione avvenuta con successo

    Viene presupposto che l'email sia valida
 */
drop procedure if exists aggiungi_utente;
DELIMITER
//
CREATE PROCEDURE aggiungi_utente (
    PRMEmail VARCHAR(255),
    PRMUsername VARCHAR(15),
    PRMPassword VARCHAR(32),
    PRMRuolo VARCHAR(15),
    out successo VARCHAR(32)
)
at: BEGIN
    ## Controllo se l'email esiste, se si allora ritorno 0
    if (select count(*) from utente where utente.email like PRMEmail) != 0 THEN
        SET successo = '0';
        select successo;
        LEAVE at;
    end if;

    ## Controllo se l'utente esiste, se si allora ritorna 1
    if (select count(*) from utente where utente.username like PRMUsername) != 0 THEN
        SET successo = '1';
        select successo;
        LEAVE at;
    end if;
    ## Crea ruolo
    call crea_ruolo(PRMRuolo);
    ## Prendo l'id del ruolo
    SET @salt = (select generateRandom());
    SET @password = (select getPassword(@salt, PRMPassword));
    ## Creo
    insert into utente(email, username, password, salt)
    values (PRMEmail, PRMUsername, @password, @salt);
    ## Creo un token
    SET @token = (select generateRandom());
    ## Prendo l'id dell'utente ed inserisco una nuova tabella in token
    SET @idUtente = (select idUtente from utente where email like PRMEmail);
    insert into token(token, idUtente)
    values (@token, @idUtente);
    SET successo = @token;
    select successo;
END
//
DELIMITER ;



# Dati default per il testing
## Aggiungo una nuova sezione
insert into sezione(nome) values ('Home');
## Utente admin
call aggiungi_utente('test@gmail.com', 'test', 'test', 'admin', @out);
call aggiungi_ruolo_sezione('test', 'admin', 'Home', @outRuolo);
## Li tolgo il token
DELETE FROM token where idUtente = (select idUtente from utente where username like 'test');