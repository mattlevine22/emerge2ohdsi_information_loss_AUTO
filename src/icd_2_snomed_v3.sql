--create a table, where each row represents a single ICD -> SNOMED mapping, using OMOP ids.
DROP TABLE icd_maps;
CREATE TABLE icd_maps AS
SELECT concept_id_1 AS omop_id_icd, concept_id_2 AS omop_id_snomed
FROM public.concept_relationship
WHERE relationship_id = 'Maps to'
AND concept_id_1 IN (
--all ICD9 codes
SELECT concept_id
FROM public.concept
WHERE vocabulary_id = 'ICD9CM'
AND domain_id = 'Condition'
)
AND concept_id_2 IN (
--all standard SNOMED codes
SELECT concept_id
FROM public.concept
WHERE standard_concept = 'S'
AND vocabulary_id = 'SNOMED'
)
AND invalid_reason IS NULL --sometimes, there are "invalid" mappings, which we want to exclude
;

--Create table that indexes [ICD, number of Snomed mappings], n>0
DROP TABLE pos_n_icd_maps;
CREATE TABLE pos_n_icd_maps AS
SELECT omop_id_icd, COUNT(omop_id_snomed) as num_snomed_mappings
FROM icd_maps
GROUP BY omop_id_icd
ORDER BY num_snomed_mappings DESC, omop_id_icd ASC
;

--Make a separate table of only NULL mappings, i.e. all the ICD codes that do not map to ANY snomed code
--Notes:
--1. some of these are Procedure ICD9s...should we make sure it is a CONDITION/OBSERVATION domain? HOW??!!
--2. Why do some seem to have a valid snomed mapping? e.g. 44820204 has a valid SNOMED mapping, but appears in the null list and does not appear in icd_map table!
--3.
DROP TABLE null_icd_maps;
CREATE TABLE null_icd_maps AS
SELECT concept_id as omop_id_icd
FROM public.concept
WHERE vocabulary_id = 'ICD9CM'
AND domain_id = 'Condition'
AND concept_name NOT LIKE '%do not use%'
AND concept_id NOT IN (
SELECT omop_id_icd
FROM icd_maps
)
;

--add a column that indicates count of the null ICDs
ALTER TABLE null_icd_maps
ADD num_snomed_mappings INTEGER
;

--set the count of all null icds to 0
UPDATE null_icd_maps
SET num_snomed_mappings = 0
;


--Add Null mappings to n_icd_maps (n=0)
DROP TABLE n_icd_maps;
CREATE TABLE n_icd_maps AS
SELECT * FROM null_icd_maps
UNION ALL
SELECT * FROM pos_n_icd_maps
ORDER BY num_snomed_mappings ASC, omop_id_icd ASC
;

--How many ICD codes map to exactly n SNOMED codes, for n=0,1,2,3,...N
CREATE TABLE n_count_icd_maps as
SELECT num_snomed_mappings, COUNT(omop_id_icd) AS num_icd_codes
FROM n_icd_maps
GROUP BY num_snomed_mappings
ORDER BY num_snomed_mappings ASC
;

select * from n_count_icd_maps;
DROP TABLE icd_maps;
DROP TABLE pos_n_icd_maps;
DROP TABLE null_icd_maps;
-- DROP TABLE n_icd_maps;
drop table n_count_icd_maps;



