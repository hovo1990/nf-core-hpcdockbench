
//-- * Example: https://github.com/nf-core/sarek/blob/5cc30494a6b8e7e53be64d308b582190ca7d2585/modules/nf-core/gawk/main.nf#L6
process filterFolders{


    label 'low_cpu'


    publishDir "${params.outdir}/stage3_prep_csv", mode: 'copy', overwrite: true
    // container  "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_use_local_file ?
    //         ${params.singularity_local_container} :
    //         'biocontainers/gawk:5.3.0' }"

    // container "/home/hovakim/GitSync/quick.sif"

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

        awk -F, 'BEGIN {OFS=","} NR==1 {$\0=$\0",ProjID"} NR>1 {$\0=$\0",${proj_id}"} 1' ${docked_pose.simpleName}_pre.csv > ${docked_pose.simpleName}.csv

        def i_version=1
    """
        python ${projectDir}/bin/filterFolders.py   --input=${input}
    """
}


