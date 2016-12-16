WHD - Market Place Install using Azure Resource Group Template using VHD Image and self installer script
---------------------------------------------------------------------

#Purpose
The primary purpose of the document is to explain the steps involved in moving Web Help Desk to Azure Cloud. This could be first step in exploring the feasibility of moving other products (related and non-related) to Azure Cloud to cut down the build and deploy time for products that are under maintenance. Link for the [Github Azure Markerplace](https://github.com/solarwinds/marketplaces/tree/master/azure/whd)

#Objective
The initial objective was to create an Hyper-V VHD Disks  with preinstalled Web Help desk configured and ready to go with the embedded PostgreSQL just like how DPA is being sold at Azure marker place. Currently, WHD Build process already creates Hyper-V VHD Disks with CentOS as the VM operation system. The second step is to port it to Marketplace using Azure SQL DB or MySQL on Cloud. The deployment on Azure cloud uses ARM (Azure Resource Manager) template along with ARM Cli or Powershell cmdlets to upload VHD Disks on to the Azure Storage Account. Currently, DPA uses this approach to launch Azure VM from VHD image. The ARM template source can be found [here](https://github.com/solarwinds/marketplaces/blob/master/azure/whd/templates/template.json)

##Issues
* WHD is currently available on lot of different platforms like CentOS, Linux, Fedora, IoS, Windows. Do we need to build different instances ?
* WHD has strong integration feature with ORION Modules for alerting, how would this be affected.
* WHD requires integration with Exchange Server and Outlook 365 for pulling calendar information and synchronizes lot of other data.
* Licensing related questions
* How can this work with On Premise databases
* Integration with other third party Asset Discovery software

#Options

**Both the approaches will use Azure Resource manager (ARM) templates to create security groups, network interface, virtual network, public IP and DNS, storage account and VM. Here is a step by step instruction to create a VM image in the [Azure Market Place Account](https://docs.microsoft.com/en-us/azure/marketplace-publishing/marketplace-publishing-vm-image-creation)

## **Option - 1: Preinstalled Hyper-V Disk Images

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fsolarwinds%2Fmarketplaces%2Fmaster%2Fazure%2Fwhd%2Ftemplates%2FmainTemplate.json)

Currently with every release of WebHelpDesk, WHD Build process creates a Hyper-V Image disks (VHDs). Only VHDs are supported on Azure as of today, so incase, the build process creates VHDX images, these dynamic disks needs to be converted to VHD image. Refer [VHDX to VHD](https://blogs.technet.microsoft.com/cbernier/2013/08/29/converting-hyper-v-vhdx-to-vhd-file-formats-for-use-in-windows-azure/) for more step by step information. There is no need to worry about sysprep or conversion for Web Help Desk since they are already created in VHD Format.

The VHD images (osdisk as well as any number of data disks)  can be uploaded to the storage account using the PowerShell or Azure CLI. The information can be found here. [Upload VHD using Powershell](https://blogs.infosupport.com/creating-a-vm-in-azure-based-on-an-uploaded-vhd/)

Once the VHD images are uploaded to the Storage Account, please go through the steps defined in the [Azure market place account](https://docs.microsoft.com/en-us/azure/marketplace-publishing/marketplace-publishing-vm-image-creation) to publish the product. When Web Help Desk is launched from the Market place, it automatically installs CentOS, Web Help Desk Application, PostgreSQL,  TomcatX.X and starts the JVM. All WebHelpDesk related files are under /usr/local/webhelpdesk. Please ensure SSH port is opened up for accessing VM. To manually start and stop the service you can run

```sh
/usr/local/webhelpdesk/whd start 
/usr/local/webhelpdesk/stop
```

The configuration files are stored under /usr/local/webhelpdesk/conf folder. For WHD to update databases, PRIVILEGE_NETWORK attribute in the whd.conf needs to modified accordingly, otherwise you will not be able to performance updates to the WHD database. Restart the whd service using the above command after making changes to the above configuration file. Once this is done, WHD is ready to go. From a browser, type http://publicdns:8081. You will be prompted to selected embedded PostgreSQL database or use external Database. However, with the VHD option of the Azure VM, embedded PostgreSQL database is the preferred option.

####Pros
Ready to go VM created from VHDs, Pre-installed and configured, No scripting or CLI/API knowledge required, No need for Linux knowledge

####Cons
Requires Multiple VHDs for each environment, Every release requires pretty much creating a new VHD everytime  and uploading them to Storage Account which is tedious, Not possible to change components

## **Option - 2: Generic CentOS VHD Image and Install WHD through scripting

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

The REST call is a Http post to https://publicdns/helpdesk/WebObjects/Helpdesk.woa/ra/configuration.json?uniqueId={uniqueId}

####**Pros

No need to pre-install everything, can change components, parameterize configuration, avoid creating multiple AMI for each release, just few templates specific to OS

####**Cons

Requires Azure Resource Manager template and CLI/API knowledge, complex to create, requires Scripting knowledge, requires complete product specific knowledge to build resources
 
####Limitations

ARM template works much better than AWS cloud formation template and have a detailed Event and diagnostics UI to check progress and errors. Azure also have capability to auto-generate templates and scripts using c#, powershell, bash and ruby. It requires a bit of scripting and takes time to install the product and get the VM started compared to readily prepared VHD images Inspite of the limitations, it is still a better option compared to pre-installed VHD image at this time as the work involved to get new version to the market place is just a matter of setting the template to list available version and a mapping JSON fragment to pass in parameters to the Custom Script.