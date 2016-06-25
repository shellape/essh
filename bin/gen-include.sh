#!/bin/bash
# name:          gen-include.sh
# description:   Generate the essh include config from essh's default values.
# author:        vd@ghostshell.de
# version:       0.1
# tested on:     Debian Jessie
# vim: ts=3 sw=3 sts=3 et ai ci
set -e

PROG_NAME="${0##*/}"
ARGV="$@"
SCRIPT_CWD=$( cd ${0%/*} 2> /dev/null; pwd )
ESSH_BIN=essh
ESSH_INCLUDE_CONF='~/.essh_include.conf'
CONFIG_START='#<USER_CONFIG>'
CONFIG_END='#</USER_CONFIG>'
USAGE="\
Write include config file to stdout (using defaults of $ESSH_BIN).

Usage: $PROG_NAME -w

Optionally write it to the include config (e.g. $ESSH_INCLUDE_CONF)\n\n"


if [[ $1 =~ -h|--help|help ]] || [[ $1 != -w ]]; then
   printf "$USAGE"
   exit 1
fi

cd $SCRIPT_CWD

grep -qw "^$CONFIG_START$" $ESSH_BIN || CONFIG_FOUND=false
grep -qw "^$CONFIG_END$" $ESSH_BIN || CONFIG_FOUND=false

if ! $CONFIG_FOUND; then
   echo "Could not find config block '$CONFIG_START', '$CONFIG_END' in $ESSH_BIN." >&2
   exit 1
fi

printf "# Generated by $PROG_NAME\n\n"
while read line; do
   [[ "$line" = $CONFIG_END ]] && exit
   if [[ "$line" = $CONFIG_START ]]; then
      CONFIG_START_FOUND='yes'
      continue
   fi
   [[ $CONFIG_START_FOUND = yes ]] && echo "$line"
done < $ESSH_BIN
