#!/bin/bash

export GANGLIA_NODE_ROLE=$(kubectl get node $KUBERNETES_NODENAME -o jsonpath='{.metadata.labels.ganglia/role}')
[[ -z $GANGLIA_NODE_ROLE  ]] && GANGLIA_NODE_ROLE="NULL"
if [[ ! $GANGLIA_NODE_ROLE = *"NULL"* ]]; then
  export GANGLIA_GMOND_UNICAST_HOST=$(kubectl get nodes -l ganglia/role=$GANGLIA_NODE_ROLE -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' | tr ' ' '\n' | sort -n | head -n1)
  [[ -z $GANGLIA_GMOND_UNICAST_HOST  ]] && GANGLIA_GMOND_UNICAST_HOST=localhost
fi

export GANGLIA_CLUSTER_NAME=$KUBERNETES_NODENAME
if [[ ! $GANGLIA_NODE_ROLE = *"NULL"* ]]; then
  GANGLIA_CLUSTER_NAME=$GANGLIA_NODE_ROLE
fi

kubectl label pod -n ganglia $KUBERNETES_POD_NAME ganglia/role=$GANGLIA_NODE_ROLE

echo "GANGLIA_GMOND_UNICAST_HOST=$GANGLIA_GMOND_UNICAST_HOST"
envsubst < /tmp/ganglia-gmond/gmond.conf.template > /etc/ganglia/gmond.conf
gmond -d 2
