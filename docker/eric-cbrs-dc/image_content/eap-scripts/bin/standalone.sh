#!/bin/sh

# Use --debug to activate debug mode with an optional argument to specify the port.
# Usage : standalone.bat --debug
#         standalone.bat --debug 9797

# By default debug mode is disable.
DEBUG_MODE=false
DEBUG_PORT="8787"
SERVER_OPTS=""
while [ "$#" -gt 0 ]
do
    case "$1" in
      --debug)
          DEBUG_MODE=true
          if [ -n "$2" ] && [ "$2" = `echo "$2" | sed 's/-//'` ]; then
              DEBUG_PORT=$2
              shift
          fi
          ;;
      --)
          shift
          break;;
      *)
          SERVER_OPTS="$SERVER_OPTS '$1'"
          ;;
    esac
    shift
done

DIRNAME=`dirname "$0"`
PROGNAME=`basename "$0"`
GREP="grep"

# Use the maximum available, or set MAX_FD != -1 to use that
MAX_FD="maximum"

# OS specific support (must be 'true' or 'false').
linux=true;

# Setup JBOSS_HOME
RESOLVED_JBOSS_HOME=`cd "$DIRNAME/.."; pwd`
if [ "x$JBOSS_HOME" = "x" ]; then
    # get the full path (without any relative bits)
    JBOSS_HOME=$RESOLVED_JBOSS_HOME
else
 SANITIZED_JBOSS_HOME=`cd "$JBOSS_HOME"; pwd`
 if [ "$RESOLVED_JBOSS_HOME" != "$SANITIZED_JBOSS_HOME" ]; then
   logger ""
   logger "   WARNING:  JBOSS_HOME may be pointing to a different installation - unpredictable results may occur."
   logger ""
   logger "             JBOSS_HOME: $JBOSS_HOME"
   logger ""
   sleep 2s
 fi
fi
export JBOSS_HOME

# Set debug settings if not already set
if [ "$DEBUG_MODE" = "true" ]; then
    DEBUG_OPT=`echo $JAVA_OPTS | $GREP "\-agentlib:jdwp"`
    if [ "x$DEBUG_OPT" = "x" ]; then
        JAVA_OPTS="$JAVA_OPTS -agentlib:jdwp=transport=dt_socket,address=$DEBUG_PORT,server=y,suspend=n"
    else
        echo "Debug already enabled in JAVA_OPTS, ignoring --debug argument"
    fi
    SERVER_OPTS="$SERVER_OPTS --debug ${DEBUG_PORT}"
fi

# Setup the JVM
if [ "x$JAVA" = "x" ]; then
    if [ "x$JAVA_HOME" != "x" ]; then
        JAVA="$JAVA_HOME/bin/java"
    else
        JAVA="java"
    fi
fi

if $linux; then
    # consolidate the server and command line opts
    CONSOLIDATED_OPTS="$JAVA_OPTS $SERVER_OPTS"
    # process the standalone options
    for var in $CONSOLIDATED_OPTS
    do
       # Remove quotes
       p=`echo $var | tr -d "'"`
       case $p in
         -Djboss.server.base.dir=*)
              JBOSS_BASE_DIR=`readlink -m ${p#*=}`
              ;;
         -Djboss.server.log.dir=*)
              JBOSS_LOG_DIR=`readlink -m ${p#*=}`
              ;;
         -Djboss.server.config.dir=*)
              JBOSS_CONFIG_DIR=`readlink -m ${p#*=}`
              ;;
       esac
    done
fi

# determine the default base dir, if not set
if [ "x$JBOSS_BASE_DIR" = "x" ]; then
   JBOSS_BASE_DIR="$JBOSS_HOME/standalone"
fi
# determine the default log dir, if not set
if [ "x$JBOSS_LOG_DIR" = "x" ]; then
   JBOSS_LOG_DIR="$JBOSS_BASE_DIR/log"
