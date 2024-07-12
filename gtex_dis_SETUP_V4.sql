-- cs5200 Summer 2024 Final Project
-- Team 30 
-- Xinlei Hu, Prachi Sardana, Matthew Runyan


-- Drop the database if it exists
DROP DATABASE IF EXISTS gtexdis_demo;

-- Enable local data loading
SET GLOBAL local_infile = 1;

-- Create the new database
CREATE DATABASE IF NOT EXISTS gtexdis_demo;
USE gtexdis_demo;

-- Subject Metadata
CREATE TABLE IF NOT EXISTS SubjectMetadata (
    SUBJID VARCHAR(20) PRIMARY KEY,
    SEX INT,
    AGE VARCHAR(10),
    DTHHRDY INT
);

-- Simplified Sample Metadata
CREATE TABLE IF NOT EXISTS SampleMetadata (
    SAMPID VARCHAR(255) PRIMARY KEY,
    SUBJID VARCHAR(20),
    SMTS VARCHAR(255),
    SMTSD VARCHAR(255),
    INDEX (SUBJID),
    FOREIGN KEY (SUBJID) REFERENCES SubjectMetadata(SUBJID)
);

-- DisGeNET Tables
CREATE TABLE IF NOT EXISTS disease_mappings (
    diseaseId VARCHAR(255),
    name VARCHAR(255),
    vocabulary VARCHAR(255),
    code VARCHAR(255),
    vocabularyName VARCHAR(255),
    PRIMARY KEY (diseaseId, vocabulary, code)
);


CREATE TABLE IF NOT EXISTS gene_associations (
    geneId INT PRIMARY KEY,
    geneSymbol VARCHAR(255),
    DSI DECIMAL(5, 3) NULL,
    DPI DECIMAL(5, 3) NULL,
    PLI DOUBLE NULL,
    protein_class_name VARCHAR(255),
    protein_class VARCHAR(255),
    NofDiseases INT,
    NofPmids INT
);

CREATE TABLE IF NOT EXISTS variant_to_gene_mappings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    snpId VARCHAR(255),
    geneId INT,
    geneSymbol VARCHAR(255),
    sourceId VARCHAR(255),
    INDEX(snpId),
    FOREIGN KEY (geneId) REFERENCES gene_associations(geneId)
);

CREATE TABLE IF NOT EXISTS variant_associations (
    snpId VARCHAR(255) PRIMARY KEY,
    class VARCHAR(255),
    chromosome VARCHAR(255),
    position INT,
    most_severe_consequence VARCHAR(255),
    DSI DECIMAL(5, 3) NULL,
    DPI DECIMAL(5, 3) NULL,
    NofDiseases INT,
    NofPmids INT,
    FOREIGN KEY (snpId) REFERENCES variant_to_gene_mappings(snpId)
);

CREATE TABLE IF NOT EXISTS vdisease_associations (
    diseaseId VARCHAR(255),
    diseaseName VARCHAR(255),
    diseaseType VARCHAR(255),
    diseaseClass VARCHAR(255),
    diseaseSemanticType VARCHAR(255),
    NofSNPs INT,
    NofPmids INT,
    FOREIGN KEY (diseaseId) REFERENCES disease_mappings(diseaseId)
);

CREATE TABLE IF NOT EXISTS disease_associations (
    diseaseId VARCHAR(255),
    diseaseName VARCHAR(255),
    diseaseType VARCHAR(255),
    diseaseClass VARCHAR(255),
    diseaseSemanticType VARCHAR(255),
    NofGenes INT,
    NofPmids INT,
    FOREIGN KEY (diseaseId) REFERENCES disease_mappings(diseaseId)
);

-- Mapping table between Ensembl and NCBI IDs
CREATE TABLE IF NOT EXISTS ensembl_ncbi_mapping (
    ensembl_gene_id VARCHAR(255) PRIMARY KEY,
    ncbi_gene_id INT
);

-- Junction table for Disease and Gene associations
CREATE TABLE IF NOT EXISTS disease_gene_associations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    diseaseId VARCHAR(255),
    geneId INT,
    FOREIGN KEY (diseaseId) REFERENCES disease_mappings(diseaseId),
    FOREIGN KEY (geneId) REFERENCES gene_associations(geneId)
);

