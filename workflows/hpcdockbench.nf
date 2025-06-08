/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

params.container_link = "docker.io/hgrabski/hpcdockbench:latest"
params.benchmark_dataset = "https://zenodo.org/records/8278563/files/posebusters_paper_data.zip"

include { paramsSummaryMap       } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_dockbench_pipeline'


// -- * Custom modules
include { downloadBenchmarkDataset} from '../modules/local/download_benchmark_dataset'


include { unzipDataset} from '../modules/local/unzip_dataset'


include { filterFolders} from '../modules/local/filter_folders'


include { prepIcmProject_RBORN } from '../modules/local/prep_icm_project'
include { prepIcmProject_Regular } from '../modules/local/prep_icm_project'



include { makePlot} from '../modules/local/make_plot'


include { collectAllData} from '../modules/local/collect_all_data'


// -- * SubWorkflow section
include { ICM_VLS as ICM_VLS_eff_5_conf_10_regular } from '../subworkflows/local/ICM_VLS'
include { ICM_VLS as ICM_VLS_eff_5_conf_10_rborn } from '../subworkflows/local/ICM_VLS'


include { ICM_RIDGE } from '../subworkflows/local/ICM_RIDGE'




/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow HPCDOCKBENCH {

    // take:
    // ch_samplesheet // channel: samplesheet read in from --input


    main:

    ch_versions = Channel.empty()

    // -- * Stage 1: Download Posebusters paper dataset https://zenodo.org/records/8278563/files/posebusters_paper_data.zip?download=1
    download_benchmark_dataset =  downloadBenchmarkDataset()

    // -- * Stage 2: Unzip the benchmark dataset
    unpacked_folders = unzipDataset(download_benchmark_dataset)
    // unpacked_folders.view()

    // -- * Stage 3: Separate folders into separate channels
    collectedFile =    unpacked_folders.map { row -> row.join('\n') }  // Convert tuple to CSV format
                .collectFile { it.toString() + "\n" }
    // collectedFile.view()


    // -- * Stage 4: Use python to filter astex and posebuster folders
    filtered_files = filterFolders(collectedFile)
    // filtered_files.view()

    filtered_flatten = filtered_files.flatten()
    // filtered_flatten.view()

    // -- * Subworkflow 0: think about having a subworkflow to prepare ICM compatible docking projects
    tasks_todo =  filtered_flatten | splitCsv(header:true) \
        | map { row-> tuple(row.SET, row.CODE, file(row.PATH)) }
    // tasks_todo.view()



    // -- * bigger debug sample
    // tasks_todo_debug = tasks_todo.take(20)

    tasks_todo_debug = tasks_todo
    // tasks_todo_debug.view()




    // -- * Stage 5: Prepare docking projects
    // -- TODO for debug purposes test out only 8F4J_PHO
    // -- * #template


    // tasks_todo_debug = tasks_todo_debug.filter { it[1]== '8F4J_PHO' }


    // -- ! #change exclude this example
    // -- * need to sort tasks_todo_debug

    tasks_todo_debug_rborn = tasks_todo_debug.filter { it[1] != '8F4J_PHO' }
    tasks_todo_debug_regular = tasks_todo_debug

    // tasks_todo_debug.view()

    icm_docking_projects_rborn = prepIcmProject_RBORN(tasks_todo_debug_rborn)
    icm_docking_projects_regular = prepIcmProject_Regular(tasks_todo_debug_regular)



    // // -- * Subworkflow 1: ICM VLS RUN, effort: 4.0, conf: 10 rborn enabled
    // method_name_1 = Channel.value("ICM_VLS_CPU_eff_5_conf_10_regular")
    // method_name_2 = Channel.value("ICM_VLS_CPU_eff_5_conf_10_rborn")
    // category_name = Channel.value("Classical")
    // icm_vls_posebusted_eff_5_conf_10_regular = ICM_VLS_eff_5_conf_10_regular(icm_docking_projects_regular,
    //                                             method_name_1, category_name)

    // icm_vls_posebusted_eff_5_conf_10_rborn= ICM_VLS_eff_5_conf_10_rborn(icm_docking_projects_rborn,
    //                                             method_name_2, category_name)



    // // icm_vls_posebusted.view()

    // // // -- * Subworkflow 2: ICM RIDGE RUN
    method_name_gpu_1 = Channel.value("ICM_RIDGE_GPU_regular")
    method_name_gpu_2 = Channel.value("ICM_RIDGE_GPU_rborn")
    category_name_gpu = Channel.value("Classical")

    icm_ridge_posebusted_regular = ICM_RIDGE(icm_docking_projects_regular,
                                                method_name_gpu_1, category_name_gpu)



    // // // -- TODO improve later so it can be toggled on or off
    // // // -- * Merge from multiple sources
    // merged_data =icm_vls_posebusted_eff_5_conf_10_regular.concat(icm_vls_posebusted_eff_5_conf_10_rborn)




    // merged_data_csv =     merged_data.map { row -> row.join(',') }.collectFile { it.toString() + "\n" }  // Collect as a string with newline

    // // // // merged_data =icm_vls_posebusted.concat(icm_ridge_posebusted)
    // // // // merged_data =icm_vls_posebusted.concat(icm_ridge_posebusted).concat(icm_ridge_rtcnn2_posebusted)
    // // // // merged_data.view()

    // // merged_data_csv =     merged_data.map { row -> row.join(',') }.collectFile { it.toString() + "\n" }  // Collect as a string with newline
    // // // merged_data_csv.view()

    // // // // // -- * Collect all data
    // collectedData = collectAllData(merged_data_csv)

    // // collectedData = collectAllData(icm_ridge_posebusted)


    // // // // -- * SStage 6: make plot test
    plots = makePlot( collectedData)


    // -- * Subworkflow 2: think about having a subworkflow for ICM-RIDGE GPU



    // -- * Subworkflow 3: make a plot for astex and posebuster benchmark set

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  +  'dockbench_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
