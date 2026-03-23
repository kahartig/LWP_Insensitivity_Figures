# LWP_Insensitivity_Figures
Data processing and figures for LWP insensitivity paper

Some scripts generate output that serves as input for other scripts. The order in which these would need to be run is below.

SOM Analysis:
In addition to the files listed here, the som_pak software would need to be set up to fully reproduce the analysis. These scripts generate inputs for som_pak and process the outputs for visualization. The sub-directories of som_analysis are labeled in the order in which they would need to be executed.
som_analysis/1-regridding/
som_analysis/2-define_domain/
som_analysis/3-create_inputs/
som_analysis/4-run_SOMPAK/
som_analysis/5-plot_output/

Data Processing:
process_sondes.py
process_radar.py
process_align_datasets.py
paper_plots.py
