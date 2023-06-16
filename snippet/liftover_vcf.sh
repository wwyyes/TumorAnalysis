# from hg19 to hg38
# chain file download: http://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/
gatk LiftoverVcf \
  -I input.vcf \
  -O lifted_over.vcf \
  -C hg19ToHg38.over.chain.gz \
  -R GRCh38.primary_assembly.genome.fa \
  --REJECT rejected.vcf
