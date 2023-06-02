#!/bin/bash
/usr/local/bin/configManta.py \
    --tumorBam ${sampleId}_Tumor.recal.cram \
    --normalBam ${sampleId}_PBMCs.recal.cram \
    --reference GRCh38.primary_assembly.genome.fa \
    --exome \
    --callRegions S31285117_Padded.bed \
    --runDir manta
