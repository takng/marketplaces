#!/bin/bash

WHD_HOME=$(ls -d /usr/local/webhelpdesk)

echo "WHD_HOME: $WHD_HOME"

if [ -f "$WHD_HOME" ]
then
  # Check if Instance Started

  if [ ! -f $WHD_HOME/conf/whd.conf ] 
  then
     cp $WHD_HOME/conf/whd.conf.orig $WHD_HOME/conf/whd.conf
  fi
  sed -i 's|^PRIVILEGED_NETWORKS=[[:space:]]*$|PRIVILEGED_NETWORKS=0.0.0.0\/0|g' $WHD_HOME/conf/whd.conf
  $WHD_HOME/whd start
fi
