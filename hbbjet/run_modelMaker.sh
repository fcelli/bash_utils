#!/bin/bash
#title		:run_modelMaker.sh
#description	:Script for running modelMaker on the hbbjet analysis regions. 
#author		:fcelli 

SCRIPT=$(basename $0)

#bin widths
BINW_CRTTBAR=5
BINW_SR=0.5

usage() {
  printf "%s\n\n" "From within xmlfit_boostedhbb/:"
  printf "\t%s\n\n" "bash $SCRIPT --tag <TAG> --jpath <JPATH> --mode <MODE> [--condor]"
  printf "%s\n\n" "Options:"
  printf "\t%-20s\n\t\t%s\n\n" "-t, --tag TAG" "TAG is the production name tag"
  printf "\t%-20s\n\t\t%s\n\n" "-p, --jpath JPATH" "JPATH is the json file directory path"
  printf "\t%-20s\n\t\t%s\n\t\t%s\n\t\t%s\n\t\t%s\n\t\t%s\n\n" "-m, --mode MODE" "- MODE=CRttbar_incl: run on CRttbar inclusive" "- MODE=CRttbar_bins: run on CRttbar pT bins" "- MODE=CRttbar: run on CRttbar inclusive and pT bins" "- MODE=SR_incl: run on SR inclusive" "- MODE=all: run on everything"
  printf "\t%-20s\n\t\t%s\n\n" "-c, --condor" "Submit jobs to HTCondor"
  printf "\t%-20s\n\t\t%s\n\n" "-h, --help" "Display this help and exit"
}

#parse arguments
unset TAG JPATH MODE
CONDOR=false
while [ "$1" != "" ]; do
  case $1 in
    -t | --tag )	shift
			TAG=$1
			;;
    -p | --jpath )	shift
			JPATH=$1
			;;
    -m | --mode )	shift
			MODE=$1
			;;
    -c | --condor )	CONDOR=true
			;;
    -h | --help )	usage
			exit
			;;
    * )			usage
			exit 1
  esac
  shift
done

#mandatory arguments check
if [ ! $TAG ] || [ ! $JPATH ] || [ ! $MODE ]; then
  usage
  exit
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

#run options
case $MODE in
  CRttbar )		do_CRttbar_incl=true
			do_CRttbar_bins=true
			;;
  CRttbar_incl )	do_CRttbar_incl=true
			;;
  CRttbar_bins )	do_CRttbar_bins=true
			;;
  SR_incl )		do_SR_incl=true
         		;;
  all )                 do_CRttbar_incl=true
			do_CRttbar_bins=true
			do_SR_incl=true
			;;
  * )    		printf "Error: unexpected MODE argument.\n"
         		exit 1
esac

#---------------------------------------------------------------------------------------------------------
#run modelMaker

#run on CRttbar inclusive
if $do_CRttbar_incl; then
  echo "Running on CRttbar inclusive..."
  cmd="${condor_prefix}python modelMaker/simple_auto.py ${JPATH}CRttbar.json ${BINW_CRTTBAR} CRttbar ${TAG}"
  echo $cmd
  eval $cmd
fi

#run on CRttbar pT bins
if $do_CRttbar_bins; then
  echo "Running on CRttbar pT bins..."
  for bin in '0' '1' '2'; do
    cmd="${condor_prefix}python modelMaker/simple_auto.py ${JPATH}CRttbar_b${bin}.json ${BINW_CRTTBAR} CRttbar ${TAG} -b ${bin}"
    echo $cmd
    eval $cmd
  done
fi

#run on SR inclusive
if $do_SR_incl; then
  echo "Running on SR inclusive..."
  for reg in 'lead' 'sublead'; do
    cmd="${condor_prefix}python modelMaker/simple_auto.py ${JPATH}AsimovSR_${reg}.json ${BINW_SR} SR ${TAG} -c ${reg:0:1}"
    echo $cmd
    eval $cmd
  done
fi

#return to base dir after condor submission
if $CONDOR; then
  cd ..
fi

unset TAG JPATH MODE
