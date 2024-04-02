#!/bin/bash -euo pipefail
bcftools \
    roh \
    --skip-indels \
    --AF-file gnomad_reformated_GRCh38.tab.gz \
     \
     \
     \
     \
    -o NA12878_roh.roh \
    NA12878_split_rmdup.vcf.gz

cat <<-END_VERSIONS > versions.yml
"NFCORE_VARIANT_ANNOTATION:VARIANT_ANNOTATION:ANNOTATE_SNVS:BCFTOOLS_ROH":
    bcftools: $(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*$//')
END_VERSIONS
