#!/bin/sh

_KEYTOOL=/usr/java/default/bin/keytool

_MV='/bin/mv -f'

ADDTIONAL_JAVA_OPTS=""

# Source jboss logger methods
. $JBOSS_HOME/bin/jbosslogger

. $JBOSS_HOME/bin/utilities/network_utilities.sh

REMOTE_EJB_CONFIGURATION_FILE="$JBOSS_HOME/bin/jboss-as-remote-ejb.conf"

declare -A DE_REMOTING_TOPOLOGY

# SGs should provide this file for EJB remoting configuration
if [ -x "$REMOTE_EJB_CONFIGURATION_FILE" ]
then
    source $REMOTE_EJB_CONFIGURATION_FILE
    userinfo "Remoting Topology: ${DE_REMOTING_TOPOLOGY[*]}" "REMOTE_EJB_CONF"
fi

if [ -z "$JBOSS_CONF" ]; then
  JBOSS_CONF="$JBOSS_HOME/jboss-as.conf"
fi
[ -r "$JBOSS_CONF" ] && . "${JBOSS_CONF}"

if [ -z "$MAX_DIRECT_MEMORY" ]; then
    MAX_DIRECT_MEMORY=1024
fi

if [ -z "$GC_OPTION" ]; then
	GC_OPTION='UseParallelGC'
fi

if [ -z "$XX_OPTIONS" ]; then
	XX_OPTIONS='-XX:+UnlockExperimentalVMOptions -XX:+AggressiveOpts -XX:+UseFastAccessorMethods'
fi

if [ -z "$SDK_CACHE_PATH" ]; then
	SDK_CACHE_PATH='/ericsson/3pp/jboss/standalone/data'
fi

if [ -z "$SDK_BUR_PATH" ]; then
	SDK_BUR_PATH='/ericsson/tor/data/enmbur'
fi

if [ -z "$DPS_IGNORE_MEDIATION" ]; then
	DPS_IGNORE_MEDIATION='false'
fi

if [ -z "$SDK_TRACE" ]; then
	SDK_TRACE='off'
fi

if [ -z "$EJB_TRANSACTION_TIMEOUT" ]; then
    EJB_TRANSACTION_TIMEOUT=300
fi


#######################################
# Action :
#   mover_batch_processing_module :
#	Batch module must be moved into
#   /ericsson/3pp/jboss/modules
#   as it overrides default JBoss
#   configuration
# Globals:
#   EXT_MODULES
#   JBOSS_MODULES
# Arguments:
# Returns:
#
#######################################
__move_batch_processing_module() {
	if [ -d "${EXT_MODULES}/javax/batch" ]; then
		$_MV "${EXT_MODULES}/javax/batch/" "$JBOSS_MODULES/javax/"
		$_MV "${EXT_MODULES}/javaee/api/main/module.xml" "$JBOSS_MODULES/javaee/api/main/module.xml"
		$_MV "${EXT_MODULES}/org/jberet" "$JBOSS_MODULES/org/"
		$_MV "${EXT_MODULES}/org/wildfly" "$JBOSS_MODULES/org"
	fi
}

#######################################
# Action :
#   configure_jgroups : Define an
#   external folder for the SDK to
#   look for configuration XML(s)
#   and configure the protocol stack
# Globals:
#   JBOSS_HOME
#   ADDTIONAL_JAVA_OPTS
#   JGROUPS_STACK
#   INTERNAL_GOSSIPROUTERS
#   GOSSIPROUTERS
# Arguments:
#   Message string
# Returns:
#
#######################################
__configure_jgroups() {
ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -Dcom.ericsson.oss.itpf.sdk.external.configuration.folder.path=$JGROUPS_CONF -Djgroups.ipmcast.prefix=FF02:: -Djgstack=$JGROUPS_STACK -Dgossiprouters_for_sfwk=$GOSSIPROUTERS_FOR_SFWK -Dgossiprouters_for_eap=$GOSSIPROUTERS_FOR_EAP -Ddeployment.type.cloud=$IS_CLOUD_DEPLOYMENT"
}