fi
# determine the default configuration dir, if not set
if [ "x$JBOSS_CONFIG_DIR" = "x" ]; then
   JBOSS_CONFIG_DIR="$JBOSS_BASE_DIR/configuration"
fi


if [ "$PRESERVE_JAVA_OPTS" != "true" ]; then
    # Check for -d32/-d64 in JAVA_OPTS
    JVM_D64_OPTION=`echo $JAVA_OPTS | $GREP "\-d64"`
    JVM_D32_OPTION=`echo $JAVA_OPTS | $GREP "\-d32"`

    # Check If server or client is specified
    SERVER_SET=`echo $JAVA_OPTS | $GREP "\-server"`
    CLIENT_SET=`echo $JAVA_OPTS | $GREP "\-client"`

    if [ "x$JVM_D32_OPTION" != "x" ]; then
        JVM_OPTVERSION="-d32"
    elif [ "x$JVM_D64_OPTION" != "x" ]; then
        JVM_OPTVERSION="-d64"
    elif $darwin && [ "x$SERVER_SET" = "x" ]; then
        # Use 32-bit on Mac, unless server has been specified or the user opts are incompatible
        "$JAVA" -d32 $JAVA_OPTS -version > /dev/null 2>&1 && PREPEND_JAVA_OPTS="-d32" && JVM_OPTVERSION="-d32"
    fi

    CLIENT_VM=false
    if [ "x$CLIENT_SET" != "x" ]; then
        CLIENT_VM=true
    elif [ "x$SERVER_SET" = "x" ]; then
        if $darwin && [ "$JVM_OPTVERSION" = "-d32" ]; then
            # Prefer client for Macs, since they are primarily used for development
            CLIENT_VM=true
            PREPEND_JAVA_OPTS="$PREPEND_JAVA_OPTS -client"
        else
            PREPEND_JAVA_OPTS="$PREPEND_JAVA_OPTS -server"
        fi
    fi

    if [ $CLIENT_VM = false ]; then
        NO_COMPRESSED_OOPS=`echo $JAVA_OPTS | $GREP "\-XX:\-UseCompressedOops"`
        if [ "x$NO_COMPRESSED_OOPS" = "x" ]; then
            "$JAVA" $JVM_OPTVERSION -server -XX:+UseCompressedOops -version >/dev/null 2>&1 && PREPEND_JAVA_OPTS="$PREPEND_JAVA_OPTS -XX:+UseCompressedOops"
        fi
    fi

    JAVA_OPTS="$PREPEND_JAVA_OPTS $JAVA_OPTS"
fi

if [ "x$JBOSS_MODULEPATH" = "x" ]; then
    JBOSS_MODULEPATH="$JBOSS_HOME/modules:$EXT_MODULES:$SFWK_MODULES"
fi

# Display our environment
logger "========================================================================="
logger ""
logger "  JBoss Bootstrap Environment"
logger ""
logger "  JBOSS_HOME: $JBOSS_HOME"
logger ""
logger "  JAVA: $JAVA"
logger ""
logger "  JAVA_OPTS: $JAVA_OPTS"
logger ""
logger "========================================================================="
logger ""

echo "JAVA_OPTS=\"$JAVA_OPTS\"" > /ericsson/3pp/jboss/jboss.env
echo "JBOSS_LOG_DIR=$JBOSS_LOG_DIR" >> /ericsson/3pp/jboss/jboss.env
echo "JBOSS_CONFIG_DIR=$JBOSS_CONFIG_DIR" >> /ericsson/3pp/jboss/jboss.env
echo "JBOSS_HOME=$JBOSS_HOME" >> /ericsson/3pp/jboss/jboss.env
echo "JBOSS_MODULEPATH=$JBOSS_MODULEPATH" >> /ericsson/3pp/jboss/jboss.env
echo "JBOSS_BASE_DIR=$JBOSS_BASE_DIR" >> /ericsson/3pp/jboss/jboss.env
echo "JBOSSEAP7_CONFIG=$JBOSSEAP7_CONFIG" >> /ericsson/3pp/jboss/jboss.env
