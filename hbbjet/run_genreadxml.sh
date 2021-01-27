#!/bin/bash
# Title          : run_genreadxml.sh
# Description    : Script for generating and reading xml cards for the hbbjet fitting framework. 
# Author         : fcelli 

SCRIPT=$(basename $0)

usage() {
  printf "%s\n\n" "From within xmlfit_boostedhbb/:"
  printf "\t%s\n\n" "bash $SCRIPT --tag <TAG> --mode <MODE> [--poi <POI> --dtype <DTYPE> --help]"
  printf "%s\n\n" "Options:"
  # --tag TAG
  printf "\t%-20s\n" "--tag TAG"
    printf "\t\t%s\n" "TAG is the production name tag"
    printf "\n"
  # --mode MODE
  printf "\t%-20s\n" "--mode MODE"
    printf "\t\t%s\n" "- MODE=SR_inc: create SR combined fit xml cards"
    printf "\t\t%s\n" "- MODE=SR_STXS_Z_inc: create SR STXS Z(inclusive) fit xml cards"
    printf "\t\t%s\n" "- MODE=SR_STXS_H_inc: create SR STXS H(inclusive) fit xml cards"
    printf "\t\t%s\n" "- MODE=SR_STXS_H_ggF: create SR STXS H(ggF) fit xml cards"
    printf "\t\t%s\n" "- MODE=SR: create fit xml cards for all SR regions"
    printf "\t\t%s\n" "- MODE=CRttbar_inc: create CRttbar fit xml cards (inclusive)"
    printf "\t\t%s\n" "- MODE=CRttbar_bins: create CRttbar fit xml cards (pT bins)"
    printf "\t\t%s\n" "- MODE=CRttbar: create CRttbar fit xml cards (inclusive and pT bins)"
    printf "\t\t%s\n" "- MODE=all: create xml cards for all defined regions"
    printf "\n"
  # --poi POI
  printf "\t%-20s\n" "--poi POI"
    printf "\t\t%s\n" "POI is the parameter of interest"
    printf "\n"
  # --dtype DTYPE
  printf "\t%-20s\n" "--dtype DTYPE[=all]"
    printf "\t\t%s\n" "- DTYPE=data: run on data"
    printf "\t\t%s\n" "- DTYPE=asimov: run on asimov"
    printf "\t\t%s\n" "- DTYPE=all: run on data and asimov"
    printf "\n"
  # -h, --help
  printf "\t%-20s\n" "-h, --help"
    printf "\t\t%s\n" "Display this help and exit"
    printf "\n"
}

# Parse arguments
DTYPE='all'
unset TAG MODE POI
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
    --poi )
      shift
      POI=$1
      ;;
    --dtype )
      shift
      DTYPE=$1
      ;;
    --help )
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

#---------------------------------------------------------------------------------------------------------
# Run genreadxml

# Bins and limits
# SRL
nbins_l='28' m_min_l='70' m_max_l='210' yield_l='5.9145e5'
range_l="'[${m_min_l},${m_max_l}]'"
# SRS
nbins_s='27' m_min_s='75' m_max_s='210' yield_s='5.3004e5'
range_s="'[${m_min_s},${m_max_s}]'"
# SRL1
nbins_l1='28' m_min_l1='70' m_max_l1='210' yield_l1='5.0797e5'
range_l1="'[${m_min_l1},${m_max_l1}]'"
# SRL2
nbins_l2='27' m_min_l2='75' m_max_l2='210' yield_l2='7.2817e4'
range_l2="'[${m_min_l2},${m_max_l2}]'"
# SRS0
nbins_s0='27' m_min_s0='75' m_max_s0='210' yield_s0='1.5780e5'
range_s0="'[${m_min_s0},${m_max_s0}]'"
# SRS1
nbins_s1='28' m_min_s1='70' m_max_s1='210' yield_s1='3.4024e5'
range_s1="'[${m_min_s1},${m_max_s1}]'"
# SRS2
nbins_s2='27' m_min_s2='75' m_max_s2='210' yield_s2='4.8390e4'
range_s2="'[${m_min_s2},${m_max_s2}]'"
# CRttbar
nbins_cr='12' m_min_cr='140' m_max_cr='200'
range_cr="'[${m_min_cr},${m_max_cr}]'"

# Generate and read SR xml cards
if $do_SR_inc; then
  title='SR'
  if [ ! $POI ]; then
    # Set default poi value
    poi=""
  else
    poi="--poi ${POI}"
  fi
  for dtype in $DTYPE; do
    # Generate xml cards
    cmd="python genxml/generate.py SR_l__${TAG} SR_s__${TAG} CRttbar__${TAG} --title ${title} --tag ${dtype}_${TAG} --bins ${nbins_l} ${nbins_s} ${nbins_cr} --fr ${range_l} ${range_s} ${range_cr} --data ${dtype} ${dtype} ${dtype} --qcd srl srs None --qcdsy ${yield_l} ${yield_s} ${poi}"
    echo $cmd
    eval $cmd
    # Read xml cards
    cd xmlAnaWSBuilder
    cmd="./exe/XMLReader -x config/hbbj/${title}_${dtype}_${TAG}/${title}.xml" 
    echo $cmd
    eval $cmd
    cd ..
  done
fi