#######################################
# Action :
#   configure_keystore
# Globals:
#   None
# Arguments:
#   Message string
# Returns:
#
#######################################
__configure_keystore() {
	info "Adding certificate to keystore."
	$_KEYTOOL -list -keystore $JVM_CACERTS_STORE -alias root -storepass changeit > /dev/null 2>&1
	if [ $? -eq 0 ] ; then
		info "Certificate already exists nothing to do."
		return 0
	else
		 $_KEYTOOL -noprompt -import -trustcacerts -alias root -file $ROOTCACERT_FILE -storepass changeit -keystore $JVM_CACERTS_STORE > /dev/null 2>&1
		 if [ $? -eq 0 ] ; then
			 info "Certificate added to keystore."
			 return 0
	 	 else
		 	error "Failed to add certificate to keystore."
		 	return 1
    	 fi
    fi
}


#######################################
# Action :
#   __set_memory_max
#   Sets the memory max value
# Globals:
#   ADDTIONAL_JAVA_OPTS
#   DEFAULT_MEM
# Arguments:
#   None
# Returns:
#
#######################################
__set_memory_max() {
  if [ ! -z "$MEMORY_MAX" ]; then
      # make sure memory settings are fist option in JVM arguments
      ADDTIONAL_JAVA_OPTS="-Xmx${MEMORY_MAX}m -Xms${MEMORY_MAX}m $ADDTIONAL_JAVA_OPTS"
  else
    ADDTIONAL_JAVA_OPTS="-Xmx${DEFAULT_MEM}m -Xms${DEFAULT_MEM}m $ADDTIONAL_JAVA_OPTS"
  fi
}

#######################################
# Action :
#   set the extra JAVA_OPTS arguments
#   provided by SG RPM.
#   e.g. SG can provide EXTRA_JAVA_OPTS=
#   "-Dkey1=value1 -Dkey2=value2" in
#   jboss-as.conf
# Globals:
#   ADDTIONAL_JAVA_OPTS
#   EXTRA_JAVA_OPTS
# Arguments:
# Returns:
#
#######################################
__set_extra_java_opts() {
    if [ ! -z "$EXTRA_JAVA_OPTS" ]; then
        ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS $EXTRA_JAVA_OPTS"
    fi
}

#######################################
# Action :
#   __set_jboss_file_logging : Sets the JAVA_OPTS
# to enable or disable the jboss server's logging
# to file.
# Globals:
#   LOG_TO_FILE
#   ADDTIONAL_JAVA_OPTS
# Arguments:
#   Message string
# Returns:
#
#######################################
__set_jboss_file_logging() {

    if [ "$LOG_TO_FILE" != "false" ]; then
        LOG_TO_FILE="true"
    fi

    ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -Djboss.server.file.log.enabled=${LOG_TO_FILE}"
}


#######################################
# Action :
#   __set_jvm_memory_configuration :
# Globals:
#   ADDTIONAL_JAVA_OPTS
#   PERM_GEN
#   MAX_META_SPACE
#   MAX_DIRECT_MEMORY
#   GC_OPTION
#   XX_OPTIONS
# Arguments:
#   Message string
# Returns:
#
#######################################
__set_jvm_memory_configuration() {

    if [ -z "$DPS_PERSISTENCE_PROVIDER" ] || [ "$DPS_PERSISTENCE_PROVIDER" == "versant" ]; then
        __set_memory_config_for_dps
    fi

    # Use MAX_META_SPACE for java version above 1.7. MetaspaceSize should be same size as MaxMetaspaceSize
    if [ "$JAVA_VER" -gt 7 ]; then
        ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -XX:MetaspaceSize=${INITIAL_META_SPACE}m -XX:MaxMetaspaceSize=${MAX_META_SPACE}m -XX:MaxDirectMemorySize=${MAX_DIRECT_MEMORY}m -XX:+${GC_OPTION} ${XX_OPTIONS}"
    else
        ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -XX:MaxPermSize=${PERM_GEN}m -XX:MaxDirectMemorySize=${MAX_DIRECT_MEMORY}m -XX:+${GC_OPTION} ${XX_OPTIONS}"
    fi
}

