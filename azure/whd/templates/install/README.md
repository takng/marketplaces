WHD - Market Place Install using Azure Resource Group Template using self installer script
---------------------------------------------------------------------

## **Generic CentOS VHD Image and Install WHD through scripting

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fsolarwinds%2Fmarketplaces%2Fmaster%2Fazure%2Fwhd%2Ftemplates%2Finstall%2FmainTemplate.json)

The ARM (Azure Resource Manager) Template builds Resources and work very similar to the AWS cloud formation template. It also uses JSON format to define resources and build the VM instance from ground up. This requires more work but easier to maintain in the long run since it does not come pre-installed with a version of the product (WHD in this case). New version of WHD installer (RPM for Linux and MSI or EXE for windows) could be uploaded to S3 bucket or Azure Storage Account or even download.solarwinds.com  and the template can be scripted to pull the latest or specific version of installer from the source. Template also provides you with the UI to configure different parameters so the instance can be built more dynamically compared to pre-installed VHDs.

Resources
========
* VM Instance running WHD Server and Embedded PostgreSQL running on the same server.
* Network Security Group allowing SSH and HTTPS access to WHD Server
* Network Security Group allowing WHD Server access to PostgreSQL Repository
* Network Interface
* Storage Account
* Public IP Address
* Custom Script Extension to download and install WebHelpDesk

####Note

The values for the properties will be passed from the template. There are other values required to be configured but they are not mandatory for this step and user will need to configure them after running the application using the Setup menu.

The REST call is a Http post to https://publicdns:port/helpdesk/WebObjects/Helpdesk.woa/ra/configuration.json?uniqueId={uniqueId}

### Self Installer Script

```sh
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
```


####**Pros

No need to pre-install everything, can change components, parameterize configuration, avoid creating multiple AMI for each release, just few templates specific to OS

####**Cons

Requires Azure Resource Manager template and CLI/API knowledge, complex to create, requires Scripting knowledge, requires complete product specific knowledge to build resources
 
####Limitations

ARM template works much better than AWS cloud formation template and have a detailed Event and diagnostics UI to check progress and errors. Azure also have capability to auto-generate templates and scripts using c#, powershell, bash and ruby. It requires a bit of scripting and takes time to install the product and get the VM started compared to readily prepared VHD images Inspite of the limitations, it is still a better option compared to pre-installed VHD image at this time as the work involved to get new version to the market place is just a matter of setting the template to list available version and a mapping JSON fragment to pass in parameters to the Custom Script.