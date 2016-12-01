#!/bin/bash
#
# Run install-whd.sh
#
# This script will attempt to download the specified version of WebHelpDesk from download.solarwinds.com
# following paths:
#   
#   Parameters
#   ----------
#   * ProductDownloadUrl -D
#   * ProductGzipFile -G
#   * ProductRpmFile -R
#
#


echo -----------------------------------------
echo "Running : $0"
echo -----------------------------------------

set -e

PRODUCT_DOWNLOAD_URL=http://downloads.solarwinds.com/solarwinds/Release/WebHelpDesk/12.5.0/Linux/webhelpdesk-12.5.0.1257-1.x86_64.rpm.gz 
PRODUCT_GZIP_FILE=webhelpdesk-12.5.0.1257-1.x86_64.rpm.gz 
PRODUCT_RPM_FILE=webhelpdesk-12.5.0.1257-1.x86_64.rpm

cd /tmp

wget $PRODUCT_DOWNLOAD_URL -o -nv
gunzip $PRODUCT_GZIP_FILE
yum install -y -v $PRODUCT_RPM_FILE 

WHD_HOME=$(ls -d /usr/local/webhelpdesk)

echo "WHD_HOME: $WHD_HOME"

# Check if Instance Started

if [ ! -f $WHD_HOME/conf/whd.conf ] 
then
   cp $WHD_HOME/conf/whd.conf.orig $WHD_HOME/conf/whd.conf
fi
sed -i 's/^PRIVILEGED_NETWORKS=[[:space:]]*$/PRIVILEGED_NETWORKS=0.0.0.0\/0/g' $WHD_HOME/conf/whd.conf

$WHD_HOME/whd start

                           