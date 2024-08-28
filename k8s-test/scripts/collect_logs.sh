#!/bin/bash

NAMESPACE=$1
HELM_RELEASE=$2
REMOTE_LOG=$3
LOCAL_LOGS_DIR=$4

for pod_name in $(kubectl get pods --namespace="${NAMESPACE}" --selector app.kubernetes.io/instance="${HELM_RELEASE}" --output=jsonpath='{.items[*].metadata.name}'); do
  kubectl cp --namespace="${NAMESPACE}" "${pod_name}:${REMOTE_LOG}" "${LOCAL_LOGS_DIR}/${pod_name}.${REMOTE_LOG##*/}"
done