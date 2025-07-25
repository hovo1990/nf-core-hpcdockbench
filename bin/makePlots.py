"""
Author: Hovakim Grabski
Purpose: Make plots based on posebuster data
Date: 05-07-2025


"""

import hashlib
import math
import os
import pathlib
import shutil
import sys
import time
import traceback
from itertools import combinations
from pathlib import Path

import click
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from loguru import logger
from matplotlib.lines import Line2D  # For legend titles
from matplotlib.patches import Patch
from tqdm.auto import tqdm
from tqdm.contrib import tzip


def logger_wraps(*, entry=True, exit=True, level="DEBUG"):
    def wrapper(func):
        name = func.__name__

        @functools.wraps(func)
        def wrapped(*args, **kwargs):
            logger_ = logger.opt(depth=1)
            if entry:
                logger_.log(
                    level, "Entering '{}' (args={}, kwargs={})", name, args, kwargs
                )
            result = func(*args, **kwargs)
            if exit:
                logger_.log(level, "Exiting '{}' (result={})", name, result)
            return result

        return wrapped

    return wrapper


def timeit(func):
    def wrapped(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        logger.debug("Function '{}' executed in {:f} s", func.__name__, end - start)
        return result

    return wrapped


def validate_csv(ctx, param, value):
    logger.info(" Info> validate_csv is ", value)
    if not value.lower().endswith(".csv"):
        raise click.BadParameter("File must have a .csv extension")
    return value



def one_based_range(n):
    return list(range(1, n + 1))

def posebusted_results_custom_rank(df, rank=3, rank_type ='RANK_corrScoreAverage'):
    logger.debug(" {}".format(df.columns))

    # logger.debug(" {}".format(df))

    unique_methods = df["_METHOD_"].unique()
    unique_categories = df["_CATEGORY_"].unique()
    unique_datasets = df["_DATASET_"].unique()
    logger.debug(" Debug> unique datasets {}".format(unique_datasets))

    name_dict = {
        "astex_diverse_set": "Astex",
        "posebusters_benchmark_set": "PoseBusters",
    }

    # Set color palette
    palette = {"Astex": "#76c7c0", "PoseBusters": "#f97b72"}  # teal  # coral

    temp_data_astex = [0,0]
    temp_data_posebuster = [0,0]

    # method = df["_METHOD_"][0]
    # category = df["_CATEGORY_"][0]
    final_list = []

    if rank_type == 'RANK_corrScoreAverage':
        rank_name= 'CorrAvScore'
    elif rank_type=='RANK_RTCNN_Ridge':
        rank_name='RTCNN Ridge'
    elif rank_type == 'RANK_Score':
        rank_name='Score'
    elif rank_type=='RANK_RTCNNscore':
        rank_name='RTCNN'
    else:
        rank_name = rank_type


    for method in tqdm(unique_methods):

        curr_method = df[df["_METHOD_"] == method]
        category = curr_method["_CATEGORY_"].values.tolist()[0]
        logger.debug(" DEBUG>  method {}".format(method))




        if method == "ICM-VLS":
            realname = "ICM-VLS (CPU)"
        elif method == "ICM-RIDGE":
            realname = "ICM-RIDGE (GPU)"
        elif method == "ICM-RIDGE-RTCNN2":
            realname = "ICM-RIDGE-RTCNN2 (GPU)"
        elif method == 'ICM_VLS_CPU_eff_5_conf_10_rborn':
            realname = 'ICM-VLS(CPU)\nRBorn\nRank: {}'.format(rank_name)
        elif method == 'ICM_VLS_CPU_eff_5_conf_10_regular':
            realname = 'ICM-VLS(CPU)\nRank: {}'.format(rank_name)
        elif method == 'ICM_RIDGE_GPU_regular':
            realname = 'ICM-Ridge(GPU)\nRank: {}'.format(rank_name)
        elif method == 'ICM_RIDGE_GPU_rborn':
            realname = 'ICM-Ridge(GPU)\nRBorn\nRank: {}'.format(rank_name)
        elif method == 'ICM_RIDGE_GPU_confGen_regular':
            realname = 'ICM-Ridge(GPU)\nconfGen\nRank: {}'.format(rank_name)
        elif method == 'ICM_RIDGE_GPU_confGen_rborn':
            realname = 'ICM-Ridge(GPU)\nconfGen+RBorn\nRank: {}'.format(rank_name)
        else:
            realname = method

        for dataset in tqdm(unique_datasets):
            logger.debug("---" * 20)
            curr_dataset = curr_method[curr_method["_DATASET_"] == dataset]
            logger.debug(" DEBUG> dataset {}, method {}".format(dataset, method))
            logger.debug(" DEBUG> curr_dataset df is {}".format(curr_dataset))

            logger.debug( " Debug> rank_type {} and rank {}".format(rank_type,rank))



    #         logger.debug(" Debug> Curr method is {}".format(method))

    #         logger.debug(" Debug> Curr category  is {}".format(category))

            # -- * don't keep those that have a -100
            curr_dataset_temp = curr_dataset[curr_dataset[rank_type]>-100]
            if len(curr_dataset_temp) < 1:
                continue

            logger.debug( " Debug curr_dataset_temp > {}".format(curr_dataset_temp))

            top_rank_custom = curr_dataset_temp [curr_dataset_temp[rank_type].isin(one_based_range(rank))]
            top_rank_custom.sort_values(by=["_CODE_", rank_type], inplace=True)
            # logger.debug(
            #     " Debug> {}".format(
            #         top_rank_custom [
            #             ["_METHOD_", "_DATASET_", "_CODE_", rank_type, "ICM_less_than_two"]
            #         ]
            #     )
            # )

            result = top_rank_custom[top_rank_custom["ICM_less_than_two"]].drop_duplicates(
                subset="_CODE_", keep="first"
            )
            logger.debug(" Debug less than two> {}".format(result))

            # logger.debug(
            #     " Debug> icm less than two {}".format(
            #         result[["_METHOD_", "_DATASET_", "_CODE_", rank_type, "ICM_less_than_two"]]
            #     )
            # )

    #         #         # -- * Make plot how many are rmsd_≤_2å

            # Count the number of True and False values
            count_data = result["ICM_less_than_two"].value_counts().reset_index()
            count_data.columns = ["ICM_less_than_two", "count"]
            logger.debug(" Debug count_data> {}".format(count_data))

            # Check if all values in the specified columns are True for each row
            columns_of_interest = [
                "mol_true_loaded",
                "mol_cond_loaded",
                "sanitization",
                "inchi_convertible",
                "all_atoms_connected",
                "molecular_formula",
                "molecular_bonds",
                "double_bond_stereochemistry",
                "tetrahedral_chirality",
                "bond_lengths",
                "bond_angles",
                "internal_steric_clash",
                "aromatic_ring_flatness",
                "non-aromatic_ring_non-flatness",
                "double_bond_flatness",
                "internal_energy",
                "protein-ligand_maximum_distance",
                "minimum_distance_to_protein",
                "minimum_distance_to_organic_cofactors",
                "minimum_distance_to_inorganic_cofactors",
                "minimum_distance_to_waters",
                "volume_overlap_with_protein",
                "volume_overlap_with_organic_cofactors",
                "volume_overlap_with_inorganic_cofactors",
                "volume_overlap_with_waters",
                "ICM_less_than_two",
            ]
            result["all_true"] = result[columns_of_interest].all(axis=1)

            # -- * Count True or False values in the 'all_true' column
            value_counts = result["all_true"].value_counts().reset_index()
            value_counts.columns = ["rmsd_≤_2å_PB_VALID", "count"]

            # # -- * Add a percentage column
            unique_projects = curr_dataset["_CODE_"].unique()


            logger.debug(" Debug> unique projects len {}".format(len(unique_projects) ))

            # -- * this is hard coded not a great idea, but keep for now
            if dataset == "astex_diverse_set":
                total = 85
                total_PB = 85
            elif dataset == "posebusters_benchmark_set":
                total = 308
                total_PB = 308

    #         # total =  len(unique_projects) # 85 # astex len is 85 len(unique_projects)
    #         # total_PB =  len(unique_projects) #308 # len(unique_projects)

            tot_perc = (count_data["count"] / total) * 100
            tot_perc_PB = (value_counts["count"] / total_PB) * 100
            logger.debug(" Debug> tot_perc is {}".format(tot_perc))
            logger.debug(" Debug> tot_perc_PB is {}".format(tot_perc_PB))
            count_data["percentage"] = tot_perc
            count_data["PB_percentage"] = tot_perc_PB
            tot_perc_vals = tot_perc.values[0]
            tot_perc_PB_vals = tot_perc_PB.values[0]

            logger.debug(f" Debug> RMSD: {tot_perc_vals} PB: {tot_perc_PB_vals}")

            # logger.debug(" Debug> {}".format(count_data))


            if dataset == "astex_diverse_set":
                temp_data_astex = [tot_perc_vals.item(), tot_perc_PB_vals.item()]
            elif dataset == "posebusters_benchmark_set":
                temp_data_posebuster = [tot_perc_vals.item(), tot_perc_PB_vals.item()]


        final_list.append([realname, category] +  temp_data_astex + temp_data_posebuster)
        logger.debug(final_list)
        logger.debug(" ========== " * 10)

    final_df = pd.DataFrame(final_list)
    final_df.columns = [
        "Method",
        "Category",
        "Astex_RMSD_le_2A",
        "Astex_RMSD_le_2A_PB_Valid",
        "PoseBusters_RMSD_le_2A",
        "PoseBusters_RMSD_le_2A_PB_Valid",
    ]
    logger.debug(final_df)

    # Columns to check
    cols_to_check = [ "Astex_RMSD_le_2A",
        "Astex_RMSD_le_2A_PB_Valid",
        "PoseBusters_RMSD_le_2A",
        "PoseBusters_RMSD_le_2A_PB_Valid",]

    # Select rows where all of the specified columns are not 0
    filtered_df = final_df[(final_df[cols_to_check] != 0).all(axis=1)]



    if len(filtered_df ) < 1:
        logger.warning(" Error> The table is empty, that is not good")
        exit(1)

    return filtered_df


def make_rank1_plot(df, bar_width=0.2,
                    output = "output_Benchmark.svg",
                    outputpdf = "output_Benchmark.pdf"):
    # -- * To make text editable
    # Optional: specify a font that Inkscape can recognize (e.g., Arial, Times New Roman)
    plt.rcParams.update(
        {
            "svg.fonttype": "none",  # <- Ensures text is stored as <text> elements
            "text.usetex": False,  # <- Avoids LaTeX rendering (which embeds text as paths)
            "font.family": "sans-serif",  # or "serif", "Arial", etc.
        }
    )

    # --- Configuration ---

    teal_color = "#80CBC4"  # A light teal
    coral_color = "#FFAB91"  # A light coral

    if df.empty:
        print("Error: The dataframe is empty.")
        exit(1)

    # Extract data from DataFrame
    methods = df["Method"].tolist()
    astex_rmsd_le_2A = df["Astex_RMSD_le_2A"].tolist()
    astex_rmsd_le_2A_pb_valid = df["Astex_RMSD_le_2A_PB_Valid"].tolist()
    posebusters_rmsd_le_2A = df["PoseBusters_RMSD_le_2A"].tolist()
    posebusters_rmsd_le_2A_pb_valid = df["PoseBusters_RMSD_le_2A_PB_Valid"].tolist()
    categories_series = df["Category"]

    # Determine category definitions (start and end indices for each category)
    # Assumes methods are grouped by category in the CSV
    category_definitions = {}
    if not categories_series.empty:
        current_category = None
        start_idx = 0
        for i, category_name in enumerate(categories_series):
            logger.debug(" Debug> i is {} and category is {}".format(i, category_name))
            if current_category != category_name:
                if current_category is not None:
                    category_definitions[current_category] = (start_idx, i - 1)
                current_category = category_name
                start_idx = i
        # -- * Add the last category
        if current_category is not None:
            category_definitions[current_category] = (
                start_idx,
                len(categories_series) - 1,
            )

    logger.debug(" Debug> category def is {}".format(category_definitions))

    # --- Setup for Plotting (derived from loaded data) ---
    N = len(methods)
    x = np.arange(N)  # the label locations


    # Dynamic figsize calculation
    scale_factor = 10  # Tweak this if needed
    fig_width = max(N * bar_width * scale_factor, 20)  # Minimum width of 6 inches
    fig_height = 10
    fig, ax = plt.subplots(figsize=(fig_width, fig_height))

    # --- Plotting Bars ---
    # Astex bars
    bars1 = ax.bar(
        x - 1.5 * bar_width,
        astex_rmsd_le_2A,
        bar_width,
        label="Astex RMSD $\le 2\mathring{A}$",
        color="white",  # White box
        hatch="////",  # Hatch pattern
        edgecolor=teal_color,  # Teal-colored hatch lines
    )
    bars2 = ax.bar(
        x - 0.5 * bar_width,
        astex_rmsd_le_2A_pb_valid,
        bar_width,
        label="Astex RMSD $\le 2\mathring{A}$ & PB-Valid",
        color=teal_color,
        edgecolor="grey",
    )

    # PoseBusters bars
    bars3 = ax.bar(
        x + 0.5 * bar_width,
        posebusters_rmsd_le_2A,
        bar_width,
        label="PoseBusters RMSD $\le 2\mathring{A}$",
        color="white",  # White box
        hatch="////",  # Hatch pattern
        edgecolor=coral_color,  # Teal-colored hatch lines
    )
    bars4 = ax.bar(
        x + 1.5 * bar_width,
        posebusters_rmsd_le_2A_pb_valid,
        bar_width,
        label="PoseBusters RMSD $\le 2\mathring{A}$ & PB-Valid",
        color=coral_color,
        edgecolor="grey",
    )

    # --- Adding Percentage Labels on Bars ---
    def add_bar_labels(bars_list):
        for bars_group in bars_list:
            for bar_item in bars_group:  # bar_item is the actual bar object
                height = bar_item.get_height()
                if height > 0.0:
                    # Ensure height is a number before formatting
                    if isinstance(height, (int, float)) and not np.isnan(height):
                        ax.annotate(
                            f"{height:.1f}%",
                            xy=(bar_item.get_x() + bar_item.get_width() / 2, height),
                            xytext=(0, 3),  # 3 points vertical offset
                            textcoords="offset points",
                            ha="center",
                            va="bottom",
                            fontsize=6,
                        )

    add_bar_labels([bars1, bars2, bars3, bars4])

    # --- Axis Labels and Ticks ---
    ax.set_ylabel("Percentage of predictions", fontsize=12)
    ax.set_xticks(x)
    ax.set_xticklabels(
        methods, rotation=0, ha="center", fontsize=10
    )  # Adjust rotation if needed
    ax.set_ylim(0, 100)
    ax.set_yticks(np.arange(0, 101, 20))
    ax.set_yticklabels([f"{val}%" for val in np.arange(0, 101, 20)], fontsize=10)

    # --- Grid and Spines ---
    ax.yaxis.grid(True, linestyle="--", which="major", color="grey", alpha=0.3)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_linewidth(0.5)
    ax.spines["bottom"].set_linewidth(0.5)
    ax.tick_params(axis="both", which="major", labelsize=10)

    # --- Custom Legend (to match the image style) ---
    legend_handles_list = [
        Patch(
            facecolor="white",
            edgecolor=teal_color,
            hatch="////",
            label=r"Astex Diverse set (85) RMSD $\leq 2\mathring{A}$",
        ),
        Patch(
            facecolor=teal_color,
            edgecolor="grey",
            label=r"Astex Diverse set (85) RMSD $\leq 2\mathring{A}$ & PB-Valid",
        ),
        Patch(
            facecolor="white",
            edgecolor=coral_color,
            hatch="////",
            label=r"PoseBusters Benchmark set (308) RMSD $\leq 2\mathring{A}$",
        ),
        Patch(
            facecolor=coral_color,
            edgecolor="grey",
            label=r"PoseBusters Benchmark set (308) RMSD $\leq 2\mathring{A}$ & PB-Valid",
        ),
    ]

    ordered_handles = [
        legend_handles_list[0],
        legend_handles_list[1],  # RMSD <= 2A
        legend_handles_list[2],
        legend_handles_list[3],  # RMSD <= 2A & PB-Valid
    ]

    leg = ax.legend(
        handles=ordered_handles,
        ncol=2,
        loc="upper right",
        handlelength=2,
        handletextpad=0.8,
        labelspacing=0.7,
        columnspacing=2.5,
        fontsize=9,
        frameon=True,
        edgecolor="lightgrey",
    )

    for i, text in enumerate(leg.get_texts()):
        if (
            text.get_text() == "Astex Diverse set"
            or text.get_text() == "PoseBusters Benchmark set"
        ):
            text.set_fontweight("bold")

    # --- Adding Category X-axis Labels ---
    plt.subplots_adjust(bottom=0.15)  # Make space for category labels

    y_pos_text = -0.12 * (
        ax.get_ylim()[1] - ax.get_ylim()[0]
    )  # Adjusted for potential negative min y_lim if not 0
    y_pos_line = y_pos_text - (0.05 * (ax.get_ylim()[1] - ax.get_ylim()[0]))

    for cat_name, (start_idx, end_idx) in category_definitions.items():
        if start_idx > end_idx:  # Should not happen if CSV is structured correctly
            print(
                f"Warning: Category '{cat_name}' has invalid indices ({start_idx}, {end_idx}). Skipping."
            )
            continue
        cat_x_start = x[start_idx] - 1.5 * bar_width - bar_width / 2
        cat_x_end = x[end_idx] + 1.5 * bar_width + bar_width / 2

        center_x = (cat_x_start + cat_x_end) / 2
        ax.text(
            center_x,
            y_pos_text,
            cat_name,
            ha="center",
            va="bottom",
            fontsize=11,
            clip_on=False,
        )
        ax.plot(
            [cat_x_start, cat_x_end],
            [y_pos_line, y_pos_line],
            color="dimgray",
            linestyle="-",
            linewidth=1,
            clip_on=False,
        )

    # --- Final Touches ---
    plt.title(
        "Performance Benchmark", fontsize=14, pad=20
    )  # Optional: Add a main title
    fig.tight_layout(rect=[0, 0.05, 1, 1])


    plt.savefig(output)

    plt.savefig(outputpdf)


def make_custom_rank_plot(df, rank=3):
    # -- * To make text editable
    # Optional: specify a font that Inkscape can recognize (e.g., Arial, Times New Roman)
    plt.rcParams.update(
        {
            "svg.fonttype": "none",  # <- Ensures text is stored as <text> elements
            "text.usetex": False,  # <- Avoids LaTeX rendering (which embeds text as paths)
            "font.family": "sans-serif",  # or "serif", "Arial", etc.
        }
    )

    # --- Configuration ---

    teal_color = "#80CBC4"  # A light teal
    coral_color = "#FFAB91"  # A light coral

    if df.empty:
        print("Error: The dataframe is empty.")
        exit(1)

    # Extract data from DataFrame
    methods = df["Method"].tolist()
    astex_rmsd_le_2A = df["Astex_RMSD_le_2A"].tolist()
    astex_rmsd_le_2A_pb_valid = df["Astex_RMSD_le_2A_PB_Valid"].tolist()
    posebusters_rmsd_le_2A = df["PoseBusters_RMSD_le_2A"].tolist()
    posebusters_rmsd_le_2A_pb_valid = df["PoseBusters_RMSD_le_2A_PB_Valid"].tolist()
    categories_series = df["Category"]

    # Determine category definitions (start and end indices for each category)
    # Assumes methods are grouped by category in the CSV
    category_definitions = {}
    if not categories_series.empty:
        current_category = None
        start_idx = 0
        for i, category_name in enumerate(categories_series):
            logger.debug(" Debug> i is {} and category is {}".format(i, category_name))
            if current_category != category_name:
                if current_category is not None:
                    category_definitions[current_category] = (start_idx, i - 1)
                current_category = category_name
                start_idx = i
        # -- * Add the last category
        if current_category is not None:
            category_definitions[current_category] = (
                start_idx,
                len(categories_series) - 1,
            )

    logger.debug(" Debug> category def is {}".format(category_definitions))

    # --- Setup for Plotting (derived from loaded data) ---
    N = len(methods)
    x = np.arange(N)  # the label locations
    bar_width = 0.15  # the width of the bars

    fig, ax = plt.subplots(figsize=(40, 8))  # Adjust figure size as needed

    # --- Plotting Bars ---
    # Astex bars
    bars1 = ax.bar(
        x - 1.5 * bar_width,
        astex_rmsd_le_2A,
        bar_width,
        label="Astex RMSD $\le 2\mathring{A}$",
        color="white",  # White box
        hatch="////",  # Hatch pattern
        edgecolor=teal_color,  # Teal-colored hatch lines
    )
    bars2 = ax.bar(
        x - 0.5 * bar_width,
        astex_rmsd_le_2A_pb_valid,
        bar_width,
        label="Astex RMSD $\le 2\mathring{A}$ & PB-Valid",
        color=teal_color,
        edgecolor="grey",
    )

    # PoseBusters bars
    bars3 = ax.bar(
        x + 0.5 * bar_width,
        posebusters_rmsd_le_2A,
        bar_width,
        label="PoseBusters RMSD $\le 2\mathring{A}$",
        color="white",  # White box
        hatch="////",  # Hatch pattern
        edgecolor=coral_color,  # Teal-colored hatch lines
    )
    bars4 = ax.bar(
        x + 1.5 * bar_width,
        posebusters_rmsd_le_2A_pb_valid,
        bar_width,
        label="PoseBusters RMSD $\le 2\mathring{A}$ & PB-Valid",
        color=coral_color,
        edgecolor="grey",
    )

    # --- Adding Percentage Labels on Bars ---
    def add_bar_labels(bars_list):
        for bars_group in bars_list:
            for bar_item in bars_group:  # bar_item is the actual bar object
                height = bar_item.get_height()
                if height > 0.0:
                    # Ensure height is a number before formatting
                    if isinstance(height, (int, float)) and not np.isnan(height):
                        ax.annotate(
                            f"{height:.1f}%",
                            xy=(bar_item.get_x() + bar_item.get_width() / 2, height),
                            xytext=(0, 3),  # 3 points vertical offset
                            textcoords="offset points",
                            ha="center",
                            va="bottom",
                            fontsize=6,
                        )

    add_bar_labels([bars1, bars2, bars3, bars4])

    # --- Axis Labels and Ticks ---
    ax.set_ylabel("Percentage of predictions", fontsize=12)
    ax.set_xticks(x)
    ax.set_xticklabels(
        methods, rotation=0, ha="center", fontsize=10
    )  # Adjust rotation if needed
    ax.set_ylim(0, 100)
    ax.set_yticks(np.arange(0, 101, 20))
    ax.set_yticklabels([f"{val}%" for val in np.arange(0, 101, 20)], fontsize=10)

    # --- Grid and Spines ---
    ax.yaxis.grid(True, linestyle="--", which="major", color="grey", alpha=0.3)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_linewidth(0.5)
    ax.spines["bottom"].set_linewidth(0.5)
    ax.tick_params(axis="both", which="major", labelsize=10)

    # --- Custom Legend (to match the image style) ---
    legend_handles_list = [
        Patch(
            facecolor="white",
            edgecolor=teal_color,
            hatch="////",
            label=r"Astex Diverse set (85) RMSD $\leq 2\mathring{A}$",
        ),
        Patch(
            facecolor=teal_color,
            edgecolor="grey",
            label=r"Astex Diverse set (85) RMSD $\leq 2\mathring{A}$ & PB-Valid",
        ),
        Patch(
            facecolor="white",
            edgecolor=coral_color,
            hatch="////",
            label=r"PoseBusters Benchmark set (308) RMSD $\leq 2\mathring{A}$",
        ),
        Patch(
            facecolor=coral_color,
            edgecolor="grey",
            label=r"PoseBusters Benchmark set (308) RMSD $\leq 2\mathring{A}$ & PB-Valid",
        ),
    ]

    ordered_handles = [
        legend_handles_list[0],
        legend_handles_list[1],  # RMSD <= 2A
        legend_handles_list[2],
        legend_handles_list[3],  # RMSD <= 2A & PB-Valid
    ]

    leg = ax.legend(
        handles=ordered_handles,
        ncol=2,
        loc="upper left",
        # bbox_to_anchor=(1.01, 1),
        handlelength=2,
        handletextpad=0.8,
        labelspacing=0.7,
        columnspacing=2.5,
        fontsize=9,
        frameon=True,
        edgecolor="lightgrey",
    )

    for i, text in enumerate(leg.get_texts()):
        if (
            text.get_text() == "Astex Diverse set"
            or text.get_text() == "PoseBusters Benchmark set"
        ):
            text.set_fontweight("bold")

    # --- Adding Category X-axis Labels ---
    plt.subplots_adjust(bottom=0.15)  # Make space for category labels

    y_pos_text = -0.12 * (
        ax.get_ylim()[1] - ax.get_ylim()[0]
    )  # Adjusted for potential negative min y_lim if not 0
    y_pos_line = y_pos_text - (0.05 * (ax.get_ylim()[1] - ax.get_ylim()[0]))

    for cat_name, (start_idx, end_idx) in category_definitions.items():
        if start_idx > end_idx:  # Should not happen if CSV is structured correctly
            print(
                f"Warning: Category '{cat_name}' has invalid indices ({start_idx}, {end_idx}). Skipping."
            )
            continue
        cat_x_start = x[start_idx] - 1.5 * bar_width - bar_width / 2
        cat_x_end = x[end_idx] + 1.5 * bar_width + bar_width / 2

        center_x = (cat_x_start + cat_x_end) / 2
        ax.text(
            center_x,
            y_pos_text,
            cat_name,
            ha="center",
            va="bottom",
            fontsize=11,
            clip_on=False,
        )
        ax.plot(
            [cat_x_start, cat_x_end],
            [y_pos_line, y_pos_line],
            color="dimgray",
            linestyle="-",
            linewidth=1,
            clip_on=False,
        )

    # --- Final Touches ---
    plt.title(
        "Performance Benchmark for Rank {}".format(rank), fontsize=14, pad=20
    )  # Optional: Add a main title
    fig.tight_layout(rect=[0, 0.05, 1, 1])
    # fig.tight_layout()

    output = "output_Benchmark_rank_{}.svg".format(rank)
    outputpdf = "output_Benchmark_rank_{}.pdf".format(rank)

    plt.savefig(output)

    plt.savefig(outputpdf)


def icm_rmsd(posebusted_data):
    less_than_two = posebusted_data['ICM_RMSD_IN_PLACE_'] <= 2.0
    logger.debug(less_than_two)

    posebusted_data['ICM_less_than_two'] = less_than_two
    return posebusted_data


@click.command()
@click.option(
    "--input",
    help="csv input of the posebusted results",
    type=click.Path(exists=True),
    required=True,
    callback=validate_csv,
)
@click.option(
    "--paperdata",
    help="csv input from the posebusters paper data",
    type=click.Path(exists=True),
    callback=validate_csv,
)
def start_program(input, paperdata):
    test = 1

    logger.info(" Info>  input {}".format(input))
    # exit(1)

    try:
        df_posebusted = pd.read_csv(input)

        # logger.debug(" Debug> {}".format(df_posebusted))




        # -- * In some cases posebuster library gives if rmsd 0.4 it gives false, when it should be true
        # -- * in other cases when ICM rmsd is 2.1, it gives that RMSD is less than 2
        # -- TODO fix it here in this script
        df_posebusted_rmsd_fix = icm_rmsd(df_posebusted)
        # logger.debug(" Debug> {}".format(df_posebusted_rmsd_fix ))



        # # -- * Top rank 1 calculations
        # df = posebusted_results_rank1(df_posebusted)
        # logger.debug(df)
        # exit(1)

        # -- * for debug > /mnt/nfsa/users/hovakim/a/Projects/hpc_dock_bench/work/6c/91679886b7a9765a44ca1f43746aca

        df_Score = posebusted_results_custom_rank(df_posebusted_rmsd_fix , rank=1 ,rank_type = 'RANK_Score')
        df_RTCNNscore = posebusted_results_custom_rank(df_posebusted_rmsd_fix , rank=1 ,rank_type = 'RANK_RTCNNscore')
        df_corrScoreAverage= posebusted_results_custom_rank(df_posebusted_rmsd_fix , rank=1 ,rank_type = 'RANK_corrScoreAverage')


        df_ridgeRTCNN= posebusted_results_custom_rank(df_posebusted_rmsd_fix , rank=1 ,rank_type = 'RANK_RTCNN_Ridge')
        logger.debug(" Debug df> {}".format(df_ridgeRTCNN))


        df = pd.concat([df_Score,df_RTCNNscore,df_corrScoreAverage, df_ridgeRTCNN])
        logger.debug( " Debug> df is {}".format(df))

        logger.debug (" Debug> writing debug table")
        df.to_csv("test_debug_table.csv", index=False)


        # -- * Load Data from CSV ---
        try:
            csv_file_path = paperdata  # Path to your CSV file
            df_paper = pd.read_csv(csv_file_path)
        except FileNotFoundError:
            print(f"Error: The file '{csv_file_path}' was not found.")
            exit()
        except Exception as e:
            print(f"Error reading CSV file: {e}")
            exit()

        # -- * Join paper results with main table
        if df_paper is not None:
            df = pd.concat([df, df_paper])
            logger.debug(df)





        # # # -- * 1. Load your data
        make_rank1_plot(df)


        to_keep_list = ['ICM-VLS(CPU)\nRank: CorrAvScore','ICM-Ridge(GPU)\nRank: CorrAvScore']
        to_keep_df = df[df['Method'].isin(to_keep_list)]

        if df_paper is not None:
            to_keep_df = pd.concat([to_keep_df, df_paper])
            logger.debug(to_keep_df)

        # -- * Make journal plot
        make_rank1_plot(to_keep_df,
                    output = "output_Manuscript_Benchmark.svg",
                    outputpdf = "output_Manuscript_Benchmark.pdf")



        # -- * Calculate top 3 rank
        df_rank_3_Score = posebusted_results_custom_rank(df_posebusted_rmsd_fix , rank=3 ,rank_type = 'RANK_Score')
        df_rank_3_RTCNNscore = posebusted_results_custom_rank(df_posebusted_rmsd_fix , rank=3 ,rank_type = 'RANK_RTCNNscore')
        df_rank_3_corrScoreAverage= posebusted_results_custom_rank(df_posebusted_rmsd_fix , rank=3 ,rank_type = 'RANK_corrScoreAverage')
        df_rank_3_ridgeRTCNN = posebusted_results_custom_rank(df_posebusted_rmsd_fix , rank=3 ,rank_type = 'RANK_RTCNN_Ridge')
        df_rank3 = pd.concat([df_rank_3_Score, df_rank_3_RTCNNscore, df_rank_3_corrScoreAverage,df_rank_3_ridgeRTCNN ])
        make_custom_rank_plot(df_rank3, rank=3)

        # -- * Calculate top 6 rank
        df_rank_6_Score = posebusted_results_custom_rank(df_posebusted_rmsd_fix , rank=6 ,rank_type = 'RANK_Score')
        df_rank_6_RTCNNscore = posebusted_results_custom_rank(df_posebusted_rmsd_fix , rank=6 ,rank_type = 'RANK_RTCNNscore')
        df_rank_6_corrScoreAverage= posebusted_results_custom_rank(df_posebusted_rmsd_fix , rank=6 ,rank_type = 'RANK_corrScoreAverage')
        df_rank_6_ridgeRTCNN = posebusted_results_custom_rank(df_posebusted_rmsd_fix , rank=6 ,rank_type = 'RANK_RTCNN_Ridge')
        df_rank6 = pd.concat([df_rank_6_Score, df_rank_6_RTCNNscore, df_rank_6_corrScoreAverage, df_rank_6_ridgeRTCNN])
        make_custom_rank_plot(df_rank6, rank=6)

        # -- * Calculate top 10 rank
        df_rank_10_Score = posebusted_results_custom_rank(df_posebusted_rmsd_fix , rank=10 ,rank_type = 'RANK_Score')
        df_rank_10_RTCNNscore = posebusted_results_custom_rank(df_posebusted_rmsd_fix , rank=10 ,rank_type = 'RANK_RTCNNscore')
        df_rank_10_corrScoreAverage= posebusted_results_custom_rank(df_posebusted_rmsd_fix , rank=10 ,rank_type = 'RANK_corrScoreAverage')
        df_rank_10_ridgeRTCNN = posebusted_results_custom_rank(df_posebusted_rmsd_fix , rank=10 ,rank_type = 'RANK_RTCNN_Ridge')
        df_rank10 = pd.concat([df_rank_10_Score, df_rank_10_RTCNNscore, df_rank_10_corrScoreAverage,df_rank_10_ridgeRTCNN])
        make_custom_rank_plot(df_rank10, rank=10)

        logger.info(" Info> There were no errors in making a plot")
        exit(0)
    except Exception as e:
        logger.warning(" Error> Processing the files {}".format(e))
        traceback.print_exc()
        exit(1)

    # -- * Check if cache directory available or not

    # -- ? Output should look with following format
    # --output="${name}_${id}.xyz"


if __name__ == "__main__":
    start_program()
if __name__ == "__main__":
    start_program()
