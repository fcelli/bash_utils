#!/bin/bash
#title		    :run_modelMaker.sh
#description	:Script for running modelMaker on the hbbjet analysis regions. 
#author		    :fcelli 

SCRIPT=$(basename $0)

#bin widths
BINW_CRTTBAR=5
BINW_SR=5

usage() {
  printf "%s\n\n" "From within xmlfit_boostedhbb/:"
  printf "\t%s\n\n" "bash $SCRIPT --tag <TAG> --jpath <JPATH> --mode <MODE> [--condor --help]"
  printf "%s\n\n" "Options:"
  #-t, --tag TAG
  printf "\t%-20s\n" "--tag TAG"
    printf "\t\t%s\n" "TAG is the production name tag"
    printf "\n"
  #-p, --jpath JPATH
  printf "\t%-20s\n" "--jpath JPATH"
    printf "\t\t%s\n" "JPATH is the json file directory path"
    printf "\n"
  #-m, --mode MODE
  printf "\t%-20s\n" "--mode MODE"
    printf "\t\t%s\n" "- MODE=CRttbar_incl: run on CRttbar inclusive"
    printf "\t\t%s\n" "- MODE=CRttbar_bins: run on CRttbar pT bins"
    printf "\t\t%s\n" "- MODE=CRttbar: run on all CRttbar modes"
    printf "\t\t%s\n" "- MODE=SR_incl: run on SR inclusive"
    printf "\t\t%s\n" "- MODE=SR_STXS_incZ: run on SR STXS incZ bins"
    printf "\t\t%s\n" "- MODE=SR: run on all SR modes"
    printf "\t\t%s\n" "- MODE=all: run on everything"
    printf "\n"
  #-c, --condor
  printf "\t%-20s\n" "--condor"
    printf "\t\t%s\n" "Submit jobs to HTCondor"
    printf "\n"
  #-h, --help
  printf "\t%-20s\n" "-h, --help"
    printf "\t\t%s\n" "Display this help and exit"
    printf "\n"
}

#parse arguments
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

#mandatory arguments check
if [ ! $TAG ] || [ ! $JPATH ] || [ ! $MODE ]; then
  usage
  exit 1
fi

#handle condor job submission
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

#initialise mode variables
do_CRttbar_incl=false
do_CRttbar_bins=false
do_SR_incl=false
do_SR_STXS_incZ=false

#run options
case $MODE in
  CRttbar )
    do_CRttbar_incl=true
    do_CRttbar_bins=true
    ;;
  CRttbar_incl )
    do_CRttbar_incl=true
    ;;
  CRttbar_bins )
    do_CRttbar_bins=true
    ;;
  SR )
    do_SR_incl=true
    do_SR_STXS_incZ=true
    ;;
  SR_incl )
    do_SR_incl=true
    ;;
  SR_STXS_incZ )
    do_SR_STXS_incZ=true
    ;;
  all )
    do_CRttbar_incl=true
    do_CRttbar_bins=true
    do_SR_incl=true
    do_SR_STXS_incZ=true
    ;;
  * )
    printf "Error: unexpected MODE value.\n"
    exit 1
esac

#---------------------------------------------------------------------------------------------------------
#run modelMaker

#run on CRttbar inclusive
if $do_CRttbar_incl; then
  echo "Running on CRttbar inclusive..."
  title="CRttbar"
  cmd="${condor_prefix}python modelMaker/simple_auto.py ${JPATH}CRttbar.json ${BINW_CRTTBAR} ${title} ${TAG}"
  echo $cmd
  eval $cmd
fi

#run on CRttbar pT bins
if $do_CRttbar_bins; then
  echo "Running on CRttbar pT bins..."
  title="CRttbar"
  for bin in '0' '1' '2'; do
    cmd="${condor_prefix}python modelMaker/simple_auto.py ${JPATH}CRttbar_b${bin}.json ${BINW_CRTTBAR} ${title} ${TAG} -b ${bin}"
    echo $cmd
    eval $cmd
  done
fi

#run on SR inclusive
if $do_SR_incl; then
  echo "Running on SR inclusive..."
  title="SR"
  for reg in 'lead' 'sublead'; do
    cmd="${condor_prefix}python modelMaker/simple_auto.py ${JPATH}AsimovSR_${reg}.json ${BINW_SR} ${title} ${TAG} -c ${reg:0:1}"
    echo $cmd
    eval $cmd
  done
fi

#run on SR STXS incZ bins
if $do_SR_STXS_incZ; then
  echo "Running on SR STXS incZ bins..."
  title="SR_STXS_incZ"
  for reg in 'l' 's'; do
    for bin in '0' '1' '2'; do
      if [ "${reg}" == "l" ] && [ "${bin}" == "0" ]; then
        continue
      fi
      cmd="${condor_prefix}python modelMaker/simple_auto.py ${JPATH}STXS_incZ_AsimovSR${reg^}${bin}.json ${BINW_SR} ${title} ${TAG} -c ${reg} -b ${bin}"
      echo $cmd
      eval $cmd
    done
  done 
fi

#return to base dir after condor submission
if $CONDOR; then
  cd ..
fi

unset TAG JPATH MODE