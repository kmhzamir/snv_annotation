#!/bin/bash -euo pipefail
bcftools view \
    --output NA12878_rohann_vcfanno_filter.vcf.gz \
     \
     \
     \
    --output-type z --exclude "INFO/GNOMADAF > 0.70 | INFO/GNOMADAF_popmax > 0.70"  \
    --threads 6 \
    NA12878.vcf.gz

cat <<-END_VERSIONS > versions.yml
"NFCORE_VARIANT_ANNOTATION:VARIANT_ANNOTATION:ANNOTATE_SNVS:BCFTOOLS_VIEW":
    bcftools: $(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*$//')
END_VERSIONS
