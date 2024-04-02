#!/bin/bash -euo pipefail
vcfanno \
    -p 2 \
     \
     \
    vcfanno_config.toml \
    NA12878.vcf.gz \
    > NA12878_rohann_vcfanno.vcf

cat <<-END_VERSIONS > versions.yml
"NFCORE_VARIANT_ANNOTATION:VARIANT_ANNOTATION:ANNOTATE_SNVS:VCFANNO":
    vcfanno: $(echo $(vcfanno 2>&1 | grep version | cut -f3 -d' ' ))
END_VERSIONS