-- GTEx Tables for Transcript Data
CREATE TABLE IF NOT EXISTS TranscriptExpectedCounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transcript_id VARCHAR(255),
    ensembl_gene_id VARCHAR(255),
    sample_id VARCHAR(255),
    expected_count FLOAT,
    INDEX (transcript_id),
    INDEX (sample_id),
    FOREIGN KEY (ensembl_gene_id) REFERENCES ensembl_ncbi_mapping(ensembl_gene_id),
    FOREIGN KEY (sample_id) REFERENCES SampleMetadata(SAMPID)
);

CREATE TABLE IF NOT EXISTS TranscriptTPM (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transcript_id VARCHAR(255),
    ensembl_gene_id VARCHAR(255),
    sample_id VARCHAR(255),
    tpm FLOAT,
    INDEX (transcript_id),
    INDEX (sample_id),
    FOREIGN KEY (ensembl_gene_id) REFERENCES ensembl_ncbi_mapping(ensembl_gene_id),
    FOREIGN KEY (sample_id) REFERENCES SampleMetadata(SAMPID)
);

USE gtexdis_demo;

-- Subject Metadata
CREATE TABLE IF NOT EXISTS SubjectMetadata (
    SUBJID VARCHAR(20) PRIMARY KEY,
    SEX INT,
    AGE VARCHAR(10),
    DTHHRDY INT
);

USE gtexdis_demo;

-- Load data into SubjectMetadata
LOAD DATA LOCAL INFILE '/Users/jasonli1/Documents/NEU_Course/5200/database/GTEx_Analysis_v8_Annotations_SubjectPhenotypesDS.txt' 
INTO TABLE SubjectMetadata 
FIELDS TERMINATED BY '\t' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES 
(SUBJID, @SEX, AGE, @DTHHRDY) 
SET 
    SEX = NULLIF(TRIM(@SEX), ''),
    DTHHRDY = NULLIF(TRIM(@DTHHRDY), '');

-- Step 1: Create a temporary table to hold the SampleMetadata data for verification
CREATE TEMPORARY TABLE TempSampleMetadata (
    SAMPID VARCHAR(255),
    SUBJID VARCHAR(255),
    SMTS VARCHAR(255),
    SMTSD VARCHAR(255)
);

-- Step 2: Load the data into the temporary table
LOAD DATA LOCAL INFILE '/Users/jasonli1/Documents/NEU_Course/5200/database/GTEx_Analysis_v8_Annotations_SampleAttributesDS.txt'
INTO TABLE TempSampleMetadata
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(SAMPID, SMTS, SMTSD)
SET SUBJID = LEFT(SAMPID, LOCATE('-', SAMPID, LOCATE('-', SAMPID) + 1) - 1);

-- Step 3: Insert only valid rows into the main SampleMetadata table
INSERT INTO SampleMetadata (SAMPID, SUBJID, SMTS, SMTSD)
SELECT t.SAMPID, t.SUBJID, t.SMTS, t.SMTSD
FROM TempSampleMetadata t
WHERE EXISTS (SELECT 1 FROM SubjectMetadata s WHERE s.SUBJID = t.SUBJID);

-- Step 4: Drop the temporary table
DROP TEMPORARY TABLE TempSampleMetadata;

-- Load data into disease_mappings
LOAD DATA LOCAL INFILE '/Users/jasonli1/Documents/NEU_Course/5200/database/disease_mappings.tsv'
INTO TABLE disease_mappings 
FIELDS TERMINATED BY '\t' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES (diseaseId, name, vocabulary, code, vocabularyName);

-- Load data into gene_associations
LOAD DATA LOCAL INFILE '/Users/jasonli1/Documents/NEU_Course/5200/database/gene_associations.tsv'
INTO TABLE gene_associations
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 LINES (geneId, geneSymbol, @DSI, @DPI, @PLI, protein_class_name, protein_class, NofDiseases, NofPmids)
SET
    DSI = NULLIF(TRIM(@DSI), ''),
    DPI = NULLIF(TRIM(@DPI), ''),
    PLI = NULLIF(TRIM(@PLI), '');

-- Create a temporary table for variant_to_gene_mappings
DROP TEMPORARY TABLE IF EXISTS variant_to_gene_mappings_temp;
CREATE TEMPORARY TABLE variant_to_gene_mappings_temp (
    snpId VARCHAR(255),
    geneId INT,
    geneSymbol VARCHAR(255),
    sourceId VARCHAR(255)
);