#######################################
# Action :
#   __set_jvm_memory_for_dps : Ensures the MaxPermSize / MaxMetaspaceSize is set
# to accommodate hot-deploy of DPS JPA Entities EAR
# Globals:
#   JAVA_VER
#   PERM_GEN
#   MAX_META_SPACE
# Arguments:
#   Message string
# Returns:
#
#######################################
__set_memory_config_for_dps() {
    # Set expected MaxPermSize / MaxMetaspaceSize if DPS is deployed
    MEMORY_SIZE_WITH_DPS_EAR=670
    # Location of DPS Persistence service runtime EAR
    DPS_PERSISTENCE_SERVICE_RUNTIME_EAR="$JBOSS_HOME/standalone/deployments/data-persistence-service-runtime-*.ear"

    # If DPS Client EAR is deployed, ensure memory settings are large enough to deploy DPS JPA EAR
    if [ -f ${DPS_PERSISTENCE_SERVICE_RUNTIME_EAR} ]; then
        # Use MAX_META_SPACE for java version above 1.7
        if [ "$JAVA_VER" -gt 7 ]; then
            if [ -z "$MAX_META_SPACE" ] || [ "$MAX_META_SPACE" -lt "$MEMORY_SIZE_WITH_DPS_EAR" ]; then
                MAX_META_SPACE=${MEMORY_SIZE_WITH_DPS_EAR}
            fi
        else
            if [ -z "$PERM_GEN" ] || [ "$PERM_GEN" -lt "$MEMORY_SIZE_WITH_DPS_EAR" ]; then
                PERM_GEN=${MEMORY_SIZE_WITH_DPS_EAR}
            fi
        fi
    fi
}

#######################################
# Action :
#   __set_sdk_configuration : Set the JAVA_OPTS
#  for sdf configuration
# Globals:
#   ADDTIONAL_JAVA_OPTS
#   SDK_CACHE_PATH
#   SDK_BUR_PATH
#   SDK_TRACE
# Arguments:
#   Message string
# Returns:
#
#######################################
__set_sdk_configuration() {
	# Set SDK CACHE PATH
	ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -Dcom.ericsson.oss.itpf.sdk.cache.persistence.location.absolute.path=${SDK_CACHE_PATH}"

	# Set SDK BUR PATH
	ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -Dsfwk.restore.burfolder.location.absolute.path=${SDK_BUR_PATH}"

    # Set SDK trace option
	ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -Dcom.ericsson.oss.itpf.sdk.tracing.autoannotate=${SDK_TRACE}"
}

#######################################
# Action :
#   __set_sdk_cluster_id : Set the JAVA_OPTS
#  for sdk cluster ID
# Globals:
#   ADDTIONAL_JAVA_OPTS
#   THIS_HOST
# Arguments:
#   Message string
# Returns:
#
#######################################
__set_sdk_cluster_id() {
  ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -Dcom.ericsson.oss.sdk.cluster.identifier=${ENM_JBOSS_SDK_CLUSTER_ID}"
}

