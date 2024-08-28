ARG OS_BASE_IMAGE_NAME=sles
ARG OS_BASE_IMAGE_REPO=armdocker.rnd.ericsson.se/proj-ldc/common_base_os_release
ARG OS_BASE_IMAGE_TAG

FROM ${OS_BASE_IMAGE_REPO}/${OS_BASE_IMAGE_NAME}:${OS_BASE_IMAGE_TAG}

ARG COMMIT
ARG RSTATE
ARG TIMESTAMP
ARG VERSION

ARG PACKAGE_REPO_URL
ARG SLES_BASE_OS_REPO=sles_base_os_repo
ARG ENM_ISO_REPO_URL
ARG ENM_ISO_REPO_NAME=enm_iso_repo

LABEL \
com.ericsson.product-number="CXU 101 1112" \
com.ericsson.product-revision=$RSTATE \
org.opencontainers.image.title="CBRS DC service Image" \
org.opencontainers.image.created=$TIMESTAMP \
org.opencontainers.image.revision=$COMMIT \
org.opencontainers.image.vendor="Ericsson" \
org.opencontainers.image.version=$VERSION

ARG USER_ID=280236
RUN echo "$USER_ID:x:$USER_ID:0:An identity for eric-cbrs-dc:/nonexistent:/bin/false" >> /etc/passwd && \
    echo "$USER_ID:!::0:::::" >> /etc/shadow

# Have to statically refer to USER_ID - due to https://github.com/moby/moby/issues/35018
COPY --chown=280236:0 image_content/scripts/nonroot/change_permissions.sh /usr/local/bin/change_permissions.sh

# TODO: Remove if Startup/Liveness/Readiness probes are updated
COPY --chown=280236:0 --from=armdocker.rnd.ericsson.se/proj-enm/eric-enm-healthcheck-agent:1.0.0-0 /ericsson/enm_healthcheck/bin/enm_healthcheck.py /ericsson/enm_healthcheck/bin/enm_healthcheck.py

# TODO: Tech Debt! Remove if sles-eap7 (image) content is merged into eap7config (rpm)
COPY --chown=280236:0 image_content/eap-scripts/ /var/tmp/eap-scripts/
COPY --chown=280236:0 image_content/eap-healthcheck/ /var/tmp/eap-healthcheck/

ARG STANDALONE_ENM_XML="/ericsson/3pp/jboss/standalone/configuration/standalone-eap7-enm.xml"
ARG LOGGING_PROPERTIES="/ericsson/3pp/jboss/bin/jboss-cli-logging.properties"

