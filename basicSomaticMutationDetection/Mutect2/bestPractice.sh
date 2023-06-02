# follow the best practice from GATK, but adapt it to own setting
# Link: https://gatk.broadinstitute.org/hc/en-us/articles/360035894731-Somatic-short-variant-discovery-SNVs-Indels-

# ---------------------- BASED ON BAM FILES, ESTIMATE CROSS-SAMPLE CONTAMINATION AND TUMOR SEGMENTATION -----------------
## ---- GetPipeupSummarise -> Normal sample ---- ##
gatk --java-options "-Xmx12g" GetPileupSummaries \
    --input ${sampleId}_PBMCs.recal.cram \ # normal sample bam file
    --variant af-only-gnomad.hg38.vcf.gz \ # germline source
    --output ${sampleId}_PBMCs.mutect2.{pileups/pileupsummaries}.table \ # out table
    --reference GRCh38.primary_assembly.genome.fa \
    --intervals {chrY_2976482-2976914|S31285117_Padded}.bed \ # sequencing kit capture region OR targeted region
    --tmp-dir . 

## Optional: ---- GatherPipeupSummaries ---- ## if need to merge multiple pipeup table from GetPipeupSummarise
gatk --java-options "-Xmx12g" GatherPileupSummaries \
    --I ${sampleId}_PBMCs.mutect2.chr18_63658461-63658787.pileups.table \
    --I ${sampleId}_PBMCs.mutect2.chr16_76558355-76558744.pileups.table \
    --I ${sampleId}_PBMCs.mutect2.chr2_241108031-241108395.pileups.table \
    --O ${sampleId}_PBMCs.mutect2.pileupsummaries.table \
    --sequence-dictionary GRCh38.primary_assembly.genome.dict \
    --tmp-dir .

## ---- GetPipeupSummarise -> Tumor sample ---- ##
gatk --java-options "-Xmx12g" GetPileupSummaries \
    --input ${sampleId}_Tumor.recal.cram \
    --variant af-only-gnomad.hg38.vcf.gz \
    --output ${sampleId}_Tumor.mutect2.pileups.table \
    --reference GRCh38.primary_assembly.genome.fa \
    --intervals {chrY_2976482-2976914|S31285117_Padded}.bed \
    --tmp-dir .


## ---- calculateContamination ---- ##
gatk --java-options "-Xmx12g" CalculateContamination \
    --input ${sampleId}_Tumor.mutect2.pileupsummaries.table \
    --output ${sampleId}_Tumor_vs_${sampleId}_PBMCs.mutect2.contamination.table \
    --matched-normal ${sampleId}_PBMCs.mutect2.pileupsummaries.table \
    --tmp-dir . \
    -tumor-segmentation ${sampleId}_Tumor_vs_${sampleId}_PBMCs.mutect2.segmentation.table

# --------------------------------- CALL SOMATIC MUTATIONS AND OUTPUT F1R2 RESULTS --------------

## ---- Mutect2 -----##
gatk --java-options "-Xmx36g" Mutect2 \
    --input ${sampleId}_PBMCs.recal.cram \ # normal sample bam file
    --input ${sampleId}_Tumor.recal.cram \ # tumor sample bam file
    --output ${sampleId}_Tumor_vs_${sampleId}_PBMCs.mutect2.vcf.gz \ # output vcf file
    --reference GRCh38.primary_assembly.genome.fa \
    --panel-of-normals 1000g_pon.hg38.vcf.gz \ # PON
    --germline-resource af-only-gnomad.hg38.vcf.gz \ # germline
    --intervals S31285117_Padded.bed \ # sequencing kit capture region 
    --tmp-dir . \
    --f1r2-tar-gz ${sampleId}_Tumor_vs_${sampleId}_PBMCs.mutect2.f1r2.tar.gz \ # collect F1R2 counts 
    --normal-sample ${patientId}_${sampleId}_PBMCs \ # normal sample name in the normal sample bam file
    --genotype-germline-sites true \ # (EXPERIMENTAL) Call all apparent germline site even though they will ultimately be filtered. As required by PureCN
    --genotype-pon-sites true \ # Call sites in the PoN even though they will ultimately be filtered.
    --native-pair-hmm-threads 20

## ---- LearnReadOrientationModel ---- ##
gatk --java-options "-Xmx12g" LearnReadOrientationModel \
 #   --input ${sampleId}_Tumor_vs_${sampleId}_PBMCs.mutect2.chr21_46563693-46564057.f1r2.tar.gz \
 #   --input ${sampleId}_Tumor_vs_${sampleId}_PBMCs.mutect2.chr19_39866621-39867315.f1r2.tar.gz \
    --input ${sampleId}_Tumor_vs_${sampleId}_PBMCs.mutect2.f1r2.tar.gz \
    --output ${sampleId}_Tumor_vs_${sampleId}_PBMCs.mutect2.artifactprior.tar.gz \
    --tmp-dir .

# --------------------- APPLY Artifact priors AND Contamination, Segmentation to FILTER calls --------
## ---- filter ---- ##
gatk --java-options "-Xmx12g" FilterMutectCalls \
    --variant ${sampleId}_Tumor_vs_${sampleId}_PBMCs.mutect2.vcf.gz \
    --output ${sampleId}_Tumor_vs_${sampleId}_PBMCs.mutect2.filtered.vcf.gz \
    --reference GRCh38.primary_assembly.genome.fa \
    --orientation-bias-artifact-priors ${sampleId}_Tumor_vs_${sampleId}_PBMCs.mutect2.artifactprior.tar.gz \
    --tumor-segmentation ${sampleId}_Tumor_vs_${sampleId}_PBMCs.mutect2.segmentation.table \
    --contamination-table ${sampleId}_Tumor_vs_${sampleId}_PBMCs.mutect2.contamination.table  \
    --tmp-dir . \
    
    
