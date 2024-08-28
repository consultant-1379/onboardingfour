#!/bin/bash
###########################################################################
#COPYRIGHT Ericsson 2020
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
###########################################################################

# UTILITIES
RPM="/bin/rpm --quiet"
MODELSERVICE_MODULE="/opt/ericsson/jboss/modules/com/ericsson/oss/itpf/modeling/modelservice/api/main/model-service-api-jar-*.jar"
SFWK4_MODULE="/ericsson/3pp/jboss/modules/system/layers/base/com/ericsson/oss/itpf/sdk/service-framework/4.x/module.xml"
VAULT_LOGIN_MODULE="/opt/ericsson/jboss/modules/com/ericsson/oss/itpf/security/vaultservice/main/module.xml"

# GLOBAL VARIABLES
if [ -z "$JBOSSEAP7_CONFIG" ]; then
    JBOSSEAP7_CONFIG="standalone-eap7-enm.xml"
fi

# SOURCE_ORIG_JBOSS_CONF, this must happen before JBOSS_CONF
[ -n "$SOURCE_ORIG_JBOSS_CONF" ] && . "${SOURCE_ORIG_JBOSS_CONF}"
if [ -z "$JBOSS_CONF" ]; then
  JBOSS_CONF="$JBOSS_HOME/jboss-as.conf"
fi
[ -r "$JBOSS_CONF" ] && . "${JBOSS_CONF}"

CLI_SYSTEM_PROPERTIES="-Djboss.transaction.id=${JBOSS_TRANSACTION_ID}"
STANDALONE_FILE="$JBOSS_HOME/standalone/configuration/$JBOSSEAP7_CONFIG"
FOLDER_CLI="$JBOSS_HOME/bin/cli"
JMS_TOPIC_CLI_FILE="$FOLDER_CLI/common/create_jms_topic.cli"
VAULT_CLI_FILE="$FOLDER_CLI/common/create_vault.cli"
DATASOURCE_CLI_FILE="$FOLDER_CLI/common/create_datasource.cli"
MODELSERVICE_GLOBAL_MODULE_FILE="$FOLDER_CLI/common/insert_modelservice_global_module.cli"
SFWK_GLOBAL_MODULE_FILE="$FOLDER_CLI/common/insert_sfwk_global_module.cli"
CONF_FILE="$JBOSS_HOME/jboss-as.conf"
DEFAULT="$JBOSS_HOME/standalone/configuration/default.properties"
SYSTEM_ENV_FILE="$FOLDER_CLI/cli-system-env.properties"

LOG_TAG="ERICeap7config"

#//////////////////////////////////////////////////////////////
# This function will print an info message to /var/log/messages
# Arguments:
#       $1 - Message
# Return: 0
#/////////////////////////////////////////////////////////////
info()
{
    logger -t ${LOG_TAG} -p user.info "$1"
}

###################################################################
#
# Method checks if model service api module is installed
# on this system
#
###################################################################
checkModelServiceRPMInstalled() {
    # check if model service module is installed
    if [ ! -f $MODELSERVICE_MODULE ]; then
        info "As $MODELSERVICE_MODULE is not installed in this VM, removing model service specific configurations"
        /bin/rm $MODELSERVICE_GLOBAL_MODULE_FILE
    fi
}

###################################################################
#
# Method checks if serviceframework module is installed
# on this system
# if serviceframework is not installed then this script will Exit with code 0
#
###################################################################
checkSFWKRPMInstalled() {
    # check if SFWK module is installed -- if not remove sfwk configurations
    if [ ! -f "$SFWK4_MODULE" ]; then
        info "ServiceFramework Module is not installed in this VM, removing SFWK specific configuration updates."
        /bin/rm "$JMS_TOPIC_CLI_FILE" "$DATASOURCE_CLI_FILE" "$SFWK_GLOBAL_MODULE_FILE" "$VAULT_CLI_FILE"
    fi
}

###################################################################
#
# Method checks if vault login module is installed
# on this system
#
###################################################################
checkVLMInstalled() {
    # check if Vault login module is installed --
    if [ -f $VAULT_LOGIN_MODULE ]; then
        info "Vault is installed, configuring the datasource"
        /bin/sed -i 's/user-name=sfwk,password=sfwk#db/security-domain=VaultSfwk/' $DATASOURCE_CLI_FILE
    else
        info "Vault is not installed, removing vault specific configurations"
        /bin/rm $VAULT_CLI_FILE
    fi
}

##############################################################################
#
# Method check ejb_cluster_name and update to the service name of the SG
#
##############################################################################
check_and_update_ejb_cluster_name()
{
   AWK="/bin/awk"
   ECHO="/bin/echo"
   XMLLINT="/usr/bin/xmllint"
   SED="/bin/sed"
   GREP="/bin/grep"

    EJB_CLUSTER_NAME=$($ECHO "xpath string(/*[local-name()='server']/*[local-name()='profile']/*[local-name()='subsystem']/*[name()='cache-container'][@module='org.jboss.as.clustering.ejb3.infinispan']/@name)" | $XMLLINT --shell  $STANDALONE_FILE | $GREP "Object is a string :" | $SED -e "s/[<>/]//g" | $AWK -F ": " '{print $2}')
        if [ "$EJB_CLUSTER_NAME" == "ejb_cluster_name" ]
        then
                $SED -i "s/ejb_cluster_name/$ENM_JBOSS_SDK_CLUSTER_ID/g" "$STANDALONE_FILE"
        fi
}

