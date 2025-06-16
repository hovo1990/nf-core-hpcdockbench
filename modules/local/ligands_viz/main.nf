process ligandsViz {
    // errorStrategy 'ignore'
    // cache false
    // def date = LocalDate.now().toString().replace("-","_")

    tag "CPU-ligandViz"


    label 'low_cpu'

    // -- * For debug purposes comment it
    maxRetries 5
    errorStrategy {
        if (task.exitStatus >= 100){
            'retry'
        } else {
            'terminate'
        }
    }


    cache true




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

    if (params.save_intermediate) {
        publishDir "${params.outdir}/stage5_ligandViz", mode: 'copy', overwrite: true
    }



    input:
        path(csv_file)


    output:
        path("ligandViz.sdf")


    script:
    def i_version=4

        // -- * #template #example #conditional
        // -- * use this only for one case
        """
            ${params.icm_exec ?: "${params.icm_home}/icm64"} \
                ${projectDir}/bin/dockScan_prep_dock_project.icm \
                    -i=${csv_file} \
                    -o=ligandViz.sdf

        """


        // if (code=='8F4J_PHO'){
        //     """
        //         trap 'if [[ \$? == 251 ]]; then echo OK; exit 0; fi' EXIT
        //         cp  -r ${folder}/* .
        //         ${params.icm_exec ?: "${params.icm_home}/icm64"} \
        //             ${projectDir}/bin/icm_prep_dock_project.icm \
        //                 -icode=${code} \
        //                 -il=${code}_ligand.sdf  \
        //                 -rborn=yes \
        //                 -projID="p${code}"
        //     """
        // } else {
        //     """
        //         trap 'if [[ \$? == 251 ]]; then echo OK; exit 0; fi' EXIT
        //         cp  -r ${folder}/* .
        //         ${params.icm_exec ?: "${params.icm_home}/icm64"} \
        //             ${projectDir}/bin/dockScan_prep_dock_project.icm \
        //                 -i=${code}_protein.pdb \
        //                 -il=${code}_ligand.sdf  \
        //                 -rborn=yes \
        //                 -projID="p${code}"
        //     """
        // }


}


process prepIcmProject_Regular {
    // errorStrategy 'ignore'
    // cache false
    // def date = LocalDate.now().toString().replace("-","_")

    tag "CPU-PREP-ICM-Regular-p${code}"


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


    cache true




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

    if (params.save_intermediate) {
        publishDir "${params.outdir}/stage4_ICM_Projects_Regular", mode: 'copy', overwrite: true
    }



    input:
        tuple val(dataset_name), val(code), path(folder)


    output:
        tuple val(dataset_name), val(code), val("p${code}"), file("${code}_protein.pdb"), file("${code}_ligand.sdf"), file("p${code}_2D_ligand.sdf"), path("p${code}/*")


    script:
    def i_version=4
        """
            trap 'if [[ \$? == 251 ]]; then echo OK; exit 0; fi' EXIT
            cp  -r ${folder}/* .
            ${params.icm_exec ?: "${params.icm_home}/icm64"} \
                ${projectDir}/bin/dockScan_prep_dock_project.icm \
                    -i=${code}_protein.pdb \
                    -il=${code}_ligand.sdf  \
                    -rborn=no \
                    -projID="p${code}"
        """


        // -- * #template #example #conditional
        // -- * use this only for one case
        // if (code=='8F4J_PHO'){
        //     """
        //         trap 'if [[ \$? == 251 ]]; then echo OK; exit 0; fi' EXIT
        //         cp  -r ${folder}/* .
        //         ${params.icm_exec ?: "${params.icm_home}/icm64"} \
        //             ${projectDir}/bin/icm_prep_dock_project.icm \
        //                 -icode=${code} \
        //                 -il=${code}_ligand.sdf  \
        //                 -projID="p${code}"
        //     """
        // } else {
        //     """
        //         trap 'if [[ \$? == 251 ]]; then echo OK; exit 0; fi' EXIT
        //         cp  -r ${folder}/* .
        //         ${params.icm_exec ?: "${params.icm_home}/icm64"} \
        //             ${projectDir}/bin/dockScan_prep_dock_project.icm \
        //                 -i=${code}_protein.pdb \
        //                 -il=${code}_ligand.sdf  \
        //                 -projID="p${code}"
        //     """
        // }


}


