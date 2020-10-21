#!/bin/bash
#title          :setup_fitframe.sh
#description    :Script for setting up the hbbjet fitting framework. 
#author         :fcelli

export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase
alias setupATLAS='source ${ATLAS_LOCAL_ROOT_BASE}/user/atlasLocalSetup.sh'

setupATLAS

lsetup git

lsetup "views LCG_97_ATLAS_1 x86_64-centos7-gcc8-opt"
source setup.sh

source xmlAnaWSBuilder/setup_lxplus.sh

source quickFit/setup_lxplus.sh