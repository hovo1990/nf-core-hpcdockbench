
process downloadBenchmarkDataset{

    label 'low_cpu'

    if (params.save_intermediate) {
        publishDir "${params.outdir}/stage1_download_benchmark_dataset", mode: 'copy', overwrite: true
    }



    beforeScript "hostname"
    if ( workflow.containerEngine == 'singularity' && params.singularity_use_local_file  ) {
        container "${params.singularity_local_container}"
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




    label "process_low"


    // input:
    //     path(input)

    output:
        path("posebusters_paper_data.zip")


    script:
        def i_version=2
        """
            wget ${params.benchmark_dataset}
        """
}
