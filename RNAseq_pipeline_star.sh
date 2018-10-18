#!/bin/bash
#SBATCH --mem=30000
#SBATCH --time=3:00:00 --qos=1day
#SBATCH --job-name=RNAseq
#SBATCH --cpus-per-task=2  ## make sure you modified $cpus accordingly!!!
#SBATCH --output="%A_%a.out"
#SBATCH --error="%A_%a.error"
#SBATCH --array=1-96


##Requires: 
# Demultiplexed files (*R1.fq.gz)
# a "listfiles" with the list of demultiplexed files from first lane *L001*R1*
# a "listfiles2" with the files from the second lane *L002*R1*
# Read 3 (i5)

## DESCRIPTION ##
# This master scripts loads "RNAseq_mappingStar.sh". 
# Previous versions used TopHat for mapping. 
# The source script, merges or not fastq files from 2 lanes of sequencing. # Modigy source script accordingly
#then it trims the raw fq files, maps using Star, removes multiple mapping reads, deduplicates bam files using either Picard or Nudup, and performs gene count using Feature Counts. 
# After all samples are processed, use the script "RNAse_parsing_output.sh" to generate general stats and a single gene count file for all samples.

## If previously run and failed, make sure there are no files left from the last run, tmp dirs, listfiles, etc. If using already trimmed files, keep the old Listfiles

date
set -e 
inDIR=/Genomics/ayroleslab/lamaya/bigProject/march_2018/novaseq_RNA
outDIR=/scratch/tmp/lamaya/novaseq_RNA

# set up the number of cpus to match --cpus-per-task, this value will be use for tophat, samtools, and featurecounts
cpus=2
## if nudup is gonna be used, set $inputcount to 'dedup', otherwilse set it to 'uniq' and make sure to load read3
inputcount='uniq'
r3=*Read_3_Index_Read_passed_filter.fastq*

refgenome=/Genomics/grid/users/lamaya/genomes/ERCC/Star/
annotation=/Genomics/grid/users/lamaya/genomes/ERCC/ERCC92.gtf

#refgenome=/Genomics/grid/users/lamaya/genomes/hsapiens/Star/
#annotation=/Genomics/grid/users/lamaya/genomes/hsapiens/Homo_sapiens.GRCh38.86.chr.protcoding.gtf

#refgenome=/Genomics/grid/users/lamaya/genomes/dmel_genome/Star/
#annotation=/Genomics/grid/users/lamaya/genomes/dmel_genome/dmel-all-r6.14.gtf

source /Genomics/grid/users/lamaya/scripts/RNAseq_pipeline/RNAseq_mappingStar.sh ${cpus} ${inputcount} ${refgenome} ${annotation} ${inDIR} ${outDIR} ${r3}

echo "Done!"
date