#######################################
# Action :
#   __set_sdk_cluster_id : Set the JAVA_OPTS
#  for sdk ejb remoting topology
# Globals:
#   ADDTIONAL_JAVA_OPTS
# Arguments:
#   Message string
# Returns:
#
#######################################
__set_sdk_remoting_topology() {
	remoting_topology=""
	regex='([a-zA-Z-_0-9]*)(?=-[0-9]*.[0-9]*.[0-9])'

	for deployable_entity in $JBOSS_HOME/standalone/deployments/*
	do
		deployable_entity_name_with_version=$(basename $deployable_entity)
		deployable_entity_name=$(echo $deployable_entity_name_with_version | grep -oP $regex)

		if [[ ${DE_REMOTING_TOPOLOGY[$deployable_entity_name]} != "" ]]
		then
			remoting_topology="$remoting_topology -Dsdk.eservice.remoting.topology.$deployable_entity_name=${DE_REMOTING_TOPOLOGY[$deployable_entity_name]}"
		fi
	done
	ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS ${remoting_topology}"
}

#######################################
# Action :
#   __set_dps_ignore_mediation_option :
# Globals:
#   ADDTIONAL_JAVA_OPTS
#   DPS_IGNORE_MEDIATION
# Arguments:
#   Message string
# Returns:
#
#######################################
__set_dps_ignore_mediation_option() {
	ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -Ddps_ignore_mediation=${DPS_IGNORE_MEDIATION}"
}

################################################
# Action :
#   __set_external_vips :
#  Passed useProxy flag with configured
#  VIPs to JVM as system properties
################################################
__set_external_vips(){

        ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -DuseProxy=true"
        ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -Dfm_VIP=$FM_VIP_ADDRESS -Dcm_VIP=$CM_VIP_ADDRESS -Dpm_VIP=$PM_VIP_ADDRESS"

}

__set_external_ipv6_vips(){
        cm_ipv6_VIP=$CM_VIP_ADDRESS_IPV6
        fm_ipv6_VIP=$FM_VIP_ADDRESS_IPV6
        pm_ipv6_VIP=$PM_VIP_ADDRESS_IPV6
        # Get rid of CIDR format for VIPs if used
	if [ "$cm_ipv6_VIP" != "" ]
	then
            cm_ipv6_VIP=${cm_ipv6_VIP%%/*}
	    ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -Dcm_ipv6_VIP=$cm_ipv6_VIP"
        fi
	if [ "$fm_ipv6_VIP" != "" ]
	then
            fm_ipv6_VIP=${fm_ipv6_VIP%%/*}
	    ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -Dfm_ipv6_VIP=$fm_ipv6_VIP"
        fi
	if [ "$pm_ipv6_VIP" != "" ]
	then
            pm_ipv6_VIP=${pm_ipv6_VIP%%/*}
	    ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -Dpm_ipv6_VIP=$pm_ipv6_VIP"
        fi
}

#######################################
# Action :
#   __set_ejb_remote_transaction_timeout : Sets the JAVA_OPTS
# for ejb remote transaction timeout
# Globals:
#   EJB_TRANSACTION_TIMEOUT
#   ADDTIONAL_JAVA_OPTS
# Arguments:
# Returns:
#
#######################################
__set_ejb_remote_transaction_timeout() {

	ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -Dorg.jboss.as.ejb3.remote-tx-timeout=${EJB_TRANSACTION_TIMEOUT}"
}

#######################################
# Action :
#   __set_timezone : Sets the JAVA_OPTS
# for user.timezone. Only applies to
# Europe/Zurich to resolve a JDK Bug.
# Globals:
#   ADDTIONAL_JAVA_OPTS
# Arguments:
# Returns:
#
#######################################
__set_timezone() {

        if [ -f "/etc/sysconfig/clock" ];
        then
            timezone=$(sed 's/ZONE=//g' /etc/sysconfig/clock)

            if [[ "${timezone,,}" == *"europe/zurich"* ]];
            then
                ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -Duser.timezone='Europe/Zurich'"
            fi
        fi
}

#######################################
# Action :
#    __set_jgroups_stack_config
#   Sets the jgroups protocol stack configuration
# Globals:
#   ADDTIONAL_JAVA_OPTS
#   JGROUPS_CONF
#   JGROUPS_STACK
#   GOSSIPROUTERS_FOR_EAP
#   GOSSIPROUTERS_FOR_SFWK
# Arguments:
#   None
# Returns:
#
#######################################
__set_jgroups_stack_config() {

if [ "${JGROUPS_STACK}" == "tcp-gossip" ]; then
   JGROUPS_CONF="$JBOSS_HOME/standalone/data/jgroupscloudconfig"
else
   JGROUPS_CONF="$JBOSS_HOME/standalone/data/consolidatedjgroups"
   GOSSIPROUTERS_FOR_EAP=""
   GOSSIPROUTERS_FOR_SFWK=""
fi
}

__set_dps_persistence_provider() {
   ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -Ddps.persistence.provider=${DPS_PERSISTENCE_PROVIDER}"
}

__set_dps_connection_mode(){
if [ "$DPS_PERSISTENCE_PROVIDER" == "neo4j" ]; then
    if [ "$NEO4J_CLUSTER" == "causal" ]; then
        ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -Dneo4j.serverTransport=bolt_routing"
    else
        ADDTIONAL_JAVA_OPTS="$ADDTIONAL_JAVA_OPTS -Dneo4j.serverTransport=bolt"
    fi
fi
}

__configure_production_environment() {

    __set_jvm_memory_configuration

    __set_sdk_configuration

    __set_sdk_cluster_id

    __set_sdk_remoting_topology

    __set_memory_max

    __set_dps_ignore_mediation_option

    __set_jgroups_stack_config

    __set_external_vips

    __set_external_ipv6_vips

    __move_batch_processing_module

    __configure_jgroups

    __set_jboss_file_logging

    __set_ejb_remote_transaction_timeout

    __set_timezone

    __set_extra_java_opts

    __configure_keystore
    if [ $? -ne 0 ]; then
       ADDTIONAL_JAVA_OPTS=""
    fi

    __set_dps_persistence_provider

    __set_dps_connection_mode

    echo $ADDTIONAL_JAVA_OPTS
}

__configure_production_environment

