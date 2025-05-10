
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


    beforeScript 'hostname;echo "Wait random 10 secs"; sleep $((RANDOM % 10))'



    label 'low_cpu_debug'

    cache true
    // debug true
    publishDir "${params.outdir}/stage5_docking/", mode: 'copy', overwrite: true
    // debug true


    if (params.mount_options) {
        containerOptions '--volume ${params.mount_options}'
    }


    // --  * val(folder was creating issues)
    input:
        tuple val(dataset_name), val(code),  val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files)
    output:
        tuple val(dataset_name), val(code), val(proj_id), val(protein_struct), val(ligand_struct), val(ligand_struct_2D),  val(proj_files),  file("${proj_id}_${ligand_struct_2D.simpleName}1.ob")

    script:
        def r_effort= params.effort ?: 4.0
        def i_confs =  params.conformations ?: 10
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

