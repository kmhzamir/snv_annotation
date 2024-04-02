#!/bin/bash -euo pipefail
awk 'BEGIN {SEP="	"}; {print $1 SEP "0" SEP $2}' genome.fa.fai > genome.fa.bed

cat <<-END_VERSIONS > versions.yml
"NFCORE_VARIANT_ANNOTATION:VARIANT_ANNOTATION:SCATTER_GENOME:BUILD_BED":
    gawk: $(awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//')
END_VERSIONS
