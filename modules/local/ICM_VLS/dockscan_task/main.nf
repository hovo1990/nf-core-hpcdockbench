
process dockScanTask {

    //-- ! something wrong with SLURM and dockScan
    //-- * in some cases dockScan can lead to segmentation fault, thus ignore those ones


    maxRetries 5
    errorStrategy {
        if (task.exitStatus >= 100 ){
            sleep(Math.pow(2, task.attempt) * 15 as long);
            'retry'
        } else {
            'terminate'
        }
    }






    label 'low_cpu_debug'

    cache true


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



        // publishDir "", mode: 'copy', overwrite: true, saveAs: { file ->
        //     def dataset_name = task.inputs[0]
        //     def proj_id = task.inputs[2]
        //     return "${dataset_name}/${proj_id}/${file.name}"
        // }


    if (params.save_intermediate) {

         publishDir = [
            path: { "${params.outdir}/" },
            mode: params.publish_dir_mode,
            saveAs: { filename ->
            filename.equals('versions.yml') ? null : "${params.outdir}/ICM-VLS/stage1_dockScan/${dataset_name}/${proj_id}/${filename}" }
        ]
    }



    // --  * val(folder was creating issues)
    input:
        tuple val(dataset_name), val(code),  val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files)
    output:
        tuple val("ICM-VLS"), val("Classical"), val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files),  file("${proj_id}_${ligand_struct_2D.simpleName}1.ob")

    script:
        def r_effort= params.effort ?: 32.0
        def i_confs =  params.conformations ?: 40
        def i_cpus = task.cpus
        def i_random_seed  = params.random_seed ?: 25051990
        """
        # -- * No need to copy nextflow will create symlinks to the docking project files

        #-- * this works
        # ls -l .

        ${params.icm_exec ?: "${params.icm_home}/icm64"} ${params.script ?: "${params.icm_home}/_dockScan" } \
                proc=${i_cpus} \
                -s  -a  -S \
                confs=${i_confs} \
                effort=${r_effort} \
                seed=${i_random_seed} \
                input=${ligand_struct_2D} \
                ${proj_id}


        """
}

    // debug true
    // if (params.save_intermediate) {
    //     publishDir "${params.outdir}/stage5_docking/${code}/ICM-VLS", mode: 'copy', overwrite: true
    // }