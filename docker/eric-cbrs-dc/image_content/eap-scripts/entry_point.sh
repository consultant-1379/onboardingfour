#!/bin/sh
###################################################
#
# ENTRY POINT SCRIPT FOR JBOSS
#
#
####################################################
JBOSS_ENV_FILE="/ericsson/3pp/jboss/jboss.env"

ulimit -n 10240

ulimit -u 10240

chown $(id -u) /dev
chown $(id -u) /var/run
chown $(id -u) /run/rsyslog

logger "Starting rsyslog ..."
/sbin/rsyslogd

logger "Initializing jboss ..."
/ericsson/3pp/jboss/bin/jboss initialize &

while [ ! -f "$JBOSS_ENV_FILE" ]
do
        logger "Waiting for jboss environment file $JBOSS_ENV_FILE"
        sleep 1
done

#Sleeping here to give time for the file to be fully prepared.
sleep 5

. /ericsson/3pp/jboss/jboss.env

logger "$JBOSS_ENV_FILE available, going to start the jboss process"

exec java -D[Standalone] $JAVA_OPTS -Dorg.jboss.boot.log.file="$JBOSS_LOG_DIR"/server.log -Dlogging.configuration=file:"$JBOSS_CONFIG_DIR"/logging.properties -jar "$JBOSS_HOME"/jboss-modules.jar -mp ${JBOSS_MODULEPATH} -jaxpmodule "javax.xml.jaxp-provider" org.jboss.as.standalone -Djboss.home.dir="$JBOSS_HOME"  -Djboss.server.base.dir="$JBOSS_BASE_DIR" -c $JBOSSEAP7_CONFIG

