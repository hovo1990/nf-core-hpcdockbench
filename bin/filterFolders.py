"""
Author: Hovakim Grabski
Purpose: Filters folders from a csv file
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
    if not value.lower().endswith(".data"):
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
    "--correction",
    help="posebusters correct pdb ids",
    type=click.Path(exists=True),
    required=True,

)
def start_program(input,correction):
    test = 1

    logger.info(" Info>  input {}".format(input))
    # exit(1)

    try:
        df = pd.read_csv(input,header=None)
        logger.debug(df)

        df.columns = ['Path']


        # -- * Check if it a file or folder
        directory_lists = []
        for p in df['Path']:
            path = Path(p)
            if path.is_file():
                logger.debug(f"{p} is a file")
            elif path.is_dir():
                logger.debug(f"{p} is a directory")
                dir_name = path.name
                directory_lists.append([dir_name,path])
            else:
                logger.debug(f"{p} does not exist")


        logger.debug(directory_lists)

        # -- * Perform correction based on ids
        df_correct = pd.read_csv(correction,header=None)
        df_correct.columns = ['CODE']
        logger.debug(df_correct)

        # -- * find all subfolders
        for i in directory_lists:
            subfolders_temp = [p for p in i[-1].iterdir() if p.is_dir()]
            subfolders = [str(p) for p in subfolders_temp]
            temp_df = pd.DataFrame(subfolders,columns=['PATH'])
            # temp_df['SET'] = i[0]

            temp_df.insert(0, 'SET',i[0])
            # temp_df['CODE'] = [p.name for p in subfolders_temp ]
            temp_p = [p.name for p in subfolders_temp ]
            temp_df.insert(1, 'CODE',temp_p)
            file_save = "{}.csv".format(i[0])

            # -- * Keep only for posebusters, that are in the corrected list
            # logger.debug(i[0])
            if (i[0] == 'posebusters_benchmark_set'):
                temp_df =  temp_df[temp_df['CODE'].isin(df_correct['CODE'])]

            temp_df.to_csv(file_save,index=False)
            logger.debug(temp_df)
            logger.debug(" ========== ")







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
