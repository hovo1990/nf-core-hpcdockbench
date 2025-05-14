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


def posebusted_results_rank1(df):
    logger.debug(" {}".format(df.columns))

    unique_datasets = df["_DATASET_"].unique()
    logger.debug(" Debug> unique datasets {}".format(unique_datasets))

    name_dict = {
        "astex_diverse_set": "Astex",
        "posebusters_benchmark_set": "PoseBusters",
    }

    # Set color palette
    palette = {"Astex": "#76c7c0", "PoseBusters": "#f97b72"}  # teal  # coral

    temp_data_astex = []
    temp_data_posebuster = []

    method = df["_METHOD_"][0]
    category = df["_CATEGORY_"][0]

    for dataset in tqdm(unique_datasets):
        curr_dataset = df[df["_DATASET_"] == dataset]

        top_rank1 = curr_dataset[curr_dataset["RANK"] == 1]
        # logger.debug( " Debug> {}".format(top_rank1))
        # logger.debug( " Debug> {}".format(top_rank1['rmsd_≤_2å']))

        # -- * Make plot how many are rmsd_≤_2å

        # Count the number of True and False values
        count_data = top_rank1["rmsd_≤_2å"].value_counts().reset_index()
        count_data.columns = ["rmsd_≤_2å", "count"]
        # logger.debug( " Debug> {}".format(count_data) )

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
            "rmsd_≤_2å",
        ]
        top_rank1["all_true"] = top_rank1[columns_of_interest].all(axis=1)

        # Count True or False values in the 'all_true' column
        value_counts = top_rank1["all_true"].value_counts().reset_index()
        value_counts.columns = ["rmsd_≤_2å_PB_VALID", "count"]

        # Add a percentage column
        total = count_data["count"].sum()
        total_PB = value_counts["count"].sum()
        tot_perc = (count_data["count"] / total) * 100
        tot_perc_PB = (value_counts["count"] / total_PB) * 100
        count_data["percentage"] = tot_perc
        count_data["PB_percentage"] = tot_perc_PB
        tot_perc_vals = tot_perc.values[0]
        tot_perc_PB_vals = tot_perc_PB.values[0]

        # logger.debug(" Debug> {}".format(count_data))

        # # Reshape data to long format
        melted_data = count_data.melt(
            id_vars="rmsd_≤_2å",
            value_vars=["percentage", "PB_percentage"],
            var_name="Type",
            value_name="Percentage",
        )

        if dataset == "astex_diverse_set":
            temp_data_astex = [tot_perc_vals, tot_perc_PB_vals]
        elif dataset == "posebusters_benchmark_set":
            temp_data_posebuster = [tot_perc_vals, tot_perc_PB_vals]

        # logger.debug(" Debug> dataset {} {}".format(dataset, melted_data))
        logger.debug(" ========== " * 10)

    final_list = [method, category] + temp_data_astex + temp_data_posebuster
    # logger.debug(final_list)

    final_df = pd.DataFrame([final_list])
    final_df.columns = [
        "Method",
        "Category",
        "Astex_RMSD_le_2A",
        "Astex_RMSD_le_2A_PB_Valid",
        "PoseBusters_RMSD_le_2A",
        "PoseBusters_RMSD_le_2A_PB_Valid",
    ]
    logger.debug(final_df)
    return final_df


def make_rank1_plot(df):
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
    bar_width = 0.2  # the width of the bars

    fig, ax = plt.subplots(figsize=(14, 8))  # Adjust figure size as needed

    # --- Plotting Bars ---
    # Astex bars
    bars1 = ax.bar(
        x - 1.5 * bar_width,
        astex_rmsd_le_2A,
        bar_width,
        label="Astex RMSD $\le 2\mathring{A}$",
        color=teal_color,
        edgecolor="grey",
    )
    bars2 = ax.bar(
        x - 0.5 * bar_width,
        astex_rmsd_le_2A_pb_valid,
        bar_width,
        label="Astex RMSD $\le 2\mathring{A}$ & PB-Valid",
        color=teal_color,
        hatch="////",
        edgecolor="grey",
    )

    # PoseBusters bars
    bars3 = ax.bar(
        x + 0.5 * bar_width,
        posebusters_rmsd_le_2A,
        bar_width,
        label="PoseBusters RMSD $\le 2\mathring{A}$",
        color=coral_color,
        edgecolor="grey",
    )
    bars4 = ax.bar(
        x + 1.5 * bar_width,
        posebusters_rmsd_le_2A_pb_valid,
        bar_width,
        label="PoseBusters RMSD $\le 2\mathring{A}$ & PB-Valid",
        color=coral_color,
        hatch="////",
        edgecolor="grey",
    )

    # --- Adding Percentage Labels on Bars ---
    def add_bar_labels(bars_list):
        for bars_group in bars_list:
            for bar_item in bars_group:  # bar_item is the actual bar object
                height = bar_item.get_height()
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
            facecolor=teal_color,
            edgecolor="grey",
            label=r"Astex Diverse set RMSD $\leq 2\mathring{A}$",
        ),
        Patch(
            facecolor=teal_color,
            edgecolor="grey",
            hatch="////",
            label=r"Astex Diverse set RMSD $\leq 2\mathring{A}$ & PB-Valid",
        ),
        Patch(
            facecolor=coral_color,
            edgecolor="grey",
            label=r"PoseBusters Benchmark se RMSD $\leq 2\mathring{A}$",
        ),
        Patch(
            facecolor=coral_color,
            edgecolor="grey",
            hatch="////",
            label=r"PoseBusters Benchmark se RMSD $\leq 2\mathring{A}$ & PB-Valid",
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

    output = "output_Benchmark.svg"
    outputpdf = "output_Benchmark.pdf"

    plt.savefig(output)

    plt.savefig(outputpdf)


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
    required=True,
    callback=validate_csv,
)
def start_program(input, paperdata):
    test = 1

    logger.info(" Info>  input {}".format(input))
    # exit(1)

    try:
        df_posebusted = pd.read_csv(input)

        logger.debug(" Debug> {}".format(df_posebusted))

        df = posebusted_results_rank1(df_posebusted)

        csv_file_path = paperdata  # Path to your CSV file
        # --- Load Data from CSV ---
        try:
            df_paper = pd.read_csv(csv_file_path)
        except FileNotFoundError:
            print(f"Error: The file '{csv_file_path}' was not found.")
            exit()
        except Exception as e:
            print(f"Error reading CSV file: {e}")
            exit()

        if df_paper is not None:
            df = pd.concat([df, df_paper])
            logger.debug(df)

        # # -- * 1. Load your data
        make_rank1_plot(df)

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
