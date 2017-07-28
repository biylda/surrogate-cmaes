#!/bin/bash
#
# Job-submitting experiment for the first 10D GP model testing
# It is expected to be located in exp/experiments/

export EXPID='exp_DTSmodels_02'
export DATASET="DTS_005_25_models"

# Enable this option for using Matlab MCR compilated binaries:
export useMCR=1

# !!! THIS HAS TO BE HERE !!!
#     vvvvvvvvvvvvvvvvvvv
CWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $CWD/../bash_settings.sh
. $CWD/../metacentrum_testmodels_common.sh
#     ^^^^^^^^^^^^^^^^^^^
# !!! THIS HAS TO BE HERE !!!

# job submittion can be done via one of the two bash functions:
#
# (a) subtask [JOBNAME_SUFFIX]
#
#     submits a job with current-set $ID, $DIM, $FUNC, $INST and $OPTS
#
#
# (b) submit_sequence LOW_IDX STEP HIGH_IDX
#
#     call subtask() with 'modelOptionsIndices' set to a small
#     numbers of model-settings;
#     it submits a job for every $2 consecutive modelOptions' indices
#
#     e.g.: submit 11 4 22
#     submits jobs for the following modelOption indices:
#       - 11:14
#       - 15:18
#       - 19:22
#
#     Important: the HIGH_IDX should be the equal to (k*LOW_IDX) - 1
#                for some k


# critical characters has to be replaced in $OPTS:
# '|' with ',' and "%" with "'"
OPTS=""

INST="[1 2 3 4 5]"
N_MODELS=4

ID=201
DIM=2
QUEUE="4:00:00"
for FUNC in `seq 1 24`; do
  subtask
done

ID=301
DIM=3
QUEUE="4:00:00"
for FUNC in `seq 1 24`; do
  subtask
done

ID=501
DIM=5
QUEUE="24:00:00"
for FUNC in `seq 1 24`; do
  subtask
done

ID=1001
DIM=10
QUEUE="24:00:00"
for FUNC in `seq 1 24`; do
  subtask
done

ID=2001
DIM=20
QUEUE="24:00:00"
for FUNC in `seq 1 24`; do
  submit_sequence 1 1 $N_MODELS
done


# Example of using submit_sequence
#
# # f1
# FUNC=1
# QUEUE="4:00:00"
# ID=490
# submit_sequence 146 1 146
# submit_sequence 147 2 170
# submit_sequence 217 2 256