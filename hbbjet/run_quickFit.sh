#!/bin/bash
# Title          : run_quickFit.sh
# Description    : Script for running quickFit on the hbbjet analysis regions. 
# Author         : fcelli 

SCRIPT=$(basename $0)

usage() {
  printf "%s\n\n" "From within xmlfit_boostedhbb/:"
  printf "\t%s\n\n" "bash path/to/$SCRIPT --tag <TAG> --mode <MODE> [--fix <FIX> --dtype <DTYPE> --minos <MINOS> --nom --condor --help]"
  printf "%s\n\n" "Options:"
  # --tag TAG
  printf "\t%-20s\n" "--tag TAG"
    printf "\t\t%s\n" "TAG is the production name tag"
    printf "\n"
  # --mode MODE
  printf "\t%-20s\n" "--mode MODE"
    printf "\t\t%s\n" "- MODE=SR_inc: run SR combined fit"
    printf "\t\t%s\n" "- MODE=SR_STXS_Z_inc: run SR STXS Z(inclusive) fit"
    printf "\t\t%s\n" "- MODE=SR_STXS_H_inc: run SR STXS H(inclusive) fit"
    printf "\t\t%s\n" "- MODE=SR_STXS_H_ggF: run SR STXS H(ggF) fit"
    printf "\t\t%s\n" "- MODE=SR: run all SR fits"
    printf "\t\t%s\n" "- MODE=CRttbar_inc: run CRttbar (inclusive) fit"
    printf "\t\t%s\n" "- MODE=CRttbar_bins: run CRttbar (pT bins) fit"
    printf "\t\t%s\n" "- MODE=CRttbar: run CRttbar fit (inclusive and pT bins)"
    printf "\t\t%s\n" "- MODE=all: run fits in all defined regions"
    printf "\n"
  # --fix FIX
  printf "\t%-20s\n" "--fix FIX"
    printf "\t\t%s\n" "FIX is the list of fixed nuisance parameters"
    printf "\n"
  # --dtype DTYPE
  printf "\t%-20s\n" "--dtype DTYPE[=all]"
    printf "\t\t%s\n" "- DTYPE=data: run on data"
    printf "\t\t%s\n" "- DTYPE=asimov: run on asimov"
    printf "\t\t%s\n" "- DTYPE=all: run on data and asimov"
    printf "\n"
  # --minos MINOS
  printf "\t%-20s\n" "--minos MINOS"
    printf "\t\t%s\n" "- MINOS=1: run scans only on parameters of interest"
    printf "\t\t%s\n" "- MINOS=3: run scans on all nuisance parameters"
    printf "\n"
  # --nom
  printf "\t%-20s\n" "--nom"
    printf "\t\t%s\n" "Run a nominal fit"
    printf "\n"
  # --condor
  printf "\t%-20s\n" "--condor"
    printf "\t\t%s\n" "Submit jobs to HTCondor"
    printf "\n"
  # -h, --help
  printf "\t%-20s\n" "-h, --help"
    printf "\t\t%s\n" "Display this help and exit"
    printf "\n"
}

# Function for handling HTCondor job submission
send_to_condor() {
  cmd=${1}
  echo "Submitting job to HTCondor: ${cmd}"
  cd submit_condor
  eval "bash submit_condor.sh -c ${cmd}"
  cd ..
}

# Parse arguments
DTYPE='all'
do_Nom=false
CONDOR=false
unset TAG MODE FIX MINOS
while [ "$1" != "" ]; do
  case $1 in
    --tag )
      shift
      TAG=$1
      ;;
    --mode )
      shift
      MODE=$1
      ;;
    --fix )
      shift
      FIX=$1
      ;;
    --dtype )
      shift
      DTYPE=$1
      ;;
    --minos )
      shift
      MINOS=$1
      ;;
    --nom )
      do_Nom=true
      ;;
    --condor )
      CONDOR=true
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

# Mandatory arguments check
if [ ! $TAG ] || [ ! $MODE ]; then
  usage
  exit 1
fi

# Define data type
if [ "$DTYPE" == 'all' ]; then
  DTYPE='data asimov'
elif [ "$DTYPE" != 'asimov' ] && [ "$DTYPE" != 'data' ]; then
  echo "Error: unexpected DTYPE value."
  exit 1
fi

