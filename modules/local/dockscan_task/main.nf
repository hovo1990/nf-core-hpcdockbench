
process dockScanTask {

    //-- ! something wrong with SLURM and dockScan
    //-- * in some cases dockScan can lead to segmentation fault, thus ignore those ones


    // maxRetries 4
    // errorStrategy {
    //     if (task.exitStatus >= 100){
    //         'retry'
    //     } else {
    //         'terminate'
    //     }
    // }


    beforeScript 'hostname;echo "Wait random 15 secs"; sleep $((RANDOM % 15))'



    label 'process_full'

    cache true
    // debug true
    publishDir "${params.outdir}/stage4_docking_projects/${code}/", mode: 'copy', overwrite: true
    // debug true


    if (params.mount_options) {
        containerOptions '--volume ${params.mount_options}'
    }



    input:
        tuple val(dataset_name), val(code), val(folder), path(protein_struct), path(ligand_struct), path(ligand_struct_2D), val(proj_id), path(proj_files)
    output:
         tuple val(dataset_name), val(code), val(folder), path(protein_struct), path(ligand_struct), path(ligand_struct), val(proj_id), path(proj_files), file("${proj_id}_${ligand_struct_2D.simpleName}1.ob")

    script:
        def input_str = proj_files instanceof List ? proj_files.join(" ") : proj_files
        def r_effort= params.effort ?: 4.0
        def i_confs =  params.confs ?: 10
        def i_cpus = params.cpus ?: task.cpus
        def i_random_seed  = params.random_seed ?: 25051990
        """
        # -- * No need to copy nextflow will create symlinks to the docking project files
        #-- * Copy docking project to scratch generated folder
        #cp -a ${input_str} .


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
