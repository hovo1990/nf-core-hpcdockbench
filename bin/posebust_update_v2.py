"""
Author: Hovakim Grabski
Purpose: Filters folders from a csv file
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
import pandas as pd
from loguru import logger
from rdkit import Chem
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


@click.command()
@click.option(
    "--input",
    help="csv input of the smiles",
    type=click.Path(exists=True),
    required=True,
    callback=validate_csv,
)
@click.option(
    "--dataset",
    help="dataset name",
    required=True,
)
@click.option(
    "--prot",
    help="protein structre",
    type=click.Path(exists=True),
    required=True,
)
@click.option(
    "--lig",
    help="ligand cocrystall structure",
    type=click.Path(exists=True),
    required=True,
)
@click.option(
    "--dock",
    help="docked pose",
    type=click.Path(exists=True),
    required=True,
)
@click.option(
    "--code",
    help="code name",
    required=True,
)
@click.option(
    "--proj",
    help="proj name",
    required=True,
)
@click.option(
    "--method",
    help="method, tool that was used",
    required=True,
)
@click.option(
    "--category",
    help="category (Classical or DL-based, etc)",
    required=True,
)
@click.option(
    "--output",
    help="output name",
    required=True,
    callback=validate_csv,
)
def start_program(
    input, dataset, prot, lig, dock, code, proj, method, category, output
):
    test = 1

    logger.info(" Info>  input {}".format(input))
    # exit(1)

    try:
        df = pd.read_csv(input)

        # df["_RANK_"] = input.split("_")[-2]
        df["_DATASET_"] = dataset
        df["_PROTFILE_"] = prot
        df["_LIGFILE_"] = lig
        df["_DOCKFILE_"] = dock
        df["_CODE_"] = code
        df["_PROJ_"] = proj
        df["_METHOD_"] = method
        df["_CATEGORY_"] = category

        # -- * Read properties about score and RTCNN in the sdf file
        RANK_LIST_Score = []
        RANK_LIST_RTCNNscore = []
        RANK_LIST_AverageScore = []
        RANK_LIST_CombinedScore = []
        RANK_LIST_corrScoreAverage = []



        SCORE_LIST = []
        RTCNN_SCORE_LIST = []
        AverageScore_LIST = []
        CombinedScore_LIST = []
        corrScoreAverage_LIST = []
        RTCNN_RIDGE_LIST = []
        ICM_RMSD_IN_PLACE_LIST = []
        ICM_RMSD_SUPERIMPOSED_LIST = []
        ICM_MATCHING_FRACTION_LIST = []

        supplier = Chem.SDMolSupplier(dock)
        for mol in supplier:
            if mol is None:
                continue  # Skip invalid entries
            # -- *  Get properties (stored in the SDF under tags)
            props = mol.GetPropsAsDict()
            logger.debug(" DEBUG> {}".format(props))



            # -- * TODO add the appropriate RANKS
            RANK_Score = mol.GetProp("Rank_Score") if mol.HasProp("Rank_Score") else "-100"
            RANK_RTCNNscore = mol.GetProp("Rank_RTCNNscore") if mol.HasProp("Rank_RTCNNscore") else "-100"
            RANK_AverageScore = mol.GetProp("Rank_AverageScore") if mol.HasProp("Rank_AverageScore") else "-100"
            RANK_CombinedScore = mol.GetProp("Rank_CombinedScore") if mol.HasProp("Rank_CombinedScore") else "-100"
            RANK_corrScoreAverage = mol.GetProp("Rank_corrScoreAverage") if mol.HasProp("Rank_corrScoreAverage") else "-100"


            RANK_LIST_Score.append(RANK_Score)
            RANK_LIST_RTCNNscore.append(RANK_RTCNNscore)
            RANK_LIST_AverageScore.append(RANK_AverageScore)
            RANK_LIST_CombinedScore.append(RANK_CombinedScore)
            RANK_LIST_corrScoreAverage .append(RANK_corrScoreAverage )

            SCORE = mol.GetProp("Score") if mol.HasProp("Score") else "N/A"
            SCORE_LIST.append(SCORE)


            RTCNN_SCORE = (
                mol.GetProp("RTCNNscore") if mol.HasProp("RTCNNscore") else "N/A"
            )
            RTCNN_SCORE_LIST.append(RTCNN_SCORE)

            AverageScore = (
                mol.GetProp("AverageScore") if mol.HasProp("AverageScore") else "N/A"
            )
            AverageScore_LIST.append(AverageScore )

            CombinedScore = (
                mol.GetProp("CombinedScore") if mol.HasProp("CombinedScore") else "N/A"
            )
            CombinedScore_LIST.append(CombinedScore)

            corrScoreAverage = (
                mol.GetProp("corrScoreAverage")
                if mol.HasProp("corrScoreAverage")
                else "N/A"
            )
            corrScoreAverage_LIST.append(corrScoreAverage)

            RTCNN_RIDGE = mol.GetProp("ENERGY") if mol.HasProp("ENERGY") else "N/A"
            RTCNN_RIDGE_LIST.append(RTCNN_RIDGE )

            ICM_RMSD_IN_PLACE_ = (
                mol.GetProp("ICM_RMSD_IN_PLACE_")
                if mol.HasProp("ICM_RMSD_IN_PLACE_")
                else "N/A"
            )
            ICM_RMSD_IN_PLACE_LIST.append(ICM_RMSD_IN_PLACE_)

            ICM_RMSD_SUPERIMPOSED_ = (
                mol.GetProp("ICM_RMSD_SUPERIMPOSED_")
                if mol.HasProp("ICM_RMSD_SUPERIMPOSED_")
                else "N/A"
            )
            ICM_RMSD_SUPERIMPOSED_LIST.append(ICM_RMSD_SUPERIMPOSED_)

            ICM_MATCHING_FRACTION_ = (
                mol.GetProp("ICM_MATCHING_FRACTION_")
                if mol.HasProp("ICM_MATCHING_FRACTION_")
                else "N/A"
            )
            ICM_MATCHING_FRACTION_LIST.append(ICM_MATCHING_FRACTION_)

        # -- * Add RTCNN_RIDGE GPU
        df["_RANK_Score_"] = RANK_LIST_Score
        df["RANK_Score"] = RANK_LIST_Score
        df["RANK_RTCNNscore"] = RANK_LIST_RTCNNscore
        df["RANK_AverageScore"] = RANK_LIST_AverageScore
        df["RANK_CombinedScore"] = RANK_LIST_CombinedScore
        df["RANK_corrScoreAverage"] = RANK_LIST_corrScoreAverage

        df["Score"] = SCORE_LIST
        df["RTCNN_SCORE"] = RTCNN_SCORE_LIST
        df["AverageScore"] = AverageScore_LIST
        df["CombinedScore"] = CombinedScore_LIST
        df["corrScoreAverage"] = corrScoreAverage_LIST
        df["RTCNN_RIDGE"] = RTCNN_RIDGE_LIST

        df["ICM_RMSD_IN_PLACE_"] = ICM_RMSD_IN_PLACE_LIST
        df["ICM_RMSD_SUPERIMPOSED_"] = ICM_RMSD_SUPERIMPOSED_LIST
        df["ICM_MATCHING_FRACTION_"] = ICM_MATCHING_FRACTION_LIST
        # logger.debug(" DEBUG> Score {}".format(SCORE))

        logger.debug(df)

        df.to_csv(output, index=False)

        logger.info(" Info> There were no errors")
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
