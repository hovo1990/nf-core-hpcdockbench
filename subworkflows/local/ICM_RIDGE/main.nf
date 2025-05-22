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

// -- * Matching Fraction calculation
include { matchingFraction} from '../../../modules/local/ICM_VLS/matching_fraction'

// -- * Pose buster
include { poseBust} from '../../../modules/local/ICM_VLS/pose_bust'

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
    // tasks_todo_debug =  lig_conformers.take(20)
    tasks_todo_debug =  lig_conformers


    // -- * Why does Ridge generate an empty sdf file? for what purpose come on
    ridge_tasks = ridgeTask_GPU(tasks_todo_debug)

    // // dockScan_tasks.view()

    // -- * SStage 3: Extract conformations and add the data to sdf file
        // -- * SStage 3: extract hit list as sdf files
    exported_sdf_files = exportRidgeSDF(ridge_tasks)

    all_comb =  exported_sdf_files.map{ pair ->
        [pair[0],pair[1],pair[2], pair[3],pair[4],pair[5],pair[6],pair[-1]]
    }

    all_comb_flat = all_comb.flatMap{ method, category, dataset_name, code,proj_id, protein_struct,
                    ligand_struct, sdf_files ->
                    sdf_files.collect { sdf ->
                        tuple(method, category, dataset_name, code, groupKey(proj_id, sdf_files.size()), protein_struct, ligand_struct, sdf )
                        }
                    }
    // all_comb_flat.view()

    // -- * SStage 4: perform RMSD, matching Fraction calculation
    // todo_debug_mf=  all_comb_flat.take(10)
    todo_debug_mf=  all_comb_flat

    matchingFraction_data_ridge = matchingFraction(todo_debug_mf)


    // -- * SStage 5: perform posebuster and compare with cocrystal structure
    // todo_debug_posebusted_ridge =  all_comb_flat.take(10)


    pose_busted = poseBust(matchingFraction_data_ridge )

    // // -- * SStage 6:  No need for it collect all the csv files and start making plots
    // posebusted_files_ridge =      pose_busted.map { row -> row.join(',') }.collectFile { it.toString() + "\n" }  // Collect as a string with newline
    // posebusted_files.view()


    emit:
    // posebusted_files   = test
    posebusted_files = pose_busted

}

