#!/bin/sh
. $JBOSS_HOME/bin/jbosslogger

_XSLTPROC="/usr/bin/xsltproc"
_XMLLINT="/usr/bin/xmllint"

STANDALONE_FILE="$JBOSS_HOME/standalone/configuration/$JBOSSEAP7_CONFIG"
MOD_CLUSTER_XSL="$JBOSS_HOME/standalone/data/remove_modcluster/remove_modcluster.xsl"

if grep -q 'modcluster' "$STANDALONE_FILE" ; then
    info "Removing mod_cluster reference in standalone file"
    $_XSLTPROC --output "$STANDALONE_FILE" "$MOD_CLUSTER_XSL" "$STANDALONE_FILE"
    if [ $? == 0 ]
    then
        info "Successfully removed modcluster entry."
    else
        error "Failed to remove modcluster entry."
    fi
    $_XMLLINT --output "$STANDALONE_FILE" --format "$STANDALONE_FILE"
    if [ $? == 0 ]
    then
        info "Successfully formatted $STANDALONE_FILE"
    else
        error "Failed to format $STANDALONE_FILE"
    fi

fi
