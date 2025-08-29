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


def validate_data(ctx, param, value):
    logger.info(" Info> validate_csv is ", value)
    if not value.lower().endswith(".data"):
        raise click.BadParameter("File must have a .csv extension")
    return value


def validate_csv(ctx, param, value):
    logger.info(" Info> validate_csv is ", value)
    if not value.lower().endswith(".csv"):
        raise click.BadParameter("File must have a .csv extension")
    return value


@click.command()
@click.option(
    "--input",
    help="csv input of the posebusted results",
    type=click.Path(exists=True),
    required=True,
    callback=validate_data,
)
@click.option(
    "--output",
    help="output name",
    required=True,
    callback=validate_csv,
)
def start_program(input, output):
    test = 1

    logger.info(" Info>  input {}".format(input))
    # exit(1)

    try:
        df = pd.read_csv(input, header=None)
        df.columns = [
            "method",
            "category",
            "dataset_name",
            "code",
            "proj_id",
            "protein_struct",
            "ligand_struct",
            "docked_pose",
            "docked_pose_mf",
            "csv_file",
        ]

        # logger.debug(df)

        csv_data_toiter = df["csv_file"]
        # logger.debug(csv_data_toiter)
        temp = []
        final_df = pd.DataFrame()
        for i in tqdm(csv_data_toiter):
            # logger.debug(" Debug> reading {}".format(i))
            temp_df = pd.read_csv(i)
            final_df = pd.concat([final_df, temp_df])

        if len(final_df) < 1:
            logger.warning(" Error> The table is empty, that is not good")
            exit(1)

        final_df.to_csv(output, index=False)

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
