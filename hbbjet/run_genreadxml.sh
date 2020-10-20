#!/bin/bash
#title          :run_genreadxml.sh
#description    :Script for generating and reading xml cards for the hbbjet fitting framework. 
#author         :fcelli 

SCRIPT=$(basename $0)

# SRL
nbins_SRL='280'
m_min_SRL='70'
m_max_SRL='210'

# SRS
nbins_SRS='270'
m_min_SRS='75'
m_max_SRS='210'

# CRttbar
nbins_CRttbar='12'
m_min_CRttbar='140'
m_max_CRttbar='200'

usage() {
  printf "%s\n\n" "From within xmlfit_boostedhbb/:"
  printf "\t%s\n\n" "bash $SCRIPT --tag <TAG> --mode <MODE> [--poi <POI> --dtype <DTYPE>]"
  printf "%s\n\n" "Options:"
  printf "\t%-20s\n\t\t%s\n\n" "-t, --tag TAG" "TAG is the production name tag"
  printf "\t%-20s\n\t\t%s\n\t\t%s\n\n" "-m, --mode MODE" "- MODE=Comb: create combined fit xml card" "- MODE=CRttbarOnly: create CRttbar-only fit xml card"
  printf "\t%-20s\n\t\t%s\n\n" "-p, --poi POI" "POI is the parameter of interest"
  printf "\t%-20s\n\t\t%s\n\t\t%s\n\t\t%s\n\t\t%s\n" "-d, --dtype DTYPE[=all]" "- DTYPE=data: run on data" "- DTYPE=asimov: run on asimov" "- DTYPE=all: run on data and asimov" 
  printf "\t%-20s\n\t\t%s\n\n" "-h, --help" "Display this help and exit"
}

#parse arguments
DTYPE='all'
unset TAG MODE POI
while [ "$1" != "" ]; do
  case $1 in
    -t | --tag )        shift
                        TAG=$1
                        ;;
    -m | --mode )       shift
                        MODE=$1
                        ;;
    -p | --poi )	shift
			POI=$1
                        ;;
    -d | --dtype )	shift
			DTYPE=$1
			;;
    -h | --help )       usage
                        exit 0
                        ;;
    * )                 usage
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

#initialise mode variables
do_Comb=false
do_CRttbarOnly=false

#run options
case $MODE in
  Comb )		do_Comb=true 
                        ;;
  CRttbarOnly )		do_CRttbarOnly=true
                        ;;
  * )                   printf "Error: unexpected MODE value.\n"
                        exit 1
esac

#---------------------------------------------------------------------------------------------------------
#run genreadxml

#generate and read Comb xml cards
if $do_Comb; then
  title='Comb'
  if [ ! $POI ]; then
    #set default poi value
    POI=""
  else
    POI="--poi ${POI}"
  fi
  for dtype in $DTYPE; do
    #generate xml cards
    cmd="python genxml/generate.py SR_l__${TAG} SR_s__${TAG} CRttbar__${TAG} --title ${title} --tag ${dtype}_${TAG} --bins ${nbins_SRL} ${nbins_SRS} ${nbins_CRttbar} --fr '[${m_min_SRL},${m_max_SRL}]' '[${m_min_SRS},${m_max_SRS}]' '[${m_min_CRttbar},${m_max_CRttbar}]' --data ${dtype} ${dtype} ${dtype} --qcd srl srs None ${POI}"
    echo ${cmd}
    eval ${cmd}
    #read xml cards
    cd xmlAnaWSBuilder
    cmd="./exe/XMLReader -x config/hbbj/${title}_${dtype}_${TAG}/${title}.xml" 
    echo ${cmd}
    eval ${cmd}
    cd ..
  done
fi

unset TAG MODE POI
