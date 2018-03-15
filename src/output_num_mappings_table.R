args = commandArgs(trailingOnly=TRUE)

input_file_name = args[1]
output_dir = args[2]

# the tables made here are designed to help with easy plotting/binning codes/concepts according to their number of mappings


hasN <- function(x,N) {
  return(as.numeric(any(x==N)))
}

x <- read.csv(input_file_name)

tab0 = aggregate(x$num_icd_src2standard_valid_mappings,by=x[c('idx')],FUN=hasN,0)
tab1 = aggregate(x$num_icd_src2standard_valid_mappings,by=x[c('idx')],FUN=hasN,1)
tab2 = aggregate(x$num_icd_src2standard_valid_mappings,by=x[c('idx')],FUN=hasN,2)
tab3 = aggregate(x$num_icd_src2standard_valid_mappings,by=x[c('idx')],FUN=hasN,3)
tabmax = aggregate(x$num_icd_src2standard_valid_mappings,by=x[c('idx')],FUN=max)

y = cbind(tab0$idx,tab0$x,tab1$x,tab2$x,tab3$x,tabmax$x)
colnames(y) = c('idx','has0','has1','has2','has3','maxN')
write.csv(y,paste(output_dir,'concept_set_num_mappings.csv',sep='/'),row.names = FALSE)

tab0 = aggregate(x$num_icd_src2standard_valid_mappings,by=x[c('concept_id')],FUN=hasN,0)
tab1 = aggregate(x$num_icd_src2standard_valid_mappings,by=x[c('concept_id')],FUN=hasN,1)
tab2 = aggregate(x$num_icd_src2standard_valid_mappings,by=x[c('concept_id')],FUN=hasN,2)
tab3 = aggregate(x$num_icd_src2standard_valid_mappings,by=x[c('concept_id')],FUN=hasN,3)
tabmax = aggregate(x$num_icd_src2standard_valid_mappings,by=x[c('concept_id')],FUN=max)

y = cbind(tab0$concept_id,tab0$x,tab1$x,tab2$x,tab3$x,tabmax$x)
colnames(y) = c('concept_id','has0','has1','has2','has3','maxN')
write.csv(y,paste(output_dir,'concept_code_num_mappings.csv',sep='/'),row.names = FALSE)
