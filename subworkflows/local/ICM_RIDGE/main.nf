//
// Subworkflow for ICM-RIDGE GPU
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// -- * Conformer generation stage
include { confGenTask_CPU } from '../../../modules/local/ICM_RIDGE_GPU/conformerGen_task'
include { gingerTask_GPU  } from '../../../modules/local/ICM_RIDGE_GPU/conformerGen_task'


// -- * GPU docking
include { ridgeTask_GPU  } from '../../../modules/local/ICM_RIDGE_GPU/ridge_task'


// -- * Export ridge docking sdf for Posebusters
include { exportRidgeSDF } from '../../../modules/local/ICM_RIDGE_GPU/export_ridge_sdf'


include { exportMFSDF } from '../../../modules/local/ICM_VLS/export_mf_sdf'


include { poseBust} from '../../../modules/local/ICM_VLS/pose_bust'


include { poseBust_update} from '../../../modules/local/ICM_VLS/pose_bust_update'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO PERFORM ICM-RIDGE benchmark on Astex and PoseBusters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ICM_RIDGE{

    take:
    icm_docking_projects //   array: List of positional nextflow CLI args
    method // just a string with the name of the method
    category // category type


    main:

    // icm_docking_projects.view()


    tasks_todo_debug =  icm_docking_projects.take(10)
    // tasks_todo_debug.view()

    test = Channel.from("Hello")
    // -- * Subworkflow 1: think about having a subworkflow for ICM-RIDGE GPU

    // -- * SStage 1: Perform ginger calculation (GPU)


    lig_conformers = gingerTask_GPU(tasks_todo_debug, method, category)

    // -- * SStage 1-1: CPU generation of the conformers
    // lig_conformers = confGenTask_CPU( tasks_todo_debug)


    // -- * SStage 2: Run Ridge calculation (GPU)
    // tasks_todo_debug =  lig_conformers.take(20)
    tasks_todo_debug =  lig_conformers


    // // -- * Why does Ridge generate an empty sdf file? for what purpose come on
    // ridge_tasks = ridgeTask_GPU(tasks_todo_debug)

    // // // dockScan_tasks.view()

    // // -- * SStage 3 V2: extract hit list as sdf files
    // // todo_debug_export_sdf = dockscan_hitlist.take(20)
    // todo_debug_export_sdf = dockscan_hitlist

    // exported_sdf_files = exportMFSDF(todo_debug_export_sdf )
    // // exported_sdf_files.view()


    // all_comb =  exported_sdf_files.map{ pair ->
    //     [pair[0],pair[1],pair[2], pair[3],pair[4],pair[5],pair[6],pair[-1]]
    // }
    // // all_comb.view()


    // pose_busted = poseBust(all_comb)


    // // -- * SStage 4 V2: update posebust data with ICM data
    // poseBust_updated = poseBust_update(pose_busted)
    // poseBust_updated.view()


    emit:
    posebusted_files   = test
    // posebusted_files = poseBust_updated

}