# Setup nominal run
if $do_Nom; then
  nom="_nom"
  if [ ! $FIX ]; then
    FIX="alpha*,*Wboson*"
  else
    FIX="${FIX},alpha*,*Wboson*"
  fi
else
  nom=""
fi

# Initialize mode variables
do_SR_inc=false
do_SR_STXS_Z_inc=false
do_SR_STXS_H_inc=false
do_SR_STXS_H_ggF=false
do_CRttbar_inc=false
do_CRttbar_bins=false

# Run options
case $MODE in
  SR_inc )
    do_SR_inc=true
    ;;
  SR_STXS_Z_inc )
    do_SR_STXS_Z_inc=true
    ;;
  SR_STXS_H_inc )
    do_SR_STXS_H_inc=true
    ;;
  SR_STXS_H_ggF )
    do_SR_STXS_H_ggF=true
    ;;
  SR )
    do_SR_inc=true
    do_SR_STXS_Z_inc=true
    do_SR_STXS_H_inc=true
    do_SR_STXS_H_ggF=true
    ;;
  CRttbar_inc )
    do_CRttbar_inc=true
    ;;
  CRttbar_bins )
    do_CRttbar_bins=true
    ;;
  CRttbar )
    do_CRttbar_inc=true
    do_CRttbar_bins=true
    ;;
  all )
    do_SR_inc=true
    do_SR_STXS_Z_inc=true
    do_SR_STXS_H_inc=true
    do_SR_STXS_H_ggF=true
    do_CRttbar_inc=true
    do_CRttbar_bins=true
    ;;
  * )
    printf "Error: unexpected MODE value.\n"
    exit 1
esac

cd quickFit
# Create output directory
if ! test -d output; then
  mkdir output
fi

#-------------------------------------------------------------------------------------------------
# Run quickFit

# Run SR combined fit
if $do_SR_inc; then
  title='SR'
  mu_Higgs='1_-10_11'
  mu_Zboson='1_-3_5'
  mu_ttbar='1_0.5_1.5'
  minStrat='1'
  minTolerance='1e-4'
  hesse='1'
  extconst_massres_wz='0.056_0.158'
  # Set default minos value
  if [ ! $MINOS ]; then
    minos=1
  else
    minos=$MINOS
  fi
  # Set default fix value
  if [ ! $FIX ]; then
    fix=""
  else
    fix="-n ${FIX}"
  fi
  for dtype in $DTYPE; do
    if [ "${dtype}" == "data" ]; then
      echo "WARNING: this region is still blinded. Skipping..."
      continue
    fi
    outname="${title}_${dtype}_${TAG}_minos${minos}${nom}.root"
    cmd="quickFit -f workspace/hbbj/${title}/${title}_model_${dtype}_${TAG}.root -d combData -p mu_Zboson=${mu_Zboson},mu_Higgs=${mu_Higgs},mu_ttbar=${mu_ttbar} -o output/${outname} --savefitresult 1 --saveWS true --ssname quickfit --minStrat ${minStrat} --minTolerance ${minTolerance} --hesse ${hesse} --minos ${minos} ${fix} --NPExtGaussConstr alpha_JET_MassRes_WZ_comb=${extconst_massres_wz}"
    # --samplingRelTol -1
    # --printChi 1
    if ! $CONDOR; then
      echo "Running job locally: ${cmd}"
      eval $cmd
    else
      send_to_condor "\"$cmd\""
    fi
  done
fi

