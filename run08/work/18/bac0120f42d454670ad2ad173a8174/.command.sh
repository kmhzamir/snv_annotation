#!/bin/bash -euo pipefail
gatk --java-options "-Xmx24576M" CreateSequenceDictionary \
    --REFERENCE genome.fa \
    --URI genome.fa \
    --TMP_DIR . \


cat <<-END_VERSIONS > versions.yml
"NFCORE_VARIANT_ANNOTATION:VARIANT_ANNOTATION:PREPARE_REFERENCES:GATK_SD":
    gatk4: $(echo $(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*$//')
END_VERSIONS