-- Load data into the temporary table
LOAD DATA LOCAL INFILE '/Users/jasonli1/Documents/NEU_Course/5200/database/variant_to_gene_mappings.tsv' 
INTO TABLE variant_to_gene_mappings_temp 
FIELDS TERMINATED BY '\t' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES (snpId, geneId, geneSymbol, sourceId);

-- Insert only valid rows into the main table
INSERT INTO variant_to_gene_mappings (snpId, geneId, geneSymbol, sourceId)
SELECT snpId, geneId, geneSymbol, sourceId
FROM variant_to_gene_mappings_temp
WHERE geneId IN (SELECT geneId FROM gene_associations);

-- Drop the temporary table
DROP TEMPORARY TABLE IF EXISTS variant_to_gene_mappings_temp;

-- Create a temporary table for variant_associations
DROP TEMPORARY TABLE IF EXISTS variant_associations_temp;
CREATE TEMPORARY TABLE variant_associations_temp (
    snpId VARCHAR(255),
    class VARCHAR(255),
    chromosome VARCHAR(255),
    position INT,
    most_severe_consequence VARCHAR(255),
    DSI DECIMAL(5, 3) NULL,
    DPI DECIMAL(5, 3) NULL,
    NofDiseases INT,
    NofPmids INT
);

-- Load data into the temporary table
LOAD DATA LOCAL INFILE '/Users/jasonli1/Documents/NEU_Course/5200/database/variant_associations.tsv' 
INTO TABLE variant_associations_temp 
FIELDS TERMINATED BY '\t' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES (snpId, class, chromosome, position, most_severe_consequence, @DSI, @DPI, NofDiseases, NofPmids)
SET 
    DSI = NULLIF(TRIM(@DSI), ''),
    DPI = NULLIF(TRIM(@DPI), '');

-- Insert only valid rows into the main table
INSERT INTO variant_associations (snpId, class, chromosome, position, most_severe_consequence, DSI, DPI, NofDiseases, NofPmids)
SELECT snpId, class, chromosome, position, most_severe_consequence, DSI, DPI, NofDiseases, NofPmids
FROM variant_associations_temp
WHERE snpId IN (SELECT snpId FROM variant_to_gene_mappings);

-- Drop the temporary table
DROP TEMPORARY TABLE IF EXISTS variant_associations_temp;

-- Create a temporary table for vdisease_associations
DROP TEMPORARY TABLE IF EXISTS vdisease_associations_temp;
CREATE TEMPORARY TABLE vdisease_associations_temp (
    diseaseId VARCHAR(255),
    diseaseName VARCHAR(255),
    diseaseType VARCHAR(255),
    diseaseClass VARCHAR(255),
    diseaseSemanticType VARCHAR(255),
    NofSNPs INT,
    NofPmids INT
);

-- Load data into the temporary table
LOAD DATA LOCAL INFILE '/Users/jasonli1/Documents/NEU_Course/5200/database/vdisease_associations.tsv' 
INTO TABLE vdisease_associations_temp 
FIELDS TERMINATED BY '\t' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES (diseaseId, diseaseName, diseaseType, diseaseClass, diseaseSemanticType, NofSNPs, NofPmids);

-- Insert only valid rows into the main table
INSERT INTO vdisease_associations (diseaseId, diseaseName, diseaseType, diseaseClass, diseaseSemanticType, NofSNPs, NofPmids)
SELECT diseaseId, diseaseName, diseaseType, diseaseClass, diseaseSemanticType, NofSNPs, NofPmids
FROM vdisease_associations_temp
WHERE diseaseId IN (SELECT diseaseId FROM disease_mappings);

-- Drop the temporary table
DROP TEMPORARY TABLE IF EXISTS vdisease_associations_temp;

-- Create a temporary table for disease_associations
DROP TEMPORARY TABLE IF EXISTS disease_associations_temp;
CREATE TEMPORARY TABLE disease_associations_temp (
    diseaseId VARCHAR(255),
    diseaseName VARCHAR(255),
    diseaseType VARCHAR(255),
    diseaseClass VARCHAR(255),
    diseaseSemanticType VARCHAR(255),
    NofGenes INT,
    NofPmids INT
);

