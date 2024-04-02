#!/bin/bash -euo pipefail
bgzip  --threads 1 -c  NA12878_rohann_vcfanno.vcf > NA12878.vcf.gz
tabix  NA12878.vcf.gz

cat <<-END_VERSIONS > versions.yml
"NFCORE_VARIANT_ANNOTATION:VARIANT_ANNOTATION:ANNOTATE_SNVS:ZIP_TABIX_VCFANNO":
    tabix: $(echo $(tabix -h 2>&1) | sed 's/^.*Version: //; s/ .*$//')
END_VERSIONS
