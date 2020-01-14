#!/bin/bash
#
# Batch copy HFP v2 csv files to Postgres db.

# TODO: set data directory based on HFPV2_ROOTDIR
# TODO: set keep_and_compress=true/false
# TODO: set log file for this process; direct ALL echo output to that file
# TODO: list files in data/raw/, and exclude currently open files from them
# TODO: mapping between raw data files and SQL COPY script for each type of data???
# TODO: for each file for which there is a mapping, do
#       - psql: copy contents to temp table, insert valid rows from temp table to prod table, echo results
#       - if psql exit status was successful:
#         - if keep_and_compress==true, gzip the csv file to data/gz/
#         - delete the csv file
#       - else (if psql failed):
#         - gzip the csv file to data/gz/
#         - record error/warning to log
#         - delete the csv file
