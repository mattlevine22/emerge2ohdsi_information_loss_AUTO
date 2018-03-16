create table IF NOT EXISTS emerge_final_icd_table as
	select *
	from emerge_final_table
	where src_vocabulary_id = 'ICD9CM'
	order by idx, mapped_concept_id, descendant_mapped_concept_id;

drop table tmp1;

create table tmp1 as
select idx, descendant_mapped_concept_id, mapped_concept_id, concept_id, concept_code, remapped_concept_id, remapped_concept_code, remapped_concept_name, remapped_vocabulary_id, remapped_mapped_from_invalid_reason
from emerge_final_icd_table
LEFT JOIN (
SELECT concept_id_1 as descendant_mapped_concept_id, concept_id_2 as remapped_concept_id, invalid_reason as remapped_mapped_from_invalid_reason
FROM public.concept_relationship
WHERE relationship_id = 'Mapped from'
) foo USING (descendant_mapped_concept_id)
LEFT JOIN
	(select concept_id as remapped_concept_id, concept_name as remapped_concept_name, domain_id as remapped_domain_id, vocabulary_id as remapped_vocabulary_id, standard_concept, concept_code as remapped_concept_code, invalid_reason as remapped_code_invalid_reason
	from public.concept
	) goo USING (remapped_concept_id)
order by idx, concept_code, remapped_concept_code;

drop table tmp2;
create table tmp2 as
select *
from (select distinct idx, descendant_mapped_concept_id, mapped_concept_id, concept_id, concept_code
	from tmp1) x
left join (select distinct descendant_mapped_concept_id, remapped_concept_id, remapped_concept_code, remapped_concept_name, remapped_vocabulary_id, remapped_mapped_from_invalid_reason
	from tmp1
	-- where remapped_vocabulary_id='ICD9CM'
	) y USING (descendant_mapped_concept_id)
order by idx, concept_code, remapped_concept_code;

--make a table that counts patients per src concept code
drop table remapped_src_concepts_and_patients;
CREATE TABLE remapped_src_concepts_and_patients AS
select x.remapped_concept_id, person_id
from (select distinct remapped_concept_id from tmp2) x
left join public.condition_occurrence
on x.remapped_concept_id = public.condition_occurrence.condition_source_concept_id;

CREATE INDEX concept_id_idx on remapped_src_concepts_and_patients (remapped_concept_id);

drop table patients_per_remapped_src_concept_id;
create table patients_per_remapped_src_concept_id AS
select remapped_concept_id, COUNT(DISTINCT person_id) as num_patients_per_remapped_src_concept
from (select distinct * from remapped_src_concepts_and_patients where person_id is not null) x
group by remapped_concept_id
order by remapped_concept_id;

create table tmp3 as
	select *
	from tmp2
	left join patients_per_remapped_src_concept_id USING (remapped_concept_id);

UPDATE tmp3
	SET num_patients_per_remapped_src_concept = 0
	where num_patients_per_remapped_src_concept is null;

drop table test_new;
create table test_new as
	select *
	from emerge_final_icd_table
	left join tmp3
	USING (idx, descendant_mapped_concept_id, mapped_concept_id, concept_id, concept_code);

drop table remap_in_idx;
create table remap_in_idx as
select idx, remapped_concept_id as remapped_concept_id_in_idx
from (select distinct idx, concept_id from test_new) as x
join (select distinct remapped_concept_id from test_new) as y
ON y.remapped_concept_id=x.concept_id;

alter table remap_in_idx
add column remapped_is_in_concept_set INTEGER;

update remap_in_idx
	SET remapped_is_in_concept_set=1;

drop table test_new2;
create table test_new2 as
select test_new.*,remap_in_idx.remapped_is_in_concept_set
from test_new
left join remap_in_idx
ON test_new.remapped_concept_id=remap_in_idx.remapped_concept_id_in_idx
and test_new.idx=remap_in_idx.idx;

update test_new2
	set remapped_is_in_concept_set = 0
	where remapped_is_in_concept_set is null;

drop table emerge_final_icd_table;
create table emerge_final_icd_table as
	select *
	from test_new2;

\copy emerge_final_icd_table TO './output_all_descendants/emerge_final_icd_table.csv' DELIMITER ',' CSV HEADER;


drop table test_new;
drop table test_new_2;
drop table tmp1;
drop table tmp2;
drop table tmp3;
drop table remap_in_idx;
drop table remapped_src_concepts_and_patients;
drop table patients_per_remapped_src_concept_id;
