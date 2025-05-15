// -- * Sometimes this fails, maybe for benchmark just use confGen
process ridgeTask_GPU {

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



    if ( workflow.containerEngine == 'singularity' && params.singularity_use_local_file  ) {
        container "${params.singularity_local_gpu_container}"
        containerOptions " --nv"
    }
    else if (workflow.containerEngine == 'singularity' ){
        container "${params.container_link}"
        containerOptions " --nv"
    }
    else {
        container "${params.container_link}"
        containerOptions " --gpus all"
    }

    if (params.mount_options) {
        if (workflow.containerEngine == 'singularity' ) {
            containerOptions " --nv --bind ${params.mount_options}"
        }
        else {
            containerOptions " --gpus all --volume ${params.mount_options}"
        }
    }





    // if (params.save_intermediate) {

    // }

    publishDir "${params.outdir}/ICM-Ridge/Stage2_ridge/${code}/", mode: 'copy', overwrite: true

    // publishDir "${params.outdir}/ICM-Ridge/Stage1_ginger/${task.id}", mode: 'copy', overwrite: true

    // --  * val(folder was creating issues)
    input:
        tuple val(method), val(category), val(dataset_name), val(code),  val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files), path(conformer_file)
    output:
        tuple val(method),val(category), val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files),  path(conformer_file), path("ridge_${proj_id}.sdf")

    script:
        def i_version = 2
        def r_effort= params.effort ?: 4.0
        def i_confs =  params.conformations ?: 10
        def i_cpus = task.cpus
        def i_random_seed  = params.random_seed ?: 25051990
        def nconf = params.nconf  ?: 10 //-- TODO modify this part for testing
        def batchSize = nconf > 5  ? 500 : 1000 //-- * not enough memory for rtx 4070 setting batchSize =1000
        def r_scoreCutoff = params.scoreCutoff  ?: -25
        def r_mnhits = params.mnhits  ?: 20000
        """
        ${params.icm_exec ?: "${params.icm_home}/icm64"} ${params.script ?: "${params.icm_home}/_ridge" } \
                ${proj_id}  \
                input=${conformer_file} \
                batchSize=${batchSize} \
                -C \
                scoreCutoff=${r_scoreCutoff} \
                mnhits=${r_mnhits}  \
                output=ridge_${proj_id}.sdf
        """
}


// -- * Ridge can write an empty file that is not good at all
// -- ! it is asking for molt file
        // /pro/icm/icms/icm64 _confGen  append=yes -c -r -A -C mnconf=30 proc=6 /tmp/confGen_p1GM8_SOX_2D_ligand_conf_skipped.sdf /tmp/confGen_p1GM8_SOX_2D_ligand_conf.molt