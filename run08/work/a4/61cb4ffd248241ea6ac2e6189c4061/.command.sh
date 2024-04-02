#!/bin/bash -euo pipefail
gatk --java-options "-Xmx24576M" SelectVariants \
    --variant NA12878_rohann_vcfanno_filter.vcf.gz \
    --output NA12878_0015-scattered.selectvariants.vcf.gz \
    --intervals 0015-scattered.interval_list \
    --tmp-dir . \


cat <<-END_VERSIONS > versions.yml
"NFCORE_VARIANT_ANNOTATION:VARIANT_ANNOTATION:ANNOTATE_SNVS:GATK4_SELECTVARIANTS":
    gatk4: $(echo $(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*$//')
END_VERSIONS
