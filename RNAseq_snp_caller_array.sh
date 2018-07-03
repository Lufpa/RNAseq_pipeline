#!/bin/bash
#SBATCH --mem=40000
#SBATCH --time=5:00:00 --qos=1day
#SBATCH --job-name=SNP_RNA
#SBATCH --cpus-per-task=2   #make sure to modify $cpus too!!!
#SBATCH --output="%A_%a.out"
#SBATCH --error="%A_%a.error"
#SBATCH --array=1-96

#Usage
#This scripts calls SNPs in RNAseq data (SE reads) using GATK in RNA mode
#This mode doesn't allow joint-genotyping, so each sample's SNPs are called
#individually. This is less of a problem in RNAseq data, given that the coverage
#per transcript is way higher than DNAseq data. 
#However, if decide to call the samples together, GATK has to be run in DNA
#mode ignoring the Ncigars. This is still not implemented in this script.

##Requires:
# "listfiles.bam" with the id of the .bam files

set -e

date
inDIR=.
outDIR=VCFs

# set up the number of cpus to match --cpus-per-task, this value will be use for bwa, samtools, and hapcaller
cpus=2
# specify if 'nudup' or 'picard' should be use for deduplication. If no deduplication, then leave empty ''
dedup='picard'
# if nudup is gonna be used for demultiplexing, load Read 3
r3=*Read_3*

#refbwa=/Genomics/grid/users/lamaya/genomes/dmel_genome/dmel-all-chromosome-r6.14
refGATK=/Genomics/grid/users/lamaya/genomes/dmel_genome/dmel-all-chromosome-r6.14.fa

source ~/scripts/RNAseq_pipeline/RNAseq_bam_to_varcalling.sh ${refGATK} ${dedup} ${cpus} ${inDIR} ${outDIR} ${r3}

date
