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


Introduction
============

ITCAM Data Collector for WebSphere can be configured interactively with the ITCAM Data Collector for WebSphere Configuration utility but if you want to configure many application server instances, or if you want to automate the process it might be more convenient to configure the data collector in silent mode.  When you configure the data collector in silent mode, you first specify configuration options in a properties file. This solution helps you to create such response files and it discovers configuration options values automatically. That way you omit possible user errors, speed up the configuration process and makes it easier to integrate configuration related work into existing automation procedures. 

Response files are created based on the descriptions found the IBM Knowledge Center for Tivoli Composite Application Manager for Applications 7.2.0 and IBM Cloud Application Performance Management, Private 8.1.4.

Configuring the data collector in silent mode.

Version 7.2
Version 7.3:

Migrating the data collector in silent mode.

Version 7.2
Version 7.3:

Unconfiguring the data collector in silent mode.
Version 7.2
Version 7.3:

Installation
=======
Unzip the attached archive to a temporary directory on the host were your ITCAM agent/datacollector and WebSPhere server are running. It contains following files:

-	Shell procedure itcam_cfg.sh 
        This is the main procedure to use.

-	This README document

-	Python procedure modify-jvm-argumenst.py
        Optional: It can be used to modify or set JVM arguments. For example "-verbosegc" is set by default during DC configuration. You can use the procedure with wsadmin.sh and delete  -verbosegc from the JVM arguments. Please refer to chapter 2.2 Preparation Point “4. OPTIONAL: Customer specific post processing”

Apart of the itcam-cfg.sh following existing WebSphere and ITCAM shell scripts are used as well.

   - ITCAMDCHOME/version/bin/[config,unconfig,migrate].sh
   - WASHOME/bin/[wsadmin,manageprofiles].sh 

