// -- * For RTCNN2
process confGenTask_RTCNN2_CPU {

    tag "CPU-confGen-RTCNN2-${proj_id}"
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



    label 'low_cpu_debug'

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




    if (params.save_intermediate) {

         publishDir = [
            path: { "${params.outdir}/" },
            mode: params.publish_dir_mode,
            saveAs: { filename ->
            filename.equals('versions.yml') ? null : "${params.outdir}/ICM-RIDGE-RTCNN2/stage1_conformer_generation/confGen/${dataset_name}/${proj_id}/${filename}" }
        ]
    }



    // --  * val(folder was creating issues)
    input:
        tuple val(dataset_name), val(code),  val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files)
    output:
        tuple val("ICM-RIDGE-RTCNN2"), val("Classical"), val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files),  path("confGen_${ligand_struct_2D.simpleName}.molt")

    script:
        def r_effort= params.effort ?: 4.0
        def i_confs =  params.conformations ?: 10
        def i_cpus = task.cpus
        def i_random_seed  = params.random_seed ?: 25051990
        """
        ${params.icm_exec ?: "${params.icm_home}/icm64"} ${params.script ?: "${params.icm_home}/_confGen" } \
             effort=10.0 torlimit=50 sizelimit=600 mnconf=50 -hydrogen\
             proc=${i_cpus} ${ligand_struct_2D} confGen_${ligand_struct_2D.simpleName}.molt

        """
}


// -- * Original for Ridge
process confGenTask_CPU {

    tag "CPU-confGen-${proj_id}"
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





    label 'low_cpu_debug'

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




    if (params.save_intermediate) {

         publishDir = [
            path: { "${params.outdir}/" },
            mode: params.publish_dir_mode,
            saveAs: { filename ->
            filename.equals('versions.yml') ? null : "${params.outdir}/ICM-RIDGE/stage1_conformer_generation/confGen/${dataset_name}/${proj_id}/${filename}" }
        ]
    }



    // --  * val(folder was creating issues)
    input:
        tuple val(dataset_name), val(code),  val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files)
    output:
        tuple val("ICM-RIDGE"), val("Classical"), val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files),  path("confGen_${ligand_struct_2D.simpleName}.molt")

    script:
        def r_effort= params.effort ?: 4.0
        def i_confs =  params.conformations ?: 10
        def i_cpus = task.cpus
        def i_random_seed  = params.random_seed ?: 25051990
        """
        ${params.icm_exec ?: "${params.icm_home}/icm64"} ${params.script ?: "${params.icm_home}/_confGen" } \
             effort=10.0 torlimit=50 sizelimit=600 mnconf=50 -hydrogen\
             proc=${i_cpus} ${ligand_struct_2D} confGen_${ligand_struct_2D.simpleName}.molt

        """
}


        // ${params.icm_exec ?: "${params.icm_home}/icm64"} ${params.script ?: "${params.icm_home}/_confGen" } \
        //      effort=10.0 torlimit=50 sizelimit=600 \
        //      -V -c -r -A  mnconf=50 \
        //      proc=${i_cpus} ${ligand_struct_2D} confGen_${ligand_struct_2D.simpleName}.molt


///pro/icm/icms/icm64 /pro/icm/icms/_confGen  append=yes effort=10.0 torlimit=30 sizelimit=500 -V -c -r  -A -C  mnconf=50 proc=8 p7MSR_DCA_2D_ligand.sdf confGen_p7MSR_DCA_2D_ligand.sdf
// Startup> Loading config file /home/$USER/.icm/config/icm.cfg ..

