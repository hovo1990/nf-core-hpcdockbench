process matchingFraction{

    label 'very_low_cpu_debug'

    beforeScript 'hostname;echo "Wait random 20 secs"; sleep $((RANDOM % 20))'
    // maxRetries 5
    // errorStrategy {
    //     if (task.exitStatus >= 100 ){
    //         sleep(Math.pow(2, task.attempt) * 20 as long);
    //         'retry'
    //     } else {
    //         'terminate'
    //     }
    // }


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



    cache true




    input:
        tuple val(method),val(category), val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct), path(docked_pose)


    output:
        tuple val(method),val(category),val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct),  path(docked_pose), path("${docked_pose.simpleName}_mf.sdf")


    script:
        def i_version=4
        """
        echo "matching Fraction  v-${i_version}"

        # -- * Run ICM script to calculate RMSD and matching fraction
        ${params.icm_exec ?: "${params.icm_home}/icm64"} \
        ${projectDir}/bin/matching_fraction.icm \
                -ic=${ligand_struct} \
                -id=${docked_pose} \
                -o="${docked_pose.simpleName}_mf.sdf"
        """
}

