#!/bin/sh

mkdir ../output_plots
matlab -nodesktop -nodisplay -r 'run aggregate_plotter_cleaned; exit;'