#!/bin/bash
src_file=$1
new_file=$2
# src_file='./eMERGE_concept_sets.csv'
# new_file='./eMERGE_concept_sets_processed.json'

cp $src_file $new_file #copy source file to new file

sed -i '' "s/;//g" $new_file # remove any semicolons (this is an inconsistency in source csv formatting)

# remove weird artificats in the source csv file
sed -i '' 's/ AND.*/"/g' $new_file
sed -i '' 's/ IS.*/"/g' $new_file


sed -i '' '1d' $new_file # remove header line

# Replace all "' with [' and all '" with ']. # this allows the concept_code list to be read as an array by python.
sed -i '' "s/\"'/['/g" $new_file
sed -i '' "s/'\"/']/g" $new_file

# convert single quotes to double quotes
sed -i '' "s/'/\"/g" $new_file

# begin each line with [ and end each line with ],
sed -i '' 's/^/[/' $new_file
sed -i '' 's/"]/"]],/' $new_file
sed -i '' '$s/],/]/g' $new_file # remove comma added to the last line

# add new line to top and bottom with [ and ]
sed -i '' -e '1 i\'$'\n''[' $new_file
sed -i '' -e '$a\'$'\n'']' $new_file

# b. Replace all "' with [' and all '" with ']. # this allows the concept_code list to be read as an array by python.
# c. Replace all single quotes ' with double quotes " # use sed "s/'/\"/g"
# d. begin each line with [
# e. end each line with ],
# f. make sure last line does not have comma.
# g. add first line to file with just [
# h. add last line to file with just ]
# i. save as a .json file