-- Load data into the temporary table
LOAD DATA LOCAL INFILE '/Users/jasonli1/Documents/NEU_Course/5200/database/disease_associations.tsv' 
INTO TABLE disease_associations_temp 
FIELDS TERMINATED BY '\t' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES (diseaseId, diseaseName, diseaseType, diseaseClass, diseaseSemanticType, NofGenes, NofPmids);

-- Insert only valid rows into the main table
INSERT INTO disease_associations (diseaseId, diseaseName, diseaseType, diseaseClass, diseaseSemanticType, NofGenes, NofPmids)
SELECT diseaseId, diseaseName, diseaseType, diseaseClass, diseaseSemanticType, NofGenes, NofPmids
FROM disease_associations_temp
WHERE diseaseId IN (SELECT diseaseId FROM disease_mappings);

-- Drop the temporary table
DROP TEMPORARY TABLE IF EXISTS disease_associations_temp;

-- Load data into ensembl_ncbi_mapping
DROP TEMPORARY TABLE IF EXISTS ensembl_ncbi_mapping_temp;
CREATE TEMPORARY TABLE ensembl_ncbi_mapping_temp (
    ensembl_gene_id VARCHAR(255),
    ncbi_gene_id INT
);

LOAD DATA LOCAL INFILE '/Users/jasonli1/Documents/NEU_Course/5200/database/mart_export.txt' 
INTO TABLE ensembl_ncbi_mapping_temp 
FIELDS TERMINATED BY '\t' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES (ensembl_gene_id, @ncbi_gene_id) 
SET 
    ncbi_gene_id = NULLIF(TRIM(@ncbi_gene_id), '');

-- Insert unique and valid data into the main table
INSERT INTO ensembl_ncbi_mapping (ensembl_gene_id, ncbi_gene_id)
SELECT ensembl_gene_id, MAX(ncbi_gene_id) AS ncbi_gene_id
FROM ensembl_ncbi_mapping_temp
WHERE ncbi_gene_id IS NOT NULL
GROUP BY ensembl_gene_id;

-- Drop the temporary table
DROP TEMPORARY TABLE IF EXISTS ensembl_ncbi_mapping_temp;

-- Disable foreign key checks
SET foreign_key_checks = 0;

-- Load data into TranscriptExpectedCounts
LOAD DATA LOCAL INFILE '/Users/jasonli1/Documents/NEU_Course/5200/database/melted_transcript_expected_count_test.csv'
INTO TABLE TranscriptExpectedCounts
FIELDS TERMINATED BY ',' -- comma delimiter
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(transcript_id, ensembl_gene_id, sample_id, expected_count)
SET 
    transcript_id = NULLIF(TRIM(transcript_id), ''),
    ensembl_gene_id = NULLIF(TRIM(ensembl_gene_id), ''),
    sample_id = NULLIF(TRIM(sample_id), ''),
    expected_count = NULLIF(TRIM(expected_count), '');

-- Load data into TranscriptTPM
LOAD DATA LOCAL INFILE '/Users/jasonli1/Documents/NEU_Course/5200/database/melted_transcript_tpm_test.csv'
INTO TABLE TranscriptTPM
FIELDS TERMINATED BY ',' -- comma delimiter
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(transcript_id, ensembl_gene_id, sample_id, tpm)
SET 
    transcript_id = NULLIF(TRIM(transcript_id), ''),
    ensembl_gene_id = NULLIF(TRIM(ensembl_gene_id), ''),
    sample_id = NULLIF(TRIM(sample_id), ''),
    tpm = NULLIF(TRIM(tpm), '');

-- Re-enable foreign key checks
SET foreign_key_checks = 1;

