## get low mappability region ###
# based on the Waldron lab and GCA_000001405.15_GRCh38_no_alt_analysis_set_100.bw [https://s3.amazonaws.com/purecn/GCA_000001405.15_GRCh38_no_alt_analysis_set_100.bw]
# wget https://s3.amazonaws.com/purecn/GCA_000001405.15_GRCh38_no_alt_analysis_set_100.bw
# wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/bigWigToBedGraph
# chmod u+x bigWigToBedGraph
# ./bigWigToBedGraph GCA_000001405.15_GRCh38_no_alt_analysis_set_100.bw GCA_000001405.15_GRCh38_no_alt_analysis_set_100.bedGraph
# awk '{if($4 <= 0.1) {print $0}}' GCA_000001405.15_GRCh38_no_alt_analysis_set_100.bedGraph > LowMappability.GCA_000001405.15_GRCh38_no_alt_analysis_set_100.bedGraph
## - mappability region with score less than 0.1 will be considered as low-mappability region, this cutoff comes from PureCN



## access ##
cnvkit.py access GRCh38.primary_assembly.genome.fa \
    -x LowMappability.GCA_000001405.15_GRCh38_no_alt_analysis_set_100.bedGraph \ # regions with mappability score < 0.1 were excluded
    -o access-excludes.GRCh38.bed
# log: Wrote access-excludes.GRCh38.bed with 1245 regions


## estimate bin size ##
cnvkit.py autobin \
    *.bam \
    -m hybrid \
    -g access-excludes.GRCh38.bed \
    -t S30409818_Padded.bed \
    --annotate refFlat.txt

## ---- coverage ---- ## 
# for each sample
for id in `cat sample.list`
do
    bam=${id}".recal.bam"
    targetcnn=${id}".targetcoverage.cnn"
    antitargetcnn=${id}".antitargetcoverage.cnn"
    outpath=cnn
    
    targets.bed=S30409818_Padded.target.bed
    antitargets.bed=S30409818_Padded.antitarget.bed
  

cnvkit.py coverage ${bam} ${targets.bed} -o ${outpath}/${id}.targetcoverage.cnn
cnvkit.py coverage ${bam} ${antitargets.bed} -o ${outpath}/${id}.antitargetcoverage.cnn

done

## ---- build reference ---- ##
# use ALL normal samples to build a reference
cnvkit.py reference \
    *PBMCs.{,anti}targetcoverage.cnn \
    -f GRCh38.primary_assembly.genome.fa \
    -o Reference.cnn \
    -y \ #Create a male reference: shift female samples' chrX log-coverage by -1, so the reference chrX average is -1
    -c 
# Provide the *.targetcoverage.cnn and *.antitargetcoverage.cnn files created by the coverage command


## fix and segment ##
# For each tumor sample...
for id in `cat sample.list`
do
cnvkit.py fix ${id}.targetcoverage.cnn ${id}.antitargetcoverage.cnn my_reference.cnn \
    -o Sample.cnr \
    -c 
done

for id in `cat patient.list`
do

    tissue=organoids
    sampleId=S${id}_${tissue}
    normalId=S${id}_PBMCs

    vcfPath=/mutect2
    vcfFile=${vcfPath}/${sampleId}_vs_${normalId}.mutect2.filtered.vcf.gz

    tumor=P${id}_${sampleId}
    normal=P${id}_${normalId}
    cnvkit.py segment ${sampleId}.cnr -o ${sampleId}.cns \
        -m hmm \ # or cbs
        --drop-low-coverage \ # Drop very-low-coverage bins before segmentation to avoid false-positive deletions in poor-quality tumor samples
        -p 40 \
        --smooth-cbs \
        -v $vcf \
        -i $tumor \
        -n $normal 
done



## optional call ##
# the purity here was from PureCN
cnvkit.py call -m clonal -y --center mode --ploidy 2 --drop-low-coverage \
    --purity ${PureCN.purity}  \
    -x m  -o ${sampleId}.call.cns  \
    ${sampleId}.cns  \
    -v {sampleId}.mutect2.ann.vep.filtered.vcf.gz  --sample-id ${tumorsampleId}  --normal-id ${normalsampleId}
    
    