//   Usage> /pro/icm/icms/_confGen <input.sdf> <output.sdf> [<options>]
//    auto=    (0) : number of rotatable bonds to auto switch between systematic and MC. 0:always MC
//    effort= (1.) : the relative mc sampling effort. Increase to 3. or 10. for more rigorous sampling
//    maxenergy=(10.) : skip conformations with higher than 10. kcal/mole energies from the base
//    mnconf=(50)     : the maximal number of conformers per compound
//    sizelimit=(80)  : do not sample bigger molecules than <sizelimit> atoms
//    torlimit=(15)   : do not sample molecules with more than <torlimit> torsions (ring torsions counted as 1/2)
//    vicinity=(30)   : [deg] the torsion root-mean-square deviation threshold for cluster size.
//    diel=(78.5)      : solvent dielectric constant (only active with -c)
//    -c  : improve geometries and energies with Cartesian MMFF minimization
//    -b  : same as -c but without bond lengths
//    -C  : set formal charges according to pKa model
//    -Cn : set formal charges according to NN pKa model
//    -d  : sample cis/trans for Double bonds
//    -e  : only evaluate conformational Entropy for compound (no poses)
//    -f  : Force overwriting of the output file
//    -h  : Help
//    -I  : force update of the Input data file index
//    -q  : Quiet (suppress warnings)
//    -r  : sample flexible Ring systems
//    -s  : use Systematic search instead of MC
//    -A  : use AI-assisted sampling instead of standard MC
//    -S  : evaluate Strain of this particular conformation from 3D mol file (implies -keep3D)
//    -V  : verbose (show commands).
//    -v  : verbose (show more info)
//    -fr=.. -to=..  from and to indexes of the database to be screened.
//    -fr=.. -stride=..  from and step indexes of the database to be screened.
//    -hydrogen  : keep hydrogens in the result table
//    -keep3D    : keep conformation from a 3D mol file
//    -molcart=connect_string  : host,user,pass,database
//    proc=<n_parallel_jobs>        : start n parallel jobs


// /pro/icm/icms/icm64 /pro/icm/icms/_confGen            append=yes effort=10.0 -V -c -r -A -C -hydrogen mnconf=30 proc=8 p7MSR_DCA_2D_ligand.sdf confGen_p7MSR_DCA_2D_ligand.sdf

// -- * Sometimes this fails, maybe for benchmark just use confGen
process gingerTask_GPU {

    tag "GPU-GINGER-${proj_id}"

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




    if (params.save_intermediate) {

         publishDir = [
            path: { "${params.outdir}/" },
            mode: params.publish_dir_mode,
            saveAs: { filename ->
            filename.equals('versions.yml') ? null : "${params.outdir}/${method}/stage1_conformer_generation/ginger/${dataset_name}/${proj_id}/${filename}" }
        ]
    }





    // --  * val(folder was creating issues)
    input:
        tuple val(dataset_name), val(code),  val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files)
        val(method)
        val(category)


    output:
        tuple val(method), val(category), val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct), path(ligand_struct_2D),  path(proj_files),  path("ginger_${ligand_struct_2D.simpleName}.molt")

    script:
        def i_version = 2
        def i_cpus = task.cpus
        def i_random_seed  = params.random_seed ?: 25051990
        """
        trap 'if [[ \$? == 1 ]]; then echo " Ginger GPU Failed, but continue"; exit 0; fi' EXIT
        ${params.icm_exec ?: "${params.icm_home}/icm64"} ${params.script ?: "${params.icm_home}/_ginger" } \
                ${ligand_struct_2D} \
                sizelimit=600 \
                -C mnconf=50 \
                -hydrogen \
                ginger_${ligand_struct_2D.simpleName}.molt

        """
}



// -- * All important code below here

