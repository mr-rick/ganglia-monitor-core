#!/bin/bash

export GANGLIA_NODE_ROLE=$(kubectl get node $KUBERNETES_NODENAME -o jsonpath='{.metadata.labels.ganglia/role}')
[[ -z $GANGLIA_NODE_ROLE  ]] && GANGLIA_NODE_ROLE="NULL"

export GANGLIA_CLUSTER_NAME=$KUBERNETES_NODENAME
if [[ ! $GANGLIA_NODE_ROLE = *"NULL"* ]]; then
  GANGLIA_CLUSTER_NAME=$GANGLIA_NODE_ROLE
fi

kubectl label pod $KUBERNETES_POD_NAME ganglia/role=$GANGLIA_NODE_ROLE

export GANGLIA_GMOND_UNICAST_HOST=$(kubectl describe service -l ganglia/role=$GANGLIA_NODE_ROLE | grep Endpoints | head -n1 | awk '{print $2}' | tr ',' '\n' | sort -n | cut -d ':' -f1)
[[ -z $GANGLIA_GMOND_UNICAST_HOST  ]] && GANGLIA_GMOND_UNICAST_HOST=localhost

echo "GANGLIA_GMOND_UNICAST_HOST=$GANGLIA_GMOND_UNICAST_HOST"
envsubst < /tmp/ganglia-gmond/gmond.conf.template > /etc/ganglia/gmond.conf
sleep 30
gmond -d 2
