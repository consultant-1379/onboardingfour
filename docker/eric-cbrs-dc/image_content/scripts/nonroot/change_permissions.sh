#!/bin/bash

###########################################################################
# COPYRIGHT Ericsson 2021
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
###########################################################################

_INSTALL_PATH_=/ericsson/3pp/jboss
_ERIC_DIRS_=${_ERIC_DIRS_:="/ericsson /opt/ericsson /usr/lib/ocf/resource.d"}
# $USER_ID should be set in Dockerfile
_USER_ID_=${USER_ID:="jboss_user"}

# Set Ericsson files to jboss_user and root group
find $_ERIC_DIRS_ \( ! -user $_USER_ID_ -o ! -group root \) -exec chown $_USER_ID_:root {} \;
# Set JBOSS_HOME files to 775
find $_INSTALL_PATH_ \( ! -name README -a ! -perm 775 \) -exec chmod 775 {} \;
# Increase permissions on Ericsson files(except JBOSS_HOME as it is already done)
find $_ERIC_DIRS_ -not -path "/ericsson/3pp/*" -exec chmod g=u {} \;
# Ensure all directories have +x so that non-root user can stat them
find $_ERIC_DIRS_ -type d -exec chmod ug+x {} \;