# Generate and read SR STXS Z(inclusive) xml cards
if $do_SR_STXS_Z_inc; then
  title='SR_STXS_Z_inc'
  if [ ! $POI ]; then
    # Set default poi value
    poi=""
  else
    poi="--poi ${POI}"
  fi
  for dtype in $DTYPE; do
    # Generate xml cards
    cmd="python genxml/generate.py SR_STXS_Z_inc_l1__${TAG} SR_STXS_Z_inc_l2__${TAG} SR_STXS_Z_inc_s0__${TAG} SR_STXS_Z_inc_s1__${TAG} SR_STXS_Z_inc_s2__${TAG} CRttbar_0__${TAG} CRttbar_1__${TAG} CRttbar_2__${TAG} --title ${title} --tag ${dtype}_${TAG} --bins ${nbins_l1} ${nbins_l2} ${nbins_s0} ${nbins_s1} ${nbins_s2} ${nbins_cr} ${nbins_cr} ${nbins_cr} --fr ${range_l1} ${range_l2} ${range_s0} ${range_s1} ${range_s2} ${range_cr} ${range_cr} ${range_cr} --data ${dtype} ${dtype} ${dtype} ${dtype} ${dtype} ${dtype} ${dtype} ${dtype} --qcd srl1 srl2 srs0 srs1 srs2 None None None --qcdsy ${yield_l1} ${yield_l2} ${yield_s0} ${yield_s1} ${yield_s2} ${poi}"
    echo $cmd
    eval $cmd
    # Read xml cards
    cd xmlAnaWSBuilder
    cmd="./exe/XMLReader -x config/hbbj/${title}_${dtype}_${TAG}/${title}.xml"
    echo $cmd
    eval $cmd
    cd ..
  done
fi

# Generate and read SR STXS H(inclusive) xml cards
if $do_SR_STXS_H_inc; then
  title='SR_STXS_H_inc'
  if [ ! $POI ]; then
    # Set default poi value
    poi=""
  else
    poi="--poi ${POI}"
  fi
  for dtype in $DTYPE; do
    # Generate xml cards
    cmd="python genxml/generate.py SR_STXS_H_inc_l1__${TAG} SR_STXS_H_inc_l2__${TAG} SR_STXS_H_inc_s0__${TAG} SR_STXS_H_inc_s1__${TAG} SR_STXS_H_inc_s2__${TAG} CRttbar_0__${TAG} CRttbar_1__${TAG} CRttbar_2__${TAG} --title ${title} --tag ${dtype}_${TAG} --bins ${nbins_l1} ${nbins_l2} ${nbins_s0} ${nbins_s1} ${nbins_s2} ${nbins_cr} ${nbins_cr} ${nbins_cr} --fr ${range_l1} ${range_l2} ${range_s0} ${range_s1} ${range_s2} ${range_cr} ${range_cr} ${range_cr} --data ${dtype} ${dtype} ${dtype} ${dtype} ${dtype} ${dtype} ${dtype} ${dtype} --qcd srl1 srl2 srs0 srs1 srs2 None None None --qcdsy ${yield_l1} ${yield_l2} ${yield_s0} ${yield_s1} ${yield_s2} ${poi}"
    echo $cmd
    eval $cmd
    # Read xml cards
    cd xmlAnaWSBuilder
    cmd="./exe/XMLReader -x config/hbbj/${title}_${dtype}_${TAG}/${title}.xml"
    echo $cmd
    eval $cmd
    cd ..
  done
fi

# Generate and read CRttbar (inclusive) xml cards
if $do_CRttbar_inc; then
  title='CRttbar'
  if [ ! $POI ]; then
    # Set default poi value
    poi="--poi mu_ttbar"
  else
    poi="--poi ${POI}"
  fi
  for dtype in $DTYPE; do
    # Generate xml cards
    cmd="python genxml/generate.py CRttbar__${TAG} --title ${title} --tag ${dtype}_${TAG} --data ${dtype} --bins ${nbins_cr} --fr ${range_cr} ${poi}"
    echo $cmd
    eval $cmd
    # Read xml cards
    cd xmlAnaWSBuilder
    cmd="./exe/XMLReader -x config/hbbj/${title}_${dtype}_${TAG}/${title}.xml"
    echo $cmd
    eval $cmd
    cd ..
  done
fi

# Generate and read CRttbar (pT bins) xml cards
if $do_CRttbar_bins; then
  for bin in '0' '1' '2'; do
    title="CRttbar_b${bin}"
    if [ ! $POI ]; then
      # Set default poi value
      poi="--poi mu_ttbar_b${bin}"
    else
      poi="--poi ${POI}"
    fi
    for dtype in $DTYPE; do
      # Generate xml cards
      cmd="python genxml/generate.py CRttbar_${bin}__${TAG} --title ${title} --tag ${dtype}_${TAG} --data ${dtype} --bins ${nbins_cr} --fr ${range_cr} ${poi}"
      echo $cmd
      eval $cmd
      # Read xml cards
      cd xmlAnaWSBuilder
      cmd="./exe/XMLReader -x config/hbbj/${title}_${dtype}_${TAG}/${title}.xml"
      echo $cmd
      eval $cmd
      cd ..
    done
  done
fi

unset TAG MODE POI