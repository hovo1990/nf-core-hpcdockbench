process poseBust{

    label 'low_cpu_debug'

    beforeScript 'hostname;echo "Wait random 10 secs"; sleep $((RANDOM % 10))'
    // maxRetries 5
    // errorStrategy {
    //     if (task.exitStatus >= 1){
    //         sleep(Math.pow(2, task.attempt) * 15 as long);
    //         'retry'
    //     } else {
    //         'terminate'
    //     }
    // }
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



    cache true
    // debug true
    publishDir "${params.outdir}/stage8_pose_bust/$dataset_name/$proj_id/", mode: 'copy', overwrite: true


    input:
        tuple val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct), path(docked_pose)


    output:
        tuple val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct),  path(docked_pose), path("${docked_pose.simpleName}.csv")


    script:
        def i_version=1
        """
        echo "Pose busting  v${i_version}"

        bust ${docked_pose} -l ${ligand_struct} -p ${protein_struct} --outfmt csv >| ${docked_pose.simpleName}_pre.csv


        # -- * Run python script to append extra info for absolute data
        python ${projectDir}/bin/posebust_update.py   --input=${docked_pose.simpleName}_pre.csv \
                                                    --dataset=${dataset_name} \
                                                    --prot=${protein_struct} \
                                                    --lig=${ligand_struct} \
                                                    --dock=${docked_pose} \
                                                    --code=${code} \
                                                    --proj=${proj_id} \
                                                    --output==${docked_pose.simpleName}.csv

        """
}

