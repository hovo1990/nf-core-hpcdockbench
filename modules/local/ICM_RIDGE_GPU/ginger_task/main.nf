
process gingerTask {

    //-- ! something wrong with SLURM and dockScan
    //-- * in some cases dockScan can lead to segmentation fault, thus ignore those ones


    // maxRetries 5
    // errorStrategy {
    //     if (task.exitStatus >= 100 ){
    //         sleep(Math.pow(2, task.attempt) * 15 as long);
    //         'retry'
    //     } else {
    //         'terminate'
    //     }
    // }


    beforeScript 'hostname;echo "Wait random 5 secs"; sleep $((RANDOM % 5))'



    label 'gpu_task'

    cache true
    // debug true
    if (params.save_intermediate) {
        publishDir "${params.outdir}/ICM-Ridge/${code}/Stage1_ginger", mode: 'copy', overwrite: true
    }

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








    // --  * val(folder was creating issues)
    input:
        tuple val(dataset_name), val(code),  val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files)
    output:
        tuple val("ICM-RIDGE"), val("Classical"), val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files),  path("ginger_${ligand_struct_2D.simpleName}.sdf")

    script:
        def r_effort= params.effort ?: 4.0
        def i_confs =  params.conformations ?: 10
        def i_cpus = task.cpus
        def i_random_seed  = params.random_seed ?: 25051990
        """

        ${params.icm_exec ?: "${params.icm_home}/icm64"} ${params.script ?: "${params.icm_home}/_ginger" } \
                ${ligand_struct_2D} \
                ginger_${ligand_struct_2D.simpleName}.sdf

        """
}

