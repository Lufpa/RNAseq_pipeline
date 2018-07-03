#/bin/bash

#Batch parameters are specified in RNAseq_pipeline_array_2lanes.sh script that calls this script

cpus=$1
inputcount=$2
refgenome=$3
annotation=$4
inDIR=$5
outDIR=$6
r3=$7

fqfile=`awk -v file=$SLURM_ARRAY_TASK_ID '{if (NR==file) print $0 }' $inDIR/listfiles`
echo "filename " $fqfile >&2
echo "# of cpus" $cpus

#merging 2lanes of fq files
fqfile2=`awk -v file=$SLURM_ARRAY_TASK_ID '{if (NR==file) print $0 }' $inDIR/listfiles2`

echo "mergin fq from L001 and L002"
infq=${fqfile%_S*}_merge_R1.fq.gz
cat $inDIR/$fqfile $inDIR/$fqfile2 > $outDIR/$infq

#echo "Start trimming"
trimfile=`basename ${infq%R*}trim.fq.gz`
java -jar ~/bin/Trimmomatic-0.32/trimmomatic-0.32.jar SE -threads $cpus $outDIR/$infq $outDIR/$trimfile ILLUMINACLIP:/Genomics/grid/users/lamaya/scripts/RNAseq_pipeline/AdaptersTrim.fasta:1:30:7 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:20

echo "Done with trimming"
mapfile=${trimfile%trim*}map.bam
summaryfile=${trimfile%trim*}summarymap.txt
tmpdir=tmp$trimfile
#mkdir $tmpdir
date
echo "Starting mapping"
~/bin/tophat-2.1.1.Linux_x86_64/tophat2 -p $cpus -o $outDIR/$tmpdir $refgenome $outDIR/$trimfile
mv $outDIR/$tmpdir/accepted_hits.bam $outDIR/$mapfile
mv $outDIR/$tmpdir/align_summary.txt $outDIR/$summaryfile
echo "Done mapping"
date
grep 'of input' $outDIR/$summaryfile >&2

echo "Start dropping multiple mapping reads"
#filters out multiple mapping reads
uniqfile=${mapfile%map.bam}uniq.bam
samtools view -b -@ $cpus -q 50 $outDIR/$mapfile -o $outDIR/$uniqfile
echo "Done dropping multiple mapping reads"


if [ -s $outDIR/$uniqfile ]
        then
        rm $outDIR/$mapfile
else
        echo "removing multiple mapping reads failed - original bam file was kept"
fi

# nudup removes (can be just marked if wanted) pcr duplicates useing the UMI from i5 and start pos. It takes for ever to run, couple of hours per sample. If preliminary results wanted, skip this step.

dedupfile=${uniqfile%.bam}
if [ $inputcount == 'dedup' ] && [ -e $r3 ]
        then
                echo "Start pcr deduplication - nudup"
		python ~/bin/nudup/nudup.py -f $r3 -o $outDIR/$dedupfile -s 8 -l 8 --rmdup-only $outDIR/$uniqfile >&2
		echo "Done pcr dedup for" $uniqfile
		countfile=${dedupfile}.genecount
                ~/bin/subread-1.5.1-Linux-x86_64/bin/featureCounts -T $cpus -t exon -g gene_id -a $annotation -o $outDIR/$countfile $outDIR/${dedupfile}.sorted.dedup.bam
		echo "Done gene count for deduplicated file" $dedupfile
else
		countfile=${dedupfile}.genecount
		 ~/bin/subread-1.5.1-Linux-x86_64/bin/featureCounts -T $cpus -t exon -g gene_id -a $annotation -o $outDIR/$countfile $outDIR/$uniqfile
		echo "Done gene count for non-deduplicated file" $uniqfile
fi

rm -r $outDIR/$tmpdir

date
