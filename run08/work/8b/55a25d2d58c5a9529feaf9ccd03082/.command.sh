#!/bin/bash -euo pipefail
rhocall \
    annotate \
    --v14  \
     \
    -r NA12878_roh.roh \
    -o NA12878_rohann_rhocall.vcf \
    NA12878_split_rmdup.vcf.gz

cat <<-END_VERSIONS > versions.yml
"NFCORE_VARIANT_ANNOTATION:VARIANT_ANNOTATION:ANNOTATE_SNVS:RHOCALL_ANNOTATE":
    rhocall: $(echo $(rhocall --version 2>&1) | sed 's/rhocall, version //' )
END_VERSIONS
