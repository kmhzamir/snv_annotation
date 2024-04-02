//
// Prepare indices
//

// Initialize channels based on params or indices that were just built
// For all modules here:
// A when clause condition is defined in the conf/modules.config to determine if the module should be run

include { TABIX_TABIX               } from '../../modules/nf-core/tabix/tabix/main'

workflow PREPARE_INDICES {
    take:
    input          // channel: [meta, vcf, []]

    main:

    ch_versions = Channel.empty()
    ch_out = Channel.empty()

    // Determine if INDEX provided
    input.branch{
        is_indexed:  it[0].index == true
        to_index:    it[0].index == false
    }.set{samtools_input}

    // Remove empty INDEX [] from channel
    input_to_index = samtools_input.to_index.map{ it -> [it[0], it[1]] }

    // INDEX BAM/CRAM only if not provided
    TABIX_TABIX(input_to_index)
    ch_versions    = ch_versions.mix(TABIX_TABIX.out.versions)
    ch_index_files = Channel.empty().mix(TABIX_TABIX.out.tbi)

    // Combine channels
    ch_new = input_to_index.join(ch_index_files)
    ch_out = samtools_input.is_indexed.mix(ch_new)

    // Gather versions of all tools used
    emit:
    vcf_tabix = ch_out
    versions         = ch_versions
}