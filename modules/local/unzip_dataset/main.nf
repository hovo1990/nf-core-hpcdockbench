
process unzipDataset{

    label 'low_cpu'


    publishDir "${params.outdir}/stage2_unpacked_dataset", mode: 'copy', overwrite: true

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



    label "process_low"


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
