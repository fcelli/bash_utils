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
  # Signal strengths
  mu_Higgs='-0.133518_-20_20'
  mu_Zboson='1.34684_-2_4'
  mu_ttbar='0.806336_0.5_1.5'
  # QCD parameters (SRL)
  yield_QCD_srl='591979_5e5_8e5'
  c_srl='-0.657705_-1_0'
  d_srl='-0.0640925_-5_5'
  e_srl='-0.144159_-5_5'
  f_srl='0.041925_-10_10'
  g_srl='0.0804319_-10_10'
  h_srl='0'
  # QCD parameters (SRS)
  yield_QCD_srs='530411_4e5_7e5'
  c_srs='-0.741208_-1_0'
  d_srs='-0.170478_-5_5'
  e_srs='-0.0517586_-5_5'
  f_srs='0.0192332_-10_10'
  g_srs='-0.0097926_-10_10'
  h_srs='0'
  # Gaussian external constraints
  extconst_massres_wz='0.054_0.146'
  # Fit options
  minStrat='1'
  minTolerance='1e-5'
  hesse='1'
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
    p_opt="mu_Zboson=${mu_Zboson},mu_Higgs=${mu_Higgs},mu_ttbar=${mu_ttbar},yield_QCD_srl=${yield_QCD_srl},c_srl=${c_srl},d_srl=${d_srl},e_srl=${e_srl},f_srl=${f_srl},g_srl=${g_srl},h_srl=${h_srl},yield_QCD_srs=${yield_QCD_srs},c_srs=${c_srs},d_srs=${d_srs},e_srs=${e_srs},f_srs=${f_srs},g_srs=${g_srs},h_srs=${h_srs}"
    outname="${title}_${dtype}_${TAG}_minos${minos}${nom}.root"
    cmd="quickFit -f workspace/hbbj/${title}/${title}_model_${dtype}_${TAG}.root -d combData -p ${p_opt} -o output/${outname} --savefitresult 1 --saveWS true --ssname quickfit --minStrat ${minStrat} --minTolerance ${minTolerance} --hesse ${hesse} --minos ${minos} ${fix} --printChi 1 --NPExtGaussConstr alpha_JET_MassRes_WZ_comb=${extconst_massres_wz}"
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

# Run SR STXS H(inclusive) fit
if $do_SR_STXS_H_inc; then
  title='SR_STXS_H_inc'
  # Signal strengths
  mu_Higgs_pt0='1'
  mu_Higgs_pt1='1_-50_50'
  mu_Higgs_pt2='1_-20_20'
  mu_Higgs_pt3='1_-20_20'
  mu_Zboson_b0='1_-10_10'
  mu_Zboson_b1='1_-3_5'
  mu_Zboson_b2='1_-10_10'
  mu_ttbar_b0='1_-2_4'
  mu_ttbar_b1='1_-1_3'
  mu_ttbar_b2='1_-2_4'
  # QCD parameters (SRL1)
  yield_QCD_srl1='509078_4e5_7e5'
  c_srl1='-0.663971_-5_5'
  d_srl1='-0.101571_-5_5'
  e_srl1='-0.160658_-5_5'
  f_srl1='0.0546747_-10_10'
  g_srl1='0.0803174_-10_10'
  h_srl1='0'
  # QCD parameters (SRL2)
  yield_QCD_srl2='73120.7_5e4_9e4'
  c_srl2='-0.564274_-5_5'
  d_srl2='0.137865_-5_5'
  e_srl2='-0.0365133_-5_5'
  f_srl2='-0.0185633_-10_10'
  g_srl2='0'
  h_srl2='0'
  # QCD parameters (SRS0)
  yield_QCD_srs0='170304_7e4_2e5'
  c_srs0='-1.18605_-5_5'
  d_srs0='-0.4745_-5_5'
  e_srs0='-0.0647228_-5_5'
  f_srs0='-0.287929_-10_10'
  g_srs0='-0.276652_-5_5'
  h_srs0='0'
  # QCD parameters (SRS1)
  yield_QCD_srs1='340819_1e5_6e5'
  c_srs1='-0.564257_-1_0'
  d_srs1='-0.109349_-5_5'
  e_srs1='-0.0916096_-5_5'
  f_srs1='0.053006_-10_10'
  g_srs1='0'
  h_srs1='0'
  # QCD parameters (SRS2)
  yield_QCD_srs2='47841_1e4_1e5'
  c_srs2='-0.4_-5_5'
  d_srs2='0.198449_-5_5'
  e_srs2='-0.0964363_-5_5'
  f_srs2='-0.129441_-10_10'
  g_srs2='0_-10_10'
  h_srs2='0'
  # Gaussian external constraints
  extconst_massres_wz_0='0.127_0.141'
  extconst_massres_wz_1='0.071_0.146'
  extconst_massres_wz_2='-0.018_0.212'
  # Fit options
  minStrat='1'
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
    p_opt="mu_Higgs_pt0=${mu_Higgs_pt0},mu_Higgs_pt1=${mu_Higgs_pt1},mu_Higgs_pt2=${mu_Higgs_pt2},mu_Higgs_pt3=${mu_Higgs_pt3},mu_Zboson_b0=${mu_Zboson_b0},mu_Zboson_b1=${mu_Zboson_b1},mu_Zboson_b2=${mu_Zboson_b2},mu_ttbar_b0=${mu_ttbar_b0},mu_ttbar_b1=${mu_ttbar_b1},mu_ttbar_b2=${mu_ttbar_b2},yield_QCD_srl1=${yield_QCD_srl1},c_srl1=${c_srl1},d_srl1=${d_srl1},e_srl1=${e_srl1},f_srl1=${f_srl1},g_srl1=${g_srl1},h_srl1=${h_srl1},yield_QCD_srl2=${yield_QCD_srl2},c_srl2=${c_srl2},d_srl2=${d_srl2},e_srl2=${e_srl2},f_srl2=${f_srl2},g_srl2=${g_srl2},h_srl2=${h_srl2},yield_QCD_srs0=${yield_QCD_srs0},c_srs0=${c_srs0},d_srs0=${d_srs0},e_srs0=${e_srs0},f_srs0=${f_srs0},g_srs0=${g_srs0},h_srs0=${h_srs0},yield_QCD_srs1=${yield_QCD_srs1},c_srs1=${c_srs1},d_srs1=${d_srs1},e_srs1=${e_srs1},f_srs1=${f_srs1},g_srs1=${g_srs1},h_srs1=${h_srs1},yield_QCD_srs2=${yield_QCD_srs2},c_srs2=${c_srs2},d_srs2=${d_srs2},e_srs2=${e_srs2},f_srs2=${f_srs2},g_srs2=${g_srs2},h_srs2=${h_srs2}"
    outname="${title}_${dtype}_${TAG}_minos${minos}${nom}.root"
    cmd="quickFit -f workspace/hbbj/${title}/${title}_model_${dtype}_${TAG}.root -d combData -p ${p_opt} -o output/${outname} --savefitresult 1 --saveWS true --ssname quickfit --minStrat ${minStrat} --minTolerance ${minTolerance} --hesse ${hesse} --minos ${minos} ${fix} --printChi 1 --NPExtGaussConstr alpha_JET_MassRes_WZ_comb_0=${extconst_massres_wz_0},alpha_JET_MassRes_WZ_comb_1=${extconst_massres_wz_1},alpha_JET_MassRes_WZ_comb_2=${extconst_massres_wz_2}"
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