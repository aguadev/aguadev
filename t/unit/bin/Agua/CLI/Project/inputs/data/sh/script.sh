#! /bin/bash

#### FixMates

# 1 sort
samtools sort $normal $cur_dir/${sample}_N_sorted

# 2 fixMate
$java -Xmx3000m -Djava.io.tmpdir=${sample}_tmp -jar /work/node/stephane/depot/picard-tools/picard-tools-1.103/FixMateInformation.jar I=${sample}_N_sorted.bam O=${sample}_N_fxmt.bam SO=coordinate CREATE_INDEX=true VALIDATION_STRINGENCY=SILENT

# 3 cleanSort
rm $cur_dir/${sample}_N_sorted.bam


#### FilterReads

# 4 filterReads
/work/node/stephane/depot/bin/bamtools filter -isMapped true -isPaired true -isProperPair true -in ${sample}_N_fxmt.bam -out ${sample}_N_fxmt_flt.bam

# 5 indexBam
samtools index ${sample}_N_fxmt_flt.bam

# 6 cleanBam
rm $cur_dir/${sample}_N_fxmt.ba*

#### MarkDuplicates

# 7 markDuplicates
$java -Xmx3000m -Djava.io.tmpdir=${sample}_tmp -jar /work/node/stephane/depot/picard-tools/picard-tools-1.103/MarkDuplicates.jar I=${sample}_N_fxmt_flt.bam O=${sample}_N_rmdup.bam M=${sample}_N_dup_report.txt PROGRAM_RECORD_ID=null VALIDATION_STRINGENCY=SILENT REMOVE_DUPLICATES=true

# 8 cleanDuplicates
rm $cur_dir/${sample}_N_fxmt_flt.ba* $cur_dir/${sample}_N_dup_report.txt

#### AddReadGroups

# 9 addReadGroups
$java -Xmx3000m -Djava.io.tmpdir=${sample}_tmp -jar /work/node/stephane/depot/picard-tools/picard-tools-1.103/AddOrReplaceReadGroups.jar RGPL=Illumina RGLB=BWA RGPU=GRP1 RGSM=GP1 I=${sample}_N_rmdup.bam O=${sample}_N_rmdup_grp.bam SO=coordinate CREATE_INDEX=true VALIDATION_STRINGENCY=SILENT

# 10 cleanReadGroups
rm $cur_dir/${sample}_N_rmdup.ba*


#### QualityFilter

# 11 qualityFilter
/work/node/stephane/depot/bin/bamtools filter -mapQuality ">=60" -in ${sample}_N_rmdup_grp.bam -out ${sample}_N_rmdup_grp_rmlq.bam

# 12 indexBam
samtools index ${sample}_N_rmdup_grp_rmlq.bam

# 13 cleanBam
rm $cur_dir/${sample}_N_rmdup_grp.ba*

#### IndelRealignment

# 14 realignTarget
$java -Xmx3000m -Djava.io.tmpdir=${sample}_tmp -jar /work/knode05/milanesej/GenomeAnalysisTK-2.8-1/GenomeAnalysisTK.jar -T RealignerTargetCreator -nt 2 -I ${sample}_N_rmdup_grp_rmlq.bam -R $ref -o ${sample}_N_forRealign.intervals

# 15 realign
$java -Xmx3000m -Djava.io.tmpdir=${sample}_tmp -jar /work/knode05/milanesej/GenomeAnalysisTK-2.8-1/GenomeAnalysisTK.jar -T IndelRealigner -I ${sample}_N_rmdup_grp_rmlq.bam -R $ref -targetIntervals ${sample}_N_forRealign.intervals --out ${sample}_N_realigned.bam -LOD 0.4 -compress 5

# 16 cleanRealign
rm $cur_dir/${sample}_N_rmdup_grp_rmlq.ba* $cur_dir/${sample}_N_forRealign.intervals

#### BaseRecalibration

# 17 recalibrateBase
$java -Xmx3000m -Djava.io.tmpdir=${sample}_tmp -jar /work/knode05/milanesej/GenomeAnalysisTK-2.8-1/GenomeAnalysisTK.jar -T BaseRecalibrator -I ${sample}_N_realigned.bam -R $ref -o ${sample}_N_recal_data.grp -knownSites $phase_indels -knownSites $dbsnp -knownSites $stand_indels

# 18 printReads
$java -Xmx3000m -Djava.io.tmpdir=${sample}_tmp -jar /work/knode05/milanesej/GenomeAnalysisTK-2.8-1/GenomeAnalysisTK.jar -T PrintReads -I ${sample}_N_realigned.bam -R $ref -o ${sample}_N_realigned_recal.bam -BQSR ${sample}_N_recal_data.grp

