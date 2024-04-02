/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap; fromSamplesheet } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

WorkflowRaredisease.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CHECK MANDATORY PARAMETERS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def mandatoryParams = [
    "analysis_type",
    "input",
]
def missingParamsCount = 0

if (missingParamsCount>0) {
    error("\nSet missing parameters and restart the run. For more information please check usage documentation on github.")
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES AND SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: local modules
//

include { FILTER_VEP as FILTER_VEP_SNV          } from '../modules/local/filter_vep'

//
// MODULE: Installed directly from nf-core/modules
//

include { CUSTOM_DUMPSOFTWAREVERSIONS           } from '../modules/nf-core/custom/dumpsoftwareversions/main'

//
// SUBWORKFLOWS
//

include { ANNOTATE_CSQ_PLI as ANN_CSQ_PLI_SNV   } from '../subworkflows/local/annotate_consequence_pli'
include { ANNOTATE_SNVS                         } from '../subworkflows/local/annotate_snvs'
include { PREPARE_REFERENCES                    } from '../subworkflows/local/prepare_references'
include { RANK_VARIANTS as RANK_VARIANTS_SNV    } from '../subworkflows/local/rank_variants'
include { SCATTER_GENOME                        } from '../subworkflows/local/scatter_genome'
include { PEDDY_CHECK                           } from '../subworkflows/local/peddy_check'
include { PREPARE_INDICES                       } from '../subworkflows/local/prepare_indices'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow VARIANT_ANNOTATION {

    ch_versions = Channel.empty()

    // Initialize read, sample, and case_info channels
    ch_input = Channel.fromSamplesheet("input")
            .map{ meta, vcf, index ->

            meta.index  = index ? true : false

            return [meta, vcf, index]

            }

    // Initialize file channels for PREPARE_REFERENCES subworkflow
    ch_genome_fasta             = Channel.fromPath(params.fasta).map { it -> [[id:it[0].simpleName], it] }.collect()
    ch_genome_fai               = params.fai            ? Channel.fromPath(params.fai).map {it -> [[id:it[0].simpleName], it]}.collect()
                                                        : Channel.empty()
    ch_gnomad_af_tab            = params.gnomad_af      ? Channel.fromPath(params.gnomad_af).map{ it -> [[id:it[0].simpleName], it] }.collect()
                                                        : Channel.value([[],[]])
    ch_vep_cache_unprocessed    = params.vep_cache      ? Channel.fromPath(params.vep_cache).map { it -> [[id:'vep_cache'], it] }.collect()
                                                        : Channel.value([[],[]])

    // Prepare references and indices.
    PREPARE_INDICES(
        ch_input
    )
    ch_versions = ch_versions.mix(PREPARE_INDICES.out.versions)
    vcf_tbi = PREPARE_INDICES.out.vcf_tabix


    // Prepare references and indices.
    PREPARE_REFERENCES (
        ch_genome_fasta,
        ch_genome_fai,
        ch_gnomad_af_tab,
        ch_vep_cache_unprocessed
    )
    .set { ch_references }

    // Gather built indices or get them from the params
    ch_cadd_header              = Channel.fromPath("$projectDir/assets/cadd_to_vcf_header_-1.0-.txt", checkIfExists: true).collect()
    ch_cadd_resources           = params.cadd_resources                    ? Channel.fromPath(params.cadd_resources).collect()
                                                                           : Channel.value([])
    ch_genome_fai               = ch_references.genome_fai
    ch_genome_dictionary        = params.sequence_dictionary               ? Channel.fromPath(params.sequence_dictionary).map {it -> [[id:it[0].simpleName], it]}.collect()
                                                                           : ch_references.genome_dict
    ch_gnomad_afidx             = params.gnomad_af_idx                     ? Channel.fromPath(params.gnomad_af_idx).collect()
                                                                           : ch_references.gnomad_af_idx
    ch_gnomad_af                = params.gnomad_af                         ? ch_gnomad_af_tab.join(ch_gnomad_afidx).map {meta, tab, idx -> [tab,idx]}.collect()
                                                                           : Channel.empty()
    ch_reduced_penetrance       = params.reduced_penetrance                ? Channel.fromPath(params.reduced_penetrance).collect()
                                                                           : Channel.value([])
    ch_score_config_snv         = params.score_config_snv                  ? Channel.fromPath(params.score_config_snv).collect()
                                                                           : Channel.value([])
    ch_variant_consequences     = Channel.fromPath("$projectDir/assets/variant_consequences_v1.txt", checkIfExists: true).collect()
    ch_vcfanno_resources        = params.vcfanno_resources                 ? Channel.fromPath(params.vcfanno_resources).splitText().map{it -> it.trim()}.collect()
                                                                           : Channel.value([])
    ch_vcfanno_lua              = params.vcfanno_lua                       ? Channel.fromPath(params.vcfanno_lua).collect()
                                                                           : Channel.value([])
    ch_vcfanno_toml             = params.vcfanno_toml                      ? Channel.fromPath(params.vcfanno_toml).collect()
                                                                           : Channel.value([])
    ch_vep_cache                = ( params.vep_cache && params.vep_cache.endsWith("tar.gz") )  ? ch_references.vep_resources
                                                                           : ( params.vep_cache    ? Channel.fromPath(params.vep_cache).collect() : Channel.value([]) )
    ch_vep_filters              = params.vep_filters                       ? Channel.fromPath(params.vep_filters).collect()
                                                                           : Channel.value([])
    ch_pedfile                  = params.ped_file                          ? Channel.fromPath(params.ped_file).collect()
                                                                           : Channel.value([])
    ch_versions                 = ch_versions.mix(ch_references.versions)



    // CREATE CHROMOSOME BED AND INTERVALS
    SCATTER_GENOME (
        ch_genome_dictionary,
        ch_genome_fai,
        ch_genome_fasta
    )
    .set { ch_scatter }

    ch_scatter_split_intervals  = ch_scatter.split_intervals  ?: Channel.empty()

    // VARIANT ANNOTATION

    if (!params.skip_snv_annotation) {
        ANNOTATE_SNVS (
            vcf_tbi,
            params.analysis_type,
            ch_cadd_header,
            ch_cadd_resources,
            ch_vcfanno_resources,
            ch_vcfanno_lua,
            ch_vcfanno_toml,
            params.genome,
            params.vep_cache_version,
            ch_vep_cache,
            ch_genome_fasta,
            ch_gnomad_af,
            ch_scatter_split_intervals
        ).set {ch_snv_annotate}
        ch_versions = ch_versions.mix(ch_snv_annotate.versions)

        ch_snv_annotate = ANNOTATE_SNVS.out.vcf_ann

        ANN_CSQ_PLI_SNV (
            ch_snv_annotate,
            ch_variant_consequences
        )
        ch_versions = ch_versions.mix(ANN_CSQ_PLI_SNV.out.versions)

        RANK_VARIANTS_SNV (
            ANN_CSQ_PLI_SNV.out.vcf_ann,
            ch_pedfile,
            ch_reduced_penetrance,
            ch_score_config_snv
        )
        ch_versions = ch_versions.mix(RANK_VARIANTS_SNV.out.versions)

        FILTER_VEP_SNV(
            RANK_VARIANTS_SNV.out.vcf,
            ch_vep_filters
        )
        ch_versions = ch_versions.mix(FILTER_VEP_SNV.out.versions)

    }

    //
    // MODULE: Pipeline reporting
    //

    // The template v2.7.1 template update introduced: ch_versions.unique{ it.text }.collectFile(name: 'collated_versions.yml')
    // This caused the pipeline to stall
    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def makePed(samples) {

    def case_name  = samples[0].case_id
    def outfile  = file("${params.outdir}/pipeline_info/${case_name}" + '.ped')
    outfile.text = ['#family_id', 'sample_id', 'father', 'mother', 'sex', 'phenotype'].join('\t')
    def samples_list = []
    for(int i = 0; i<samples.size(); i++) {
        sample_tokenized   =  samples[i].id.tokenize("_")
        sample_tokenized.removeLast()
        sample_name        =  sample_tokenized.join("_")
        if (!samples_list.contains(sample_name)) {
            outfile.append('\n' + [samples[i].case_id, sample_name, samples[i].paternal, samples[i].maternal, samples[i].sex, samples[i].phenotype].join('\t'));
            samples_list.add(sample_name)
        }
    }
    return outfile
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
