-- 1.	How many ICD9CM codes are in the OMOP vocabulary?
select count(distinct concept_id) from public.concept where vocabulary_id = 'ICD9CM';
-- 2.	How many ICD9CM condition codes are in the OMOP vocabulary?
select count(distinct concept_id) from public.concept where vocabulary_id = 'ICD9CM' and domain_id='Condition';
-- 3.	How many ICD9CM condition codes in the OMOP vocabulary map to exactly n standard SNOMED codes, for n=0,1,2,3…
icd_2_snomed_v3.sql
-- 4.	How many SNOMED codes map to exactly n ICD9CM codes, for n=0,1,2,3…
snomed_from_icd.sql
-- 7.	What proportion of condition occurrences have an ICD9CM source code that has exactly n SNOMED mappings, for n=0,1,2,3…
icd_2_snomed_v3.sql (generate n_icd_maps table)

-- 8.	What proportion of patients have at least one condition occurrence with an ICD9CM source code that has exactly n SNOMED mappings, for n=0,1,2,3…

-- 9.	How many condition_source_concept_id codes in the condition_occurrence table map to 0 in our database
select count(distinct condition_source_concept_id) from public.condition_occurrence where condition_concept_id=0;

-- 10.	ii.	How many standard SNOMED mappings do these have? (hint, not all have 0 maps because of ETL issues)
select num_snomed_mappings, count(condition_source_concept_id) as num_icd_codes
from (
select x.condition_source_concept_id, n_icd_maps.num_snomed_mappings
from (select distinct condition_source_concept_id from public.condition_occurrence where condition_concept_id=0) x
left join n_icd_maps
on n_icd_maps.omop_id_icd = x.condition_source_concept_id) x
group by num_snomed_mappings
order by num_snomed_mappings asc;

--(side check to make sure that the null count are not ICD9 codes...)
select distinct vocabulary_id
from (select * from tmp123 where num_snomed_mappings is null) x
left join public.concept
on x.condition_source_concept_id = public.concept.concept_id;

-- 11a.	How many non-condition ICD codes are in our phenotype list, but are NOT in the condition_occurrence table
select count(distinct concept_id)
from (select * from icd_src_concepts where concept_domain_id='Observation') x
left join public.condition_occurrence
on x.concept_id = public.condition_occurrence.condition_source_concept_id
where condition_source_concept_id is null;

-- 11b.	How many non-condition ICD codes are in our phenotype list, and ARE in the condition_occurrence table
select count(distinct concept_id)
from (select * from icd_src_concepts where concept_domain_id='Observation') x
left join public.condition_occurrence
on x.concept_id = public.condition_occurrence.condition_source_concept_id
where condition_source_concept_id is not null;



