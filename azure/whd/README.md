WHD - Market Place Install using AWS Cloud Formation Template and AMI
---------------------------------------------------------------------

#Purpose
The primary purpose of the document is to explain the steps involved in moving Web Help Desk to AWS Cloud. This could be first step in exploring the feasibility of moving other products (related and non-related) to AWS Cloud to cut down the build and deploy time for products that are under maintenance.

#Objective
The initial objective was to create an AMI image with preinstalled Web Help desk configured and ready to go with the embedded PostgreSQL. This would be offered only on specific platforms so as to keep the number of AMI to minimum. The second step is to port it to Marketplace using CloudFormation Template stack with the option to use embedded postgreSQL or Amazon RDS.

##Issues
* WHD is currently available on lot of different platforms like CentOS, Linux, Fedora, IoS, Windows. Do we need to build different instances ?
* WHD has strong integration feature with ORION Modules for alerting, how would this be affected.
* WHD requires integration with Exchange Server and Outlook 365 for pulling calendar information and synchronizes lot of other data.
* Licensing related questions
* How can this work with On Premise databases
* Integration with other third party Asset Discovery software

#Options

##Option - 1: Preinstalled AMI

Create a new EC2 Instance preferably Amazon Linux AMI 2016.09.0 (HVM), if you want to use Python, Ruby, Perl, and Java. The repositories include Docker, PHP, MySQL, PostgreSQL, and other packages. Since WHD RPM is already equipped with TomCat and PostgreSQL, I would go with RHEL Linux AMI to start with. This would give you a clean Linux OS and you could install WebHelpDesk for Linux over that. When you create an EC2 install, you will be prompted to create or use a Key Pair which is required to ssh on to the instance remotely. So you would be required to store the private key file so that you can configure SSH terminal like putty to log on to the Console.

Once the EC2 instance is ready for use, copy the WHD Installer RPM for Linux to the EC2 instance using pscp command line (along with putty). You can also use AWS console to upload the RPM file on to S3 bucket. Once the RPM is available for you to install, run the following command to install WHD on the EC2 instance.

```sh
sudo rpm - ihv webhelpdesk-XX.X.X.XXX-1.x86_64.rpm
```

Once WHD is installed, it automatically install TomcatX.X and starts the JVM. All WebHelpDesk related files are under /usr/local/webhelpdesk. To manually start and stop the service you can run

```sh
/usr/local/webhelpdesk/whd start 
/usr/local/webhelpdesk/stop
```

The configuration files are stored under /usr/local/webhelpdesk/conf folder. For WHD to update databases, PRIVILEGE_NETWORK attribute in the whd.conf needs to modified accordingly, otherwise you will not be able to performance updates to the WHD database. Restart the whd service using the above command after making changes to the above configuration file. Once this is done, WHD is ready to go. From a browser, type http://publicdns:8081. You will be prompted to selected embedded PostgreSQL database or use external Database. However, with the v1 version of AMI, embedded PostgreSQL database is the preferred option.

####Pros
Ready to go VM, Pre-installed and configured, No scripting or CLI/API knowledge required, No need for Linux knowledge
####Cons

Requires Multiple AMI for each environment, Every release requires pretty much new AMI creating which is tedious, Not possible to change components

##Option - 2: CloudFormation Template

The cloudFormation stack requires building up the instance from ground up. This requires more work but easier to maintain in the long run since it does not come pre-installed with a version of the product (WHD in this case). New version of WHD installer could be uploaded to S3 bucket and the template can be scripted to pull the latest or specific version of installer from the S3 bucket. Template also provides you with the UI to configure different parameters so the instance can be built more dynamically compared to pre-installed AMI. It could also be combined with the pre-built skeleton AMI and still use parameters to launch the instance.
WHD CloudFormation Stack

Resources
========
* WHD Server running on an Amazon Linux EC2 instance (Tomcat X.X)
* WHD Repository running in MySQL RDS instance or Embedded PostgreSQL running on the same server.
* VPC Security Group allowing SSH and HTTPS access to WHD Server
* VPC Security Group allowing WHD Server access to MySQL Repository
* Possible: VPC ID (set on two security groups as parameters)

####Note

The values for the properties will be passed from the template. There are other values required to be configured but they are not mandatory for this step and user will need to configure them after running the application using the Setup menu.
The REST call is a Http post to https://publicdns/helpdesk/WebObjects/Helpdesk.woa/ra/configuration.json?uniqueId={uniqueId}

####Pros

No need to pre-install everything, can change components, parameterize configuration, avoid creating multiple AMI for each release, just few templates specific to OS

####Cons

 Requires CloudFormation CLI/API knowledge, complex to create, requires Scripting knowledge, requires complete product specific knowledge to build resources
 
####Limitations

CloudFormation template by itself is a work in progress and is not available on all flavors of Linux and across regions. It requires a lot of scripting and coding to achieve conditional and look up features. The cfn bootstrap seems to vary even with in the different flavor of Linux so it is difficult to come up with a standard template to take care of all the scenarios. However, working with Amazon Linux EC2 instance seems to work fine. Inspite of the limitations, it is still a better option compared to pre-installed AMI at this time.
