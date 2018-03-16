--long_run3 adds constraint that we only check if a source code is ICD9CM if it is listed as a 'Condition' domain in the original CSV document
--note that the final count of patients in each concept set uses valid/invalid standard/non-standard mappings

-- create empty shell for emerge concept set table
DROP TABLE emerge_concept_sets;
DROP TABLE my_input;

CREATE TABLE my_input (
	idx INTEGER,
	src_file_name VARCHAR(50),
	concept_set_name VARCHAR(50),
	domain_type VARCHAR(50),
	concept_code VARCHAR(50)
);

-- load pre-processed emerge csv into the table
\copy my_input FROM './emerge_files/eMERGE_concept_sets_processed.csv' WITH DELIMITER ',' CSV HEADER;

create table emerge_concept_sets as
	select *
	from my_input;
drop table my_input;

DROP TABLE definite_n_mappings;
DROP TABLE definite_null_mappings;
DROP TABLE possible_null_mappings;
DROP TABLE definite_badcodes;
DROP TABLE possible_badcodes;
DROP TABLE definite_goodcodes;
drop table bad_icd_src_concepts;
DROP TABLE icd_src_concepts;
DROP TABLE icd_src_concepts_mapped;
DROP TABLE icd_src_concepts_mapped_descendants;
DROP TABLE src_concepts_and_patients;
DROP TABLE patients_per_src_concept_id;
DROP TABLE descendants_concepts_and_patients;
DROP TABLE patients_per_descendant_concept_id;
DROP TABLE patients_per_mapped_concept_id;
DROP TABLE patients_per_set_via_src;
DROP TABLE patients_per_set_via_mapping;
DROP TABLE num_icd_src2standard_valid_mappings;
-- subset of the concept table corresponding to emerge source codes
-- this is the inner join of concepts in emerge csv and ohdsi concept table

--make table of all detectable ICD9CM codes in the emerge csv
CREATE TABLE icd_src_concepts AS
(
	SELECT DISTINCT idx, goo.concept_code, concept_id, domain_id as concept_domain_id, invalid_reason as concept_code_invalid_reason, standard_concept as src_is_standard, vocabulary_id as src_vocabulary_id
	FROM (select * from emerge_concept_sets where domain_type = 'Condition') as goo
	JOIN public.concept ON goo.concept_code = public.concept.concept_code
	WHERE vocabulary_id = 'ICD9CM'
	-- AND public.concept.invalid_reason IS NULL
);

-- ?: How many unique concept_codes did we keep? How many unique omop ids did we get?
SELECT COUNT(distinct concept_code) FROM icd_src_concepts; --6480
SELECT COUNT(distinct concept_id) FROM icd_src_concepts; --6480
SELECT COUNT(*) FROM (select distinct * from icd_src_concepts) x; --6480

--?: How many invalid ICDs are there?
--this involves checking to make sure that there is ONLY an INVALID omop code for an icd
create table possible_badcodes AS
(
SELECT DISTINCT concept_id
FROM icd_src_concepts
WHERE concept_code_invalid_reason IS not NULL
);

create table definite_goodcodes AS
(SELECT DISTINCT concept_id
FROM icd_src_concepts
WHERE concept_code_invalid_reason IS NULL
);

create table definite_badcodes as
(select *
from possible_badcodes
WHERE concept_id NOT IN (
	select *
	from definite_goodcodes
	)
);

CREATE TABLE bad_icd_src_concepts as
select icd_src_concepts.*
from icd_src_concepts
Right join definite_badcodes
on icd_src_concepts.concept_id = definite_badcodes.concept_id
;

--these are the invalid ICDs
select * from bad_icd_src_concepts order by concept_code;
--So, how many Invalid ICDs are there? 3
select count(distinct concept_id) from bad_icd_src_concepts;


--get all 'mappings' (even invalid) for these detected ICD9CM codes.
--do a left join so that we see when there is no mapping for an icd_src_concept row
CREATE TABLE icd_src_concepts_mapped AS
SELECT DISTINCT foo.*, vocabulary_id as mapped_vocabulary_id, standard_concept as mapped_is_standard
FROM
(
	SELECT DISTINCT idx, concept_code, concept_id, concept_domain_id, concept_code_invalid_reason, src_vocabulary_id, src_is_standard, concept_id_2 as mapped_concept_id, maps_to_invalid_reason
	FROM icd_src_concepts
	LEFT JOIN (
		SELECT concept_id_1, concept_id_2, relationship_id, invalid_reason as maps_to_invalid_reason
		FROM public.concept_relationship
		WHERE relationship_id = 'Maps to' --needs to be inside the join, or it will spoil the join!
		-- AND invalid_reason IS NULL --this where needs to be inside join. otherwise, it spoils the join!
		) foo ON icd_src_concepts.concept_id = foo.concept_id_1
) foo
LEFT JOIN public.concept
ON foo.mapped_concept_id = public.concept.concept_id
;

