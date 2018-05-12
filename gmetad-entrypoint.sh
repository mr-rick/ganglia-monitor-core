#!/bin/bash

declare -x -A GMETAD_SOURCES
while read -d $'\n' KUBECTL_NODE
do
  KUBE_NODE=$(echo $KUBECTL_NODE | cut -d ' ' -f1)
  NODE_LABELS=$(echo $KUBECTL_NODE | cut -d ' ' -f2)
  export NODE_ROLE=$KUBE_NODE
  IFS=$','
  for LABEL in $NODE_LABELS
    do
      if [[ $LABEL = *"ganglia/role="* ]]; then
        NODE_ROLE=$(echo $LABEL | cut -d '=' -f2)
      fi
    done;
  unset IFS
  read -r NAMESPACE KUBE_SERVICE <<< `kubectl get services --all-namespaces -l "ganglia/role=$NODE_ROLE" | grep $NODE_ROLE | head -n1 | awk '{ print $1,$2}' `
  GANGLIA_GMOND_UNICAST_HOST=$(kubectl describe service $KUBE_SERVICE -n $NAMESPACE | grep Endpoints | head -n1 | awk '{print $2}' | tr ',' '\n' | sort -n | cut -d ':' -f1)
  [[ -z $GANGLIA_GMOND_UNICAST_HOST  ]] && GANGLIA_GMOND_UNICAST_HOST=$KUBE_NODE
  GMETAD_SOURCES[$NODE_ROLE]=$GANGLIA_GMOND_UNICAST_HOST
done < <(kubectl get nodes --show-labels | grep -v NAME | awk '{ print $1,$6 }')

echo "" > /etc/ganglia/gmetad.conf
for GMETAD_KEY in "${!GMETAD_SOURCES[@]}"
do
  echo "data_source \"$GMETAD_KEY\" ${GMETAD_SOURCES[$GMETAD_KEY]}" >> /etc/ganglia/gmetad.conf
done
echo "rrd_rootdir \"/var/lib/ganglia/rrds\"" >> /etc/ganglia/gmetad.conf

gmetad -d 1
