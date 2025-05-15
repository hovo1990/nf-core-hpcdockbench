
//-- * Example: https://github.com/nf-core/sarek/blob/5cc30494a6b8e7e53be64d308b582190ca7d2585/modules/nf-core/gawk/main.nf#L6
process filterFolders{


    label 'low_cpu'

    // -- ! this does not work unfortunately
    if (params.save_intermediate) {
        publishDir "${params.outdir}/stage3_prep_csv", mode: 'copy', overwrite: true
    }



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
        path("*.csv")


    script:
        def i_version=1
    """
        python ${projectDir}/bin/filterFolders.py   --input=${input}
    """
}