// -- * Original for Ridge
process confGenTask_CPU_separate {

    tag "CPU-confGen-${proj_id}"
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





    label 'low_cpu_debug'

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




    if (params.save_intermediate) {

         publishDir = [
            path: { "${params.outdir}/" },
            mode: params.publish_dir_mode,
            saveAs: { filename ->
             filename.equals('versions.yml') ? null : "${params.outdir}/CPU_confGen/${proj_id}/${filename}" }
        ]
    }



    // --  * val(folder was creating issues)
    input:
        tuple val(proj_id), path(ligand_struct_2D)

    output:
        tuple val(proj_id), path("confGen_${ligand_struct_2D.simpleName}.molt"), optional: true


    script:
        def r_effort= params.effort ?: 4.0
        def i_confs =  params.conformations ?: 10
        def i_cpus = task.cpus
        def i_random_seed  = params.random_seed ?: 25051990
        """
        ${params.icm_exec ?: "${params.icm_home}/icm64"} ${params.script ?: "${params.icm_home}/_confGen" } \
             effort=10.0 torlimit=50 sizelimit=600 mnconf=50 -hydrogen\
             proc=${i_cpus} ${ligand_struct_2D} confGen_${ligand_struct_2D.simpleName}.molt

        """
}

// -- * Sometimes this fails, maybe for benchmark just use confGen
process gingerTask_GPU_separate {

    tag "GPU-GINGER-${proj_id}"

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




    if (params.save_intermediate) {

         publishDir = [
            path: { "${params.outdir}/" },
            mode: params.publish_dir_mode,
            saveAs: { filename ->
            filename.equals('versions.yml') ? null : "${params.outdir}/GPU_GINGER/${proj_id}/${filename}" }
        ]
    }





    // --  * val(folder was creating issues)
    input:
        tuple val(proj_id), path(ligand_struct_2D)


    output:
        tuple val(proj_id), path("ginger_${ligand_struct_2D.simpleName}.molt"), optional: true

    script:
        def i_version = 2
        def i_cpus = task.cpus
        def i_random_seed  = params.random_seed ?: 25051990
        """
        trap 'if [[ \$? == 1 ]]; then echo " Ginger GPU Failed, but continue"; exit 0; fi' EXIT
        ${params.icm_exec ?: "${params.icm_home}/icm64"} \
                ${params.script ?: "${params.icm_home}/_ginger" }  \
                ${ligand_struct_2D} \
                sizelimit=600 \
                -C mnconf=50 \
                -hydrogen \
                ginger_${ligand_struct_2D.simpleName}.molt

        """
}


// -- ! Older version 4

                // -neutral=yes \
                // -T \


// -- ! Older verison 3
        // """
        // trap 'if [[ \$? == 1 ]]; then echo " Ginger GPU Failed, but continue"; exit 0; fi' EXIT
        // ${params.icm_exec ?: "${params.icm_home}/icm64"} \
        //         ${projectDir}/bin/_ginger_custom \
        //         ${ligand_struct_2D} \
        //         sizelimit=600 \
        //         -C mnconf=50 \
        //         -hydrogen \
        //         -T \
        //         ginger_${ligand_struct_2D.simpleName}.molt

        // """



// -- ! Old version 2
//                 -neutral=yes \

// -- ! Old version
//     script:
//         def i_version = 2
//         def i_cpus = task.cpus
//         def i_random_seed  = params.random_seed ?: 25051990
//         """
//         trap 'if [[ \$? == 1 ]]; then echo " Ginger GPU Failed, but continue"; exit 0; fi' EXIT
//         ${params.icm_exec ?: "${params.icm_home}/icm64"} ${params.script ?: "${params.icm_home}/_ginger" } \
//                 ${ligand_struct_2D} \
//                 sizelimit=600 \
//                 -C mnconf=50 \
//                 -hydrogen \
//                 -T \
//                 ginger_${ligand_struct_2D.simpleName}.molt

//         """
// }





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




    // if (params.save_intermediate) {
    //     publishDir "${params.outdir}/ICM-Ridge/Stage1_conformerGen/confGen/${code}/", mode: 'copy', overwrite: true
    // }


    // if (params.save_intermediate) {
    //     publishDir "${params.outdir}/ICM-Ridge/Stage1_conformerGen/ginger/${code}/", mode: 'copy', overwrite: true
    // }