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
  printf "\t%s\n\n" "bash $SCRIPT --tag <TAG> --mode <MODE> [--poi <POI> --dtype <DTYPE> --help]"
  printf "%s\n\n" "Options:"
  #-t, --tag TAG
  printf "\t%-20s\n" "-t, --tag TAG"
	printf "\t\t%s\n" "TAG is the production name tag"
        printf "\n"
  #-m, --mode MODE
  printf "\t%-20s\n" "-m, --mode MODE" 
	printf "\t\t%s\n" "- MODE=Comb: create combined fit xml cards"
        printf "\t\t%s\n" "- MODE=STXS_incZ: create STXS fit xml cards (inclusive Z)"
	printf "\t\t%s\n" "- MODE=CRttbarOnly_incl: create CRttbar-only fit xml cards (inclusive)"
	printf "\t\t%s\n" "- MODE=CRttbarOnly_bins: create CRttbar-only fit xml cards (pT bins)"
	printf "\t\t%s\n" "- MODE=CRttbarOnly: create CRttbar-only fit xml cards (inclusive and pT bins)"
	printf "\t\t%s\n" "- MODE=all: create xml cards for all defined regions"
        printf "\n"
  #-p, --poi POI
  printf "\t%-20s\n" "-p, --poi POI"
	printf "\t\t%s\n" "POI is the parameter of interest"
        printf "\n"
  #-d, --dtype DTYPE
  printf "\t%-20s\n" "-d, --dtype DTYPE[=all]"
	printf "\t\t%s\n" "- DTYPE=data: run on data"
	printf "\t\t%s\n" "- DTYPE=asimov: run on asimov"
	printf "\t\t%s\n" "- DTYPE=all: run on data and asimov"
        printf "\n"
  #-h, --help
  printf "\t%-20s\n" "-h, --help"
	printf "\t\t%s\n" "Display this help and exit"
        printf "\n"
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
do_STXS_incZ=false
do_CRttbarOnly_incl=false
do_CRttbarOnly_bins=false

#run options
case $MODE in
  Comb )		do_Comb=true 
                        ;;
  STXS_incZ )		do_STXS_incZ=true
			;;
  CRttbarOnly )		do_CRttbarOnly_incl=true
			do_CRttbarOnly_bins=true
                        ;;
  CRttbarOnly_incl )	do_CRttbarOnly_incl=true
			;;
  CRttbarOnly_bins )	do_CRttbarOnly_bins=true
			;;
  all )			do_Comb=true
			do_STXS_incZ=true
			do_CRttbarOnly_incl=true
                        do_CRttbarOnly_bins=true
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
    poi=""
  else
    poi="--poi ${POI}"
  fi
  for dtype in $DTYPE; do
    #generate xml cards
    cmd="python genxml/generate.py SR_l__${TAG} SR_s__${TAG} CRttbar__${TAG} --title ${title} --tag ${dtype}_${TAG} --bins ${nbins_SRL} ${nbins_SRS} ${nbins_CRttbar} --fr '[${m_min_SRL},${m_max_SRL}]' '[${m_min_SRS},${m_max_SRS}]' '[${m_min_CRttbar},${m_max_CRttbar}]' --data ${dtype} ${dtype} ${dtype} --qcd srl srs None ${poi}"
    echo $cmd
    eval $cmd
    #read xml cards
    cd xmlAnaWSBuilder
    cmd="./exe/XMLReader -x config/hbbj/${title}_${dtype}_${TAG}/${title}.xml" 
    echo $cmd
    eval $cmd
    cd ..
  done
fi

#generate and read STXS incZ xml cards
if $do_STXS_incZ; then
  title='STXS_incZ'
  if [ ! $POI ]; then
    #set default poi value
    poi=""
  else
    poi="--poi ${POI}"
  fi
  for dtype in $DTYPE; do
    #generate xml cards
    cmd="python genxml/generate.py STXS_incZ_l1__${TAG} STXS_incZ_l2__${TAG} STXS_incZ_s0__${TAG} STXS_incZ_s1__${TAG} STXS_incZ_s2__${TAG} CRttbar_0__${TAG} CRttbar_1__${TAG} CRttbar_2__${TAG} --title ${title} --tag ${dtype}_${TAG} --bins 290 280 280 280 270 ${nbins_CRttbar} ${nbins_CRttbar} ${nbins_CRttbar} --fr '[65,210]' '[70,210]' '[70,210]' '[70,210]' '[75,210]' '[${m_min_CRttbar},${m_max_CRttbar}]' '[${m_min_CRttbar},${m_max_CRttbar}]' '[${m_min_CRttbar},${m_max_CRttbar}]' --data ${dtype} ${dtype} ${dtype} ${dtype} ${dtype} ${dtype} ${dtype} ${dtype} --qcd srl1 srl2_a srs0_a srs1 srs2 None None None --qcdsy 5e5 5e5 5e5 5e5 5e5 ${poi}"
    echo $cmd
    eval $cmd
    #read xml cards
    cd xmlAnaWSBuilder
    cmd="./exe/XMLReader -x config/hbbj/${title}_${dtype}_${TAG}/${title}.xml"
    echo $cmd
    eval $cmd
    cd ..
  done
fi

#generate and read CRttbarOnly xml cards (inclusive)
if $do_CRttbarOnly_incl; then
  title='CRttbarOnly'
  if [ ! $POI ]; then
    #set default poi value
    poi="--poi mu_ttbar"
  else
    poi="--poi ${POI}"
  fi
  for dtype in $DTYPE; do
    #generate xml cards
    cmd="python genxml/generate.py CRttbar__${TAG} --title ${title} --tag ${dtype}_${TAG} --data ${dtype} --bins ${nbins_CRttbar} --fr '[${m_min_CRttbar},${m_max_CRttbar}]' ${poi}"
    echo $cmd
    eval $cmd
    #read xml cards
    cd xmlAnaWSBuilder
    cmd="./exe/XMLReader -x config/hbbj/${title}_${dtype}_${TAG}/${title}.xml"
    echo $cmd
    eval $cmd
    cd ..
  done
fi

#generate and read CRttbarOnly xml cards (pT bins)
if $do_CRttbarOnly_bins; then
  for bin in '0' '1' '2'; do
    title="CRttbarOnly_b${bin}"
    if [ ! $POI ]; then
      #set default poi value
      poi="--poi mu_ttbar_b${bin}"
    else
      poi="--poi ${POI}"
    fi
    for dtype in $DTYPE; do
      #generate xml cards
      cmd="python genxml/generate.py CRttbar_${bin}__${TAG} --title ${title} --tag ${dtype}_${TAG} --data ${dtype} --bins ${nbins_CRttbar} --fr '[${m_min_CRttbar},${m_max_CRttbar}]' ${poi}"
      echo $cmd
      eval $cmd
      #read xml cards
      cd xmlAnaWSBuilder
      cmd="./exe/XMLReader -x config/hbbj/${title}_${dtype}_${TAG}/${title}.xml"
      echo $cmd
      eval $cmd
      cd ..
    done
  done
fi

unset TAG MODE POI
