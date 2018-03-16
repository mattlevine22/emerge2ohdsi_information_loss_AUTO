create table src_code_descriptions as
select concept_id, concept_code, num_patients_per_src_code_src_only, num_patients_per_src_code_map_only, num_patients_per_src_code_both, (num_patients_per_src_code_both + num_patients_per_src_code_src_only) as num_patients_per_src_concept, (num_patients_per_src_code_both + num_patients_per_src_code_map_only) as num_patients_per_map_concept, num_patients_per_descendant_concept, src_concept_name, concept_domain_id, src_vocabulary_id
from emerge_final_icd_table;

\copy src_code_descriptions TO './output_all_descendants/src_code_descriptions.csv' DELIMITER ',' CSV HEADER;

drop table src_code_descriptions;
