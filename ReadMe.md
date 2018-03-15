# eMERGE concept set terminology mapping evaluation

1. Download file containing the ICD9 codes for eMERGE concept sets:
	`scp USER@gem.dbmi.columbia.edu:/phi/proj/phenotype2008/emerge/omopdefinitions/eMERGE_concept_sets.csv ./emerge_files`

2. Pre-process eMERGE concept set file
	1. Convert to JSON style:
		If on linux: `bash src/PreProcessJSON_GNU.sh ./emerge_files/eMERGE_concept_sets.csv ./emerge_files/eMERGE_concept_sets_processed.json`
		If on macOS: `bash src/PreProcessJSON_macOS.sh ./emerge_files/eMERGE_concept_sets.csv ./emerge_files/eMERGE_concept_sets_processed.json`
	2. Generate processed CSV with Python script
	`python src/ProcessConceptSets.py ./emerge_files/eMERGE_concept_sets_processed.json ./emerge_files/eMERGE_concept_sets_processed.csv`

3. Run primary analysis
	1. `bash run_analysis.sh MY_DB_NAME MY_DB_USER_NAME`
	2. (optional) Send output to machine with matlab, for plotting:
		`rsync -avrz ./output USER@gem.dbmi.columbia.edu:/phi/proj/terminology_info_loss/emerge2ohdsi_information_loss_AUTO`

4. Run plotting
	`cd ./src`
	In matlab, run:
```
	data_dir = '/phi/proj/terminology_info_loss/emerge2ohdsi_automatic/output';
	output_dir = '/phi/proj/terminology_info_loss/emerge2ohdsi_automatic/output';
	aggregate_plotter_cleaned(data_dir, output_dir);
```