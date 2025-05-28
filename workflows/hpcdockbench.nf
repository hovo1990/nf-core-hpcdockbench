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


include { prepIcmProject } from '../modules/local/prep_icm_project'



include { makePlot} from '../modules/local/make_plot'


include { collectAllData} from '../modules/local/collect_all_data'


// -- * SubWorkflow section
include { ICM_VLS } from '../subworkflows/local/ICM_VLS'

include { ICM_RIDGE } from '../subworkflows/local/ICM_RIDGE'


include { ICM_RIDGE_RTCNN2 } from '../subworkflows/local/ICM_RIDGE_RTCNN2'

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



    // tasks_todo_debug = tasks_todo.take(10)

    // -- * bigger debug sample
    // tasks_todo_debug = tasks_todo.take(200)
    tasks_todo_debug = tasks_todo
    // tasks_todo_debug.view()




    // -- * Stage 5: Prepare docking projects
    // -- TODO fix mount problem issues
    icm_docking_projects = prepIcmProject(tasks_todo_debug)
    // icm_docking_projects.view()


    // // -- * Subworkflow 1: ICM VLS RUN
    icm_vls_posebusted = ICM_VLS(icm_docking_projects)
    // // icm_vls_posebusted.view()

    // // // -- * Subworkflow 2: ICM RIDGE RUN
    // icm_ridge_posebusted = ICM_RIDGE(icm_docking_projects)

    // // // -- * Subworkflow 3: ICM RIDGE RUN RTCNN2 missing Error> [9532] can not open '/pro/icm/icms/nnInterMod2.inm' for reading
    // icm_ridge_rtcnn2_posebusted = ICM_RIDGE_RTCNN2(icm_docking_projects)



    // // -- TODO improve later so it can be toggled on or off
    // // -- * Merge from multiple sources
    // merged_data =icm_vls_posebusted

    // // merged_data =icm_vls_posebusted.concat(icm_ridge_posebusted)
    // // merged_data =icm_vls_posebusted.concat(icm_ridge_posebusted).concat(icm_ridge_rtcnn2_posebusted)
    // // merged_data.view()

    // merged_data_csv =     merged_data.map { row -> row.join(',') }.collectFile { it.toString() + "\n" }  // Collect as a string with newline
    // // merged_data_csv.view()

    // // // // -- * Collect all data
    // collectedData = collectAllData(merged_data_csv)

    // // collectedData = collectAllData(icm_ridge_posebusted)


    // // // // -- * SStage 6: make plot test
    // plots = makePlot( collectedData)


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
