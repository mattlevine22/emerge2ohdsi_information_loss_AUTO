import sys
import json

infile = sys.argv[1]
outfile = sys.argv[2]

# infile = 'eMERGE_concept_sets_processed.json'
# outfile = 'eMERGE_concept_sets_processed.csv'

json1_file = open(infile)
json1_str = json1_file.read()
json1_data = json.loads(json1_str)

out_str = '"idx","files","concept_sets","domain_id","concept_code"'
for line in json1_data:
	for code in line[4]:
		out_str = out_str + '\n"{0}","{1}","{2}","{3}","{4}"'.format(line[0],line[1],line[2],line[3],code)


with open(outfile, "w") as text_file:
    text_file.write(out_str)
