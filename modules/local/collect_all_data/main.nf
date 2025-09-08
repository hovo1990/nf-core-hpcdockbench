
//-- * Example: https://github.com/nf-core/sarek/blob/5cc30494a6b8e7e53be64d308b582190ca7d2585/modules/nf-core/gawk/main.nf#L6
process collectAllData{


    label 'low_cpu'

    maxRetries 5
    errorStrategy {
        if (task.exitStatus >= 100 ){
            sleep(Math.pow(2, task.attempt) * 15 as long);
            'retry'
        } else {
            'terminate'
        }
    }


    publishDir "${params.outdir}/stage9_collected_data", mode: 'copy', overwrite: true

    // container  "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_use_local_file ?
    //         ${params.singularity_local_cpu_container} :
    //         'biocontainers/gawk:5.3.0' }"

    // container "/home/hovakim/GitSync/quick.sif"

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




    input:
        path(input)

    output:
        path("collectedData.csv")


    script:
        def i_version=1
    """
        python ${projectDir}/bin/collectAllData.py   --input=${input} --output=collectedData.csv
    """
}


