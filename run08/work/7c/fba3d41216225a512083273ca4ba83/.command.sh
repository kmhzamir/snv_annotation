#!/bin/bash -euo pipefail
tabix  NA12878_rohann_vcfanno_filter.vcf.gz

cat <<-END_VERSIONS > versions.yml
"NFCORE_VARIANT_ANNOTATION:VARIANT_ANNOTATION:ANNOTATE_SNVS:TABIX_BCFTOOLS_VIEW":
    tabix: $(echo $(tabix -h 2>&1) | sed 's/^.*Version: //; s/ .*$//')
END_VERSIONS
