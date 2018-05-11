# ibm-itcam-silent-config
Create ITCAM data collector silent response file by minimizing user input 
# IBM APM plugin for Grafana

Author: Richard Niewolik

Contact: niewolik@de.ibm.com

Revision: 0.1



Contents 
========

[**1. Introduction**](#introduction)

[**2. Installation**](#installation)


1. Introduction
===============

ITCAM Data Collector for WebSphere can be configured interactively with the ITCAM Data Collector for WebSphere Configuration utility but if you want to configure many application server instances, or if you want to automate the process it might be more convenient to configure the data collector in silent mode.  When you configure the data collector in silent mode, you first specify configuration options in a properties file. This solution helps you to create such response files and it discovers configuration options values automatically. That way you omit possible user errors, speed up the configuration process and makes it easier to integrate configuration related work into existing automation procedures. 

Response files are created based on the descriptions found the IBM Knowledge Center for Tivoli Composite Application Manager for Applications 7.2.0 and IBM Cloud Application Performance Management, Private 8.1.4.

**Configuring the data collector in silent mode:**

Version 7.2 [*https://www.ibm.com/support/knowledgecenter/en/SSHLNR_8.1.4/com.ibm.pm.doc/install/was_config_dcsilent_properties_file.htm#was_config_dcsilent_properties_file*](https://www.ibm.com/support/knowledgecenter/en/SSHLNR_8.1.4/com.ibm.pm.doc/install/was_config_dcsilent_properties_file.htm#was_config_dcsilent_properties_file)

Version 7.3 [*https://www.ibm.com/support/knowledgecenter/en/SS3JRN_7.2.0/com.ibm.itcamfapps_ad.doc_72/ecam_guide_72_new/silent_config_was_dc.html*](https://www.ibm.com/support/knowledgecenter/en/SS3JRN_7.2.0/com.ibm.itcamfapps_ad.doc_72/ecam_guide_72_new/silent_config_was_dc.html)

**Migrating the data collector in silent mode:**

Version 7.2 [*https://www.ibm.com/support/knowledgecenter/en/SS3JRN_7.2.0/com.ibm.itcamfapps_ad.doc_72/ecam_guide_72_new/silent_migrate_was_dc.html*](https://www.ibm.com/support/knowledgecenter/en/SS3JRN_7.2.0/com.ibm.itcamfapps_ad.doc_72/ecam_guide_72_new/silent_migrate_was_dc.html)

Version 7.3 [*https://www.ibm.com/support/knowledgecenter/en/SSHLNR_8.1.4/com.ibm.pm.doc/install/was_migrate_dcsilent.htm*](https://www.ibm.com/support/knowledgecenter/en/SSHLNR_8.1.4/com.ibm.pm.doc/install/was_migrate_dcsilent.htm)

**Unconfiguring the data collector in silent mode:**

Version 7.2 [*https://www.ibm.com/support/knowledgecenter/en/SS3JRN_7.2.0/com.ibm.itcamfapps_ad.doc_72/ecam_guide_72_new/silent_unconfig_was_dc.html*](https://www.ibm.com/support/knowledgecenter/en/SS3JRN_7.2.0/com.ibm.itcamfapps_ad.doc_72/ecam_guide_72_new/silent_unconfig_was_dc.html)

Version 7.3 [*https://www.ibm.com/support/knowledgecenter/en/SSHLNR_8.1.4/com.ibm.pm.doc/install/was_unconfigure_dcsilent.htm*] (https://www.ibm.com/support/knowledgecenter/en/SSHLNR_8.1.4/com.ibm.pm.doc/install/was_unconfigure_dcsilent.htm)


2. Installation
===============
Unzip the attached archive to a temporary directory on the host were your ITCAM agent/datacollector and WebSPhere server are running. It contains following files:

-	Shell procedure itcam_cfg.sh 
        This is the main procedure to use.

-	This README document

-	Python procedure modify-jvm-argumenst.py
        Optional: It can be used to modify or set JVM arguments. For example "-verbosegc" is set by default during DC configuration. You can use the procedure with wsadmin.sh and delete  -verbosegc from the JVM arguments. Please refer to chapter 2.2 Preparation Point “4. OPTIONAL: Customer specific post processing”

Apart of the itcam-cfg.sh following existing WebSphere and ITCAM shell scripts are used as well.

   - ITCAMDCHOME/version/bin/[config,unconfig,migrate].sh
   - WASHOME/bin/[wsadmin,manageprofiles].sh 

