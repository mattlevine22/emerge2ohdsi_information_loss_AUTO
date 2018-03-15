-- redo ETL, aka create table that re-maps ALL condition_source_concept_id's in condition_occurrence table
-- create table that maps all unmapped condition_source_concept_id's in condition_occurrence table
drop table full_fake_mappings;
create table full_fake_mappings as
select condition_source_concept_id, concept_id_2 as intended_mapping
from (select bla.condition_source_concept_id, x.*
from (select distinct condition_source_concept_id
from public.condition_occurrence) bla
left join (select * from public.concept_relationship) x
on x.concept_id_1 = bla.condition_source_concept_id
where relationship_id = 'Maps to'
and invalid_reason is null) bloo
left join public.concept
on bloo.concept_id_2 = public.concept.concept_id
where standard_concept = 'S';
-- and invalid_reason is null;

drop table full_fake_condition_occurrence;
create table full_fake_condition_occurrence as
select c1.condition_occurrence_id, c1.person_id, c1.condition_start_date, c1.condition_end_date, c1.condition_type_concept_id, c1.stop_reason, c1.provider_id, c1.visit_occurrence_id, c1.condition_source_value,
condition_source_concept_id, condition_source_vocabulary_id, intended_mapping as condition_concept_id, condition_vocabulary_id
from public.condition_occurrence as c1
left join full_fake_mappings USING (condition_source_concept_id)
left join (select concept_id, vocabulary_id as condition_source_vocabulary_id from public.concept) p1 on condition_source_concept_id = p1.concept_id
left join (select concept_id, vocabulary_id as condition_vocabulary_id from public.concept) p2 on condition_concept_id = p2.concept_id;

create index fake_cond_idx on full_fake_condition_occurrence (person_id, condition_start_date, visit_occurrence_id);

drop table full_fake_mappings;


