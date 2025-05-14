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

        df["RANK"] = input.split("_")[-2]
        df["_DATASET_"] = dataset
        df["_PROTFILE_"] = prot
        df["_LIGFILE_"] = lig
        df["_DOCKFILE_"] = dock
        df["_CODE_"] = code
        df["_PROJ_"] = proj
        df["_METHOD_"] = method
        df["_CATEGORY_"] = category

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
