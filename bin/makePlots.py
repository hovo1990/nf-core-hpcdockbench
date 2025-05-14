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


def posebusted_results(df):
    logger.debug(" {}".format(df.columns))

    unique_datasets = df["_DATASET_"].unique()
    logger.debug(" Debug> unique datasets {}".format(unique_datasets))

    name_dict = {
        "astex_diverse_set": "Astex",
        "posebusters_benchmark_set": "PoseBusters",
    }

    # Set color palette
    palette = {"Astex": "#76c7c0", "PoseBusters": "#f97b72"}  # teal  # coral

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
        count_data["percentage"] = (count_data["count"] / total) * 100
        count_data["PB_percentage"] = (value_counts["count"] / total_PB) * 100

        # logger.debug(" Debug> {}".format(count_data))

        # # Reshape data to long format
        melted_data = count_data.melt(
            id_vars="rmsd_≤_2å",
            value_vars=["percentage", "PB_percentage"],
            var_name="Type",
            value_name="Percentage",
        )
        logger.debug(" Debug> {}".format(melted_data))

        # Create the barplot
        plt.figure()
        # sns.barplot(data=count_data, x='rmsd_≤_2å', y='percentage')

        sns.barplot(data=melted_data, x="rmsd_≤_2å", y="Percentage", hue="Type")

        # Add labels and show the plot
        plt.xlabel("RMSD ≤ 2Å")
        plt.ylabel("Percentage")
        plt.title("Count of True/False in RMSD ≤ 2Å")

        output = "output_{}.svg".format(dataset)
        outputpdf = "output_{}.pdf".format(dataset)

        plt.savefig(output)

        plt.savefig(outputpdf)
        plt.gca()
        logger.debug(" ===" * 20)


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

        # -- * 1. Load your data
        df = pd.read_csv(paperdata)
        logger.debug(" Debug> dataframe is {}".format(df))

        # -- * It works but the way it looks like this
        # # -- * Make sure the ordering is fixed:
        # tools = [
        #     "Gold",
        #     "Vina",
        #     "DeepDock",
        #     "Uni-Mol",
        #     "DiffDock",
        #     "Equibind",
        #     "TankBind",
        # ]
        # datasets = ["Astex", "PoseBusters"]

        # # --* 3. Set up the bar plot
        # n_tools = len(tools)
        # bar_width = 0.35
        # x = np.arange(n_tools)  # the label locations

        # fig, ax = plt.subplots(figsize=(10, 5))

        # # -- * For each dataset, shift the bars left/right
        # offsets = {"Astex": -bar_width / 2, "PoseBusters": +bar_width / 2}
        # hatches = {"rmsd_<2_in_percent": "//", "rmsd_<2_PB_in_percent": "xx"}

        # for dataset in datasets:
        #     subset = df[df["dataset"] == dataset].set_index("tool").loc[tools]
        #     for i, metric in enumerate(["rmsd_<2_in_percent", "rmsd_<2_PB_in_percent"]):
        #         values = subset[metric].astype(float).values
        #         # compute x positions for this dataset+metric
        #         xpos = x + offsets[dataset]
        #         # further offset the second metric within each dataset
        #         xpos = xpos + (i * bar_width / 2)
        #         ax.bar(
        #             xpos,
        #             values,
        #             bar_width / 2,
        #             label=f"{dataset} – {'RMSD ≤2 Å' if i==0 else 'RMSD ≤2 Å & PB‑valid'}",
        #             hatch=hatches[metric],
        #             edgecolor="black",
        #             linewidth=1,
        #         )

        # # 4. Formatting
        # ax.set_xticks(x)
        # ax.set_xticklabels(tools, rotation=45, ha="right")
        # ax.set_ylabel("Percentage of predictions")
        # ax.set_ylim(0, 100)
        # ax.legend(ncol=2, fontsize="small", frameon=False)
        # ax.grid(axis="y", linestyle="--", alpha=0.5)

        # plt.tight_layout()

        methods = [
            "Gold",
            "Vina",
            "DeepDock",
            "Uni-Mol",
            "DiffDock",
            "EquiBind",
            "TankBind",
        ]
        method_categories = {
            "classical": ["Gold", "Vina"],
            "DL-based": ["DeepDock", "Uni-Mol", "DiffDock"],
            "DL-based blind": ["EquiBind", "TankBind"],
        }

        # Values for Astex Diverse Set
        astex_rmsd_le_2A = [67, 60, 35, 45, 72, 7.1, 59]  # Solid Teal
        astex_rmsd_le_2A_pb_valid = [64, 56, 11, 12, 47, 1.2, 5.9]  # Hatched Teal

        # Values for PoseBusters Benchmark Set
        posebusters_rmsd_le_2A = [58, 60, 20, 22, 38, 2.0, 16]  # Solid Coral
        posebusters_rmsd_le_2A_pb_valid = [
            55,
            58,
            5.2,
            2.0,
            12,
            2.0,
            3.3,
        ]  # Hatched Coral

        # Colors
        teal_color = "#80CBC4"  # A light teal
        coral_color = "#FFAB91"  # A light coral

        # --- Setup ---
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
                for bar in bars_group:
                    height = bar.get_height()
                    ax.annotate(
                        f"{height:.1f}%",  # Using .1f to show one decimal like in EquiBind/TankBind
                        xy=(bar.get_x() + bar.get_width() / 2, height),
                        xytext=(0, 3),  # 3 points vertical offset
                        textcoords="offset points",
                        ha="center",
                        va="bottom",
                        fontsize=7,
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
        legend_handles = [
            Line2D(
                [0], [0], linestyle="none", marker="", label="Astex Diverse set"
            ),  # Title for 1st column
            Patch(
                facecolor=teal_color,
                edgecolor="grey",
                label=r"RMSD $\leq 2\mathring{A}$",
            ),
            Patch(
                facecolor=teal_color,
                edgecolor="grey",
                hatch="////",
                label=r"RMSD $\leq 2\mathring{A}$ & PB-Valid",
            ),
            Line2D(
                [0], [0], linestyle="none", marker="", label="PoseBusters Benchmark set"
            ),  # Title for 2nd column
            Patch(
                facecolor=coral_color,
                edgecolor="grey",
                label=r"RMSD $\leq 2\mathring{A}$",
            ),
            Patch(
                facecolor=coral_color,
                edgecolor="grey",
                hatch="////",
                label=r"RMSD $\leq 2\mathring{A}$ & PB-Valid",
            ),
        ]

        # The legend is filled column by column due to ncol=2 and the order of handles.
        # To achieve row-by-row filling for titles then items:
        # Order for handles: Title1, Title2, Item1_Col1, Item1_Col2, Item2_Col1, Item2_Col2
        ordered_handles = [
            legend_handles[0],
            legend_handles[3],  # Titles
            legend_handles[1],
            legend_handles[4],  # RMSD <= 2A
            legend_handles[2],
            legend_handles[5],  # RMSD <= 2A & PB-Valid
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

        # Make legend titles bold and adjust spacing if needed
        for i, text in enumerate(leg.get_texts()):
            if (
                text.get_text() == "Astex Diverse set"
                or text.get_text() == "PoseBusters Benchmark set"
            ):
                text.set_fontweight("bold")
                # To remove the (non-existent) marker for title lines if they had one:
                # leg.legendHandles[i].set_visible(False) # Not strictly needed for Line2D with no visible elements

        # --- Adding Category X-axis Labels ---
        plt.subplots_adjust(bottom=0.15)  # Make space for category labels

        # Determine y-position for these labels relative to the plot
        y_pos_text = -0.12 * (ax.get_ylim()[1] - ax.get_ylim()[0])
        y_pos_line = y_pos_text - (0.05 * (ax.get_ylim()[1] - ax.get_ylim()[0]))

        category_definitions = {
            "classical": (0, 1),  # indices of methods in this category
            "DL-based": (2, 4),
            "DL-based blind": (5, 6),
        }

        for cat_name, (start_idx, end_idx) in category_definitions.items():
            # Calculate the x-range for the category based on actual bar positions
            # Left edge of the first bar in the category's first method
            cat_x_start = x[start_idx] - 1.5 * bar_width - bar_width / 2
            # Right edge of the last bar in the category's last method
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
        fig.tight_layout(
            rect=[0, 0.05, 1, 1]
        )  # Adjust layout to prevent labels from being cut off, leave space at bottom for category labels

        output = "output_Benchmark.svg"
        outputpdf = "output_Benchmark.pdf"

        plt.savefig(output)

        plt.savefig(outputpdf)

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
