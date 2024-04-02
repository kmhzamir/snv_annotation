#!/bin/bash -euo pipefail
gatk --java-options "-Xmx9830M" SplitIntervals \
    --output home_genome_intervals \
    --intervals genome.fa.bed \
    --reference genome.fa \
    --tmp-dir . \
    --subdivision-mode BALANCING_WITHOUT_INTERVAL_SUBDIVISION --scatter-count 22

cat <<-END_VERSIONS > versions.yml
"NFCORE_VARIANT_ANNOTATION:VARIANT_ANNOTATION:SCATTER_GENOME:GATK4_SPLITINTERVALS":
    gatk4: $(echo $(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*$//')
END_VERSIONS
