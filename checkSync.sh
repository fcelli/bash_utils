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
  #prints folder content and stats
  dirName=$1 
  for file in $dirName/*
    do  
     filename=$(basename $file)
     size=$(stat -c '%s' ${file}) 
     date=$(date -r ${file} '+%d/%b/%y')
     echo "$filename $size $date" 
    done
}

#get content of remote and local directories
printf "Accessing remote directory $remoteHost:$remoteDir\n"
ssh $remoteHost "$(typeset -f getCont); getCont $remoteDir" >> $remoteTmp
printf "Accessing local directory $localDir\n"
getCont $localDir >> $localTmp

#check if the tmp files are equal
RED='\033[0;31m'
NC='\033[0m'
cmp -s $localTmp $remoteTmp \
  || echo -e "${RED}Local and remote directories diverged, please update.${NC}"

#initialize lists
files_chsize=""
sizes_chsize=""
dates_chsize=""
files_chdate=""
sizes_chdate=""
dates_chdate=""
files_newloc=""
sizes_newloc=""
dates_newloc=""
files_newrem=""
sizes_newrem=""
dates_newrem=""

#loop over local tmp file
while IFS=' ' read -r filename_l size_l date_l;do
  read -r filename_r size_r date_r <<< $(grep ^"${filename_l}" $remoteTmp) 
  if [ "${filename_l}" == "${filename_r}" ];then
    if [ "${size_l}" != "${size_r}" ];then
      files_chsize+="${filename_l} "
      sizes_chsize+="loc:${size_l},rem:${size_r} "
      dates_chsize+="loc:${date_l},rem:${date_r} "
    elif [ "${date_l}" != "${date_r}" ];then
      files_chdate+="${filename_l} "
      sizes_chdate+="${size_l} "
      dates_chdate+="loc:${date_l},rem:${date_r} "
    fi
  else
    files_newloc+="${filename_l} "
    sizes_newloc+="${size_l} "
    dates_newloc+="${date_l} "
  fi
done < $localTmp

#loop over remote tmp file
while IFS=' ' read -r filename_r size_r date_r;do
  read -r filename_l size_l date_l <<< $(grep ^"${filename_r}" $localTmp)
  if [ "${filename_r}" != "${filename_l}" ];then
    files_newrem+="${filename_r} "
    sizes_newrem+="${size_r} "
    dates_newrem+="${date_r} "
  fi
done < $remoteTmp

function print_lists {
  #print formatted info
  list1=$1
  list2=$2
  list3=$3
  paste <(printf "%-30s\n" $list1) <(printf "%-30s\n" $list2) <(printf "%-30s\n" $list3)
}

function print_sep {
  #print separator
  length=$1
  printf '=%.0s' $(eval "echo {1.."$(($length))"}")
  printf "\n"
}

#printouts
sep_length=90
print_sep $sep_length
printf "CHANGED SIZE:\n"
print_lists "" "size" "date"
print_lists "$files_chsize" "$sizes_chsize" "$dates_chsize"
print_sep $sep_length
printf "CHANGED DATE:\n"
print_lists "" "size" "date"
print_lists "$files_chdate" "$sizes_chdate" "$dates_chdate"
print_sep $sep_length
printf "NEW IN LOCAL:\n"
print_lists "" "size" "date"
print_lists "$files_newloc" "$sizes_newloc" "$dates_newloc"
print_sep $sep_length
printf "NEW IN REMOTE:\n"
print_lists "" "size" "date"
print_lists "$files_newrem" "$sizes_newrem" "$dates_newrem"
