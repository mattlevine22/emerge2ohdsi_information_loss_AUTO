#!/bin/sh
mkdir ./output_all_descendants
mkdir ./output_no_descendants

dbname=$1
username=$2

# Run fake condition mappings (since we don't want to rely on the current ETL)
psql $dbname $username -a -f src/fake_condition_mappings2.sql
psql $dbname $username -a -f src/condition_occurrence_descriptions.sql;

# Run for all-descendants mapping
psql $dbname $username -a -f src/long_run4_fake_mapped_all_descendants.sql;
psql $dbname $username -a -f src/remap_run1_all_descendants.sql;
psql $dbname $username -a -f src/output_src_code_descriptions_for_histograms_all_descendants.sql;
Rscript --vanilla src/output_num_mappings_table.R ./output_all_descendants/emerge_final_icd_table.csv ./output_all_descendants;

# Run for no-descendants mapping
psql $dbname $username -a -f src/long_run4_fake_mapped_no_descendants.sql;
psql $dbname $username -a -f src/remap_run1_no_descendants.sql;
psql $dbname $username -a -f src/output_src_code_descriptions_for_histograms_no_descendants.sql;
Rscript --vanilla src/output_num_mappings_table.R ./output_no_descendants/emerge_final_icd_table.csv ./output_no_descendants;
