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
-- AND domain_id = 'Condition'
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
-- AND domain_id = 'Condition'
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

drop table condition_src_descriptions;
create table condition_src_descriptions as
select x.concept_id, x.condition_concept_id, x.person_id, num_snomed_mappings, z.domain_id, z.vocabulary_id, z.standard_concept
-- from (select condition_source_concept_id as concept_id, condition_concept_id, person_id from public.condition_occurrence) x
from (select condition_source_concept_id as concept_id, condition_concept_id, person_id from fake_condition_occurrence) x
left join (select omop_id_icd as concept_id, num_snomed_mappings from n_icd_maps) y USING (concept_id)
left join (select * from public.concept) z USING (concept_id);

-- 7.	What are the source code domain breakdowns in the condition occurrence table?
SELECT domain_id, COUNT(concept_id) AS num_condition_occurrences
FROM condition_src_descriptions
GROUP BY domain_id
ORDER BY num_condition_occurrences DESC;

-- 7.	What are the source code vocabulary breakdowns in the condition occurrence table?
SELECT vocabulary_id, COUNT(concept_id) AS num_condition_occurrences
FROM condition_src_descriptions
GROUP BY vocabulary_id
ORDER BY num_condition_occurrences DESC;

--How many condition occurrences have an ICD9CM Condition
-- source code with exactly n SNOMED mappings, for n=0,1,2,3
SELECT num_snomed_mappings, COUNT(concept_id) AS num_condition_occurrences
FROM (select * from condition_src_descriptions where domain_id='Condition' and vocabulary_id='ICD9CM') x
GROUP BY num_snomed_mappings
ORDER BY num_snomed_mappings ASC;

-- 6.	How many patients have at least one condition occurrence with an ICD9CM source code that has exactly n SNOMED mappings, for n=0,1,2,3…
select count(distinct person_id) from condition_src_descriptions where num_snomed_mappings=0 and domain_id='Condition' and vocabulary_id='ICD9CM';
select count(distinct person_id) from condition_src_descriptions where num_snomed_mappings=1 and domain_id='Condition' and vocabulary_id='ICD9CM';
select count(distinct person_id) from condition_src_descriptions where num_snomed_mappings=2 and domain_id='Condition' and vocabulary_id='ICD9CM';
select count(distinct person_id) from condition_src_descriptions where num_snomed_mappings=3 and domain_id='Condition' and vocabulary_id='ICD9CM';
select count(distinct person_id) from condition_src_descriptions where num_snomed_mappings>3 and domain_id='Condition' and vocabulary_id='ICD9CM';


drop table icd_maps;
drop table pos_n_icd_maps;
drop table null_icd_maps;
drop table condition_src_descriptions;

