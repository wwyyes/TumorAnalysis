# Use GATK Mutect2 to call somatic small mutations while keeping germline ones in the results
## _The whole pipeline follow the Best Practice from GATK, but with slight modifications_

[![GTAK source](https://drive.google.com/uc?id=1rDDE0v_F2YCeXfQnS00w0MY3cAGQvfho)](https://gatk.broadinstitute.org/hc/en-us/articles/360035894731-Somatic-short-variant-discovery-SNVs-Indels-)

## Features
- estimate cross-tumor-noral-sample contamination and tumor segmentation
```sh
gatk GetPileupSummaries
gatk CalculateContamination
```
- keep germline variants in the output vcf files
```sh
--genotype-germline-sites true \  
--genotype-pon-sites true 
# As required by PureCN
```
- Apply learnt read orientation model
```sh
gatk LearnReadOrientationModel
```

## Reference

- [GATK](https://gatk.broadinstitute.org/hc/en-us) 
- [PureCN](https://bioconductor.org/packages/release/bioc/vignettes/PureCN/inst/doc/Quick.html#5_Run_PureCN_with_third-party_segmentation)
