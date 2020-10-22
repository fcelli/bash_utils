#!/bin/bash
#title          :run_quickFit.sh
#description    :Script for running quickFit on the hbbjet analysis regions. 
#author         :fcelli 

SCRIPT=$(basename $0)

usage() {
  printf "%s\n\n" "From within xmlfit_boostedhbb/:"
  printf "\t%s\n\n" "bash path/to/$SCRIPT --tag <TAG> --mode <MODE> [--fix <FIX> --dtype <DTYPE> --minos <MINOS> --nom --condor --help]"
  printf "%s\n\n" "Options:"
  #--tag TAG
  printf "\t%-20s\n" "--tag TAG"
    printf "\t\t%s\n" "TAG is the production name tag"
    printf "\n"
  #--mode MODE
  printf "\t%-20s\n" "--mode MODE"
    printf "\t\t%s\n" "- MODE=Comb: run combined fit"
    printf "\t\t%s\n" "- MODE=STXS_incZ: run STXS fit (inclusive Z)"
    printf "\t\t%s\n" "- MODE=CRttbarOnly_incl: run CRttbar-only fit (inclusive)"
    printf "\t\t%s\n" "- MODE=CRttbarOnly_bins: run CRttbar-only fit (pT bins)"
    printf "\t\t%s\n" "- MODE=CRttbarOnly: run CRttbar-only fit (inclusive and pT bins)"
    printf "\t\t%s\n" "- MODE=all: run fits in all defined regions"
    printf "\n"
  #--fix FIX
  printf "\t%-20s\n" "--fix FIX"
    printf "\t\t%s\n" "FIX is the list of fixed nuisance parameters"
    printf "\n"
  #--dtype DTYPE
  printf "\t%-20s\n" "--dtype DTYPE[=all]"
    printf "\t\t%s\n" "- DTYPE=data: run on data"
    printf "\t\t%s\n" "- DTYPE=asimov: run on asimov"
    printf "\t\t%s\n" "- DTYPE=all: run on data and asimov"
    printf "\n"
  #--minos MINOS
  printf "\t%-20s\n" "--minos MINOS"
    printf "\t\t%s\n" "- MINOS=1: run scans only on parameters of interest"
    printf "\t\t%s\n" "- MINOS=3: run scans on all nuisance parameters"
    printf "\n"
  #--nom
  printf "\t%-20s\n" "--nom"
    printf "\t\t%s\n" "Run a nominal fit"
    printf "\n"
  #--condor
  printf "\t%-20s\n" "--condor"
    printf "\t\t%s\n" "Submit jobs to HTCondor"
    printf "\n"
  #-h, --help
  printf "\t%-20s\n" "-h, --help"
    printf "\t\t%s\n" "Display this help and exit"
    printf "\n"
}

#parse arguments
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

#mandatory arguments check
if [ ! $TAG ] || [ ! $MODE ]; then
  usage
  exit 1
fi

#establish data type
if [ "$DTYPE" == 'all' ]; then
  DTYPE='data asimov'
elif [ "$DTYPE" != 'asimov' ] && [ "$DTYPE" != 'data' ]; then
  echo "Error: unexpected DTYPE value."
  exit 1
fi

#setup nominal run
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

#initialise mode variables
do_Comb=false
do_STXS_incZ=false
do_CRttbarOnly_incl=false
do_CRttbarOnly_bins=false

#run options
case $MODE in
  Comb )
    do_Comb=true
    ;;
  STXS_incZ )
    do_STXS_incZ=true
    ;;
  CRttbarOnly )
    do_CRttbarOnly_incl=true
    do_CRttbarOnly_bins=true
    ;;
  CRttbarOnly_incl )
    do_CRttbarOnly_incl=true
    ;;
  CRttbarOnly_bins )
    do_CRttbarOnly_bins=true
    ;;
  all )
    do_Comb=true
    do_STXS_incZ=true
    do_CRttbarOnly_incl=true
    do_CRttbarOnly_bins=true
    ;;
  * )
    printf "Error: unexpected MODE value.\n"
    exit 1
esac

cd quickFit
#create output directory
if ! test -d output; then
  mkdir output
fi

#handle condor job submission
condor_prefix=""
if $CONDOR; then
  echo "Submitting jobs to HTCondor..."
  cd submit_condor
  for dir in 'log' 'err' 'out'; do
    if ! test -d $dir; then
      echo "Creating ${dir} directory..."
      mkdir $dir
    fi
  done
  condor_prefix=". submit_condor.sh "
fi

#-------------------------------------------------------------------------------------------------
#run quickFit

#run combined fit
if $do_Comb; then
  title='Comb'
  mu_Higgs='1_-10_11'
  mu_Zboson='1_-3_5'
  mu_ttbar='1_0.5_1.5'
  minStrat='1'
  minTolerance='1e-4'
  hesse='1'
  #set default minos value
  if [ ! $MINOS ]; then
    minos=1
  else
    minos=$MINOS
  fi
  #set default fix value
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
    cmd="${condor_prefix}quickFit -f workspace/hbbj/${title}/${title}_model_${dtype}_${TAG}.root -d combData -p mu_Zboson=${mu_Zboson},mu_Higgs=${mu_Higgs},mu_ttbar=${mu_ttbar} -o output/${outname} --savefitresult 1 --saveWS true --ssname quickfit --minStrat ${minStrat} --minTolerance ${minTolerance} --hesse ${hesse} --minos ${minos} ${fix}"
    echo $cmd
    eval $cmd
  done
fi

#run STXS incZ fit
if $do_STXS_incZ; then
  title='STXS_incZ'
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
  #set default minos value
  if [ ! $MINOS ]; then
    minos=3
  else
    minos=$MINOS
  fi
  #set default fix value
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
    cmd="${condor_prefix}quickFit -f workspace/hbbj/${title}/${title}_model_${dtype}_${TAG}.root -d combData -p mu_Higgs_b0=${mu_Higgs_b0},mu_Higgs_b1=${mu_Higgs_b1},mu_Higgs_b2=${mu_Higgs_b2},mu_Zboson_pt0=${mu_Zboson_pt0},mu_Zboson_pt1=${mu_Zboson_pt1},mu_Zboson_pt2=${mu_Zboson_pt2},mu_Zboson_pt3=${mu_Zboson_pt3},mu_ttbar_b0=${mu_ttbar_b0},mu_ttbar_b1=${mu_ttbar_b1},mu_ttbar_b2=${mu_ttbar_b2} -o output/${outname} --savefitresult 1 --saveWS true --ssname quickfit --minStrat ${minStrat} --minTolerance ${minTolerance} --hesse ${hesse} --minos ${minos} ${fix}"
    echo $cmd
    eval $cmd
  done
fi

#return to base dir after condor submission
if $CONDOR; then
  cd ..
fi

#return to base directory
cd ..

unset TAG MODE FIX MINOS