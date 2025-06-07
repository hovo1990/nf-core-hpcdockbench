
//-- * Example: https://github.com/nf-core/sarek/blob/5cc30494a6b8e7e53be64d308b582190ca7d2585/modules/nf-core/gawk/main.nf#L6
process makePlot{


    label 'low_cpu'


    publishDir "${params.outdir}/plots", mode: 'copy', overwrite: true
    // container  "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_use_local_file ?
    //         ${params.singularity_local_cpu_container} :
    //         'biocontainers/gawk:5.3.0' }"


    if ( workflow.containerEngine == 'singularity' && params.singularity_use_local_file  ) {
        container "${params.singularity_local_cpu_container}"
        // containerOptions " --nv"
    }
    else if (workflow.containerEngine == 'singularity' ){
        container "${params.container_link}"
    }
    else {
        container "${params.container_link}"
        // containerOptions " --gpus all"
    }

    if (params.mount_options) {
        if (workflow.containerEngine == 'singularity' ) {
            containerOptions "--bind ${params.mount_options}"
        }
        else {
            containerOptions "--volume ${params.mount_options}"
        }
    }




    input:
        path(input)

    output:
        path("*.pdf")
        path("*.svg")
        path("*.csv")


    script:
        def i_version=6
    """
        python ${projectDir}/bin/makePlots.py   --input=${input} --paperdata=${projectDir}/assets/posebuster_paper.csv
    """
}


