#!/bin/bash
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
# This script requires bash 4 or above
# $Date: 2015-11-23$
# $Author: Fei Chen$
#          Rakesh K Shukla$
#
# Performs required configurations for remote EJB invocations, including:
# 1. add the jboss-ejb-client.xml file into the DEs.
# 2. use the JBoss CLI to create the outbound connections;
# This script should be run after the JBoss container has started, but
# before any DE is deployed.
###########################################################################

source "$JBOSS_HOME/bin/utilities/jboss_mgmt_api_executor.sh"

EJB_CLIENT_XML_DIR="$JBOSS_HOME/standalone/data/ejb_remoting"
REMOTE_EJB_CONFIGURATION_FILE="/ericsson/3pp/jboss/bin/jboss-as-remote-ejb.conf"
DEFAULT_DEPLOYMENT_DIR="$JBOSS_HOME/standalone/tmp/deployments"
XSLTPROC="/usr/bin/xsltproc"
XMLLINT="/usr/bin/xmllint"
MKDIR="/bin/mkdir -p"
CP="/bin/cp -f"
JAR="/usr/bin/jar"

#REST Commands for JBOSS Management APIs
COMPOSITE_COMMAND="{\"operation\": \"composite\", \"address\": [], \"steps\": [#STEPS#]}"
REMOTING_CONFIG_COMMAND="{\"operation\": \"add\", \"host\": \"#HOST#\", \"port\": \"4447\", \"address\": [{\"socket-binding-group\": \"standard-sockets\"}, {\"remote-destination-outbound-socket-binding\": \"remote-ejb-#SOCKET_REF#\"}]},{\"operation\": \"add\", \"outbound-socket-binding-ref\": \"remote-ejb-#SOCKET_REF#\", \"username\": \"ejbuser\", \"protocol\": \"remote\", \"security-realm\": \"ejb-security-realm\", \"address\": [{\"subsystem\": \"remoting\"}, {\"remote-outbound-connection\": \"remote-ejb-connection-#SOCKET_REF#\"}]},{\"operation\": \"add\", \"value\": \"false\", \"address\": [{\"subsystem\": \"remoting\"}, {\"remote-outbound-connection\": \"remote-ejb-connection-#SOCKET_REF#\"}, {\"property\": \"SASL_POLICY_NOANONYMOUS\"}]},{\"operation\": \"add\", \"value\": \"false\", \"address\": [{\"subsystem\": \"remoting\"}, {\"remote-outbound-connection\": \"remote-ejb-connection-#SOCKET_REF#\"}, {\"property\": \"SSL_ENABLED\"}]},{\"operation\": \"add\", \"value\": \"60000\", \"address\": [{\"subsystem\": \"remoting\"}, {\"remote-outbound-connection\": \"remote-ejb-connection-#SOCKET_REF#\"}, {\"property\": \"org.jboss.remoting3.RemotingOptions.HEARTBEAT_INTERVAL\"}]},{\"operation\": \"add\", \"value\": \"180000\", \"address\": [{\"subsystem\": \"remoting\"}, {\"remote-outbound-connection\": \"remote-ejb-connection-#SOCKET_REF#\"}, {\"property\": \"READ_TIMEOUT\"}]},{\"operation\": \"add\", \"value\": \"true\", \"address\": [{\"subsystem\": \"remoting\"}, {\"remote-outbound-connection\": \"remote-ejb-connection-#SOCKET_REF#\"}, {\"property\": \"KEEP_ALIVE\"}]}"
SECURE_REMOTING_CONFIG_COMMAND="{\"operation\": \"add\", \"host\": \"#HOST#\", \"port\": \"4447\", \"address\": [{\"socket-binding-group\": \"standard-sockets\"}, {\"remote-destination-outbound-socket-binding\": \"remote-ejb-#SOCKET_REF#\"}]},{\"operation\": \"add\", \"outbound-socket-binding-ref\": \"remote-ejb-#SOCKET_REF#\", \"security-realm\": \"SSLRealm\", \"protocol\": \"remote\", \"address\": [{\"subsystem\": \"remoting\"}, {\"remote-outbound-connection\": \"remote-ejb-connection-#SOCKET_REF#\"}]},{\"operation\": \"add\", \"value\": \"false\", \"address\": [{\"subsystem\": \"remoting\"}, {\"remote-outbound-connection\": \"remote-ejb-connection-#SOCKET_REF#\"}, {\"property\": \"SASL_POLICY_NOANONYMOUS\"}]},{\"operation\": \"add\", \"value\": \"true\", \"address\": [{\"subsystem\": \"remoting\"}, {\"remote-outbound-connection\": \"remote-ejb-connection-#SOCKET_REF#\"}, {\"property\": \"SSL_ENABLED\"}]},{\"operation\": \"add\", \"value\": \"60000\", \"address\": [{\"subsystem\": \"remoting\"}, {\"remote-outbound-connection\": \"remote-ejb-connection-#SOCKET_REF#\"}, {\"property\": \"org.jboss.remoting3.RemotingOptions.HEARTBEAT_INTERVAL\"}]},{\"operation\": \"add\", \"value\": \"180000\", \"address\": [{\"subsystem\": \"remoting\"}, {\"remote-outbound-connection\": \"remote-ejb-connection-#SOCKET_REF#\"}, {\"property\": \"READ_TIMEOUT\"}]},{\"operation\": \"add\", \"value\": \"true\", \"address\": [{\"subsystem\": \"remoting\"}, {\"remote-outbound-connection\": \"remote-ejb-connection-#SOCKET_REF#\"}, {\"property\": \"KEEP_ALIVE\"}]}"


