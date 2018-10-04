#/bin/bash

#Batch parameters are specified in snpcaller.sh script that calls this script

#refbwa=$1
refGATK=$1
dedup=$2
cpus=$3
inDIR=$4
outDIR=$5
r3=$6

uniqfile=`awk -v file=$SLURM_ARRAY_TASK_ID '{if (NR==file) print $0 }' $inDIR/listfiles.bam`
echo "filename" $file >&2
#fqfile2=${fqfile/R1/R2}
name=${uniqfile%_merge*}
#uniqfile=$name\.sorteduniq.bam

#adding ReadGroup info, tophat doesnt add that by defaul
uniqfileRG=${uniqfile%.bam}.RG.bam
java -Xmx30g -jar ~/bin/picard.jar AddOrReplaceReadGroups I=$uniqfile O=$outDIR/$uniqfileRG RGID=$name RGSM=$name RGPL=ILLUMINA RGLB=$name RGPU=$name

if [ $dedup == 'picard' ]
	then
		echo "Start picard deduplication"
		dedupfile=${name}.markdup.bam
		metrics=$name.metricspicard
		java -Xmx30g -jar ~/bin/picard.jar MarkDuplicates I=$outDIR/$uniqfileRG O=$outDIR/$dedupfile M=$outDIR/$metrics
		echo "Done dedup for" $uniqfileRG
		java -Xmx30g -jar ~/bin/picard.jar BuildBamIndex I=$outDIR/$dedupfile
		echo "Done with bam index"
elif [ $dedup == 'nudup' ]
	then
		echo "Start nudup deduplication"
		dedupfile=${name}
		python ~/bin/nudup/nudup.py -2 -f $r3 -o $outDIR/$dedupfile -s 8 -l 8 $outDIR/$uniqfileRG --rmdup-only
		dedupfile=${dedupfile}.sorted.dedup.bam
		echo "Done dedup for" $dedupfile
		java -Xmx30g -jar ~/bin/picard.jar BuildBamIndex I=$outDIR/$dedupfile
                echo "Done with bam index"
else	dedupfile=${uniqfileRG}
	echo "no deduplication for" $uniqfile
	java -Xmx30g -jar ~/bin/picard.jar BuildBamIndex I=$outDIR/$dedupfile
                echo "Done with bam index"
fi

date
# for some reason HapCal is finding that the contigs in bam are not the same
# order than in the reference
echo "start re ordering"
dedupOrder=${dedupfile%.bam}.ordered.bam
java -Xmx30g -jar ~/bin/picard.jar ReorderSam I=$outDIR/$dedupfile O=$outDIR/$dedupOrder R=$refGATK CREATE_INDEX=true
# GATK implemented a way of splitting reads into exons and discarding intronic regions. This improve the false positive rate
echo "start spliting Ncigars"
dedupSplit=${dedupfile%.bam}.split.bam
java -Xmx30g -jar ~/bin/GATK/GenomeAnalysisTK.jar -T SplitNCigarReads -R $refGATK -I $outDIR/$dedupOrder -o $outDIR/$dedupSplit -U ALLOW_N_CIGAR_READS

echo "Start haplotype caller in GATK"
vcffile=$name.g.vcf
# uses gvcf for RNA as normally used for DNA, otherwise RNA snps cannot be called for every position and then merged. The RNAseq option only calles variable site per sample. GATK still doesnt support join calling fo RNAseq snps, ut I'm running it anyways that way, after doing the advised remmaping of the RNAseq data with splitNcigar
java -Xmx30g -jar ~/bin/GATK/GenomeAnalysisTK.jar -T HaplotypeCaller -nct $cpus -R $refGATK -I $outDIR/$dedupSplit -dontUseSoftClippedBases -drf DuplicateRead -ERC GVCF -o $outDIR/$vcffile
echo "Done with variantcalling"
date

if [ -s $outDIR/$dedupSplit ]
       then
       rm $outDIR/$uniqfileRG
       rm $outDIR/$dedupfile
else
       echo "Split of Ncigar failed, Split file is empty - all bam file were kept"
fi