# Run SR STXS Z(inclusive) fit
if $do_SR_STXS_Z_inc; then
  title='SR_STXS_Z_inc'
  mu_Higgs_b0='1'
  mu_Higgs_b1='1'
  mu_Higgs_b2='1'
  mu_Zboson_pt0='1'
  mu_Zboson_pt1='1_-4_5'
  mu_Zboson_pt2='1_-1_3'
  mu_Zboson_pt3='1_-3_4'
  mu_ttbar_b0='1_0.5_1.5'
  mu_ttbar_b1='1_0.5_1.5'
  mu_ttbar_b2='1_0.5_1.5'
  minStrat='1'
  minTolerance='1e-4'
  hesse='1'
  extconst_massres_wz_0='0.127_0.141'
  extconst_massres_wz_1='0.071_0.146'
  extconst_massres_wz_2='-0.018_0.212'
  # Set default minos value
  if [ ! $MINOS ]; then
    minos=3
  else
    minos=$MINOS
  fi
  # Set default fix value
  if [ ! $FIX ]; then
    fix=""
  else
    fix="-n ${FIX}"
  fi
  for dtype in $DTYPE; do
    if [ "${dtype}" == "data" ]; then
      echo "WARNING: this region is still blinded. Skipping..."
      continue
    fi
    outname="${title}_${dtype}_${TAG}_minos${minos}${nom}.root"
    cmd="quickFit -f workspace/hbbj/${title}/${title}_model_${dtype}_${TAG}.root -d combData -p mu_Higgs_b0=${mu_Higgs_b0},mu_Higgs_b1=${mu_Higgs_b1},mu_Higgs_b2=${mu_Higgs_b2},mu_Zboson_pt0=${mu_Zboson_pt0},mu_Zboson_pt1=${mu_Zboson_pt1},mu_Zboson_pt2=${mu_Zboson_pt2},mu_Zboson_pt3=${mu_Zboson_pt3},mu_ttbar_b0=${mu_ttbar_b0},mu_ttbar_b1=${mu_ttbar_b1},mu_ttbar_b2=${mu_ttbar_b2} -o output/${outname} --savefitresult 1 --saveWS true --ssname quickfit --minStrat ${minStrat} --minTolerance ${minTolerance} --hesse ${hesse} --minos ${minos} ${fix} --NPExtGaussConstr alpha_JET_MassRes_WZ_comb_0=${extconst_massres_wz_0},alpha_JET_MassRes_WZ_comb_1=${extconst_massres_wz_1},alpha_JET_MassRes_WZ_comb_2=${extconst_massres_wz_2}"
    if ! $CONDOR; then
      echo "Running job locally: ${cmd}"
      eval $cmd
    else
      send_to_condor "\"$cmd\""
    fi
  done
fi

# Run CRttbar (inclusive) fit 
if $do_CRttbar_inc; then
  title='CRttbar'
  mu_ttbar='1_0_2'
  minStrat='2'
  minTolerance='1e-4'
  hesse='1'
  # Set default minos value
  if [ ! $MINOS ]; then
    minos=3
  else
    minos=$MINOS
  fi
  # Set default fix value
  if [ ! $FIX ]; then
    fix=""
  else
    fix="-n ${FIX}"
  fi
  for dtype in $DTYPE; do
    outname="${title}_${dtype}_${TAG}_minos${minos}${nom}.root"
    cmd="quickFit -f workspace/hbbj/${title}/${title}_model_${dtype}_${TAG}.root -d combData -p mu_ttbar=${mu_ttbar} -o output/${outname} --savefitresult 1 --saveWS true --ssname quickfit --minStrat ${minStrat} --minTolerance ${minTolerance} --hesse ${hesse} --minos ${minos} ${fix}"
    if ! $CONDOR; then
      echo "Running job locally: ${cmd}"
      eval $cmd
    else
      send_to_condor "\"$cmd\""
    fi
  done
fi

# Run CRttbar (pT bins) fit
if $do_CRttbar_bins; then
  mu_ttbar='1_0_2'
  minStrat='2'
  minTolerance='1e-4'
  hesse='1'
  # Set default minos value
  if [ ! $MINOS ]; then
    minos=3
  else
    minos=$MINOS
  fi
  # Set default fix value
  if [ ! $FIX ]; then
    fix=""
  else
    fix="-n ${FIX}"
  fi
  for dtype in $DTYPE; do
    for bin in '0' '1' '2'; do
      title="CRttbar_b${bin}"
      outname="${title}_${dtype}_${TAG}_minos${minos}${nom}.root"
      cmd="quickFit -f workspace/hbbj/${title}/${title}_model_${dtype}_${TAG}.root -d combData -p mu_ttbar_b${bin}=${mu_ttbar} -o output/${outname} --savefitresult 1 --saveWS true --ssname quickfit --minStrat ${minStrat} --minTolerance ${minTolerance} --hesse ${hesse} --minos ${minos} ${fix}"
    if ! $CONDOR; then
      echo "Running job locally: ${cmd}"
      eval $cmd
    else
      send_to_condor "\"$cmd\""
    fi
    done
  done
fi

# Return to base directory
cd ..

# Unset variables after use
unset TAG MODE FIX MINOS