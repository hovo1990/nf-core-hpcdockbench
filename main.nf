#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/hpcdockbench
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/nf-core/hpcdockbench
    Website: https://nf-co.re/hpcdockbench
    Slack  : https://nfcore.slack.com/channels/hpcdockbench
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { HPCDOCKBENCH  } from './workflows/hpcdockbench'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_dockbench_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_dockbench_pipeline'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow NFCORE_HPCDOCKBENCH {

    // take:
    // samplesheet // channel: samplesheet read in from --input

    main:

    //
    // WORKFLOW: Run pipeline
    //
    HPCDOCKBENCH (
        // samplesheet
    )
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def greet(name) {
    return "Hello, ${name}!"
}



// -- * Why create this function?
// -- * https://apptainer.org/docs/user/main/gpu.html
// Function to choose the "highest compatible" container
String pickContainer(String glibc) {
    def containerCandidates = [
            '2.27': 'docker.io/hgrabski/hpc_dock_bench:gpu-18.04', // glibc 2.27
            '2.31': 'docker.io/hgrabski/hpc_dock_bench:gpu-20.04', // glibc 2.31
            '2.35': 'docker.io/hgrabski/hpc_dock_bench:gpu-22.04', // glibc 2.35
            '2.39': 'docker.io/hgrabski/hpc_dock_bench:gpu-24.04'  // glibc 2.39
        ]


    def v = new BigDecimal(glibc)
    if (v >= 2.39) return containerCandidates['2.39']
    if (v >= 2.35) return containerCandidates['2.35']
    if (v >= 2.31) return containerCandidates['2.31']
    return containerCandidates['2.27']  // fallback for older hosts
}

workflow {

    main:
    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION (
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir
    )

    //
    // WORKFLOW: Run main workflow
    //
    // -- * Custom parameter definition
    // Detect host glibc version from wrapper (fallback = 2.31)
    def glibc = System.getenv('NXF_GLIBC_VERSION') ?: '2.31'


    // println containerCandidates

    // -- * debug
    // log.info greet('Nextflow')



    container_link = pickContainer(glibc)
    println container_link

    // NFCORE_HPCDOCKBENCH (
    //     // PIPELINE_INITIALISATION.out.samplesheet
    // )


    // SUBWORKFLOW: Run completion tasks
    //
    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        params.hook_url,
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