--Make sure the left joins worked, and we didn't lose any concept codes or concept_ids
SELECT COUNT(distinct concept_code) FROM icd_src_concepts_mapped; --6480
SELECT COUNT(distinct concept_id) FROM (select concept_id from icd_src_concepts_mapped where concept_id is not null) x; --6480

--how many distinct mapped_concept_id did we map to?
SELECT COUNT(distinct mapped_concept_id) FROM icd_src_concepts_mapped; --4144
--ok, this means that overall, we are mapping into a smaller space. condensing information.

--?: How many NULL mappings are there? looks like ZERO!
SELECT COUNT(*) FROM (select distinct concept_id from icd_src_concepts_mapped WHERE mapped_concept_id IS NULL) x;

--?: How many invalid mappings are there? (note that many of the codes with an invalid mapping ALSO have a valid mapping)
SELECT COUNT(distinct mapped_concept_id) FROM icd_src_concepts_mapped WHERE maps_to_invalid_reason IS NOT NULL; --375

--?: How did the invalid ICD codes get mapped? (looks like they actually all have a valid mapping!)
select icd_src_concepts_mapped.*
from bad_icd_src_concepts
left join icd_src_concepts_mapped
on bad_icd_src_concepts.concept_id = icd_src_concepts_mapped.concept_id
order by concept_code;

--how many of the N mappings are there (valid/invalid)?
select num_mappings, count(concept_code) as num_icds
from
(select concept_code, count(distinct mapped_concept_id) as num_mappings
from icd_src_concepts_mapped
group by concept_code
) as goo
group by num_mappings
order by num_mappings asc;

--Inspect the VALID STANDARD mappings ?
create table definite_n_mappings as
select distinct *
from icd_src_concepts_mapped
where (maps_to_invalid_reason is null
AND mapped_is_standard = 'S');

create table possible_null_mappings as
select distinct *
from icd_src_concepts_mapped
where (maps_to_invalid_reason is not null
	OR mapped_is_standard != 'S');

create table definite_null_mappings as
(select distinct *
from possible_null_mappings
WHERE concept_id NOT IN (
	select concept_id
	from definite_n_mappings
	)
);

--how many sources codes have n>0 valid standard mappings
CREATE TABLE num_icd_src2standard_valid_mappings as
select distinct concept_code, concept_id, count(distinct mapped_concept_id) as num_mappings
from icd_src_concepts_mapped
where (maps_to_invalid_reason is null
AND mapped_is_standard = 'S')
group by concept_code, concept_id;

select num_mappings, count(concept_code) as num_icds
from num_icd_src2standard_valid_mappings as goo
group by num_mappings
order by num_mappings asc;

--how many source codes only have 0 valid standard mappings?
select count(distinct concept_id) from definite_null_mappings;
--Which source codes have 0 valid standard mappings?
select * from definite_null_mappings order by concept_code;

-- append descendants of mapped codes
CREATE TABLE icd_src_concepts_mapped_descendants AS
SELECT DISTINCT foo.*, vocabulary_id as descendant_vocabulary_id, standard_concept as descendant_is_standard
FROM
(
SELECT DISTINCT icd_src_concepts_mapped.*, descendant_concept_id as descendant_mapped_concept_id
FROM icd_src_concepts_mapped
LEFT JOIN public.concept_ancestor
ON icd_src_concepts_mapped.mapped_concept_id = public.concept_ancestor.ancestor_concept_id
) foo
LEFT JOIN public.concept
ON foo.descendant_mapped_concept_id = public.concept.concept_id
;

CREATE INDEX my_idx on icd_src_concepts_mapped_descendants (idx, concept_id);

--make a table that counts patients per src concept code
CREATE TABLE src_concepts_and_patients AS
select icd_src_concepts.concept_id, icd_src_concepts.idx, person_id
from icd_src_concepts
left join full_fake_condition_occurrence
on icd_src_concepts.concept_id = full_fake_condition_occurrence.condition_source_concept_id;

