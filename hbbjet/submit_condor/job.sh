#!/bin/bash

pwd
localdir=XWORKDIR
dir=XDIR
mycommand=XCOMMAND
inputname=XINPUT
outputname=XOUTPUT
blind=XBLIND

export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase
source ${ATLAS_LOCAL_ROOT_BASE}/user/atlasLocalSetup.sh

# Create required directories
mkdir dir
cd dir
mkdir out log err output

# Copy everything necessary from the local directory
cp -rf ${localdir}/app .
cp -rf ${localdir}/bin .
cp -rf ${localdir}/build .
cp -rf ${localdir}/dtd .
cp -rf ${localdir}/inc .
cp -rf ${localdir}/lib .
cp -rf ${localdir}/RooFitExtensions .
cp -rf ${localdir}/src .
cp -rf ${localdir}/setup_lxplus.sh .
ln -s ${localdir}/workspace workspace
if [ "${inputname}" != "" ]; then
    cp -rf ${localdir}/$inputname .
fi

# Source setup script
source setup_lxplus.sh

# Start setting up command
cmd="${mycommand} "

# Handle blinding
if [ "${blind}" != "" ]; then
    if [[ "${blind}" == *","* ]]; then
        # if blind contains commas
        IFS=','; read -a blind_arr <<< "${blind}"; IFS=' '
        for par in ${blind_arr[@]}; do
            echo "Blinding ${par} parameter in txt outputs."
            cmd+="| grep -v ${par} "
        done
    else
        # if blind does not contain commas
        echo "Blinding ${blind} parameter in txt outputs."
        cmd+="| grep -v ${blind} "
    fi
fi

# Handle txt output 
if [ "${outputname}" != "" ]; then
    if [ "${outputname##*.}" != "txt" ]; then
        echo "Error: -o argument must have .txt extension." 1>&2
        exit 1
    fi
    cmd+="|& tee out/$(basename ${outputname})"
fi

# Run command
echo "Evaluating command: ${cmd}"
eval $cmd

# Copy outputs to local dir
cp -f output/*.root ${localdir}/output/
if [ "${outputname}" != "" ]; then
    cp -f out/$(basename ${outputname}) ${localdir}/${outputname}
fi

echo 'done.'