RUN zypper addrepo -C -G -f ${PACKAGE_REPO_URL}?ssl_verify=no $SLES_BASE_OS_REPO && \
    zypper addrepo -C -G -f ${ENM_ISO_REPO_URL}?ssl_verify=no $ENM_ISO_REPO_NAME && \
    zypper dist-upgrade -y && \
    zypper download ERICenmsgdpmediation_CXP9036117  && \
    zypper install -y rsyslog \
    hostname \
    sysvinit-tools \
    curl \
    # SLES - previously needed for vmmonitord - is this still required?
    python \
    # SLES - python2-pycurl - used by pib, default on rhel, needs to be installed on SLES
    python2-pycurl \
    bind-utils \
    EXTRserverjre_CXP9035480 \
    # EAP & SG RPM Dependencies
    bc \
    libxslt1 \
    # libxml2-tools - xmllint
    libxml2-tools \
    # aaa_base - /etc/rc.status init functions
    aaa_base \
    EXTReap7_CXP9037438 \
    ERICeap7config_CXP9037440 \
    ERICmediationengineapi2_CXP9038435 \
    ERICdpsruntimeapi_CXP9030469 \
    ERICserviceframeworkmodule4_CXP9037453 \
    ERICmodelserviceapi_CXP9030594 \
    ERICmodelservice_CXP9030595 \
    ERICdomainproxypersistence_CXP9035433 \
    ERICdomainproxyservice_CXP9035414 \
    ERICsessionmanagerapi_CXP9031998 \
    ERICnetconfsessionapi_CXP9032052 \
    ERICcbanetconfmanager_CXP9031308 \
    ERICtransportapi_CXP9031610 \
    ERICcryptographyservice_CXP9031013 \
    ERICcryptographyserviceapi_CXP9031014 \
    ERICtlstransportlibrary_CXP9031764 \
    ERICpostgresqljdbc_CXP9031176 \
    ${SLES_BASE_OS_REPO}:postgresql10 && \
    rpm -ivh --replacefiles /var/cache/zypp/packages/enm_iso_repo/ERICenmsgdpmediation_CXP9036117*.rpm --nodeps --noscripts && \
    zypper clean -a && \
    zypper removerepo $SLES_BASE_OS_REPO && \
    zypper removerepo $ENM_ISO_REPO_NAME && \
    rm -rf /var/log/*log /var/log/zypp/ /usr/lib/sysimage/rpm/ /var/log/YaST2/ && \
    rpm --rebuilddb && \
    # TODO: Tech Debt! Remove if sles-eap7 (image) content is merged into eap7config (rpm)
    cp -r /var/tmp/eap-scripts/* /ericsson/3pp/jboss/ && \
    cp -r /var/tmp/eap-healthcheck/* /usr/lib/ocf/resource.d/ && \
    rm -rf /var/tmp/eap-scripts/ /var/tmp/eap-healthcheck/ && \
    # Following scripts delivered by SG RPM
    #   configure_dns.sh file removed to fix postgres connectivity
    #   oomKillerTuning.sh file removed for unsafe sysctl usage
    rm -f /ericsson/3pp/jboss/bin/pre-start/configure_dns.sh /ericsson/3pp/jboss/bin/pre-start/oomKillerTuning.sh && \
    # POSTGRES Stuff
    mkdir -p /opt/rh/postgresql92/root/usr/ && \
    ln -s /usr/lib/postgresql10/bin /opt/rh/postgresql92/root/usr/ && \
    # RSYSLOG Stuff
    sed -i 's/local5/user/g' /ericsson/3pp/jboss/bin/jbosslogger && \
    rm -f /etc/rsyslog.d/remote.conf && \
    # TODO: Can these updates to $STANDALONE_ENM_XML be made at source
    sed -i '/property name="syslogType"/a \ <property name="port" value="5140"/>' $STANDALONE_ENM_XML && \
    sed -i '/<property\s\+name="truncate"/s/value="false"/value="true"/' $STANDALONE_ENM_XML && \
    sed -i '/<property\s\+name="maxLength"/s/value="65000"/value="63000"/' $STANDALONE_ENM_XML && \
    sed -i '/handler.SYSLOG.syslogType=/a handler.SYSLOG.port=5140' $LOGGING_PROPERTIES && \
    # Create /ericsson/tor/data/ "mountpoint" for ConfigMaps
    mkdir -p /ericsson/tor/data/ && \
    # Non-root
    chgrp root /run/lock && \
    chmod 775 /ericsson/3pp && \
    bash /usr/local/bin/change_permissions.sh && \
    find /var/log -exec chmod g=u {} \; && \
    chmod g=u /run /usr/java/default/jre/lib/security/cacerts && \
    chmod u+s /usr/bin/chown && \
    # TODO: Investigate ulimit requirements & handling
    sed -i '$ i\*               -       nofile          10240' /etc/security/limits.conf && \
    sed -i '$ i\*           -       nproc           10240' /etc/security/limits.conf && \
    # Timezone?
    rm -f /etc/localtime && \
    # RHEL to SLES mapping
    mkdir -p /etc/rc.d/init.d/ && \
    ln -s /ericsson/3pp/jboss/bin/initfunctions /etc/init.d/functions && \
    ln -s /ericsson/3pp/jboss/bin/initfunctions /etc/rc.d/init.d/functions && \
    rm /etc/init.d/jboss

# TODO: Once rsyslog dependency is removed, delete the basescripts/healthcheck directory and remove these lines
COPY image_content/omelasticsearch.so /usr/lib64/rsyslog/omelasticsearch.so
COPY image_content/rsyslog.d/* /etc/rsyslog.d/
COPY image_content/rsyslog.conf /etc/rsyslog.conf
COPY --chown=280236:0 image_content/scripts/healthcheck/ /usr/lib/ocf/resource.d/
RUN chmod 771 /usr/lib/ocf/resource.d/rsyslog-healthcheck.sh

#############################################
# TODO: Remove this MASSIVE TECH DEBT!!!!
#       ROOTCACERT_FILE installed by OpenDJ RPM in ENM into /ericsson/tor/data - not available here
#############################################
RUN sed -i '/^__configure_keystore() {/a \ \ \ \ \ \ \ \ return 0' /ericsson/3pp/jboss/bin/configure_production_env.sh

ENV JAVA_HOME=/usr/java/latest \
    PATH=$PATH:$JAVA_HOME/bin:/sbin:/usr/sbin \
    GLOBAL_CONFIG="/gp/global.properties" \
    ENM_JBOSS_SDK_CLUSTER_ID="dpmediation"

# TODO: Is this needed? If so, check the ports
EXPOSE 8080 9990 9999

USER $USER_ID

ENTRYPOINT ["/ericsson/3pp/jboss/entry_point.sh"]