CREATE INDEX concept_id_idx on src_concepts_and_patients (concept_id);

create table patients_per_src_concept_id AS
select concept_id, COUNT(DISTINCT person_id) as num_patients_per_src_concept
from (select * from src_concepts_and_patients where person_id is not null) x
group by concept_id
order by concept_id;

--make a table that counts patients per descendant_mapped_concept_id
CREATE TABLE descendants_concepts_and_patients AS
select descendant_mapped_concept_id, idx, person_id
from (
	select distinct descendant_mapped_concept_id, idx
	from icd_src_concepts_mapped_descendants
	) foo
left join full_fake_condition_occurrence
on foo.descendant_mapped_concept_id = full_fake_condition_occurrence.condition_concept_id;

CREATE INDEX desc_pats_concept_idx on descendants_concepts_and_patients (descendant_mapped_concept_id);

create table patients_per_descendant_concept_id AS
select descendant_mapped_concept_id, COUNT(DISTINCT person_id) as num_patients_per_descendant_concept
from (select * from descendants_concepts_and_patients where person_id is not null) x
group by descendant_mapped_concept_id
order by descendant_mapped_concept_id;

--make a table that counts patients per mapped_concept_id
-- CREATE TABLE patients_per_mapped_concept_id AS
-- select distinct descendant_mapped_concept_id as mapped_concept_id, SUM(num_patients_per_descendant_concept) as num_patients_per_mapped_concept
-- from patients_per_descendant_concept_id
-- where descendant_mapped_concept_id in (
-- 	select distinct mapped_concept_id
-- 	from icd_src_concepts_mapped_descendants
-- )
-- group by descendant_mapped_concept_id;

--these two tables are for listing patients per concept set
drop table persons_and_idx_via_src;
drop table persons_and_idx_via_mapping;

CREATE TABLE persons_and_idx_via_src AS
SELECT DISTINCT idx, person_id
FROM src_concepts_and_patients
WHERE person_id is not null
ORDER BY idx, person_id;

CREATE TABLE persons_and_idx_via_mapping AS
SELECT DISTINCT idx, person_id
FROM descendants_concepts_and_patients
WHERE person_id is not null
ORDER BY idx, person_id;

--list patients for each concept, and label as 'source', 'mapped', or 'both'
drop table foofoo_src;
create table foofoo_src as
	select distinct *
	from (
		select distinct concept_id
		from icd_src_concepts_mapped_descendants
		) as x
	left join (select distinct concept_id, person_id as person_id_src from src_concepts_and_patients) as y USING (concept_id);

drop table foofoo_map;
create table foofoo_map as
	select distinct *
	from (
		select distinct concept_id, descendant_mapped_concept_id
		from icd_src_concepts_mapped_descendants
		) as x
	left join (select distinct descendant_mapped_concept_id, person_id as person_id_mapping from descendants_concepts_and_patients) as y USING (descendant_mapped_concept_id);

drop table foofoo;
CREATE TABLE foofoo AS
SELECT DISTINCT foofoo_src.concept_id as concept_id_src, xfoo.concept_id as concept_id_map, person_id_src, person_id_mapping
FROM foofoo_src
FULL OUTER JOIN (select distinct concept_id, person_id_mapping from foofoo_map) as xfoo
ON foofoo_src.concept_id = xfoo.concept_id
AND foofoo_src.person_id_src = xfoo.person_id_mapping;

ALTER TABLE foofoo
ADD COLUMN concept_id INTEGER,
ADD COLUMN patient_inclusion VARCHAR(25),
ADD COLUMN person_id INTEGER;

UPDATE foofoo
	SET concept_id = concept_id_src
	where concept_id_src is not null;
UPDATE foofoo
	SET concept_id = concept_id_map
	where concept_id_map is not null;
UPDATE foofoo
	SET patient_inclusion = 'SOURCE'
	where person_id_src is not null
		and person_id_mapping is null;
UPDATE foofoo
	SET patient_inclusion = 'MAPPED'
	where person_id_mapping is not null
		and person_id_src is null;
UPDATE foofoo
	SET patient_inclusion = 'BOTH'
	where person_id_mapping is not null
		and person_id_src is not null;
UPDATE foofoo
	set person_id = person_id_src
	where person_id_src is not null;
UPDATE foofoo
	set person_id = person_id_mapping
	where person_id_mapping is not null;

ALTER TABLE foofoo
	DROP COLUMN concept_id_src,
	DROP COLUMN concept_id_map,
	DROP COLUMN person_id_src,
	DROP COLUMN person_id_mapping;

