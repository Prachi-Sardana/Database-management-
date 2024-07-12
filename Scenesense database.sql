-- Drop the database if it exists scenesense
drop database if exists scenesense;
-- Creating database scenesense
CREATE DATABASE scenesense;

-- Use the database scenesense
USE scenesense;

-- Creating Play table with playid as primary key, Title, Author and description 

CREATE TABLE Play (
    PlayID INT PRIMARY KEY AUTO_INCREMENT not null unique,
    Title VARCHAR(200) not null,
    Author VARCHAR(200) not null,
    description varchar(200)
);

-- Creating Production table where production id is primary key, name, description, billboard image, Premier Date , Play id as foreign key
CREATE TABLE Production (
    ProductionID INT PRIMARY KEY AUTO_INCREMENT not null unique,
    Name VARCHAR(200) not null,
    Description varchar(200) not null,
    BillBoardImage Blob,
    PremierDate DATE not null,
    PlayID INT not null,
    constraint prod_fk_play FOREIGN KEY (PlayID) REFERENCES Play(PlayID)
    ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Creating table for actor where actor id is primary key , name, email and phone number 
CREATE TABLE Actor (
    ActorID INT PRIMARY KEY AUTO_INCREMENT not null unique,
    Name VARCHAR(200) not null,
    Email VARCHAR(200) UNIQUE not null,
    Phone VARCHAR(20)
);

-- Create table for Characters with Character id as primary key , name , Description , play id as a foreign key 
CREATE TABLE Characters (
    CharacterID INT PRIMARY KEY AUTO_INCREMENT not null unique,
    Name VARCHAR(200) not null,
    Description VARCHAR(200),
    PlayID INT not null,
    constraint char_fk_play FOREIGN KEY (PlayID) REFERENCES Play(PlayID)
    ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Creating Scene table where Scene id is the primary key , title, sequence number, play id as a foreign key
CREATE TABLE Scene (
    SceneID INT PRIMARY KEY AUTO_INCREMENT not null unique,
    Title VARCHAR(200) not null,
    SeqNo VARCHAR(200) not null,
    PlayID INT not null,
    constraint scene_fk_play FOREIGN KEY (PlayID) REFERENCES Play(PlayID)
    ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Create Rehearsal table where rehearsal id is the primary key, date, start time , end time and production id as a foreign key 
CREATE TABLE Rehearsal (
    RehearsalID INT PRIMARY KEY AUTO_INCREMENT not null unique,
    Date DATE not null,
    StartTime TIME not null,
    EndTime TIME not null,
    ProductionID INT not null,
    constraint rehearsal_fk_prod FOREIGN KEY (ProductionID) REFERENCES Production(ProductionID)
    ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Creating a join table Casted where Actor id , character id and production id are foreign keys
CREATE TABLE Casted (
    ActorID INT not null,
    CharacterID INT not null,
    ProductionID INT not null,
    PRIMARY KEY (ActorID, CharacterID, ProductionID),
    constraint casted_fk_actor FOREIGN KEY (ActorID) REFERENCES Actor(ActorID)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    constraint casted_fk_char FOREIGN KEY (CharacterID) REFERENCES Characters(CharacterID)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    constraint casted_fk_prod FOREIGN KEY (ProductionID) REFERENCES Production(ProductionID)
    ON UPDATE CASCADE ON DELETE RESTRICT
);


-- Creating an appears join table where scene id and character id are foreign keys
CREATE TABLE Appears (
    SceneID INT not null,
    CharacterID INT not null,
    PRIMARY KEY (SceneID, CharacterID),
    constraint appear_fk_scene FOREIGN KEY (SceneID) REFERENCES Scene(SceneID)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    constraint appear_fk_char FOREIGN KEY (CharacterID) REFERENCES Characters(CharacterID)
    ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Creating a join table for RehearsalMinutes where rehearsal id and scene id are primary keys. Adding a record for minutes 
CREATE TABLE RehearsalMinutes (
    RehearsalID INT not null,
    SceneID INT not null,
    Minutes INT,
    PRIMARY KEY (RehearsalID, SceneID),
    constraint reharsalMin_fk_reharsal FOREIGN KEY (RehearsalID) REFERENCES Rehearsal(RehearsalID)
    ON UPDATE CASCADE ON DELETE RESTRICT,
    constraint reharsalMin_fk_scene FOREIGN KEY (SceneID) REFERENCES Scene(SceneID)
    ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Inserting data into play table
INSERT INTO Play (Title, Author, Description) VALUES
('Julius Caesar', 'William Shakespeare', 'A tragedy by William Shakespeare'),
('Rosencrantz and Guildenstern are Dead', 'Tom Stoppard', 'A play by Tom Stoppard');

-- Inserting data into Production table
INSERT INTO Production (Name, Description, PremierDate, PlayID) VALUES
('Julius Caesar the Musical', 'A musical adaptation of Julius Caesar', '2025-03-14', 1),
('Rosencrantz and Guildenstern are Dead', 'A comedy play by Tom Stoppard', '2025-03-15', 2);

-- Inserting data into Actor table
INSERT INTO Actor (Name, Email, Phone) VALUES
('Peter O’Toole', 'peterotoole@example.com', '123-456-7890'),
('Will Smith', 'willsmith@example.com', '234-567-8901'),
('Brad Pitt', 'bradpitt@example.com', '345-678-9012'),
('Russell Crowe', 'russellcrowe@example.com', '456-789-0123'),
('Angelina Jolie', 'angelinajolie@example.com', '567-890-1234'),
('Scarlett Johansson', 'scarlettjohansson@example.com', null);

-- Inserting data into Characters table
INSERT INTO Characters (Name, Description, PlayID) VALUES
('Caesar', null, 1),
('Brutus', null, 1),
('Cassius', null, 1),
('Antony', null, 1),
('Portia', null, 1);

-- Inserting data into Scene table
INSERT INTO Scene (Title, SeqNo, PlayID) VALUES
('Act 3 Scene 1', '1', 1),
('Act 3 Scene 2', '2', 1);

-- Inserting data into Casted table
INSERT INTO Casted (ActorID, CharacterID, ProductionID) VALUES
(1, 1, 1),  -- Peter O’Toole as Caesar
(2, 2, 1),  -- Will Smith as Brutus
(3, 3, 1),  -- Brad Pitt as Cassius
(4, 4, 1),  -- Russell Crowe as Antony
(5, 5, 1);  -- Angelina Jolie as Portia

-- Insert data into Appears table joining the scenes and characters 
-- Caesar in Act 3 Scene 1
-- Brutus in Act 3 Scene 1
-- Cassius in Act 3 Scene 1
-- Antony in Act 3 Scene 1
-- Brutus in Act 3 Scene 2
-- Cassius in Act 3 Scene 2
-- Antony in Act 3 Scene 2
INSERT INTO Appears (SceneID, CharacterID) VALUES
(1, 1),  
(1, 2), 
(1, 3),  
(1, 4),  
(2, 2),  
(2, 3),  
(2, 4);  

-- Insert data into Rehearsal table
INSERT INTO Rehearsal (Date, StartTime, EndTime, ProductionID) VALUES
('2025-03-15', '14:00:00', '18:00:00', 1),
('2025-03-16', '14:00:00', '18:00:00', 1),
('2025-03-17', '14:00:00', '18:00:00', 1);

-- Insert data into RehearsalMinutes table
INSERT INTO RehearsalMinutes (RehearsalID, SceneID, Minutes) VALUES
(1, 1, 120),  -- Rehearsal 1: Scene 1 for two hours
(1, 2, 120),  -- Rehearsal 1: Scene 2 for two hours
(2, 2, 240),  -- Rehearsal 2: Scene 2 for all four hours
(3, 1, 60),   -- Rehearsal 3: Scene 1 for one hour
(3, 2, 180);  -- Rehearsal 3: Scene 2 for three hours