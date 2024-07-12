drop database if exists enterprise;
create database enterprise;

use enterprise;

create table crew (
    crew_id int primary key,
    name varchar(10),
    reports_to int,
    foreign key (reports_to) references crew (crew_id)
);

insert into crew values
(1, 'Kirk', null),
(2, 'Spock', 1),
(3, 'Scotty', 1),
(4, 'McCoy', 1),
(5, 'Chapel', 4),
(6, 'Oreilly', 3),
(7, 'Uhuru', 3);


-- "Star Trek" was an American Science-Fiction TV show from the 1960's
-- The name of their spaceship was the U.S.S. Enterprise.
-- For each member of the Starship Enterprise crew, 
-- indicate who they report to.  
-- Include crew members who report to nobody.
-- Output two columns: name, reports_to
-- The reports_to column is also a NAME.
-- For example, "Spock" reports to "Kirk"

SELECT c1.name AS crew_names,
COALESCE(c2.name, 'Nobody') AS reports_to
FROM crew c1
LEFT JOIN crew c2 ON c1.reports_to = c2.crew_id;

