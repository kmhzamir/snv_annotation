#!/bin/bash -euo pipefail
tabix -s 1 -b 2 -e 2 gnomad_reformated_GRCh38.tab.gz

cat <<-END_VERSIONS > versions.yml
"NFCORE_VARIANT_ANNOTATION:VARIANT_ANNOTATION:PREPARE_REFERENCES:TABIX_GNOMAD_AF":
    tabix: $(echo $(tabix -h 2>&1) | sed 's/^.*Version: //; s/ .*$//')
END_VERSIONS
