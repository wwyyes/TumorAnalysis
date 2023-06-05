#!/bin/bash
# according to PureCN best practice: https://bioconductor.org/packages/release/bioc/vignettes/PureCN/inst/doc/Quick.html#52_Recommended_CNVkit_usage
PURECN=/home/wwang/R/x86_64-pc-linux-gnu-library/4.2/PureCN/extdata

NORMAL_PANEL=joint.recalibrated.wwang.vcf
# Recommended: Provide a normal panel VCF to remove mapping biases, pre-compute
# position-specific bias for much faster runtimes with large panels
# This needs to be done only once for each assay

Rscript $PURECN/NormalDB.R --out-dir ${outPath} \
        --normal-panel $NORMAL_PANEL \
    --assay S30409818  --genome hg38 --force
    


PURECN=/home/wwang/R/x86_64-pc-linux-gnu-library/4.2/PureCN/extdata
tissue=Pancreatic
#tissue=organoids
for id in `cat patient.list`
do
  SAMPLEID=S${id}_${tissue}
  normalId=S${id}_PBMCs
  vcfPath=mutect2
	vcfFile=${vcfPath}/${sampleId}_vs_${normalId}.mutect2.ann.vep.filtered.vcf.gz
  
  echo "Rscript $PURECN/PureCN.R --out $OUT/${SAMPLEID} \
      --sampleid $SAMPLEID \
      --tumor $CNR/${SAMPLEID}.cnr \
      --seg-file $CNR/${SAMPLEID}.seg \
      --vcf ${vcfFile} \
      --genome hg38  \
      --fun-segmentation hclust \
      --model betabin \
      --force --post-optimize --seed 123 \
     # --mapping-bias-file \ too much warnings....
    #  --normaldb \
      --sex $sex\
      
      "

done
