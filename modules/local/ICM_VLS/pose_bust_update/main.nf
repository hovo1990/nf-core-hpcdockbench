process poseBust_update{
    tag "CPU-PBUP-${proj_id}"
    label 'very_low_cpu_debug'


    maxRetries 5
    errorStrategy {
        if (task.exitStatus >= 100 ){
            sleep(Math.pow(2, task.attempt) * 35 as long);
            'retry'
        } else {
            'terminate'
        }
    }


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



    cache true
    if (params.save_intermediate) {

         publishDir = [
            path: { "${params.outdir}/" },
            mode: params.publish_dir_mode,
            saveAs: { filename ->
            filename.equals('versions.yml') ? null : "${params.outdir}/${method}/stage6_posebusted_update/${dataset_name}/${proj_id}/${filename}" }
        ]
    }




    input:
        tuple val(method),val(category), val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct), path(docked_pose_mf), path(docked_pose_pb)


    output:
        tuple val(method),val(category),val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct),  path(docked_pose_mf),  path(docked_pose_pb), path("${docked_pose_pb.simpleName}_up.csv")


    script:
        def i_version=6
        """
        echo "Pose busting update  v${i_version}"


        # -- * Run python script to append extra info for absolute data
        python ${projectDir}/bin/posebust_update_v2.py --input=${docked_pose_pb} \
                                                    --dataset=${dataset_name} \
                                                    --prot=${protein_struct} \
                                                    --lig=${ligand_struct} \
                                                    --dock=${docked_pose_mf} \
                                                    --code=${code} \
                                                    --proj=${proj_id} \
                                                    --method=${method} \
                                                    --category=${category} \
                                                    --output=${docked_pose_pb.simpleName}_up.csv

        """
}

