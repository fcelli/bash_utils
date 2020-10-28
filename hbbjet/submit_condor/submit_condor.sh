#!/bin/bash

# Script name
SCRIPT=$(basename $0)

usage() {
    printf "%s\n\n" "From within submit_condor/:"
        printf "\t%s\n\n" "bash $SCRIPT -c \"<COMMAND>\" [-i <INPUT> -o <OUTPUT> -b <BLIND> -h]"
        printf "%s\n\n" "Options:"
    #-c, --command COMMAND
    printf "\t%-20s\n" "-c, --command \"COMMAND\" (required)"
        printf "\t\t%s\n" "Command to be submitted to HTCondor"
        printf "\n"
    #-i, --input INPUT
    printf "\t%-20s\n" "-i, --input INPUT"
        printf "\t\t%s\n" "Input file name (path relative to quickFit/ directory). N.B. all files inside the directory (or softlink) quickFit/workspace are by default accessible by COMMAND"
        printf "\n"
    #-o, --o OUTPUT
    printf "\t%-20s\n" "-o, --output OUTPUT"
        printf "\t\t%s\n" "Path to a txt file where the standard output of COMMAND will be saved. Use .txt extension and path relative to quickFit/"
        printf "\n"
    #-b, --blind BLIND
    printf "\t%-20s\n" "-b, --blind BLIND"
        printf "\t\t%s\n" "Used for omitting from the standard output any line containing the word given as argument. Multiple parameters can be blinded if separated by a comma e.g. -b mu_Zboson,mu_Higgs"
        printf "\n"
    #-h, --help
    printf "\t%-20s\n" "-h, --help"
        printf "\t\t%s\n" "Display this help and exit"
        printf "\n"
}

# Parse arguments
unset COMMAND
INPUT="\"\""
OUTPUT="\"\""
BLIND="\"\""
while [ "$1" != "" ]; do
    case $1 in
        -c | --command )
            shift
            COMMAND="\"${1}\""
            ;;
        -i | --input )
            shift
            INPUT="\"${1}\""
            ;;
        -o | --output )
            shift
            OUTPUT="\"${1}\""
            ;;
        -b | --blind )
            shift
            BLIND="\"${1}\""
            ;;
        -h | --help )
            usage
            exit 0
            ;;
        * )
            usage
            exit 1
    esac
    shift
done

# Check required arguments
if [ ! $COMMAND ]; then
    echo "ERROR: Missing required -c argument."
    exit 1
fi

# Create required output directories if they don't exist
for dir in out err log ../output; do
    if ! test -d $dir; then
        mkdir $dir
    fi
done

# Edit files and submit to HTCondor
workdir=${PWD}
mycommand=${COMMAND}
echo "running command: ${mycommand}"
workdir=${workdir%/*}
dir=${workdir##*/}
random=${RANDOM}
cat job.sh | sed "s|XWORKDIR|${workdir}|g" | sed "s|XDIR|${dir}|g" | sed "s|XCOMMAND|${mycommand}|g" | sed "s|XINPUT|${INPUT}|g" | sed "s|XOUTPUT|${OUTPUT}|g" | sed "s|XBLIND|${BLIND}|g" > job_${random}.sh
chmod 755 job_${random}.sh
cat hello.sub | sed "s/XJOBSH/job_${random}.sh/g" > hello_${random}.sub
echo hello_${random}.sub
condor_submit hello_${random}.sub