#######################################################
#
# Method merges all the cli scripts, generating the
# standalone_common_configuration.cli and
# standalone_service_configuration.cli
#
########################################################
generateConfigureStandaloneCLI() {
    cd "$FOLDER_CLI" || exit
    i=0
    echo -e "set vm_identity=$ENM_JBOSS_SDK_CLUSTER_ID \n\n" >> service_name.cli
    echo -e "# Add vm_identity as a system property" >> service_name.cli
    echo -e "if (outcome != \"success\") of :resolve-expression(expression=\${vm_identity})" >> service_name.cli
    echo -e "/system-property=vm_identity:add(value=\$vm_identity)" >> service_name.cli
    echo -e "end-if \n\n" >> service_name.cli
    for file in common/* ; do
       if [[ ${file: -4} == ".cli" ]] ; then
          aux=$i
          ((i++))
          if [ $aux -eq 0 ] ; then
              info "Start merging cli scripts from common folder"
              cat start.cli service_name.cli "$file" > merging$i.cli
              echo -e "\n#--------------------------------------------------------\n#    end of ${file##*/}    \n#--------------------------------------------------------" >> merging$i.cli
              echo -e "\n\n" >> merging$i.cli
              info "file ${file##*/} merged"
          else
              cat merging$aux.cli "$file" > merging$i.cli
              echo -e "\n#--------------------------------------------------------\n#    end of ${file##*/}    \n#--------------------------------------------------------" >> merging$i.cli
              echo -e "\n\n" >> merging$i.cli
              info "file ${file##*/} merged"
         fi
       fi
    done
    /bin/mv merging$i.cli "$FOLDER_CLI"/merged.cli
    /bin/rm merging*.cli
    cat merged.cli stop.cli > standalone_common_configuration.cli
    /bin/rm merged.cli
    info "Merge finished generating standalone_common_configuration.cli. You can find it at /ericsson/3pp/jboss/bin/cli/standalone_common_configuration.cli "
    STANDALONE_CLI_FILE="$FOLDER_CLI/standalone_common_configuration.cli"
    configureStandalone

    i=0
    containsCLIFile=false
    for file in services/* ; do
        if [[ ${file: -4} == ".cli" ]] ; then
           containsCLIFile=true
           aux=$i
           ((i++))
           if [ $aux -eq 0 ] ; then
              info "Start merging cli scripts from service folder"
              cat start.cli service_name.cli "$file" > merging$i.cli
              echo -e "\n#--------------------------------------------------------\n#    end of ${file##*/}    \n#--------------------------------------------------------" >> merging$i.cli
              echo -e "\n\n" >> merging$i.cli
              info "file ${file##*/} merged"
           else
              cat merging$aux.cli "$file" > merging$i.cli
              echo -e "\n#--------------------------------------------------------\n#    end of ${file##*/}    \n#--------------------------------------------------------" >> merging$i.cli
              echo -e "\n\n" >> merging$i.cli
              info "file ${file##*/} merged"
           fi
        fi
    done
    /bin/rm service_name.cli
    if [[ "$containsCLIFile" == "false" ]] ; then
        info "No cli files to be merge in service folder"
        /bin/rm standalone_service_configuration.cli
    else
        /bin/mv merging$i.cli "$FOLDER_CLI"/merged.cli
        /bin/rm merging*.cli
        cat merged.cli stop.cli > standalone_service_configuration.cli
        /bin/rm merged.cli
        info "Merge finished generating standalone_service_configuration.cli. You can find it at /ericsson/3pp/jboss/bin/cli/standalone_service_configuration.cli "
        STANDALONE_CLI_FILE="$FOLDER_CLI/standalone_service_configuration.cli"
        configureStandalone
    fi
    cd ~ || exit
}


##############################################
# Configure the standalone configuration file
#############################################
configureStandalone() {
if [ -f $STANDALONE_CLI_FILE ] && [ -f $STANDALONE_FILE ]; then
    info "Configuring the $STANDALONE_FILE file using the $STANDALONE_CLI_FILE"
    printenv > $SYSTEM_ENV_FILE
    $JBOSS_HOME/bin/jboss-cli.sh ${CLI_SYSTEM_PROPERTIES} --file=$STANDALONE_CLI_FILE --properties=$DEFAULT --properties=$CONF_FILE --properties=$SYSTEM_ENV_FILE
else
        info "File $STANDALONE_CLI_FILE or $STANDALONE_FILE not found"
fi
}

##########################################################
# Insert environmental variables into default properties #
# Return: 0
##########################################################
updateDefaultPropertiesWithEnvVar() {
    if [[ ! -z "$POSTGRES_SERVICE" ]]; then
        info "Inserting POSTGRES_SERVICE=$POSTGRES_SERVICE into JBoss default.properties"
        echo "POSTGRES_SERVICE=$POSTGRES_SERVICE" >> $DEFAULT
    fi
}


#main
checkModelServiceRPMInstalled
checkSFWKRPMInstalled
checkVLMInstalled
check_and_update_ejb_cluster_name
updateDefaultPropertiesWithEnvVar
generateConfigureStandaloneCLI
