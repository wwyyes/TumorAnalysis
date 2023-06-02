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
    
for id in `cat sample.list`
do
    bam=${id}".recal.bam"
    targetcnn=${id}".targetcoverage.cnn"
    antitargetcnn=${id}".antitargetcoverage.cnn"
    outpath=/mnt/external/it_nfs_share_immuno/CBBI_Projects/FOLFIRINOX_Neoantigen/processed/wwang/nextflow/DNA_parsed_pipeline/04_wwangCNVcalling/data/reference/cnn
    
    targets.bed=/mnt/external/it_nfs_share_immuno/CBBI_Projects/FOLFIRINOX_Neoantigen/processed/wwang/nextflow/DNA_parsed_pipeline/04_wwangCNVcalling/data/reference/S30409818_Padded.target.bed
    antitargets.bed=/mnt/external/it_nfs_share_immuno/CBBI_Projects/FOLFIRINOX_Neoantigen/processed/wwang/nextflow/DNA_parsed_pipeline/04_wwangCNVcalling/data/reference/S30409818_Padded.antitarget.bed
  
## ---- coverage ---- ##
cnvkit.py coverage ${bam} ${targets.bed} -o ${outpath}/${id}.targetcoverage.cnn
cnvkit.py coverage ${bam} ${antitargets.bed} -o ${outpath}/${id}.antitargetcoverage.cnn

done

## ---- build reference ---- ##
cnvkit.py reference \
    *coverage.cnn \
    -f GRCh38.primary_assembly.genome.fa \
    -o Reference.cnn
# Provide the *.targetcoverage.cnn and *.antitargetcoverage.cnn files created by the coverage command
