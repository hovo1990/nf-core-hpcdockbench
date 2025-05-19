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


    // tasks_todo_debug =  icm_docking_projects.take(10)
    // tasks_todo_debug.view()

    test = Channel.from("Hello")
    // -- * Subworkflow 1: think about having a subworkflow for ICM-RIDGE GPU

    // -- * SStage 1: Perform ginger calculation (GPU)


    // tasks_todo_debug_conf =  icm_docking_projects.take(50)
    // lig_conformers = gingerTask_GPU(tasks_todo_debug_conf)

    // -- * SStage 1-1: CPU generation of the conformers
    lig_conformers = confGenTask_CPU(icm_docking_projects)


    // -- * SStage 2: Run Ridge calculation (GPU)
    tasks_todo_debug =  lig_conformers.take(20)

    ridge_tasks = ridgeTask_GPU(tasks_todo_debug)

    // dockScan_tasks.view()

    // -- * SStage 3: Extract conformations and add the data to sdf file
        // -- * SStage 3: extract hit list as sdf files
    exported_sdf_files = exportRidgeSDF(ridge_tasks)

    emit:
    posebusted_files = test
    // samplesheet = ch_samplesheet
    // posebusted_files   = posebusted_files
}

