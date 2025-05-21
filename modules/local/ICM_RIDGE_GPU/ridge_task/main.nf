// -- * Sometimes this fails, maybe for benchmark just use confGen
process ridgeTask_GPU {

    tag "GPU-RIDGE-${proj_id}"

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
    //     publishDir "${params.outdir}/ICM-Ridge/Stage2_ridge/${code}/", mode: 'copy', overwrite: true
    // }




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
        def r_scoreCutoff = params.scoreCutoff  ?: 20000
        def r_mnhits = params.mnhits  ?: 20000
        """
        ${params.icm_exec ?: "${params.icm_home}/icm64"} \
        ${projectDir}/bin/_ridge_custom  \
                ${proj_id}  \
                input=${conformer_file} \
                batchSize=${batchSize} \
                -C \
                -keepStack  \
                scoreCutoff=${r_scoreCutoff} \
                mnhits=${r_mnhits}  \
                output=ridge_${proj_id}.sdf


        """
}


// -- * Ridge can write an empty file that is not good at all
// -- ! it is asking for molt file
        // /pro/icm/icms/icm64 _confGen  append=yes -c -r -A -C mnconf=30 proc=6 /tmp/confGen_p1GM8_SOX_2D_ligand_conf_skipped.sdf /tmp/confGen_p1GM8_SOX_2D_ligand_conf.molt



// -- * Command line
// Startup> Loading config file /home/hovakim/.icm/config/icm.cfg ..
// Use: <icm> ./_ridge <projFile> [output=<.sdf>] [<options>] input=<s_confMolt1.molt>,..,<s_confMoltN.molt>
// Options:
//   confs=<N>          : score/save only up to <N> top poses for RTCNN rescore
//   randomSelect=<N>   : dock N random compounds (default - 0, dock everything )
//   list=<subselection.tsv>   : dock subset by ID
//   fr=<i_fr>,to=<i_to>: dock range i_fr/i_to (default, dock everything )
//   output=<.sdf>      : output hitlist sdf file name
//   gpuid=<i_gpu_id>   : use specific GPU (default -1)
//   scoreCutoff=<score>: accept ligs with score better than <score> Default: -25
//   clashWeight=<r_value> : clash penalty weight (default 20.)
//   clashScale=<r_value> : clash van der Waals scale (default 0.82)
//   threads=<i_threadsPerBlock> : GPU threads per block (default 256)
//   mnhits=<N>         : maximum number of top scored output hits (default: 20K, 0: disable)
//   -s                 : 'smooth' maps
//   -C                 : perform cartesian optimization for best poses
//   -S                 : rescore with physics-based ICM VLS score
//   confsRescore=<i_ncf> : number of conformations to rescore by combined physics-based ICM VLS and RTCNN scores (default 1)
//   -keepStack         : store all conformations in the hitlist
//   smicol=<s_col>     : name of SMILES column (for direct CSV/TSV input)
//   idcol=<s_col>      : name of ID column (for direct CSV/TSV/SDF input)
//   header=<yes|no>    : interpret first line of CSV/TSV as column names (deault yes)