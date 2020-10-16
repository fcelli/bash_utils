#!/bin/bash
#title          :run_modelMaker_CRttbar.sh
#description    :Script for running modelMaker on the CRttbar region. 
#author         :fcelli 

SCRIPT=$(basename $0)

usage() {
  printf "%s\n\n" "From within xmlfit_boostedhbb/:"
  printf "\t%s\n\n" "bash $SCRIPT -t <tag> -p <json_path> -r <run_type>"
  printf "%s\n\n" "Options:"
  printf "\t%-20s\n\t\t%-20s\n\n" "-t, --tag TAG" "TAG is the production name tag."
  printf "\t%-20s\n\t\t%-20s\n\n" "-p, --jpath JPATH" "JPATH is the json file directory path."
  printf "\t%-20s\n\t\t%-20s\n\n" "-m, --mode MODE" "MODE=incl: run inclusive-only, MODE=bins: run on pT bins only, MODE=all: run on both."
  printf "\t%-20s\n\t\t%-20s\n\n" "-h, --help:" "Display this help and exit."
}

#parse arguments
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

#run options
case $MODE in
  incl )	do_incl=true
        	do_bins=false
         	;;
  bins )	do_incl=false
         	do_bins=true
         	;;
  all )  	do_incl=true
        	do_bins=true
         	;;
  * )    	printf "Error: unexpected -r|--run argument.\n"
         	exit 1
esac

#run modelMaker
if $do_incl; then
  echo "Running on Inclusive..."
  cmd="python modelMaker/simple_auto.py ${JPATH}CRttbar.json 5 CRttbar ${TAG}"
  echo $cmd
  eval $cmd
fi

if $do_bins; then
  echo "Running on pT bins..."
  for bin in '0' '1' '2'; do
    cmd="python modelMaker/simple_auto.py ${JPATH}CRttbar_b${bin}.json 5 CRttbar ${TAG} -b ${bin}"
    echo $cmd
    eval $cmd
  done
fi

unset TAG JPATH MODE
