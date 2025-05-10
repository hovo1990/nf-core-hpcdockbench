process dockScanMakeHitList{

    label 'cpu_pretty_decent_mem'

    beforeScript 'hostname;echo "Wait random 25 secs"; sleep $((RANDOM % 25))'
    maxRetries 5
    errorStrategy {
        if (task.exitStatus >= 1){
            sleep(Math.pow(2, task.attempt) * 15 as long);
            'retry'
        } else {
            'terminate'
        }
    }


    cache true
    // debug true
    publishDir "${params.output_folder}/6_dockProc_novs/$proj_id/", mode: 'copy', overwrite: true


    input:
        tuple val(ligs), val(pocket_id), val(proj_id), path(proj_files), path(ob_file)


    output:
        tuple val(ligs), val(pocket_id), val(proj_id), path(proj_files), path(ob_file), file("proc_novs_${proj_id}_${ligs.simpleName}1.icb")


    script:
        def input_str = ligs instanceof List ? ligs.join(",") : ligs
        def i_version=9
        """
        #-- * Copy docking project to scratch generated folder
        hostname
        echo "Time to Process NO VS mode v${i_version}"


        #-- * this works
        #ls -l .
        ${params.icm_exec ?: "${params.icmhome_default}/icm64"} \
        ${projectDir}/bin/dockScan_proc_vs_stage1_novs_v2.icm \
                -pf="." \
                -pn=${proj_id} \
                -ob=${ob_file} \
                -o="proc_novs_${proj_id}_${ligs.simpleName}1.icb"

        """
}

