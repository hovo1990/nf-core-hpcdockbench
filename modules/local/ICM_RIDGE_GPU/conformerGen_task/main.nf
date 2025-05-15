
process confGenTask_CPU {

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



    label 'cpu_task'

    cache true
    // debug true



    if ( workflow.containerEngine == 'singularity' && params.singularity_use_local_file  ) {
        container "${params.singularity_local_cpu_container}"
    }
    else if (workflow.containerEngine == 'singularity' ){
        container "${params.container_link}"
    }
    else {
        container "${params.container_link}"
    }

    if (params.mount_options) {
        if (workflow.containerEngine == 'singularity' ) {
            containerOptions "  --bind ${params.mount_options}"
        }
        else {
            containerOptions " --volume ${params.mount_options}"
        }
    }





    // if (params.save_intermediate) {

    // }

    publishDir "${params.outdir}/ICM-Ridge/Stage1_conformerGen/confGen/${code}/", mode: 'copy', overwrite: true

    // publishDir "${params.outdir}/ICM-Ridge/Stage1_ginger/${task.id}", mode: 'copy', overwrite: true

    // --  * val(folder was creating issues)
    input:
        tuple val(dataset_name), val(code),  val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files)
    output:
        tuple val("ICM-RIDGE"), val("Classical"), val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files),  path("confGen_${ligand_struct_2D.simpleName}.sdf")

    script:
        def r_effort= params.effort ?: 4.0
        def i_confs =  params.conformations ?: 10
        def i_cpus = task.cpus
        def i_random_seed  = params.random_seed ?: 25051990
        """
        ${params.icm_exec ?: "${params.icm_home}/icm64"} ${params.script ?: "${params.icm_home}/_confGen" } \
            append=yes -c -r -A -C mnconf=30 proc=${i_cpus} ${ligand_struct_2D} confGen_${ligand_struct_2D.simpleName}.sdf

        """
}



// -- * Sometimes this fails, maybe for benchmark just use confGen
process gingerTask_GPU {

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

    publishDir "${params.outdir}/ICM-Ridge/Stage1_conformerGen/ginger/${code}/", mode: 'copy', overwrite: true

    // publishDir "${params.outdir}/ICM-Ridge/Stage1_ginger/${task.id}", mode: 'copy', overwrite: true

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






//   GINGER: Generative Internal-coordinate Network Graph with Energy Refinement
//   Usage> /pro/icm/icms/_ginger <input.sdf|.tsv|.csv> [header=no smicol=A idcol=B] <output.sdf|.molt> [<options>]
//    maxenergy=(10.) : skip conformations with higher than 10. kcal/mole energies from the base
//    mnconf=(30)     : the maximal number of conformers per compound
//    sizelimit=(60)  : do not sample bigger molecules than <sizelimit> atoms
//    vicinity=(10.)  : [deg] the torsion root-mean-square deviation threshold for cluster size.
//    header=yes|no   : for TSV/CSV input reads first line as column names
//    smicol=<smi_col_name> : for TSV/CSV input name of the smiles column
//    idcol=<id_col_name>   : for TSV/CSV input name of ID column
//    sdfcompress=yes|no    : for SDF output store each conformation as a separate MOL entry (sdfcompress=no) or into CONF_LIST list field
//    -C  : set formal charges according to pKa model
//    -C  : set formal charges according to NN pKa model
//    -T  : enumerate tautomers
//    -f  : Force overwriting of the output file
//    -hydrogen : keep all hydrogen (by default only polar are kept). This option only affects on SDF output
//    -h  : Help
//    -fr=.. -to=..  from and to indexes of the database to be screened.



// -- * Maybe use
//  Warning> GINGER cannot generate conformation for 1 (out of 1) compounds (Stored into ginger_p1GM8_SOX_2D_ligand_skipped.sdf)
//  Info> use command below to append them to result molt
//         /pro/icm/icms/icm64 _confGen  append=yes -c -r -A -C mnconf=30 proc=27 ginger_p1GM8_SOX_2D_ligand_skipped.sdf ginger_p1GM8_SOX_2D_ligand.sdf