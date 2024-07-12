use scenesense;

show tables;
-- select * from actor;
-- select * from appears;
-- select * from casting;
-- select * from characters;
-- select * from play;
-- select * from production;
-- select * from rehearsal;
-- select * from rehearsal_schedule;
-- select * from scene;

-- Q1. For each production, count the number of scheduled rehearsals. Include
-- productions that have no scheduled rehearsals

select p.name , count(r.rehearsal_id) as scheduled_rehearsals_count from production p 
left join rehearsal r on p.production_id = r.production_id
group by p.name
order by p.name;



-- Q2. For the play of "Julius Caesar", list each scene title
-- and the characters appearing in that scene
-- Sort by the scene sequence number

select  play.title as play_title, 
scene.title as scene_title, 
characters.name, 
scene.sequence_no 
from play  
inner join characters on play.play_id = characters.play_id 
inner join scene on characters.play_id = scene.play_id
where play.title = 'Julius Caesar'
order by sequence_no;


-- Q3. How many minutes are being dedicated to the rehearsal of each scene in
-- Julius Caesar the Musical? (This is something the Director wants to keep 
-- track of when formulating the rehearsal schedule.


select scene.title, sum(minutes) from scene 
inner join
rehearsal_schedule 
 on scene.scene_id = rehearsal_schedule.scene_id 
 inner join rehearsal on rehearsal.rehearsal_id = rehearsal_schedule.rehearsal_id
 inner join production on production.production_id = rehearsal.production_id
 where  production.name = 'Julius Caesar the Musical'
 group by scene.scene_id ;


-- Q4. How much rehearsal time must each actor rehearse?
-- Give the actor name and the number of minutes.
-- Include actors that never rehearse either because they were assigned
-- no part or because they do not appear in any rehearsed scene.
-- (Those actors should show "0" minutes rehearsed.)
-- Show only actors that are rehearsing LESS than 500 minutes.
-- Sort in descending order by number of minutes


SELECT a.name,
       COALESCE(SUM(MINUTES),0) AS rehearsal_min
FROM actor a
LEFT JOIN casting c ON a.actor_id = c.actor_id
LEFT JOIN characters ch ON c.character_id = ch.character_id
LEFT JOIN appears ap ON ch.character_id = ap.character_id
LEFT JOIN scene s ON ap.scene_id = s.scene_id
LEFT JOIN rehearsal_schedule r ON s.scene_id = r.scene_id
GROUP BY a.name
HAVING rehearsal_min < 500
ORDER BY rehearsal_min DESC;




-- Q5. Generate the call lists for the rehearsal occurring on the "Ides of March" (March 15th).
-- The call list is the distinct list of actors that need to come to that rehearsal.
-- Show the actor’s name, phone number, and email address



SELECT DISTINCT a.name , a.phone, a.email
FROM rehearsal r
JOIN rehearsal_schedule rs on r.rehearsal_id = rs.rehearsal_id
JOIN scene s on s.scene_id = rs.scene_id
JOIN appears ap on ap.scene_id = s.scene_id 
JOIN characters ch on ap.character_id = ch.character_id
JOIN casting c on c.character_id = ch.character_id 
JOIN actor a on a.actor_id = c.actor_id 
WHERE DATE(r.starttime) = '2023-03-15';


 
