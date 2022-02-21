## Crea il database se non esiste
create database if not exists dbMiBShare
    CHARACTER SET =  "utf8"
    COLLATE = "utf8_unicode_ci";

## Selezioniamo il database da usare
use dbMiBShare;

# Creazione dei database
## Utente
### Prima cancello tutte le tabelle connesse che creeranno problemi
drop table if exists messaggi;
drop table if exists possiede;
drop table if exists commitTable;
drop table if exists confrontabili;
drop table if exists fileTable;
### Ora posso cancellare utente e ricrearlo
drop table if exists utente;
create table utente (
    idUtente INTEGER PRIMARY KEY AUTO_INCREMENT,
    ### 255 e' la lunghezza massima di un email
    email VARCHAR(255) NOT NULL,
    username VARCHAR(15) NOT NULL,
    password VARCHAR(64) NOT NULL,
    salt VARCHAR(32) NOT NULL,
    token VARCHAR(16) NOT NULL
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
    nome VARCHAR(30) NOT NULL
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
    ### Chiavi esterne
    FOREIGN KEY (idUtente) REFERENCES utente(idUtente)
);
## Confrontabili
create table confrontabili (
    idConfrontazione INTEGER PRIMARY KEY AUTO_INCREMENT,
    primoFile INTEGER NOT NULL,
    secondoFile INTEGER NOT NULL,
    ### Chiavi esterne
    FOREIGN KEY (primoFile) REFERENCES fileTable(idFile),
    FOREIGN KEY (secondoFile) REFERENCES fileTable(idFile)
);
## CommitTable
create table commitTable (
    idCommit INTEGER PRIMARY KEY AUTO_INCREMENT,
    date DATE NOT NULL,
    idFile INTEGER NOT NULL,
    ### Chiavi esterne
    FOREIGN KEY (idFile) REFERENCES fileTable(idFile)
)