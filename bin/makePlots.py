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

import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt


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
        df = pd.read_csv(input)
        logger.debug(" {}".format(df.columns))

        unique_datasets = df['_DATASET_'].unique()
        logger.debug (" Debug> unique datasets {}".format(unique_datasets))


        name_dict = {'astex_diverse_set':'Astex',
                     'posebusters_benchmark_set':'PoseBusters'}

        # Set color palette
        palette = {
            'Astex': '#76c7c0',         # teal
            'PoseBusters': '#f97b72'    # coral
        }




        for dataset in tqdm(unique_datasets):
            curr_dataset = df[ df['_DATASET_'] == dataset]

            top_rank1 = curr_dataset[curr_dataset['RANK'] == 1]
            # logger.debug( " Debug> {}".format(top_rank1))
            # logger.debug( " Debug> {}".format(top_rank1['rmsd_≤_2å']))

            # -- * Make plot how many are rmsd_≤_2å


            # Count the number of True and False values
            count_data = top_rank1['rmsd_≤_2å'].value_counts().reset_index()
            count_data.columns = ['rmsd_≤_2å', 'count']
            # logger.debug( " Debug> {}".format(count_data) )

            # Check if all values in the specified columns are True for each row
            columns_of_interest=['mol_true_loaded',
            'mol_cond_loaded', 'sanitization', 'inchi_convertible',
            'all_atoms_connected', 'molecular_formula', 'molecular_bonds',
            'double_bond_stereochemistry', 'tetrahedral_chirality', 'bond_lengths',
            'bond_angles', 'internal_steric_clash', 'aromatic_ring_flatness',
            'non-aromatic_ring_non-flatness', 'double_bond_flatness',
            'internal_energy', 'protein-ligand_maximum_distance',
            'minimum_distance_to_protein', 'minimum_distance_to_organic_cofactors',
            'minimum_distance_to_inorganic_cofactors', 'minimum_distance_to_waters',
            'volume_overlap_with_protein', 'volume_overlap_with_organic_cofactors',
            'volume_overlap_with_inorganic_cofactors', 'volume_overlap_with_waters',
            'rmsd_≤_2å']
            top_rank1['all_true'] = top_rank1[columns_of_interest].all(axis=1)

            # Count True or False values in the 'all_true' column
            value_counts = top_rank1['all_true'].value_counts().reset_index()
            value_counts.columns = ['rmsd_≤_2å_PB_VALID', 'count']



            # Add a percentage column
            total = count_data['count'].sum()
            total_PB = value_counts['count'].sum()
            count_data['percentage'] = (count_data['count'] / total) * 100
            count_data['PB_percentage'] = (value_counts['count'] / total_PB) * 100

            # logger.debug(" Debug> {}".format(count_data))

            # # Reshape data to long format
            melted_data = count_data.melt(id_vars='rmsd_≤_2å', value_vars=['percentage', 'PB_percentage'], var_name='Type', value_name='Percentage')
            logger.debug (" Debug> {}".format(melted_data))


            # Create the barplot
            plt.figure()
            # sns.barplot(data=count_data, x='rmsd_≤_2å', y='percentage')


            sns.barplot(data=melted_data, x='rmsd_≤_2å', y='Percentage', hue='Type')

            # Add labels and show the plot
            plt.xlabel('RMSD ≤ 2Å')
            plt.ylabel('Percentage')
            plt.title('Count of True/False in RMSD ≤ 2Å')

            output = 'output_{}.svg'.format(dataset)
            outputpdf = 'output_{}.pdf'.format(dataset)


            plt.savefig(output)

            plt.savefig(outputpdf)
            plt.gca()
            logger.debug(" ==="*20)


        logger.info(" Info> There were no errorrmsd_≤_2ås")
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
