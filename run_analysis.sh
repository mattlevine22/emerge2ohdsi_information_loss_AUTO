#!/bin/sh
mkdir ./output

dbname=$1
username=$2

# Run fake condition mappings (since we don't want to rely on the current ETL)
psql $dbname $username -a -f src/fake_condition_mappings2.sql
psql $dbname $username -a -f src/condition_occurrence_descriptions.sql;
psql $dbname $username -a -f src/long_run4_fake_mapped_all_descendants.sql;
psql $dbname $username -a -f src/remap_run1.sql;
psql $dbname $username -a -f src/output_src_code_descriptions_for_histograms.sql;
R --vanilla < src/output_num_mappings_table.R ./output/emerge_final_icd_table.csv ./output;

