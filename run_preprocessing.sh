# Here is the workflow for pre-processing the terminology mapping data

# GEM: /phi/proj/phenotype2008/emerge/omopdefinitions/eMERGE_concept_sets.csv

# Convert to JSON style:
bash src/PreProcessJSON_macOS.sh ./emerge_files/eMERGE_concept_sets.csv ./emerge_files/eMERGE_concept_sets_processed.json

# Generate processed CSV with Python script
python src/ProcessConceptSets.py ./emerge_files/eMERGE_concept_sets_processed.json ./emerge_files/eMERGE_concept_sets_processed.csv
