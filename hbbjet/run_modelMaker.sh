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
  printf "\t%s\n\n" "bash $SCRIPT -t <TAG> -p <JPATH> -m <MODE>"
  printf "%s\n\n" "Options:"
  printf "\t%-20s\n\t\t%s\n\n" "-t, --tag TAG" "TAG is the production name tag"
  printf "\t%-20s\n\t\t%s\n\n" "-p, --jpath JPATH" "JPATH is the json file directory path"
  printf "\t%-20s\n\t\t%s\n\t\t%s\n\t\t%s\n\t\t%s\n\t\t%s\n\n" "-m, --mode MODE" "- MODE=CRttbar_incl: run on CRttbar inclusive" "- MODE=CRttbar_bins: run on CRttbar pT bins" "- MODE=CRttbar: run on CRttbar inclusive and pT bins" "- MODE=SR_incl: run on SR inclusive" "- MODE=all: run on everything"
  printf "\t%-20s\n\t\t%s\n\n" "-h, --help" "Display this help and exit"
}

#parse arguments
unset TAG JPATH MODE
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
  cmd="python modelMaker/simple_auto.py ${JPATH}CRttbar.json ${BINW_CRTTBAR} CRttbar ${TAG}"
  echo $cmd
  eval $cmd
fi

#run on CRttbar pT bins
if $do_CRttbar_bins; then
  echo "Running on CRttbar pT bins..."
  for bin in '0' '1' '2'; do
    cmd="python modelMaker/simple_auto.py ${JPATH}CRttbar_b${bin}.json ${BINW_CRTTBAR} CRttbar ${TAG} -b ${bin}"
    echo $cmd
    eval $cmd
  done
fi

#run on SR inclusive
if $do_SR_incl; then
  echo "Running on SR inclusive..."
  for reg in 'lead' 'sublead'; do
    cmd="python modelMaker/simple_auto.py ${JPATH}AsimovSR_${reg}.json ${BINW_SR} SR ${TAG} -c ${reg:0:1}"
    echo $cmd
    eval $cmd
  done
fi

unset TAG JPATH MODE
