#!/bin/bash
# Title		    : run_modelMaker.sh
# Description : Script for running modelMaker on the hbbjet analysis regions. 
# Author		  : fcelli 

SCRIPT=$(basename $0)

usage() {
  printf "%s\n\n" "From within xmlfit_boostedhbb/:"
  printf "\t%s\n\n" "bash $SCRIPT --tag <TAG> --jpath <JPATH> --mode <MODE> [--condor --help]"
  printf "%s\n\n" "Options:"
  # --tag TAG
  printf "\t%-20s\n" "--tag TAG"
    printf "\t\t%s\n" "TAG is the production name tag"
    printf "\n"
  # --jpath JPATH
  printf "\t%-20s\n" "--jpath JPATH"
    printf "\t\t%s\n" "JPATH is the json file directory path"
    printf "\n"
  # --mode MODE
  printf "\t%-20s\n" "--mode MODE"
    printf "\t\t%s\n" "- MODE=SR_inc: run on SR inclusive"
    printf "\t\t%s\n" "- MODE=SR_STXS_Z_inc: run on SR STXS Z(inclusive) bins"
    printf "\t\t%s\n" "- MODE=SR_STXS_H_inc: run on SR STXS H(inclusive) bins"
    printf "\t\t%s\n" "- MODE=SR_STXS_H_ggF: run on SR STXS H(ggF) bins"
    printf "\t\t%s\n" "- MODE=SR: run on all SR modes"
    printf "\t\t%s\n" "- MODE=CRttbar_inc: run on CRttbar inclusive"
    printf "\t\t%s\n" "- MODE=CRttbar_bins: run on CRttbar pT bins"
    printf "\t\t%s\n" "- MODE=CRttbar: run on all CRttbar modes"
    printf "\t\t%s\n" "- MODE=all: run on everything"
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

# Parse arguments
unset TAG JPATH MODE
CONDOR=false
while [ "$1" != "" ]; do
  case $1 in
    --tag )
      shift
      TAG=$1
      ;;
    --jpath )
      shift
      JPATH=$1
      ;;
    --mode )
      shift
      MODE=$1
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
if [ ! $TAG ] || [ ! $JPATH ] || [ ! $MODE ]; then
  usage
  exit 1
fi

# Handle condor job submission
condor_prefix=""
if $CONDOR; then
  echo "Submitting jobs to HTCondor..."
  cd submit_condor
  for dir in 'log' 'error' 'output'; do
    if ! test -d $dir; then
      echo "Creating ${dir} directory..."
      mkdir $dir
    fi
  done
  condor_prefix=". submit_condor.sh "
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
  SR )
    do_SR_inc=true
    do_SR_STXS_Z_inc=true
    do_SR_STXS_H_inc=true
    do_SR_STXS_H_ggF=true
    ;;
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
  CRttbar )
    do_CRttbar_inc=true
    do_CRttbar_bins=true
    ;;
  CRttbar_inc )
    do_CRttbar_inc=true
    ;;
  CRttbar_bins )
    do_CRttbar_bins=true
    ;;
  all )
    do_CRttbar_inc=true
    do_CRttbar_bins=true
    do_SR_inc=true
    do_SR_STXS_Z_inc=true
    do_SR_STXS_H_inc=true
    do_SR_STXS_H_ggF=true
    ;;
  * )
    printf "Error: unexpected MODE value.\n"
    exit 1
esac

#---------------------------------------------------------------------------------------------------------
# Run modelMaker

# Run on SR inclusive
if $do_SR_inc; then
  echo "Running on SR inclusive..."
  title="SR"
  binw="5"
  for reg in 'l' 's'; do
    cmd="${condor_prefix}python modelMaker/simple_auto.py ${JPATH}SR${reg^}.json ${binw} ${title} ${TAG} -c ${reg}"
    echo $cmd
    eval $cmd
  done
fi

# Run on SR STXS Z(inclusive) bins
if $do_SR_STXS_Z_inc; then
  echo "Running on SR_STXS_Z_inc bins..."
  title="SR_STXS_Z_inc"
  binw="5"
  for reg in 'l' 's'; do
    for bin in '0' '1' '2'; do
      if [ "${reg}" == "l" ] && [ "${bin}" == "0" ]; then
        continue
      fi
      cmd="${condor_prefix}python modelMaker/simple_auto.py ${JPATH}STXS_Z_inc_SR${reg^}${bin}.json ${binw} ${title} ${TAG} -c ${reg} -b ${bin}"
      echo $cmd
      eval $cmd
    done
  done 
fi

# Run on SR STXS H(inclusive) bins
if $do_SR_STXS_H_inc; then
  echo "Running on SR_STXS_H_inc bins..."
  title="SR_STXS_H_inc"
  binw="5"
  for reg in 'l' 's'; do
    for bin in '0' '1' '2'; do
      if [ "${reg}" == "l" ] && [ "${bin}" == "0" ]; then
        continue
      fi
      cmd="${condor_prefix}python modelMaker/simple_auto.py ${JPATH}STXS_H_inc_SR${reg^}${bin}.json ${binw} ${title} ${TAG} -c ${reg} -b ${bin}"
      echo $cmd
      eval $cmd
    done
  done 
fi

# Run on SR STXS H(ggF) bins
if $do_SR_STXS_H_ggF; then
  echo "Running on SR_STXS_H_ggF bins..."
  title="SR_STXS_H_ggF"
  binw="5"
  for reg in 'l' 's'; do
    for bin in '0' '1' '2'; do
      if [ "${reg}" == "l" ] && [ "${bin}" == "0" ]; then
        continue
      fi
      cmd="${condor_prefix}python modelMaker/simple_auto.py ${JPATH}STXS_H_ggF_SR${reg^}${bin}.json ${binw} ${title} ${TAG} -c ${reg} -b ${bin}"
      echo $cmd
      eval $cmd
    done
  done 
fi

# Run on CRttbar inclusive
if $do_CRttbar_inc; then
  echo "Running on CRttbar inclusive..."
  title="CRttbar"
  binw="5"
  cmd="${condor_prefix}python modelMaker/simple_auto.py ${JPATH}CRttbar.json ${binw} ${title} ${TAG}"
  echo $cmd
  eval $cmd
fi

# Run on CRttbar pT bins
if $do_CRttbar_bins; then
  echo "Running on CRttbar pT bins..."
  title="CRttbar"
  binw="5"
  for bin in '0' '1' '2'; do
    cmd="${condor_prefix}python modelMaker/simple_auto.py ${JPATH}CRttbar_b${bin}.json ${binw} ${title} ${TAG} -b ${bin}"
    echo $cmd
    eval $cmd
  done
fi

# Return to base dir after condor submission
if $CONDOR; then
  cd ..
fi

unset TAG JPATH MODE