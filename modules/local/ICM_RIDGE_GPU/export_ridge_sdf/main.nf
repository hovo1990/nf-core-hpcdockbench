process exportRidgeSDF{


    label 'low_cpu_debug'

    beforeScript 'hostname;echo "Wait random 10 secs"; sleep $((RANDOM % 10))'
    maxRetries 5
    errorStrategy {
        if (task.exitStatus >= 100 ){
            sleep(Math.pow(2, task.attempt) * 15 as long);
            'retry'
        } else {
            'terminate'
        }
    }

    cache true
    // debug true



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
        tuple val(method),val(category),val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files),  path(ob_file), path(icb_file)


    output:
        tuple val(method),val(category), val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files),  path(ob_file), path(icb_file), path("${proj_id}_ridge_rank_*.sdf")


    script:
        def i_version=1
        """
        echo "Export ridge docking poses as sdf file  v${i_version}"

        #ls -l .
        ${params.icm_exec ?: "${params.icm_home}/icm64"} \
        ${projectDir}/bin/export_ridge_sdf.icm \
                -p=${proj_id} \
                -i=${icb_file}

        """
}

    // if (params.save_intermediate) {
    //     publishDir "${params.outdir}/stage7_export_sdf/$proj_id/${method}", mode: 'copy', overwrite: true
    // }