INSERT INTO disease_gene_associations (diseaseId, geneId)
SELECT DISTINCT d.diseaseId, g.geneId
FROM disease_associations d
JOIN gene_associations g
WHERE 
	g.geneId IN 
		(26, 204, 292, 381, 572, 799, 843, 
		 889, 952, 996, 1080, 1387, 1595, 
         1856, 2268, 2288, 2519, 2729, 3052, 
         3075, 3207, 3382, 3927, 3980, 4074, 
         4222, 4267, 4353, 4706, 4800, 5166, 
         5244, 5439, 5444, 5577, 5893, 5965, 
         5976, 6296, 6405, 6521, 6542, 6936, 
         7035, 7105, 8379, 8813, 8837, 8935, 
         9108, 9256, 9957, 10165, 10180, 10181, 
         10943, 22875, 23028, 23072, 23098, 23129, 
         26073, 29916, 51056, 51226, 51364, 51384, 
         54467, 54677, 55013, 55365, 55471, 55610, 
         55732, 55904, 56603, 56919, 56928, 57019, 
         57147, 57185, 57414, 57679, 64063, 54102, 
         79007, 79657, 80256, 81691, 81887, 84058, 
         84254, 85413, 90293, 90529, 93655, 115703, 
         126393, 170302, 221981, 340273)
    AND (d.diseaseSemanticType = 'Neoplastic Process' AND g.protein_class_name IN ('Enzyme', 'Nucleic acid binding'))
    OR (d.diseaseSemanticType = 'Disease or Syndrome' AND g.protein_class_name IN ('Receptor', 'Enzyme modulator'))
    OR (d.diseaseSemanticType = 'Congenital Abnormality' AND g.protein_class_name = 'Nucleic acid binding')
--     AND 
limit 20000;


-- Samples population stats
WITH
	patientsSamples AS (
		SELECT * FROM SubjectMetadata
		LEFT JOIN SampleMetadata USING (SUBJID))
SELECT SEX, AGE, count(*) AS cnt FROM patientsSamples
GROUP BY 1, 2
order by 2, 1;



-- CREATE TEMPORARY TABLE patients_gene_id AS (
WITH
	patientsSamples AS (
		SELECT * FROM SubjectMetadata
		LEFT JOIN SampleMetadata USING (SUBJID)),
    joinedTranscripts AS (
		SELECT 
        *,
        LEFT(ensembl_gene_id, 15) AS en_gene_id
		 FROM TranscriptTPM
		FULL JOIN TranscriptExpectedCounts 
			USING (id,transcript_id, ensembl_gene_id, sample_id)),
    patientsGene AS (
		SELECT * FROM patientsSamples a 
        LEFT JOIN 
			( SELECT * FROM joinedTranscripts c
				LEFT JOIN (
					SELECT 
						LEFT(ensembl_gene_id, 15) AS en_gene_id,
						ncbi_gene_id
                        FROM ensembl_ncbi_mapping) d 
					USING (en_gene_id)) b
            ON (a.SAMPID = b.sample_id)
    ),
    joinedDiseaseGene AS (
		SELECT 
			diseaseId,
            geneId,
            diseaseName,
            diseaseType,
            diseaseClass,
            diseaseSemanticType,
            NofGenes,
            NofPmids
        FROM disease_gene_associations JOIN disease_associations USING (diseaseId)
    ),
    joinedPatientsDisease AS (
		select * from patientsGene a LEFT JOIN joinedDiseaseGene b ON (b.geneId = a.ncbi_gene_id)
    )
    /*
    -- Functionality 1: Find subject's disease 
    SELECT 
    SUBJID,
    SEX, 
    AGE,
    geneId,
    diseaseId,
    diseaseName,
    diseaseType,
    diseaseClass,
    diseaseSemanticType
	FROM joinedPatientsDisease
    WHERE diseaseId IS NOT NULL
		AND SUBJID = 'GTEX-1117F';
    */
    /*
    -- Functionality 2: Stats of sampling group
    SELECT 
	SEX, 
	AGE,
	COUNT(*) AS cnt
	FROM joinedPatientsDisease
    WHERE diseaseId IS NOT NULL
	GROUP BY 1, 2
	ORDER BY 2, 1
    */
	/*
    -- Functionality 3: Disease distribution by name
    SELECT 
		diseaseName,
        count(*) AS cnt
        FROM joinedPatientsDisease
        WHERE diseaseId IS NOT NULL
	GROUP BY 1
	ORDER BY 1
	*/
    
    /*
    -- Functionality 4: Disease distribution by diseaseType
    SELECT 
		diseaseType,
        count(*) AS cnt
        FROM joinedPatientsDisease
        WHERE diseaseId IS NOT NULL
	GROUP BY 1
	ORDER BY 1
    ;
*/
/*
    -- Functionality 5: Disease distribution by diseaseClass
    SELECT 
		diseaseClass,
        count(*) AS cnt
        FROM joinedPatientsDisease
        WHERE diseaseId IS NOT NULL
	GROUP BY 1
	ORDER BY 1
;
*/