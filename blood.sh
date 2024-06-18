#!/bin/bash
###############################################################################
# BPS2 (Blood Parameters Storage System) is a simple command line interface   #
# to store previous measured blood parameters such as pressure (diastolic,    #
# systolic and pulse) sugar level, and urine acid level.                      #
# Author:     Paweł Prokop (pa810p@gmail.com)                                 #
# Repository: https://github.com/pa810p/bps2                                  #
# License:    GNU General Public License v3.0  see: LICENSE                   #
###############################################################################

# ensure we're running in bash
SHELL=$(readlink /proc/$$/exe | awk -F '/' '{print $NF}')

if [ "$SHELL" != "bash" ]; then
  echo "$_ -> $(readlink "$_")";
  echo "Please use bash instead of $SHELL :";
  echo "\$ ./$0";
  echo "\$ bash $0";
  exit 1;
fi;

source $(dirname $0)/blood_functions.sh

main "$@";
