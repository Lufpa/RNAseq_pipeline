#!/bin/bash
#SBATCH --mem=20000
#SBATCH --time=1:00:00 --qos=1hr
#SBATCH --job-name=RNAseq
#SBATCH --cpus-per-task=5  ## make sure you modified $cpus accordingly!!!
#SBATCH --output="%A_%a.out"
#SBATCH --error="%A_%a.error"
#SBATCH --array=1


##Requires: 
# Demultiplexed files (*R1.fq.gz)
# Read 3 (i5)

## DESCRIPTION ##
# This master scripts loads "RNAseq_map_readcounts2.sh". That script trims the raw fq files, maps using TopHat, removes multiple mapping reads, deduplicates bam files using either Picard or Nudup, and performs gene count using Feature Counts. 
# After all samples are processed, use the script "RNAse_parsing_output.sh" to generate general stats and a single gene count file for all samples.

## If previously run and failed, make sure there are no files left from the last run, tmp dirs, listfiles, etc. 

date
set -e 
# set up the number of cpus to match --cpus-per-task, this value will be use for tophat, samtools, and featurecounts
cpus=5
## if nudup is gonna be used, set $inputcount to 'dedup', otherwilse set it to 'uniq' and make sure to load read3
inputcount='uniq'
r3=*Read_3_Index_Read_passed_filter.fastq*

#refgenome=~/genomes/hsapiens/genome
#annotation=~/genomes/hsapiens/Homo_sapiens.GRCh38.86.chr.protcoding.gtf

refgenome=~/genomes/dmel_genome/dmel-all-chromosome-r6.14
annotation=~/genomes/dmel_genome/dmel-all-r6.14.gtf

source /Genomics/grid/users/lamaya/scripts/RNAseq_pipeline/RNAseq_map_readcounts2.sh ${cpus} ${inputcount} ${refgenome} ${annotation} ${r3}

echo "Done!"
date
