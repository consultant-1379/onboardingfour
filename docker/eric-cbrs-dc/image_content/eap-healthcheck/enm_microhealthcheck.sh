#!/bin/bash
###########################################################################
# COPYRIGHT Ericsson 2018
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
###########################################################################

# GLOBAL VARIABLES
_INITSCRIPT=/ericsson/3pp/jboss/bin/microhealthcheck.sh

#//////////////////////////////////////////////////////////////
# Main Part of Script
#/////////////////////////////////////////////////////////////

$_INITSCRIPT > /dev/null 2>&1
exit $?
