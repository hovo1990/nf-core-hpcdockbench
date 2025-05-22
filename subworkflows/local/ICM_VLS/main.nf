//
// Subworkflow for ICM-VLS CPU
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


include { dockScanTask  } from '../../../modules/local/ICM_VLS/dockscan_task'

include { dockScanMakeHitList  } from '../../../modules/local/ICM_VLS/dockscan_makehitlist'


include { exportSDF } from '../../../modules/local/ICM_VLS/export_sdf'


include { matchingFraction} from '../../../modules/local/ICM_VLS/matching_fraction'


include { poseBust} from '../../../modules/local/ICM_VLS/pose_bust'





/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO PERFORM ICM-VLS benchmark on Astex and PoseBusters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ICM_VLS{

    take:
    icm_docking_projects //   array: List of positional nextflow CLI args

    main:
    // -- * Debug purposes
    test = Channel.from("Hello")

    // -- * Subworkflow 1: think about having a subworkflow for ICM-VLS CPU

    // -- * SStage 1: Perform dockscan
    dockScan_tasks = dockScanTask( icm_docking_projects)

    // // dockScan_tasks.view()

    // // -- * SStage 2: create hitlist
    // dockscan_hitlist = dockScanMakeHitList(dockScan_tasks)
    // // dockscan_hitlist.view()

    // // -- * SStage 3: extract hit list as sdf files
    // exported_sdf_files = exportSDF(dockscan_hitlist)
    // // exported_sdf_files.view()


    // all_comb =  exported_sdf_files.map{ pair ->
    //     [pair[0],pair[1],pair[2], pair[3],pair[4],pair[5],pair[6],pair[-1]]
    // }
    // // all_comb.view()
    // // all_comb_flat = all_comb.flatten()
    // // all_comb_flat.view()

    // // -- * groupTuple looks like the solution i am looking for
    // // channel.of(
    // //     ['chr1', ['/path/to/region1_chr1.vcf', '/path/to/region2_chr1.vcf']],
    // //     ['chr2', ['/path/to/region1_chr2.vcf', '/path/to/region2_chr2.vcf', '/path/to/region3_chr2.vcf']],
    // // )
    // // .flatMap { chr, vcfs ->
    // //     vcfs.collect { vcf ->
    // //         tuple(groupKey(chr, vcfs.size()), vcf)              // preserve group size with key
    // //     }
    // // }.view()

    // all_comb_flat = all_comb.flatMap{ method, category, dataset_name, code,proj_id, protein_struct,
    //                 ligand_struct, sdf_files ->
    //                 sdf_files.collect { sdf ->
    //                     tuple(method, category, dataset_name, code, groupKey(proj_id, sdf_files.size()), protein_struct, ligand_struct, sdf )
    //                     }
    //                 }
    // // all_comb_flat.view()





    // // -- * SStage 4: calculate RMSD and matching fraction
    // todo_debug_mf=  all_comb_flat.take(10)
    // todo_debug_mf.view()

    // matchingFraction_data = matchingFraction(todo_debug_mf)


    // -- * SStage 5: perform posebuster and compare with cocrystal structure

    // todo_debug_posebusted =  all_comb_flat.take(10)
    // todo_debug_posebusted.view()


    // todo_debug_posebusted =  all_comb_flat
    // pose_busted = poseBust(matchingFraction_data)




    // -- * SStage 6: collect all the csv files and start making plots
    // posebusted_files =      pose_busted.map { row -> row.join(',') }.collectFile { it.toString() + "\n" }  // Collect as a string with newline
    // posebusted_files.view()



    emit:
    // samplesheet = ch_samplesheet

    // -- * debug
    posebusted_files   = test
    // posebusted_files   = pose_busted
}

