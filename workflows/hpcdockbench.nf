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



include { dockScanTask  } from '../modules/local/dockscan_task'

include { dockScanMakeHitList  } from '../modules/local/dockscan_makehitlist'


include { exportSDF } from '../modules/local/export_sdf'

include { poseBust} from '../modules/local/pose_bust'


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
    tasks_todo_debug = tasks_todo.take(200)
    // tasks_todo_debug.view()


    // -- * Stage 5: Prepare docking projects
    // -- TODO fix mount problem issues
    icm_docking_projects = prepIcmProject(tasks_todo_debug)
    // icm_docking_projects.view()


    // -- * Subworkflow 1: think about having a subworkflow for ICM-VLS CPU

    // -- * SStage 1: Perform dockscan
    dockScan_tasks = dockScanTask( icm_docking_projects)

    // dockScan_tasks.view()

    // -- * SStage 2: create hitlist
    dockscan_hitlist = dockScanMakeHitList(dockScan_tasks)
    // dockscan_hitlist.view()

    // -- * SStage 3: extract hit list as sdf files
    exported_sdf_files = exportSDF(dockscan_hitlist)
    // exported_sdf_files.view()


    all_comb =  exported_sdf_files.map{ pair ->
        [pair[0],pair[1],pair[2], pair[3],pair[4],pair[-1]]
    }
    // all_comb.view()
    // all_comb_flat = all_comb.flatten()
    // all_comb_flat.view()

    // -- * groupTuple looks like the solution i am looking for
    // channel.of(
    //     ['chr1', ['/path/to/region1_chr1.vcf', '/path/to/region2_chr1.vcf']],
    //     ['chr2', ['/path/to/region1_chr2.vcf', '/path/to/region2_chr2.vcf', '/path/to/region3_chr2.vcf']],
    // )
    // .flatMap { chr, vcfs ->
    //     vcfs.collect { vcf ->
    //         tuple(groupKey(chr, vcfs.size()), vcf)              // preserve group size with key
    //     }
    // }.view()

    all_comb_flat = all_comb.flatMap{ dataset_name, code,proj_id, protein_struct,
                    ligand_struct, sdf_files ->
                    sdf_files.collect { sdf ->
                        tuple(dataset_name, code, groupKey(proj_id, sdf_files.size()), protein_struct, ligand_struct, sdf )
                        }
                    }
    // all_comb_flat.view()
    // -- * SStage 4: perform posebuster and compare with cocrystal structure
    pose_busted = poseBust(all_comb_flat)


    // -- * SStage 5: collect all the csv files and start making plots
    posebusted_files =      pose_busted .collectFile { it.toString() + "\n" }  // Collect as a string with newline
    posebusted_files.view()




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
