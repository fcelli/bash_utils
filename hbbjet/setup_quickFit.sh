#!/bin/bash
#title          : setup_quickFit.sh
#description    : Script for setting up the hbbjet fitting framework (quickFit). 
#author         : fcelli

export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase
alias setupATLAS='source ${ATLAS_LOCAL_ROOT_BASE}/user/atlasLocalSetup.sh'

setupATLAS

lsetup git

cd quickFit
source setup_lxplus.sh
cd ..
echo "done"