process poseBust{
    tag "CPU-PB-${proj_id}"
    label 'low_cpu_debug'


    maxRetries 5
    errorStrategy {
        if (task.exitStatus >= 100 ){
            sleep(Math.pow(2, task.attempt) * 20 as long);
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
            filename.equals('versions.yml') ? null : "${params.outdir}/${method}/stage5_posebusted/${dataset_name}/${proj_id}/${filename}" }
        ]
    }




    input:
        tuple val(method),val(category), val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct), path(docked_pose_mf)


    output:
        tuple val(method),val(category),val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct),  path(docked_pose_mf), path("${docked_pose_mf.simpleName}_pb.csv")


    script:
        def i_version=5
        """
        echo "Pose busting  v${i_version}"

        bust ${docked_pose_mf} -l ${ligand_struct} -p ${protein_struct} --outfmt csv >| ${docked_pose_mf.simpleName}_pb.csv

        """
}







process poseBust_v1{

    label 'very_low_cpu_debug'


    maxRetries 5
    errorStrategy {
        if (task.exitStatus >= 100 ){
            sleep(Math.pow(2, task.attempt) * 20 as long);
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
            filename.equals('versions.yml') ? null : "${params.outdir}/${method}/stage5_posebusted/${dataset_name}/${proj_id}/${filename}" }
        ]
    }




    input:
        tuple val(method),val(category), val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct), path(docked_pose),path(docked_pose_mf)


    output:
        tuple val(method),val(category),val(dataset_name), val(code), val(proj_id), path(protein_struct), path(ligand_struct),  path(docked_pose), path(docked_pose_mf), path("${docked_pose_mf.simpleName}.csv")


    script:
        def i_version=4
        """
        echo "Pose busting  v${i_version}"

        bust ${docked_pose_mf} -l ${ligand_struct} -p ${protein_struct} --outfmt csv >| ${docked_pose_mf.simpleName}_pre.csv


        # -- * Run python script to append extra info for absolute data
        python ${projectDir}/bin/posebust_update.py --input=${docked_pose_mf.simpleName}_pre.csv \
                                                    --dataset=${dataset_name} \
                                                    --prot=${protein_struct} \
                                                    --lig=${ligand_struct} \
                                                    --dock=${docked_pose_mf} \
                                                    --code=${code} \
                                                    --proj=${proj_id} \
                                                    --method=${method} \
                                                    --category=${category} \
                                                    --output=${docked_pose_mf.simpleName}.csv

        """
}

