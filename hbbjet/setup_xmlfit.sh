#!/bin/bash
#title          : setup_xmlfit.sh
#description    : Script for setting up the hbbjet fitting framework (xmlfit_boostedhbb). 
#author         : fcelli

setupATLAS

lsetup "views LCG_97_ATLAS_1 x86_64-centos7-gcc8-opt"

source /cvmfs/sft.cern.ch/lcg/releases/LCG_97_ATLAS_1/Boost/1.72.0/x86_64-centos7-gcc8-opt/Boost-env.sh

source /data/atlas/atlasdata/celli/hbbjet/ROOT_build_RooBinSamplingPdf/build/bin/thisroot.sh

source setup.sh