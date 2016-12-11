#!/bin/bash
#
# Run whd-install.sh
#
# This script will attempt to download the specified version of WebHelpDesk from download.solarwinds.com
# following paths:
#   
#   Parameters
#   ----------
#    ProductName -n --product-name
#    ProductMajorVersion -x --major-version
#    ProductMinorVersion -y --minor-version
#    help -h --help

usage()
{
echo This script will attempt to download the specified version of WebHelpDesk from download.solarwinds.com
echo following paths:
echo
echo   "Usage: `basename $0` -p|--product-name productName -x|--major-version x.x.x -y|--minor-version [y.y] -h|--help"
echo
echo   Parameters
echo   ----------
echo   ProductName -n --product-name
echo   ProductMajorVersion -x --major-version
echo   ProductMinorVersion -y --minor-version
echo   help -h --help
echo
exit 1;
}

echo -----------------------------------------
echo "Running : $0 $@"
echo -----------------------------------------

PRODUCT_MAJOR_VERSION=
PRODUCT_MINOR_VERSION=
PRODUCT_NAME=
PRODUCT_DOWNLOAD_URL=
CMD_NAME=`basename $0`
# read the options
TEMP=`getopt -o hp:x:y: --long help,product-name:,major-version:,minor-version: -n '$CMD_NAME' -- "$@" 2>/dev/null`

if [[ $? -ne 0 ]]
then
   usage;
fi

eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -p|--product-name)
            PRODUCT_NAME=$2 ; shift 2 ;;
        -x|--major-version)
            PRODUCT_MAJOR_VERSION=$2; shift 2 ;;
        -y|--minor-version)
            case "$2" in
                "") shift 2 ;;
                *) PRODUCT_MINOR_VERSION=$2 ; shift 2 ;;
            esac ;;
        --) shift; break ;;
        -h|--help|*) usage;;
    esac
done

PRODUCT_NAME_LOWER=`echo $PRODUCT_NAME | awk '{print tolower($0)}'`
PRODUCT_GZIP_FILE="$PRODUCT_NAME_LOWER"-"$PRODUCT_MAJOR_VERSION"."$PRODUCT_MINOR_VERSION".x86_64.rpm.gz 
PRODUCT_RPM_FILE="$PRODUCT_NAME_LOWER"-"$PRODUCT_MAJOR_VERSION"."$PRODUCT_MINOR_VERSION".x86_64.rpm
PRODUCT_DOWNLOAD_URL=http://downloads.solarwinds.com/solarwinds/Release/"$PRODUCT_NAME"/"$PRODUCT_MAJOR_VERSION"/Linux/"$PRODUCT_GZIP_FILE"

# Now take action
echo PRODUCT_NAME=$PRODUCT_NAME
echo PRODUCT_MAJOR_VERSION=$PRODUCT_MAJOR_VERSION
echo PRODUCT_MINOR_VERSION=$PRODUCT_MINOR_VERSION
echo PRODUCT_GZIP_FILE=$PRODUCT_GZIP_FILE
echo PRODUCT_RPM_FILE=$PRODUCT_RPM_FILE
echo PRODUCT_DOWNLOAD_URL=$PRODUCT_DOWNLOAD_URL

if [ -z "$PRODUCT_NAME" -o -z "$PRODUCT_MAJOR_VERSION" -o -z "$PRODUCT_MINOR_VERSION" ]
then
   usage;
fi

cd /tmp

wget $PRODUCT_DOWNLOAD_URL -nv
gunzip $PRODUCT_GZIP_FILE

yum clean all
yum update -y
yum install -y -v $PRODUCT_RPM_FILE 

WHD_HOME=$(ls -d /usr/local/webhelpdesk)

echo "WHD_HOME: $WHD_HOME"

# Check if Instance Started

if [ ! -f $WHD_HOME/conf/whd.conf ] 
then
   cp $WHD_HOME/conf/whd.conf.orig $WHD_HOME/conf/whd.conf
fi
sed -i 's|^PRIVILEGED_NETWORKS=[[:space:]]*$|PRIVILEGED_NETWORKS=0.0.0.0\/0|g' $WHD_HOME/conf/whd.conf

$WHD_HOME/whd start
