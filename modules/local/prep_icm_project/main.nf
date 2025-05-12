process prepIcmProject {
    // errorStrategy 'ignore'
    // cache false
    // def date = LocalDate.now().toString().replace("-","_")

    tag "prepare docking Project"


    label 'low_cpu_debug'

    // -- * For debug purposes comment it
    maxRetries 5
    errorStrategy {
        if (task.exitStatus >= 100){
            'retry'
        } else {
            'terminate'
        }
    }


    beforeScript 'hostname;echo "Wait random 15 secs"; sleep $((RANDOM % 15))'



    cache true

    if (params.save_intermediate) {
        publishDir "${params.outdir}/stage4_docking_projects/${code}/", mode: 'copy', overwrite: true
    }

    // publishDir { params.save_intermediate? "${params.outdir}/stage4_docking_projects/${code}/" : null }, mode: 'copy', overwrite: true


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




    input:
        tuple val(dataset_name), val(code), path(folder)


    output:
        tuple val(dataset_name), val(code), val("p${code}"), file("${code}_protein.pdb"), file("${code}_ligand.sdf"), file("p${code}_2D_ligand.sdf"), path("p${code}/*")


    script:
    """
    trap 'if [[ \$? == 251 ]]; then echo OK; exit 0; fi' EXIT
    cp  -r ${folder}/* .
    ${params.icm_exec ?: "${params.icm_home}/icm64"} \
        ${projectDir}/bin/dockScan_prep_dock_project.icm \
            -i=${code}_protein.pdb \
            -il=${code}_ligand.sdf  \
            -projID="p${code}"
    """
}