declare -A DE_REMOTING_TOPOLOGY
# SGs should provide this file for EJB remoting configuration
if [ -x "$REMOTE_EJB_CONFIGURATION_FILE" ]
then
    source $REMOTE_EJB_CONFIGURATION_FILE
    userinfo "Remoting Topology: ${DE_REMOTING_TOPOLOGY[*]} " "REMOTE_EJB_CONF"
fi

# Make sure there's no space in the value of the variable below
SECURE_CLUSTERS="sps"
SSLREALM_REQUIRED="false"


declare -A CONNECTION_ARRAY

###############################################################
# Prepares JSON body to be passed as command for creating EJB
# remoting for one cluster
###############################################################
prepare_ejb_remoting_command_for_cluster()
{
    cluster="$1"
    hosts="$2"
    info "Preparing EJB remoting command for cluster[$cluster] and hosts[$hosts]"
    full_cluster_config_command=""
    host_index=1
    for remote_host in $($ECHO $hosts|tr "," " ")
    do
        if [[ ",$SECURE_CLUSTERS," == *",$cluster,"* ]]; then
            single_host_config_command="${SECURE_REMOTING_CONFIG_COMMAND//#HOST#/$remote_host}"
            SSLREALM_REQUIRED="true"
        else
            single_host_config_command="${REMOTING_CONFIG_COMMAND//#HOST#/$remote_host}"
        fi

        single_host_config_command="${single_host_config_command//#SOCKET_REF#/$cluster-$host_index}"
        full_cluster_config_command=$(appendCommands "$full_cluster_config_command" "$single_host_config_command")
        ((++host_index))
    done
    $ECHO $full_cluster_config_command
}

###############################################################
# Creats jboss-ejb-client.xml file for a deployable entity
###############################################################
process_jboss_ejb_client_xml()
{
    remote_hosts="$1"
    clusters="$2"
    jboss_ejb_client_file="$3"
    info "Starting creation of file[$jboss_ejb_client_file] with hosts[$remote_hosts] and clusters[$clusters]"
    $XSLTPROC --output "$jboss_ejb_client_file" --stringparam remotehosts "$remote_hosts" --stringparam clusters "$clusters" --stringparam secure-clusters "$SECURE_CLUSTERS" "$EJB_CLIENT_XML_DIR/jboss-ejb-client.xsl" "$jboss_ejb_client_file"

    if [ $? == 0 ]
    then
        info "Successfully prepared jboss-ejb-client.xml"
    else
        error "Failed to prepare jboss-ejb-client.xml"
        exit 2
    fi
    $XMLLINT --output "$jboss_ejb_client_file" --format "$jboss_ejb_client_file"
    if [ $? == 0 ]
    then
        info "Successfully formatted jboss-ejb-client.xml"
    else
        error "Failed to format jboss-ejb-client.xml"
        exit 3
    fi
}

