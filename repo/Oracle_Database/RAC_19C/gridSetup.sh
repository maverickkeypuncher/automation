#!/bin/sh
#
# $Header: install/utl/scripts/db/gridSetup.sh /main/22 2016/07/21 07:40:17 davjimen Exp $
#
# gridSetup.sh
#
# Copyright (c) 2014, 2016, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      gridSetup.sh
#
#    DESCRIPTION
#      script to launch config wizard for configuring Grid Infrastructure home image
#
#    MODIFIED   (MM/DD/YY)
#    davjimen    07/20/16 - set cvu os settings property
#    davjimen    05/10/16 - update ownership messages
#    davjimen    05/02/16 - check if the home software is complete
#    davjimen    04/06/16 - change the ownership check for execution perm check
#    davjimen    04/05/16 - change cd behavior for solaris 5.10
#    davjimen    03/17/16 - do not error out if xdpyinfo is not present
#    davjimen    02/19/16 - check if find exists
#    davjimen    01/13/16 - do not save and change back the current working dir
#    supalava    12/15/15 - Bug 22359581 fix. -e doesn't work on solaris sparc.
#    supalava    12/01/15 - Replace who am i with whoami.
#    supalava    11/30/15 - Correcting whoami command.
#    davjimen    11/19/15 - syntax error in function definition
#    davjimen    10/28/15 - check current user before running gridSetup.pl
#    davjimen    09/04/15 - change dirs to pwd -L, and shell to sh
#    davjimen    07/16/15 - add the -l param to dirs command
#    davjimen    07/13/15 - change shell to bash
#    davjimen    07/10/15 - add unset module
#    davjimen    07/02/15 - honor specific provided path from gridSetup.sh to
#                           determine the Oracle home
#    davjimen    04/15/15 - exit if unable to verify the graphical display
#                           setup and its not silent
#    davjimen    02/25/15 - use an alternative for readlink if its not available
#    davjimen    01/28/15 - use an alternative for readlink in solaris 5.10
#    davjimen    09/01/14 - Creation
#

silent="false"
help="false";
for arg in $*
do
    if [ "$arg" = "-silent" ]; then
       silent="true"
    else
      if [ "$arg" = "-h" -o "$arg" = "-help" ]; then
         help="true";
      fi
    fi
    if [ $silent = "true" -a $help = "true" ]; then
       break;
    fi  
done
UNAME="/bin/uname"
XDPYINFO="/usr/bin/xdpyinfo"
if [ ! -f $XDPYINFO ]; then
    case `$UNAME` in
        AIX)
            XDPYINFO="/usr/bin/X11/xdpyinfo"
        ;;
        HP-UX)
            XDPYINFO="/usr/contrib/bin/X11/xdpyinfo"
        ;;
        Linux)
            XDPYINFO="/usr/X11R6/bin/xdpyinfo"
        ;;
        SunOS)
            XDPYINFO="/usr/openwin/bin/xdpyinfo"
        ;;
    esac
    if [ ! -f $XDPYINFO ]; then
        XDPYINFO="/usr/lpp/tcpip/X11R6/Xamples/clients/xdpyinfo"
        if [ ! -f $XDPYINFO ]; then
            XDPYINFO="xdpyinfo"
        fi
    fi
fi
${XDPYINFO} > /dev/null 2>&1
#if xdpyinfo fails and -silent is not passed then error out
if [ $? -ne 0 -a "$silent" = "false" -a "$help" = "false" ]; then
    echo "ERROR: Unable to verify the graphical display setup. This application requires X display. Make sure that xdpyinfo exist under PATH variable."
fi

ORACLE_HOME="";

DIRNAME="/usr/bin/dirname";
DIRLOC="`${DIRNAME} $0`";
if [ "`${UNAME}`" = "SunOS" ] && [ "`${UNAME} -r`" = "5.10" ]; then
  SYMLINKSFOUND="false";
  AUXDIRLOC="${DIRLOC}";
  while [ "${AUXDIRLOC}" != "." ] && [ "${AUXDIRLOC}" != "/" ]; do
    if [ -L "${AUXDIRLOC}" ]; then
      SYMLINKSFOUND="true";
      break;
    fi
    AUXDIRLOC="`${DIRNAME} ${AUXDIRLOC}`";
  done
 
  if [ "${SYMLINKSFOUND}" = "true" ]; then
    case "${DIRLOC}" in
      /*)
        ORACLE_HOME="${DIRLOC}";
      ;;
      *)
        CURRENTDIR="`pwd`";
        ORACLE_HOME="${CURRENTDIR}/${DIRLOC}";
      ;;
    esac
  else
    cd "${DIRLOC}";
    ORACLE_HOME="`pwd -L`";
  fi
else
  cd "${DIRLOC}";
  ORACLE_HOME="`pwd -L`";
fi

export ORACLE_HOME;

unset module;

GSPL_FILE="${ORACLE_HOME}/bin/gridSetup.pl";
if [ ! -f "${GSPL_FILE}" ]; then
  echo "ERROR: The Oracle Grid Infrastructure home software is not complete. Ensure the complete software is available at location (${ORACLE_HOME}).";
  exit 1;
fi

WHOAMI="/usr/bin/whoami";
USRNAME="";
if [ -f ${WHOAMI} ]; then
  USRNAME="`${WHOAMI}`";
fi

PERL_FILE="${ORACLE_HOME}/perl/bin/perl";
PERL_LIB_DIR="${ORACLE_HOME}/perl/lib";
EXEC_PERM="true";
if [ ! -x "${PERL_FILE}" ]; then
  EXEC_PERM="false";
else
  FIND="/bin/find";
  if [ ! -f "${FIND}" ]; then
    FIND="/usr/bin/find";
  fi
  if [ -f "${FIND}" ]; then
    if [ -n "`${FIND} ${PERL_LIB_DIR} ! -executable 2> /dev/null`" ]; then
      EXEC_PERM="false";
    fi
  fi
fi
if [ "${EXEC_PERM}" = "false" ]; then
  if [ "${USRNAME}" = "" ]; then
    echo "ERROR: Unable to continue with the setup. Ensure the current user has execution permission over software home (${ORACLE_HOME}).";
  else
    echo "ERROR: Unable to continue with the setup. Ensure user (${USRNAME}) has execution permission over software home (${ORACLE_HOME}).";
  fi
  exit 1;
fi

# Define CVU OS Settings
SHELL_NOFILE_SOFT_LIMIT="`/bin/sh -c 'ulimit -S -n'`";
SHELL_STACK_SOFT_LIMIT="`/bin/sh -c 'ulimit -S -s'`";
SHELL_UMASK="`/bin/sh -c 'umask'`";
CVU_OS_SETTINGS="CVU_OS_SETTINGS=SHELL_NOFILE_SOFT_LIMIT:${SHELL_NOFILE_SOFT_LIMIT},SHELL_STACK_SOFT_LIMIT:${SHELL_STACK_SOFT_LIMIT},SHELL_UMASK:${SHELL_UMASK}";

${ORACLE_HOME}/perl/bin/perl -I${ORACLE_HOME}/perl/lib ${ORACLE_HOME}/bin/gridSetup.pl -J-D${CVU_OS_SETTINGS} $*
exit $?

