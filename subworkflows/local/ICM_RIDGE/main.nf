//
// Subworkflow for ICM-RIDGE GPU
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { gingerTask } from '../../../modules/local/ICM_RIDGE_GPU/ginger_task'




/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO PERFORM ICM-RIDGE benchmark on Astex and PoseBusters
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ICM_RIDGE{

    take:
    icm_docking_projects //   array: List of positional nextflow CLI args

    main:

    // icm_docking_projects.view()


    tasks_todo_debug =  icm_docking_projects.take(10)
    // tasks_todo_debug.view()

    test = Channel.from("Hello")
    // -- * Subworkflow 1: think about having a subworkflow for ICM-RIDGE GPU

    // -- * SStage 1: Perform ginger calculation (GPU)
    gingered_tasks =  gingerTask(tasks_todo_debug)

    // -- * SStage 2: Run Ridge calculation (GPU)


    // dockScan_tasks.view()


    emit:
    posebusted_files = test
    // samplesheet = ch_samplesheet
    // posebusted_files   = posebusted_files
}

