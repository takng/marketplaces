WHD - Market Place Install using Azure Resource Group Template using Preinstalled Hyper-V Disk Images
---------------------------------------------------------------------

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