drop table patient_inclusion_per_src_code;
create table patient_inclusion_per_src_code as
	select concept_id, person_id, patient_inclusion
	from foofoo
	order by concept_id, person_id;

drop table a2_src;
drop table a2_mapped;
drop table a2_both;
drop table count_patient_inclusion_per_src_code;
CREATE TABLE a2_src as select concept_id, count(patient_inclusion) as num_patients_per_src_code_src_only
from patient_inclusion_per_src_code
where patient_inclusion = 'SOURCE'
group by concept_id;

CREATE TABLE a2_mapped as
select concept_id, count(patient_inclusion) as num_patients_per_src_code_map_only
from patient_inclusion_per_src_code
where patient_inclusion = 'MAPPED'
group by concept_id;

CREATE TABLE a2_both as select concept_id, count(patient_inclusion) as num_patients_per_src_code_both
from patient_inclusion_per_src_code
where patient_inclusion = 'BOTH'
group by concept_id;

create table count_patient_inclusion_per_src_code as
select *
from (select distinct concept_id from icd_src_concepts) x
left join a2_both USING (concept_id)
left join a2_src USING (concept_id)
left join a2_mapped  USING (concept_id)
order by concept_id;

update count_patient_inclusion_per_src_code set num_patients_per_src_code_both = 0 where num_patients_per_src_code_both is null;
update count_patient_inclusion_per_src_code set num_patients_per_src_code_src_only = 0 where num_patients_per_src_code_src_only is null;
update count_patient_inclusion_per_src_code set num_patients_per_src_code_map_only = 0 where num_patients_per_src_code_map_only is null;

\copy count_patient_inclusion_per_src_code TO './output_all_descendants/count_patient_inclusion_per_src_code.csv' DELIMITER ',' CSV HEADER;


--list patients in each concept SET, and label as 'source', 'mapped', or 'both'
drop table booboo;
CREATE TABLE booboo AS
SELECT DISTINCT persons_and_idx_via_src.idx AS idx_src, persons_and_idx_via_mapping.idx AS idx_mapping, persons_and_idx_via_src.person_id AS person_id_src, persons_and_idx_via_mapping.person_id AS person_id_mapping
FROM persons_and_idx_via_src
FULL OUTER JOIN persons_and_idx_via_mapping
ON persons_and_idx_via_src.person_id = persons_and_idx_via_mapping.person_id
AND persons_and_idx_via_src.idx = persons_and_idx_via_mapping.idx;

ALTER TABLE booboo
ADD COLUMN patient_inclusion VARCHAR(25),
ADD COLUMN idx INTEGER,
ADD COLUMN person_id INTEGER;

UPDATE booboo
	SET patient_inclusion = 'SOURCE'
	where person_id_src is not null
		and person_id_mapping is null;
UPDATE booboo
	SET patient_inclusion = 'MAPPED'
	where person_id_mapping is not null
		and person_id_src is null;
UPDATE booboo
	SET patient_inclusion = 'BOTH'
	where person_id_mapping is not null
		and person_id_src is not null;
UPDATE booboo
	SET idx = idx_src
	where idx_src is not null;
UPDATE booboo
	SET idx = idx_mapping
	where idx_mapping is not null;
UPDATE booboo
	set person_id = person_id_src
	where person_id_src is not null;
UPDATE booboo
	set person_id = person_id_mapping
	where person_id_mapping is not null;

drop table patient_inclusion_per_concept_set;
create table patient_inclusion_per_concept_set as
	select idx, person_id, patient_inclusion
	from booboo
	order by idx, person_id;

drop table booboo;
drop table a1_src;
drop table a1_mapped;
drop table a1_both;
drop table count_patient_inclusion_per_concept_set;
CREATE TABLE a1_src as select idx, count(patient_inclusion) as num_patients_per_concept_set_src_only
from patient_inclusion_per_concept_set
where patient_inclusion = 'SOURCE'
group by idx;

CREATE TABLE a1_mapped as
select idx, count(patient_inclusion) as num_patients_per_concept_set_map_only
from patient_inclusion_per_concept_set
where patient_inclusion = 'MAPPED'
group by idx;

CREATE TABLE a1_both as select idx, count(patient_inclusion) as num_patients_per_concept_set_both
from patient_inclusion_per_concept_set
where patient_inclusion = 'BOTH'
group by idx;

