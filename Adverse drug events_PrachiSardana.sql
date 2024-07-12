-- HW5: Identifying Adverse Drug Events (ADEs) with Stored Programs
-- Prof. Rachlin
-- CS CS5200: Databases

-- We've already setup the ade database by running ade_setup.sql
-- First, make ade the active database.  Note, this database is actually based on 
-- the emr_sp schema used in the lab, but it included some extra tables.

use ade;



-- A stored procedure to process and validate prescriptions
-- Four things we need to check
-- a) Is patient a child and is medication suitable for children?
-- b) Is patient pregnant and is medication suitable for pregnant women?
-- c) Is dosage reasonable?
-- d) Are there any adverse drug reactions


drop procedure if exists prescribe;

delimiter //
create procedure prescribe
(
	in patient_name_param varchar(255),
    in doctor_name_param varchar(255),
    in medication_name_param varchar(255),
    in ppd_param int
)
begin
	-- variable declarations (YOU MAY NOT NEED ALL OF THESE!)
    declare patient_id_var int;
    declare age_var float;
    declare is_pregnant_var boolean;
    declare weight_var int;
    declare doctor_id_var int;
    declare medication_id_var int;
    declare take_under_12_var boolean;
    declare take_if_pregnant_var boolean;
    declare mg_per_pill_var double;
    declare max_mg_per_10kg_var double;
 
    
	declare message varchar(255); -- The error message
    declare ddi_medication varchar(255); -- The name of a medication involved in a drug-drug interaction
    
    


    
    -- select relevant values into variables
    
    select patient_id into patient_id_var from patient where patient_name = patient_name_param;
      select doctor_id into doctor_id_var from doctor  where doctor_name = doctor_name_param;
       select medication_id into medication_id_var from medication  where medication_name = medication_name_param;
    
    if patient_id_var is null then
        set message = 'Patient not found';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = message;
    else
        select DATEDIFF(CURDATE(), dob)/365 into age_var from patient where patient_name = patient_name_param;
        select case when is_pregnant = 1 then true else  false end into is_pregnant_var from patient where patient_name = patient_name_param;
        select weight * 0.45 into weight_var from patient where patient_name = patient_name_param;
        end if;
        
        if doctor_id_var is null then
        set message = 'Doctor not found';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = message;
        end if;
        
         if medication_id_var is null then
        set message = 'Medication not found';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = message;
        end if;
        
          select take_under_12 into take_under_12_var from medication where medication_id = medication_id_var;
		select take_if_pregnant into take_if_pregnant_var from medication where medication_id = medication_id_var;
        
        select mg_per_pill into mg_per_pill_var from medication where medication_id = medication_id_var;
        
        select max_mg_per_10kg into  max_mg_per_10kg_var from medication where medication_id = medication_id_var;
        
        select medication_name into ddi_medication  from medication where medication_id = ( select medication_2  from interaction where medication_1 =  medication_id_var);
        
        
    -- check age of patient and if medication ok for children
  
    
    if take_under_12_var = 0 and age_var < 12 then
    set message = CONCAT(medication_name_param, ' cannot be prescribed to children under 12');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = message;
        end if;
    
    

    
    -- check if medication ok for pregnant women
    
     if take_if_pregnant_var = 0 and is_pregnant_var then
    set message = CONCAT(medication_name_param, ' cannot be prescribed to pregnant women');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = message;
        end if;
 
    
    -- check dosage
    if ppd_param > floor( ((max_mg_per_10kg_var / 10) * weight_var) / mg_per_pill_var) then 
  
    set message =  concat('Maximum dosage for ', medication_name_param, ' is ', floor( ((max_mg_per_10kg_var / 10) * weight_var) / mg_per_pill_var),  ' pills per day for patient ', patient_name_param);
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = message;
        end if;

    
    -- Check for reactions involving medications already prescribed to patient
    
    if ddi_medication = (select medication_name from medication where medication_id = (select medication_id from prescription where patient_id = patient_id_var)) then 

    set message = concat(medication_name_param, ' interacts with ', ddi_medication,' prescribed to ', patient_name_param);
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = message;
        end if;

    
    -- No exceptions thrown, so insert the prescription record
    
    insert into prescription values (medication_id_var, patient_id_var, doctor_id_var, now(), ppd_param);

end //
delimiter ;


-- After you do the update, perform some checks.....
-- Patient became pregnant
-- Add pre-natal recommenation
-- Delete any prescriptions that shouldn't be taken if pregnant
-- Patient is no longer pregnant
-- Remove pre-natal recommendation

    



-- --------------------------          TEST CASES          -----------------------
-- -------------------------- DONT CHANGE BELOW THIS LINE! -----------------------
-- Test cases
truncate prescription;

-- These prescriptions should succeed
call prescribe('Jones', 'Dr.Marcus', 'Happyza', 2);
call prescribe('Johnson', 'Dr.Marcus', 'Forgeta', 1);
call prescribe('Williams', 'Dr.Marcus', 'Happyza', 1);
call prescribe('Phillips', 'Dr.McCoy', 'Forgeta', 1);

-- These prescriptions should fail
-- Pregnancy violation
call prescribe('Jones', 'Dr.Marcus', 'Forgeta', 2);

-- Age restriction
call prescribe('BillyTheKid', 'Dr.Marcus', 'Muscula', 1);

-- Excessive Dosage
call prescribe('Lee', 'Dr.Marcus', 'Foobaral', 3);

-- Drug interaction
call prescribe('Williams', 'Dr.Marcus', 'Sadza', 1);



-- Testing trigger
-- Phillips (patient_id=4) becomes pregnant
-- Verify that a recommendation for pre-natal vitamins is added
-- and that her prescription for 

DELIMITER //

-- Trigger for when a patient becomes pregnant
CREATE TRIGGER patient_pregnancy_start
AFTER UPDATE ON patient
FOR EACH ROW
BEGIN
    IF NEW.is_pregnant = 1 AND OLD.is_pregnant = 0 THEN
        -- Add recommendation for pre-natal vitamins
        INSERT INTO recommendation (patient_id, message)
        VALUES (NEW.patient_id, 'Take pre-natal vitamins');
        
        -- Remove prescriptions for medications that shouldn't be taken during pregnancy
        DELETE FROM prescription
        WHERE patient_id = NEW.patient_id
        AND medication_id IN (
            SELECT medication_id FROM medication WHERE take_if_pregnant = False
        );
    END IF;
END;
//

-- Trigger for when a patient is no longer pregnant
DELIMITER //
CREATE TRIGGER patient_pregnancy_end
AFTER UPDATE ON patient
FOR EACH ROW
BEGIN
    IF NEW.is_pregnant = 0 AND OLD.is_pregnant = 1 THEN
        -- Remove recommendation for pre-natal vitamins
        DELETE FROM recommendation
        WHERE patient_id = NEW.patient_id
        AND message = 'Take pre-natal vitamins';
    END IF;
END;
//

DELIMITER ;



update patient
set is_pregnant = True
where patient_id = 4;

select * from recommendation;
select * from prescription;


-- Phillips (patient_id=4) is no longer pregnant
-- Verify that the prenatal vitamin recommendation is gone
-- Her old prescription does not need to be added back

update patient
set is_pregnant = False
where patient_id = 4;

select * from recommendation;



