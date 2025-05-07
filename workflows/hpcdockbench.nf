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



    tasks_todo_debug = tasks_todo.take(10)
    // tasks_todo_debug.view()


    // -- * Stage 5: Prepare docking projects
    icm_docking_projects = prepIcmProject(tasks_todo_debug)
    // icm_docking_projects.view()


    // -- * Subworkflow 1: think about having a subworkflow for ICM-VLS CPU





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
