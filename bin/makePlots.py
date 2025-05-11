"""
Author: Hovakim Grabski
Purpose: Make plots based on posebuster data
Date: 05-07-2025


"""

import math
import os
import pathlib
import sys
import time
from itertools import combinations
from loguru import logger
import click
import shutil
import pandas as pd
import os
import hashlib
from tqdm.auto import tqdm
from tqdm.contrib import tzip
import traceback
from pathlib import Path

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
    help="csv input of the posebusted results",
    type=click.Path(exists=True),
    required=True,
    callback=validate_csv,
)
def start_program(input):
    test = 1

    logger.info(" Info>  input {}".format(input))
    # exit(1)

    try:
        df = pd.read_csv(input,header=None)


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
