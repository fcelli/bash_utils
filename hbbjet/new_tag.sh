#!/bin/bash
# Title         : new_tag.sh
# Description   : Generates a directory containing all json files needed to run the fitting framework on a new production tag.
# Author        : fcelli 

TAG=${1}

fitframe_dir='/home/celli/hbbjet/xmlfit_boostedhbb'
jsonasimov_dir='json/general/Asimov'

mkdir ${TAG} && cd ${TAG}

# SR
cp ${fitframe_dir}/${jsonasimov_dir}/SR/AsimovSR*.json ./

# STXS_Z_inc
cp ${fitframe_dir}/${jsonasimov_dir}/SR/STXS_Z_inc/STXS_Z_inc_AsimovSR*.json ./

# STXS_H_inc
cp ${fitframe_dir}/${jsonasimov_dir}/SR/STXS_H_inc/STXS_H_inc_AsimovSR*.json ./

# STXS_H_ggF
cp ${fitframe_dir}/${jsonasimov_dir}/SR/STXS_H_ggF/STXS_H_ggF_AsimovSR*.json ./

# CRttbar
cp ${fitframe_dir}/${jsonasimov_dir}/CRttbar/CRttbar*.json ./

# Change paths to local
sed -i 's/\/eos\/atlas\/atlascerngroupdisk\/phys-higgs\/HSG5\/dibjetISR_boosted\/data_latest/\/data\/atlas\/atlasdata\/celli\/hbbjet\/data_latest/g' *.json

# Apply level of pruning
#sed -i 's/\"prun_norm_thr\": .*/"prun_norm_thr\": 0.005,/g' *.json
#sed -i 's/\"prun_shape_thr\": .*/"prun_shape_thr\": 0.005,/g' *.json

cd ..