create table count_patient_inclusion_per_concept_set as
select *
from (select distinct idx from icd_src_concepts) x
left join a1_both USING (idx)
left join a1_src USING (idx)
left join a1_mapped  USING (idx)
left join (select DISTINCT idx, src_file_name, concept_set_name, domain_type from emerge_concept_sets) y USING (idx)
order by idx;

update count_patient_inclusion_per_concept_set set num_patients_per_concept_set_both = 0 where num_patients_per_concept_set_both is null;
update count_patient_inclusion_per_concept_set set num_patients_per_concept_set_src_only = 0 where num_patients_per_concept_set_src_only is null;
update count_patient_inclusion_per_concept_set set num_patients_per_concept_set_map_only = 0 where num_patients_per_concept_set_map_only is null;

\copy (select * from count_patient_inclusion_per_concept_set order by idx) TO './output_all_descendants/count_patient_inclusion_per_concept_set.csv' DELIMITER ',' CSV HEADER;

--### COUNTING patients per concept set###
DROP TABLE tmp_codes2_src;
DROP TABLE sub_condition_occurrence_source_idx;
DROP TABLE patients_per_set_via_src;
DROP TABLE tmp_codes2_map;
DROP TABLE sub_condition_occurrence_map_idx;
DROP TABLE patients_per_set_via_mapping;

-- get distinct list of concept codes and their cohort idx, then index it
CREATE TABLE tmp_codes2_src AS
SELECT DISTINCT idx, concept_id
FROM icd_src_concepts_mapped_descendants;

CREATE INDEX tmp_code2_src_idx ON tmp_codes2_src (idx, concept_id);

CREATE TABLE sub_condition_occurrence_source_idx AS
SELECT src_concepts_and_patients.*
FROM tmp_codes2_src
LEFT JOIN src_concepts_and_patients ON tmp_codes2_src.concept_id = src_concepts_and_patients.concept_id;

-- count persons per source concept and index it
CREATE TABLE patients_per_set_via_src AS
SELECT idx, COUNT(DISTINCT person_id) AS total_patients_per_set_via_src
FROM sub_condition_occurrence_source_idx
GROUP BY idx;


-- get distinct list of concept codes and their cohort idx, then index it
CREATE TABLE tmp_codes2_map AS
SELECT DISTINCT idx, descendant_mapped_concept_id
FROM icd_src_concepts_mapped_descendants;

CREATE INDEX tmp_code2_map_idx ON tmp_codes2_map (idx, descendant_mapped_concept_id);

CREATE TABLE sub_condition_occurrence_map_idx AS
SELECT descendants_concepts_and_patients.*
FROM tmp_codes2_map
LEFT JOIN descendants_concepts_and_patients ON tmp_codes2_map.descendant_mapped_concept_id = descendants_concepts_and_patients.descendant_mapped_concept_id;

-- count persons per source concept and index it
CREATE TABLE patients_per_set_via_mapping AS
SELECT idx, COUNT(DISTINCT person_id) AS total_patients_per_set_via_mapping
FROM sub_condition_occurrence_map_idx
GROUP BY idx;

--connect everything back to the emerge
DROP TABLE foo1;
DROP TABLE foo2;
DROP TABLE foo22;
DROP TABLE foo3;
DROP TABLE foo4;
DROP TABLE foo5;
DROP TABLE foo6;
DROP TABLE foo7;
DROP TABLE foo8;


create table foo1 as
select distinct
	emerge_concept_sets.* ,
	icd_src_concepts_mapped_descendants.concept_id,
	icd_src_concepts_mapped_descendants.concept_code_invalid_reason,
	icd_src_concepts_mapped_descendants.src_vocabulary_id,
	icd_src_concepts_mapped_descendants.src_is_standard,
	icd_src_concepts_mapped_descendants.mapped_concept_id,
	icd_src_concepts_mapped_descendants.maps_to_invalid_reason,
	icd_src_concepts_mapped_descendants.mapped_vocabulary_id,
	icd_src_concepts_mapped_descendants.mapped_is_standard,
	icd_src_concepts_mapped_descendants.descendant_mapped_concept_id,
	icd_src_concepts_mapped_descendants.descendant_vocabulary_id,
	icd_src_concepts_mapped_descendants.descendant_is_standard
from emerge_concept_sets
left join icd_src_concepts_mapped_descendants USING (concept_code);

create table foo22 as
select *
from foo1
left join patients_per_src_concept_id USING (concept_id);

