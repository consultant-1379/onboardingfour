#!/bin/bash
cacert="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
token="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
NAMESPACE="$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)"
TIMEOUT=/usr/bin/timeout

/sbin/rsyslogd
logger "Starting rsyslog ..."

usage() { echo "Usage: $0 [-s <service1,service2,service3,....>]" 1>&2; exit 1; }

while getopts ":s:" arg; do
    case "${arg}" in
        s)
            services=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${services}" ]; then
    usage
fi

IFS=","
for service in ${services}; do
    while true
    do
      ${TIMEOUT} -s SIGUSR1 10s curl --silent --cacert $cacert --header "Authorization: Bearer $token"  https://kubernetes.default.svc/api/v1/namespaces/${NAMESPACE}/endpoints/${service} | grep -qw "addresses"
      if [ $? -eq 0 ] ;then
        logger "$(date '+%Y-%m-%d %H:%M:%S') - Service query ran successfully,  available : ${service}"
        break
      else
        logger "$(date '+%Y-%m-%d %H:%M:%S') - Waiting for service : ${service}"
        sleep 10
      fi
      done
done
