#!/bin/bash
#title		:checkSync.sh
#description	:this script checks if a local directory is syncronised with a remote one.
#author		:fcelli

#options
remoteHost="fcelli@lxplus.cern.ch"
remoteDir="/eos/atlas/atlascerngroupdisk/phys-higgs/HSG5/dibjetISR_boosted/data_latest"
localDir="/data/atlas/atlasdata/stankait/HbbISR/fitting/samples/data_latest"

#path where the script is stored
baseDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

#create or clean tmp directory
tmpDir=$baseDir/.tmp
if test -d $tmpDir
  then
   rm $tmpDir/*.txt
  else
   mkdir -p $tmpDir
  fi

#define tmp filenames
localTmp=$tmpDir/local.txt
remoteTmp=$tmpDir/remote.txt

function getCont {
  #prints folder content and corresponding code
  dirName=$1 
  for file in $dirName/*
    do  
     filename=$(basename $file)
     code=$(stat -c '%s' ${file})
     #code=$(md5sum $file | cut -d ' ' -f 1)
     echo "$filename $code" 
    done
}

#get content of remote and local directories
ssh $remoteHost "$(typeset -f getCont); getCont $remoteDir" >> $remoteTmp
getCont $localDir >> $localTmp

#check if the tmp files are equal
RED='\033[0;31m'
NC='\033[0m'
cmp -s $localTmp $remoteTmp \
  || echo -e "${RED}Local and remote directories diverged, please update.${NC}"

#loop over local tmp file
while read -r line
  do
   IFS=' '
   read -a arr <<< "$line"
   filename="${arr[0]}"
   code="${arr[1]}"
   if ! grep -Fxq "$line" $remoteTmp
     then
      if grep -wq $filename $remoteTmp
       then
        echo "${filename} has changed."
       elif grep -wq $md5 $remoteTmp
         then
          echo "${filename} has changed name."
       else
        echo "${filename} is new in the local directory."
      fi
     fi
  done < $localTmp

#loop over remote tmp file
while read -r line
  do
   IFS=' '
   read -a arr <<< "$line"
   filename="${arr[0]}"
   code="${arr[1]}"
   if (! grep -Fxq "$line" $localTmp) && (! grep -wq $filename $localTmp) && (! grep -wq $md5 $localTmp)
     then
      echo "${filename} is new in the remote directory."
     fi
  done < $remoteTmp