###############################################################
# Injects jboss-ejb-client.xml file in deployable entity
###############################################################
inject_ejb_client_xml()
{
    deployable_entity_name="$1"
    deployable_entity_file="$2"
    remote_hosts="$3"
    cluster_names="$4"
    deployable_entity_name_with_version="$5"
    if [ ! -d  "$EJB_CLIENT_XML_DIR/$deployable_entity_name/META-INF" ]
    then
        $MKDIR "$EJB_CLIENT_XML_DIR/$deployable_entity_name/META-INF"
        $CP "$EJB_CLIENT_XML_DIR/jboss-ejb-client-template.xml" "$EJB_CLIENT_XML_DIR/$deployable_entity_name/META-INF/jboss-ejb-client.xml"
        if [ $? == 0 ]
        then
            info "Successfully copied jboss-ejb-client-template.xml to $EJB_CLIENT_XML_DIR/$deployable_entity_name/META-INF"
        else
            error "Failed to copy jboss-ejb-client-template.xml to $EJB_CLIENT_XML_DIR/$deployable_entity_name/META-INF"
            exit 4
        fi
        process_jboss_ejb_client_xml "$remote_hosts" "$cluster_names" "$EJB_CLIENT_XML_DIR/$deployable_entity_name/META-INF/jboss-ejb-client.xml"
    fi
    add_deployment_overlay_command="deployment-overlay add --name=ejb-remoting-overlay-for-${deployable_entity_name} --content=/META-INF/jboss-ejb-client.xml=${EJB_CLIENT_XML_DIR}/${deployable_entity_name}/META-INF/jboss-ejb-client.xml --deployments=${deployable_entity_name_with_version} --redeploy-affected"

    export JAVA_OPTS=''
    ${JBOSS_HOME}/bin/jboss-cli.sh --connect --command="${add_deployment_overlay_command}"
    if [ $? != 0 ]
    then
        error "Failed to add jboss-ejb-client.xml for $deployable_entity_file"
    else
        info "Added jboss-ejb-client.xml successfully for $deployable_entity_file"
    fi
}

###############################################################
# Creates EJB remoting connections
###############################################################
create_ejb_remoting_connections()
{
    full_create_command=""
    for cluster_name in "${!CONNECTION_ARRAY[@]}"
    do
        ip_addresses="${CONNECTION_ARRAY[$cluster_name]}"
        create_command_for_cluster=$(prepare_ejb_remoting_command_for_cluster $cluster_name $ip_addresses)
        full_create_command=$(appendCommands "$full_create_command" "$create_command_for_cluster")
    done
    create_composite_command="${COMPOSITE_COMMAND/\#STEPS\#/$full_create_command}"
    create_response=$(run_jboss_mgmt_rest_api "$create_composite_command")
    create_response_code=$(get_http_response_code "$create_response")
    if [ "$create_response_code" == "$HTTP_SUCCESS_CODE" ]
    then
        info "Successfully created EJB remoting connections"
    else
        error "Failed to create EJB remoting connections"
        exit 6
    fi
}

# Main starts here
logger "${DE_REMOTING_TOPOLOGY}"
for deployable_entity in $DEFAULT_DEPLOYMENT_DIR/*
do
    deployable_entity_name_with_version=$(basename $deployable_entity)
    info "Starting processing of DeployableEntityWithVersion[$deployable_entity_name_with_version]"

    regex='([a-zA-Z-_0-9]*)(?=-[0-9]*.[0-9]*.[0-9])'
    deployable_entity_name=$(echo $deployable_entity_name_with_version | grep -oP $regex)

    info "Name of deployable entity after trimming version information DeployableEntity[$deployable_entity_name]"
    if [[ ${DE_REMOTING_TOPOLOGY[$deployable_entity_name]} != "" ]]
    then
        remote_hosts=""
        cluster_names=""
        configured_clusters="${DE_REMOTING_TOPOLOGY[$deployable_entity_name]}"
        info "Configured EJB remoting $deployable_entity_name[$configured_clusters]"
        for cluster in $(echo $configured_clusters|tr "," " ")
        do
            if [[ ${CONNECTION_ARRAY[$cluster]} == "" ]]
            then
                ip_addresses=$cluster
                if [ "$ip_addresses" == "" ]
                then
                    error "$cluster is not defined in $GLOBAL_CONFIG or it is empty"
                    # Don't fail or exit because, for a single slice deployment, some SG global properties SGs might be missing as expected.
                else
                    CONNECTION_ARRAY[$cluster]="$ip_addresses"
                fi
            fi
            if [[ ${CONNECTION_ARRAY[$cluster]} != "" ]]
            then
                 cluster_names=$(appendCommands "$cluster_names" "$cluster")
                 host_index=1
                 for ip_address in $(echo ${CONNECTION_ARRAY[$cluster]}|tr "," " ")
                 do
                     remote_hosts=$(appendCommands "$remote_hosts" "$cluster-$host_index")
                     ((++host_index))
                 done
	    fi
        done
        inject_ejb_client_xml "$deployable_entity_name" "$deployable_entity" "$remote_hosts" "$cluster_names" "${deployable_entity_name_with_version}"
    else
        info "EJB remoting is not configured for $deployable_entity_name"
    fi
done

create_ejb_remoting_connections

exit 0
