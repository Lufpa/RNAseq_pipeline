# RNAseq_pipeline
Scripts for the Tn5-TagSeq manuscript


1. *demultiplex.sh 
Demultiplexes samples based on i7 barcodes. If several plates (different i5) were sequenced together, an initial demultiplex step has to be done using Lance's i5 code (i5_parse_gencomp1_template.sbatch)

This step also generales the "listfiles" file used in the next scripts.

2. *pipeline_array2.sh
This script runs all samples in an array by calling *map_readcoutns2.sh" that is where the trimming, mapping, deduplication (UMIs), and genecount happens. 
It defines whether deduplication should be done or not, and defines the genome and genome annotation variabiles. 

3. *parsing_output.sh
This scripts outputs 2 files
- readcountsallsamples.txt, it contains the read counts per gene per samples for all the samples processed in the array
- read.parameters, it contains the number of raw reads, trimmed out, mapped, assigned to genes, etc. 
