process prepIcmProject {
    // errorStrategy 'ignore'
    // cache false
    // def date = LocalDate.now().toString().replace("-","_")

    tag "prepare docking Project"


    label 'low_cpu'


    maxRetries 4
    errorStrategy {
        if (task.exitStatus >= 100){
            'retry'
        } else {
            'terminate'
        }
    }


    beforeScript 'hostname;echo "Wait random 5 secs"; sleep $((RANDOM % 5))'



    cache true

    maxForks 20
    publishDir "${params.output_folder}/stage4_docking_projects", mode: 'copy', overwrite: true
    // debug true

    input:
        tuple val(pocket_id), val(proj_id), path(icb_input)


    output:
        tuple val(pocket_id), val("p${proj_id}"), path("p${proj_id}/*")


    script:
    """
    trap 'if [[ \$? == 251 ]]; then echo OK; exit 0; fi' EXIT
    ${params.icm_exec ?: "${params.icmhome_default}/icm64"} \
        ${projectDir}/bin/dockScan_prep_dock_project.icm \
            -i=${pdb_input}  \
            -il=${ligand_input}  \
            -projID="p${code}"
    """
}