-- create table foo22 as
-- select *
-- from foo2
-- left join patients_per_mapped_concept_id USING (mapped_concept_id);


create table foo3 as
select *
from foo22
left join patients_per_descendant_concept_id USING (descendant_mapped_concept_id);

update foo3
	set num_patients_per_descendant_concept = 0
	where num_patients_per_descendant_concept IS NULL;

create table foo4 as
select foo3.*, concept_name as src_concept_name, domain_id as concept_domain_id
from foo3
left join public.concept USING (concept_id);

create table foo5 as
select foo4.*, concept_name as mapped_concept_name
from foo4
left join public.concept on foo4.mapped_concept_id = public.concept.concept_id;

create table foo6 as
select foo5.*, concept_name as descendant_concept_name
from foo5
left join public.concept on foo5.descendant_mapped_concept_id = public.concept.concept_id;

create table foo7 as
	select foo6.*, num_icd_src2standard_valid_mappings.num_mappings as num_icd_src2standard_valid_mappings
	from foo6
	left join num_icd_src2standard_valid_mappings USING (concept_id);

--need to add patients_per_set_via_source and patients_per_set_via_map
drop table emerge_final_table;

create table emerge_final_table as
	select *
	from foo7
	left join patients_per_set_via_src USING (idx)
	left join patients_per_set_via_mapping USING (idx)
	left join (
		select idx, num_patients_per_concept_set_both, num_patients_per_concept_set_src_only, num_patients_per_concept_set_map_only
		from count_patient_inclusion_per_concept_set
		) x USING (idx)
	left join (
		select concept_id, num_patients_per_src_code_both, num_patients_per_src_code_src_only, num_patients_per_src_code_map_only
		from count_patient_inclusion_per_src_code
		) y USING (concept_id);

ALTER TABLE emerge_final_table
	ADD COLUMN fraction_patient_gain_from_map NUMERIC,
	ADD COLUMN fraction_patient_loss_from_map NUMERIC;

-- update emerge_final_table
-- 	set fraction_patient_gain_from_map = cast(num_patients_map_only as decimal) / cast(num_patients_both as decimal)
-- 	where num_patients_both !=0 ;

-- update emerge_final_table
-- 	set fraction_patient_loss_from_map = cast(num_patients_src_only as decimal) / cast(num_patients_both as decimal)
-- 	where num_patients_both !=0 ;

update emerge_final_table
	set num_icd_src2standard_valid_mappings = 0
	where (num_icd_src2standard_valid_mappings is null
	and src_vocabulary_id = 'ICD9CM');

drop table emerge_final_icd_table;
create table emerge_final_icd_table as
	select *
	from emerge_final_table
	where src_vocabulary_id = 'ICD9CM'
	order by idx, mapped_concept_id, descendant_mapped_concept_id;

\copy emerge_final_icd_table TO './output_all_descendants/emerge_final_icd_table.csv' DELIMITER ',' CSV HEADER;

-- Clean things up, delete temporary tables
DROP TABLE definite_n_mappings;
DROP TABLE definite_null_mappings;
DROP TABLE possible_null_mappings;
DROP TABLE definite_badcodes;
DROP TABLE possible_badcodes;
DROP TABLE definite_goodcodes;
drop table bad_icd_src_concepts;
DROP TABLE icd_src_concepts;
DROP TABLE icd_src_concepts_mapped;
DROP TABLE icd_src_concepts_mapped_descendants;
DROP TABLE src_concepts_and_patients;
-- DROP TABLE patients_per_src_concept_id;
-- DROP TABLE descendants_concepts_and_patients;
-- DROP TABLE patients_per_descendant_concept_id;
-- DROP TABLE patients_per_mapped_concept_id;
-- DROP TABLE patients_per_set_via_src;
-- DROP TABLE patients_per_set_via_mapping;
DROP TABLE num_icd_src2standard_valid_mappings;
DROP TABLE tmp_codes2_src;
DROP TABLE sub_condition_occurrence_source_idx;
-- DROP TABLE patients_per_set_via_src;
DROP TABLE tmp_codes2_map;
DROP TABLE sub_condition_occurrence_map_idx;
-- DROP TABLE patients_per_set_via_mapping;
DROP TABLE foo1;
DROP TABLE foo2;
DROP TABLE foo22;
DROP TABLE foo3;
DROP TABLE foo4;
DROP TABLE foo5;
DROP TABLE foo6;
-- DROP TABLE foo7;
drop table a1_src;
drop table a1_mapped;
drop table a1_both;

