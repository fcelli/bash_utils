#!/bin/bash
# Title         : new_tag.sh
# Description   : Generates a directory containing all json files needed to run the fitting framework on a new production tag.
# Author        : fcelli 

SCRIPT=$(basename $0)

# Usage function
usage() {
    printf "\t%s\n\n" "bash $SCRIPT --tag <TAG> [--help]"
    printf "%s\n\n" "Options:"
    # --tag TAG
    printf "\t%-20s\n" "--tag TAG"
        printf "\t\t%s\n" "TAG is the production name tag"
        printf "\n"
    # -h, --help
    printf "\t%-20s\n" "-h, --help"
        printf "\t\t%s\n" "Display this help and exit"
        printf "\n"
}

# Parse arguments
unset TAG
while [ "$1" != "" ]; do
    case $1 in
        --tag )
            shift
            TAG=${1}
            ;;
        -h | --help )
            usage
            exit 0
            ;;
        * )
            usage
            exit 1
    esac
    shift
done

fitframe_dir='/home/celli/hbbjet/xmlfit_boostedhbb'
json_path='json/paper'

mkdir ${TAG} && cd ${TAG}

# SR
cp ${fitframe_dir}/${json_path}/SR/SR*.json ./

# STXS_Z_inc
cp ${fitframe_dir}/${json_path}/SR/STXS_Z_inc/STXS_Z_inc_SR*.json ./

# STXS_H_inc
cp ${fitframe_dir}/${json_path}/SR/STXS_H_inc/STXS_H_inc_SR*.json ./

# STXS_H_ggF
cp ${fitframe_dir}/${json_path}/SR/STXS_H_ggF/STXS_H_ggF_SR*.json ./

# CRttbar
cp ${fitframe_dir}/${json_path}/CRttbar/CRttbar*.json ./

# Change paths to local
sed -i 's/\/eos\/atlas\/atlascerngroupdisk\/phys-higgs\/HSG5\/dibjetISR_boosted\/data_latest/\/data\/atlas\/atlasdata\/celli\/hbbjet\/data_latest/g' *.json

# Apply level of pruning
#sed -i 's/\"prun_norm_thr\": .*/"prun_norm_thr\": 0.005,/g' *.json
#sed -i 's/\"prun_shape_thr\": .*/"prun_shape_thr\": 0.005,/g' *.json

cd ..