#!/bin/bash
#title          : setup_xmlAnaWSBuilder.sh
#description    : Script for setting up the hbbjet fitting framework (xmlAnaWSBuilder). 
#author         : fcelli

export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase
alias setupATLAS='source ${ATLAS_LOCAL_ROOT_BASE}/user/atlasLocalSetup.sh'

setupATLAS

lsetup git

lsetup "views LCG_97_ATLAS_1 x86_64-centos7-gcc8-opt"
source setup.sh

cd xmlAnaWSBuilder
source setup_lxplus.sh
cd ..
echo "done"