
      Copyright (c) 2012 Zuora, Inc.
    
      Permission is hereby granted, free of charge, to any person obtaining a copy of 
      this software and associated documentation files (the "Software"), to use copy, 
      modify, merge, publish the Software and to distribute, and sublicense copies of 
      the Software, provided no fee is charged for the Software.  In addition the
      rights specified above are conditioned upon the following:
    
      The above copyright notice and this permission notice shall be included in all
      copies or substantial portions of the Software.
    
      Zuora, Inc. or any other trademarks of Zuora, Inc.  may not be used to endorse
      or promote products derived from this Software without specific prior written
      permission from Zuora, Inc.
    
      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
      IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
      FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL
      ZUORA, INC. BE LIABLE FOR ANY DIRECT, INDIRECT OR CONSEQUENTIAL DAMAGES
      LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
      ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
      SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


Zuora Invoice Dunning Email Notifications
----------------------------------------

Introduction
------------

This Z-Force Sample Code package provides a reference implementation that allows Invoice Dunning Email Notifications capability.

A Dunning Notification Service Apex job contained in this package can be scheduled to do the following: 

   * Look through all invoices having balance > 0 and are past due, grouped by billing account ID
   * Calculate how many days the invoice has been past due, and group them into different dunning phases
   * For each dunning phase group
      * Group the invoices by its associated Billing Account, and construct the following information in a table for each billing account
         * Invoice Number
         * Invoice Balance
         * Invoice Date
         * Payment Term
         * Due Date
         * # of Days Past Due
      * Contruct the email body and send out the email per billing account group
      * If Billing Account's Bill-to Work Email is null, set the To Address as the CC Address defined on the dunning phase header.

Prerequisites
-------------

1. This sample code package is an unmanaged package that depends on the following Z-Force managed packages: 
Z-Force 360 Version 2.3
Z-Force Quotes Version 5.5

2. If you do not have Force.com Migration Tool already installed, please follow the instructions below: 

1). Visit http://java.sun.com/javase/downloads/index.jsp and install Java JDK, Version 6.1 or greater on the deployment machine.
2). Visit http://ant.apache.org/ and install Apache Ant, Version 1.6 or greater on the deployment machine.
3). Set up the environment variables (such as ANT_HOME, JAVA_HOME, and PATH) as specified in the Ant Installation Guide at http://ant.apache.org/manual/install.html.
4). Log in to Salesforce on your deployment machine. Click Your Name | Setup | Develop | Tools, then click Force.com Migration Tool.
5). Unzip the downloaded file to the directory of your choice. The Zip file contains a Jar file containing the ant tasks: ant-salesforce.jar
6). Copy the ant-salesforce.jar file from the unzipped file into the ant lib directly.  The ant lib directly is located in the root folder of your Ant installation. 

Installation Instructions
-------------------------
Option 1: Install it as an unmanaged package by clicking on the following installation URL
https://login.salesforce.com/packaging/installPackage.apexp?p0=04td0000000AJlD

Option 2: Install and deploy the source code using Force.com Migration Toolkit:

1. Open build.properties, and specify the login credentials for your Salesforce.com organization: 

>sf.username=

>sf.password= 

Please note that the password should be your login password concatenated with the security token.

2. Navigate to Z-Force/DunningNotification folder, and type: 
>ant deploy

This will deploy the sample code unmanaged package into your Salesforce.com organization.  

Package Contents 
-----

**1. Custom Objects**

This package includes the following 2 custom objects: 

*Dunning Notification Definition*

Use this custom object to define the dunning notification properties, including

       Default Send-by Display Name
       Default Email Subject
       CC Email Address
       Reply-to Email Address
       CRON Expression of the dunning notification jobe.g. '0 00 19 * *   ?' - Run everyday at 7pm.
       Default Email Template Name

  You may create only one Dunning Notification Definition object.

*Dunning Notification Phase*

  Use this custom object to define the dunning notification phases. You may define more than one phases. Each phase contains the following information: 

    Phase Number
    Trigger after # of days Past-Due
    Email Template Name (If not specified, the default email template name defined on Dunning Notification Definition object will be used)
    Email Subject (If not specified, the default email subject on Dunning Notification Definition object will be used)

**2. Custom Tabs**

This package includes the following custom tabs:
 
*Dunning Notification Definition*

 Navigate to this tab to create Dunning Notification Definition and its phases.

**3. Permission Set**

This package includes the following permission set: 

 *Dunning Notification Permission Set*
 
  Grant this permission set to users who need to define dunning notification properties, phases and schedule dunning notification jobs.

**4. Static Resources**

This package includes the following static resources:

*DunningEmailTemplateA*: 
  Sample email template to be associated to dunning phase 1.

*DunningEmailTemplateB*: 
  Sample email template to be associated to dunning phase 2.

*DunningEmailTemplateC*: 
  Sample email template to be associated to dunning phase 3.

This templates are for your references only. You can customize these templates.  The email template names need to be used as the "*Email Template Name*" in Dunning Notification Phase object or "*Default Email Template Name*" in Dunning Notification Definition object.
You may certainly define more than 3 dunning phases. 


Getting Started
----
* Grant permission set "Dunning Notification Permission Set" to users who need to define dunning notification properties, phases and schedule dunning notification jobs.
* Navigate to Setup --> App Setup --> Develop --> Static Resources, and customize email templates "DunningEmailTemplateA", "DunningEmailTemplateB" and "DunningEmailTemplateC".
* Navigate to tab "Dunning Notification Definition"
* Specify Dunning Notification Definition properties
* Create one or more Dunning Notification Phases
* Run the following Apex script to schedule the Dunning Notification Service job.  The job will be scheduled according to the CRON Expression specified at the Dunning Notification Definition object. 

>     DunningNotificationService service = new DunningNotificationService();
>     service.scheduleJob();

