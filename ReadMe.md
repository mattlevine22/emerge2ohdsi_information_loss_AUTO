# Download file containing the ICD9 codes for eMERGE concept sets
`scp USER@gem.dbmi.columbia.edu:/phi/proj/phenotype2008/emerge/omopdefinitions/eMERGE_concept_sets.csv ./emerge_files`

# Pre-process eMERGE concept set file
## Convert to JSON style:
If on linux: `bash src/PreProcessJSON_GNU.sh ./emerge_files/eMERGE_concept_sets.csv ./emerge_files/eMERGE_concept_sets_processed.json`
If on macOS: `bash src/PreProcessJSON_macOS.sh ./emerge_files/eMERGE_concept_sets.csv ./emerge_files/eMERGE_concept_sets_processed.json`

## Generate processed CSV with Python script
`python src/ProcessConceptSets.py ./emerge_files/eMERGE_concept_sets_processed.json ./emerge_files/eMERGE_concept_sets_processed.csv`

# Run primary analysis
## `bash run_analysis.sh my_db_name my_db_user_name`

# (optional) Send output to machine with matlab, for plotting
`rsync -avrz ./output USER@gem.dbmi.columbia.edu:/phi/proj/terminology_info_loss/emerge2ohdsi_automatic`

# Run plotting
In matlab, run:
```
data_dir = '/phi/proj/terminology_info_loss/output';
output_dir = '/phi/proj/terminology_info_loss/output_plots';
aggregate_plotter_cleaned(data_dir, output_dir);
```