#!/bin/bash
# name:          install.sh
# description:   Copy rc files to be used with essh to $ESSH_RC_DIR.
# author:        vd@ghostshell.de
# version:       0.1
# tested on:     Debian Wheezy, Debian Jessie
# vim: ts=3 sw=3 sts=3 et ai ci
set -e 

PROG_NAME=${0##*/}
SCRIPT_CWD=$( cd ${0%/*} 2> /dev/null; pwd )
ESSH_BASE_DIR=$( cd $SCRIPT_CWD; cd ..; pwd )
ESSH_BIN=essh
INSTALL_FLAG=false
UNINSTALL_FLAG=false
FORCE_FLAG=false
USAGE="\
Copy rc files to be used with essh to \$ESSH_RC_DIR.

Usage: $PROG_NAME <-i|--install|-u|--uninstall> [-f|--force] [-d|--dry-run]\n\n"

if [[ $1 =~ -h|--help|help ]] || [[ -z $1 ]]; then
   printf "$USAGE"
   exit 0
fi

if [[ -z $SCRIPT_CWD ]]; then
   echo "Cannot determine script cwd." >&2
   exit 1
fi

cd $SCRIPT_CWD

if [[ -f $ESSH_BIN ]]; then
   ESSH_RC_DIR=$( awk -F'=' '/^ESSH_RC_DIR/{print $2}' $ESSH_BIN )
else
   echo "Can't find $ESSH_BIN." >&2
   exit 1
fi

if [[ ! -d $ESSH_BASE_DIR ]]; then
   echo "Can't find $ESSH_BASE_DIR." >&2
   exit 1
fi

for arg in $@; do
   [[ $arg =~ ^-i|--install$ ]] && INSTALL_FLAG=true
   [[ $arg =~ ^-u|--uninstall$ ]] && UNINSTALL_FLAG=true
   [[ $arg =~ ^-f|--force$ ]] && FORCE_FLAG=true
   if [[ $arg =~ ^-d|--dry-run ]]; then
      DRY_RUN=echo
      DRY_RUN_INDICATOR=DRY_RUN
   fi
done

$FORCE_FLAG || PROMPT_USER_PARAM='-i'

# Manually expand home directory (via parameter expansion) if specified.
ESSH_RC_DIR=${ESSH_RC_DIR/\~/$HOME}
ESSH_RC_DIR=${ESSH_RC_DIR/\$HOME/$HOME}

if $INSTALL_FLAG; then
   printf "Installing essh... %s\n\n" "$DRY_RUN_INDICATOR"
   $DRY_RUN mkdir -pv $ESSH_RC_DIR
   if [[ -n $DRY_RUN ]]; then
      echo "cd $ESSH_BASE_DIR"
   else
      echo "essh base dir: $ESSH_BASE_DIR"
   fi
   cd $ESSH_BASE_DIR
   $DRY_RUN cp -vr $PROMPT_USER_PARAM essh.d/* "$ESSH_RC_DIR"
   printf '\nInstallation finished.\n'
   printf '\nESSH_RC_DIR=%s\n' $ESSH_RC_DIR
   printf '\nPut essh in your $PATH, e.g. via symlink:\n'
   printf '# ln -s %s %s\n' $ESSH_BASE_DIR/bin/essh /usr/local/bin/essh
elif $UNINSTALL_FLAG; then
   printf "Uninstalling essh... %s\n\n" "$DRY_RUN_INDICATOR"
   $DRY_RUN rm -vr $PROMPT_USER_PARAM "$ESSH_RC_DIR" || true
   printf '\nUninstall finished.\n'
   printf '\nRemove essh from your $PATH.\n'
else
   printf "$USAGE"
fi

