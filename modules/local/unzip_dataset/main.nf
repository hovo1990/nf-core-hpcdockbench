
process unzipDataset{

    label 'low_cpu'


    if ( workflow.containerEngine == 'singularity' && params.singularity_use_local_file  ) {
        container "${params.singularity_local_cpu_container}"
        // containerOptions " --nv"
    }
    else if (workflow.containerEngine == 'singularity' ){
        container "${params.container_cpu_link}"
    }
    else {
        container "${params.container_cpu_link}"
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


    if (params.save_intermediate) {
        publishDir "${params.outdir}/stage2_unzipped_datasets/", mode: 'copy', overwrite: true
    }



    input:
        path(input)

    output:
        path("*")


    script:
        def i_version=2
        """
            unzip ${input}
        """
}


    // if (params.save_intermediate) {
    //     publishDir "${params.outdir}/stage2_unpacked_dataset", mode: 'copy', overwrite: true
    // }