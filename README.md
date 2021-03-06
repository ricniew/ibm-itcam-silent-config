# ibm-itcam-silent-config
Create ITCAM data collector silent response file by minimizing user input 

Author: Richard Niewolik

Contact: niewolik@de.ibm.com

Revision: 2.2

#

[1 General](#1-general)

[2 Installation](#2-installation)

[2.1 Supported Operating System](#supported-operating-system)

[2.2 Preparation](#preparation)

[3 Usage](#3-usage)

[3.1 Syntax](#syntax)

[3.2 Sample executions for Configuration](#sample-executions-for-configuration)

[3.3 Sample executions for Unconfiguration](#sample-executions-for-unconfiguration)

[3.4 Sample executions for Migration](#sample-executions-for-migration)

[4 Troubleshooting](#4-troubleshooting)

[5 Appendixes](#5-appendixes)

[5.1 Sample configuration response file](#sample-configuration-response-file)

[5.2 Sample unconfiguration response file](#sample-unconfiguration-response-file)

[5.3 Sample migration response file](#sample-migration-response-file)

[5.4 Sample execution flow](#sample-execution-flows)

#

1 General
=========

ITCAM Data Collector for WebSphere can be configured interactively with
the ITCAM Data Collector for WebSphere Configuration utility but if you
want to configure many application server instances, or if you want to
automate the process it might be more convenient to configure the data
collector in silent mode. When you configure the data collector in
silent mode, you first specify configuration options in a properties
file. This solution helps you to create such response files and it
discovers configuration options values automatically. That way you omit
possible user errors, speed up the configuration process and makes it
easier to integrate configuration related work into existing automation
procedures.

Response files are created based on the descriptions found the IBM
Knowledge Center for *[Tivoli Composite Application Manager for
Applications 7.2.0](https://www.ibm.com/support/knowledgecenter/en/SS3JRN_7.2.0)
and IBM Cloud Application Performance Management, Private 8.1.4*.

**Configuring the data collector in silent mode**

[Version 7.2]

[https://www.ibm.com/support/knowledgecenter/en/SSHLNR\_8.1.4/com.ibm.pm.doc/install/was\_config\_dcsilent\_properties\_file.htm\#was\_config\_dcsilent\_properties\_file](https://www.ibm.com/support/knowledgecenter/en/SSHLNR_8.1.4/com.ibm.pm.doc/install/was_config_dcsilent_properties_file.htm#was_config_dcsilent_properties_file)

[Version 7.3]

[https://www.ibm.com/support/knowledgecenter/en/SS3JRN\_7.2.0/com.ibm.itcamfapps\_ad.doc\_72/ecam\_guide\_72\_new/silent\_config\_was\_dc.html](https://www.ibm.com/support/knowledgecenter/en/SS3JRN_7.2.0/com.ibm.itcamfapps_ad.doc_72/ecam_guide_72_new/silent_config_was_dc.html)

**Migrating the data collector in silent mode**

[Version 7.2]

[https://www.ibm.com/support/knowledgecenter/en/SS3JRN\_7.2.0/com.ibm.itcamfapps\_ad.doc\_72/ecam\_guide\_72\_new/silent\_migrate\_was\_dc.html](https://www.ibm.com/support/knowledgecenter/en/SS3JRN_7.2.0/com.ibm.itcamfapps_ad.doc_72/ecam_guide_72_new/silent_migrate_was_dc.html)

[Version 7.3:]

[https://www.ibm.com/support/knowledgecenter/en/SSHLNR\_8.1.4/com.ibm.pm.doc/install/was\_migrate\_dcsilent.htm](https://www.ibm.com/support/knowledgecenter/en/SSHLNR_8.1.4/com.ibm.pm.doc/install/was_migrate_dcsilent.htm)

**Unconfiguring the data collector in silent mode**

[Version 7.2]

[https://www.ibm.com/support/knowledgecenter/en/SS3JRN\_7.2.0/com.ibm.itcamfapps\_ad.doc\_72/ecam\_guide\_72\_new/silent\_unconfig\_was\_dc.html](https://www.ibm.com/support/knowledgecenter/en/SS3JRN_7.2.0/com.ibm.itcamfapps_ad.doc_72/ecam_guide_72_new/silent_unconfig_was_dc.html)

[Version 7.3:]

[https://www.ibm.com/support/knowledgecenter/en/SSHLNR\_8.1.4/com.ibm.pm.doc/install/was\_unconfigure\_dcsilent.htm](https://www.ibm.com/support/knowledgecenter/en/SSHLNR_8.1.4/com.ibm.pm.doc/install/was_unconfigure_dcsilent.htm)

2 Installation
==============

Download the latest release of the script [here](https://github.com/ricniew/ibm-itcam-silent-config/releases) and unzip to a temporary directory on the host were your ITCAM Agent\+Datacollector and WebSPhere server are running. It
contains following files:

-   Shell procedure *itcam\_cfg.sh*\
    This is the main procedure to use.

-   This README document

-   Python procedure *modify-jvm-argumenst.py*\
    Optional: It can be used to modify or set JVM arguments. For example *-verbosegc* is set by default during DC configuration.
    You can use the procedure with *wsadmin.sh* and delete *-verbosegc* from the JVM arguments. Please refer to chapter "Preparation", 
    Point "'4. OPTIONAL: Customer specific post processing*"

Apart of the *itcam-cfg.sh* following existing WebSphere and ITCAM shell scripts are used as well:

- ITCAMDCHOME/version/bin/\[config,unconfig,migrate\].sh\
- WASHOME/bin/\[wsadmin,manageprofiles\].sh*

Supported Operating System
--------------------------

Procedure was tested on UNIX AIX and Linux Redhat but should run on all
UNIX and Linux Operating systems. The required shell is *bash*. It is
not running on Windows.

The ITCAM for WebSphere agent and Data Collector (DC) must be installed.
The tested version have been 7.2 and 7.3.

Preparation
-----------

The created response files contains configuration options which are
valid for the most popular set up with a DC monitoring a WebSphere
instance. For the authentication client SOAP properties are used.
**Please check below for possible changes you may need to perform.**
Always check the created response file if it meets your required set up.
<br/>  
 
1.  **In case you configure a new DC the following configuration options are not enabled by default:**

       -   Integration of the DC with the *ITCAM for Transactions*

       -   Integration of the DC with the *ITCAM for SOA*

       -   Integration of the DC with the *Tivoli Performance Monitoring*

       -   Integration of the DC with the *ITCAM Diagnostics Tool*

       -   Integration of the data collector with *ITCAM Agent for WebSphere version 6* (for Version 7.3 only)

     If you would like to use any of that options the procedure must be
     modified and the function *CreateConfigRespFile* needs to be adjusted
     with the required options to be used (modify *False* to *True*)

       > \# Integration of the DC with the ITCAM for Transactions"\
       > ttapi.enable=False\
       > ttapi.host=yourhost\
       > ttapi.port=

       > \# Integration of the DC with the ITCAM for SOA\
       > soa.enable=False

       > \# Integration of the DC with the Tivoli Performance Monitoring\
       > tpv.enable=False

       > \# Integration of the DC with the ITCAM Diagnostics Tool\
       > de.enable=False

       > \# Integration of the data collector with ITCAM Agent for WebSphere version 6 (7.2)\
       > config.tema.v6=false\
       > tema.host.v6=\
       > tema.port.v6=63336
<br/>   

2.  **For configuration actions (configure, unconfigure and migration):**

       -   No *Backup of the WebSphere configuration* is performed by default.
    If you wish so you need to modify
    ***was.backup.configuration=True*** and a set directory in
    *CreateConfigRespFile*, *CreateMigrateRespFil*e and
    *CreateUnConfigRespFile*)

       -   Configuration option ***default.hostip*** is not set by default. If
    the computer system uses multiple IP addresses, specify the IP
    address for the data collector to use. You may need to add your own
    code to discover it automatically.

       -   Configuration option ***was.client.props=true*** is used by default.
    If you are not using it you need to modify *CreateUnConfigRespFile*,
    *CreateMigrateRespFil*e and *CreateConfigRespFile* to set
    user/password instead (***was.wsadmin.username, was.wsadmin.password***)
<br/> 

3.  **Only if using ITCAM for Diagnostic Managing Server (ms.connect=True)**

       -   If you use other ports than the product provided you need to modify
    "\# ITCAM for Application Diagnostics" section in function
    *CreateConfigRespFile.*

       -   The function *CreateAmVariables* sets variables (AMHOST, AMHOME)
    used for configuration options for the ITCAM Managing Server. Before
    execution you **must** set the hostname and home directory according
    to your environment. Two different hostnames can be set (for *prod*
    or *stage* environment, please also refer to the "-e" procedure
    argument)
<br/> 

4.  ***OPTIONAL: Customer specific post processing***
    
    Specific post processing code can be inserted. Procedure needs to be modified,
    remove comment from almost the end of the script:
    
    >  \#By default no post processing defined.\
    >  \#You can uncomment the line below and modify function PostProcessing\
    >   \# PostProcessing

    To
    >    PostProcessing

    Add required code to the function *PostProcessing*. A sample code could be:
    > 
    > if \[ \"\${ACTION}\" == \"config\" \] ; then\
    > \#\-\-\-\-\-\-\-\-\-\-\-\-\-- CONFIG
    > \-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\--\
    > echo \"INFO Customer specific post processing for \"-a config\" defined\"\
    > echo \"INFO Post processing: Delete "-verbosegc\" from the JVM arguments for servers configured previously\"\
    > echo \"\${WSADMIN\_HOME}/wsadmin.sh -lang jython -f jvm\_arguments.py del \${SERVERJVM\[\*\]}\" --verbosegc\
    > \${WSADMIN\_HOME}/wsadmin.sh -lang jython -f jvm\_arguments.py del "\${SERVERJVM\[\*\]}" --verbosegc\
    > if [ \$? -ne 0 ] ; then\
    > echo " ERROR During post processing"\
    > return 1\
    > fi   
    
    The sample python script *jvm\_arguments.py* is included in this package.
<br/> 

5.  ***OPTIONAL: Modify CreateServerAliases***
   
    This function creates server aliases based on input values made. You
    should modify it when you are using aliases for your server names.
    Only relevant for option \"-a config\". Alias is only required when
    you use option \"-m \[yn,yndiad\]\" and server's node name is longer
    then 18 character. ITM/APM has a limitation of 32 characters for
    managed system (like a WebSphere application server) names. This 32
    character limit has to include the server name, host name and the
    managed system code (KYNS, KYNP, etc.) that further restricts the
    length of the server name. The WebSphere server node name that is
    displayed on the TEP/APM console is constructed using the following
    format:\
    \
    \< server\_subnode\_name\>:\<hostname\>:\<product code with
    postfix\>\
    \
    Details can be found here:\
    [[http://www-01.ibm.com/support/docview.wss?uid=swg21516636]{.underline}](http://www-01.ibm.com/support/docview.wss?uid=swg21516636)\
    \
    If you must use aliases, you need to modify this procedure and set
    the array ALIASES accordingly. Either by setting fix aliases or by
    using a logic to create an alias based on server's node name
    (function *CreateServerAliases* contains a sample algorithm). As a
    result the array should contain "serve node name; server alias".\
    For example:\
    \
    ALIASES=(\
    \#server node name; server alias\
    \"lx2345mu\_Portal\_My\_Server\_01;lx2345\_WPS\_01\"\
    \"lx2345mu\_Portal\_My\_Server\_02;lx2345\_WPS\_02\"\
    \"lx3355mu\_AppSrv\_My\_Server\_01;lx3355\_WAS\_01\"\
    \"lx3355mu\_AppSrv\_My\_Server\_02;lx3355\_WAS\_02\"\
    \"lx2266mu\_Proc\_My\_Server\_01;lx2266\_BPM\_01\"\
    \"lx2266mu\_Proc\_My\_Server\_02;lx2266\_BPM\_01\"\
    )



3 Usage
=======

Syntax
------

> itmcam-cfg.sh { -h WAS home } \[ -p \]\
> { -a \[config {-v} { -m \[yn\|yndiag\|diag\] } { -e \[prod\|stage\] }\
>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;unconfig {-v}\
>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;migrate {-f} {-t} \] }\
> \[-s servern1,servern2,\...}\
> \[ -x \] \[ -d \]


    -h    home directory

    -p    SOAP port used to connect to Dmgr (OPTIONAL). Only relevant in case of "-a=config".
          By default this port is retrieved by a wsadmin Python script. However you can use this
          option to override the Dmgr port discovered by the internal Python script.

    -a    Configuration action [config, unconfig, migrate].

    -m    Configuration mode [yn, yndiag, diag]. Only relevant for action "-a config"
          yn= Data collector (DC) is configured to communicate with the ITCAM Agent  
              only (ITM/APM WebSphere Agent).
          yndiag= Data collector (DC) is configured to send data to the ITCAM Managing server (MS) 
              and to the ITCAM Agent. Function "CreateAmVariables" must contain the correct values 
              for your environment (MS server host and home directorsy).
          diag= Data collector (DC) is configured to send data to the ITCAM Managing server (MS) ONLY. 
              Function "CreateAmVariables" must contain the correct values for your environment.

    -e    Deployment environment [prod, stage]. Only relevant for action=config. Used to verify which
          ITCAM Managaing Server host needs to be used in case of a "-m [diag, yndiag]" configuration
          (set in function "CreateAmVariables").

    -v    Version to configure/unconfigure. Only relevant for action "-a [config, unconfig]"

    -f    Version to migrate from (old version). Only relevant for action "-a migrate"

    -t    Version to migrate to (new version). Only relevant for action "-a migrate"

    -s    A list of servers to process separated by comma (!must be without any space after comma). 
          All server set in this parameter must be running otherwise not processed!
          
    -x    If set action (-a argument) is executed. By default only the silent response file is
          going to be created. Note that checks to ensure a successful execution are still performed.
          Hence check both response file and the message flow.

    -d    If set, temporary files are deleted. By default those files are not deleted but 
          overwritten during the next call.
          
Sample executions for configuration
------------------------------------

1.  Configure two server in production environment with ITCAM Managing
    Server and TEMA for WebSphere enabled\


         itcam-cfg.sh -h /usr/WebSphere/AppServer -e prod -m yndiag -a config -v 7.3.0.0.02 -s server1,server2 -x
    
    *If you want to override the Dmgr SOAP\_CONNECTOR\_ADDRESS Port discovered automatically please use -p argument*:
    
        itcam-cfg.sh -h /usr/WebSphere/AppServer -p 1234 -e prod -m yndiag -a config -v 7.2.0.0.13 -s server1,server2 -x

2.  Create a configuration [silent response file only] without execution for all servers running with TEMA for WebSphere
    enabled only\
        
        itcam-cfg.sh -h /usr/WebSphere/AppServer -m yn -a config -v 7.2.0.0.13

3.  Configure all server in *Stage* env ITCAM Managing Server enabled only\
    
        itcam-cfg.sh -h /usr/WebSphere/AppServer -a config -e stage -m diag -v 7.2.0.0.13 -x

Sample executions for Unconfiguration
-------------------------------------

1.  Create a [silent response file only]{.underline} without execution
    unconfiguration step for all servers\
    
        itcam-cfg.sh -h /usr/WebSphere/AppServer -a unconfig -v 7.2.0.0.13

2.  Unconfigure a server and delete temporary files\
    
        itcam-cfg.sh -h /usr/WebSphere/AppServer -a unconfig -v 7.3.0.0.02 -s server1,server2 -x -d

Sample executions for Migration
-------------------------------

1.  Migrate all server to a new version (note that version 7.2.0.0.14 should be installed before)\
    
        itcam-cfg.sh -h /usr/WebSphere/AppServer -a migrate -f 7.2.0.0.13 -t 7.2.0.0.14 -x

2.  Migrate server \"server1\" to a new version.\
    
        itcam-cfg.sh -h /usr/WebSphere/AppServer -a migrate -f 7.2.0.0.13 -t 7.2.0.0.14 -s server1

3.  Create a [silent response file only]{.underline} without execution migration step for all servers\
    
        itcam-cfg.sh -h /usr/WebSphere/AppServer -a migrate -f 7.2.0.0.13 -t 7.2.0.0.14

4 Troubleshooting
=================

Temporary files created are not deleted by default (prefixed by tmp.\[filename\]). You may use them for problem analysis in case of
errors:

- tmp.itcamdc.silentinput.txt (response file created)
- tmp.itcamdc.websphere\_data.conf (data retrieved using wsadmin.sh)
- tmp.itcamdc.wsadminScript.py (Python script used for wsadmin.sh)

**Please note:**

-   All servers must be running in order to perform any configuration
    action.

-   Not running servers are not going to be processed.

-   Procedure must be started on the host where WebSphere server is
    running

If there are any errors which may prevent a successful execution an error message will be thrown. After installation please always start the procedure without argument "-x", check response file created and the message flow.

Server will also not be processed in case of:\
- configured already and you choose *-a config*
- is not configured and you choose *-a unconfig, migrate*

You will see errors or warning messages indicating the problem encountered.

The procedure tries to discover automatically JAVAHOME, DCHOME, ITMHOME, WSADMINHOME. If it is not possible error message is reported and you may need to set e.g. JAVA\_HOME manually before execution.

Following procedures are used which are installed by the ITCAM for WebSphere product.

    DCHOME/version/bin/[config,unconfig,migrate].sh
    
If the names are changed by IBM, you need to modify the procedure. If these scripts fail to run it could be related to the response file created. Execute it manually and check messages.

Following procedures are used which are installed by the IBM WebSphere product:

    WASHOME/bin/[wsadmin,manageprofiles].sh

If the names will be changed by IBM, you need to modify the procedure. If these scripts fail to run please execute them manually and check messages and output, for example:

    WASHOME/bin/wsadmin.sh -lang jython -f tmp.itcamdc.wsadminScript.py
    WASHOME/bin/manageprofiles.sh

5 Appendixes
============

Sample configuration response file
----------------------------------

ITCAM Agent for WebSphere only configuration:

       # ITCAM Data Collector silent response file 
       [DEFAULT SECTION]
       # Integration of the DC with the ITCAM for Transactions
       ttapi.enable=False
       # Integration of the DC with the ITCAM for SOA
       soa.enable=False
       # Integration of the DC with the Tivoli Performance Monitoring
       tpv.enable=False
       # Integration of the DC with the ITCAM Diagnostics Tool
       de.enable=False
       # Backup of the WebSphere configuration
       was.backup.configuration=False
       # Integration with ITCAM Agent for WebSphere Applications:
       temaconnect=True
       tema.host=127.0.0.1
       tema.port=63335
       # Connect to WebSphere Admin Services
       was.wsadmin.connection.host=dmgr.mycompany.com
       was.wsadmin.connection.type=SOAP
       was.wsadmin.connection.port=28880
       was.client.props=true
       # WebSphere Application Server settings
       was.appserver.profile.name=WasNode01
       was.appserver.home=/usr/WebSphere855/AppServer
       was.appserver.cell.name=WasCell
       was.appserver.node.name=WasNode01
       # WebSphere Application Server runtime instance settings
       [SERVER]
       was.appserver.server.name=Server_01
       
Sample unconfiguration response file
------------------------------------

    # ITCAM Data Collector silent response file
    [DEFAULT SECTION]
    # Backup of the WebSphere configuration
    was.backup.configuration=False
    # Connect to WebSphere Admin Services
    was.wsadmin.connection.host= dmgr.mycompany.com
    was.wsadmin.connection.type=SOAP
    was.client.props=true
    # WebSphere Application Server details
    was.appserver.profile.name=WasNode01
    was.appserver.home=/usr/WebSphere855/AppServer
    was.appserver.cell.name=WasCell
    was.appserver.node.name=WasNode01
    # WebSphere Application Server runtime instance settings
    [SERVER]
    was.appserver.server.name=Server_01
    [SERVER]
    was.appserver.server.name=Server_02

Sample migration response file
------------------------------

    # ITCAM Data Collector silent response file
    [DEFAULT SECTION]
    migrate.type=AD
    # Location of data collector to be migrated
    itcam.migrate.home=/apm/yn/dchome/7.3.0.0.2
    # Connect to WebSphere Admin Services
    was.wsadmin.connection.host= dmgr.mycompany.com
    was.wsadmin.connection.type=SOAP
    was.client.props=true
    # WebSphere Application Server details
    was.appserver.profile.name=WasNode01
    was.appserver.home=/usr/WebSphere855/AppServer
    was.appserver.cell.name=WasCell
    was.appserver.node.name=WasNode01
    # WebSphere Application Server runtime instance settings
    [SERVER]
    was.appserver.server.name=Server_01
    [SERVER]
    was.appserver.server.name=Server_02
    [SERVER]
    was.appserver.server.name=Server_03


Sample execution flows
----------------------

Configuration (create response file only)

    $ /itcam-cfg.sh -h /usr/WebSphere855/AppServer -a config -m yn -v 7.2.0.0.14 
    INFO Script Version 2.2
    INFO Check options
    INFO WASHOME=/usr/WebSphere855/AppServer
    INFO ACTION=config
    INFO SHORTVERSION=72
    INFO VERSION=7.2.0.0.14
    INFO MODE=yn
    INFO DELTMP=false \# Temporary files will NOT be deleted (DEFAULT)
    INFO SERVER=all
    INFO EXECACTION=false \# Only silent response will be created (DEFAULT)
    INFO ITMHOME=/itm
    INFO WSADMIN_HOME=/usr/WebSphere855/AppServer/bin
    INFO WASDCHOME=/itm/aix533/yn/wasdc
    INFO DCHOME=/itm/aix533/yn/wasdc/7.2.0.0.14
    INFO Collecting required data from WebSphere using wsadmin
    INFO Executing /usr/WebSphere855/AppServer/bin/wsadmin.sh -lang jython -f tmp.itcamdc.wsadminScript.py
    INFO Data successfully collected from WebSphere
    INFO CellMgrHostname=dmgr.host.com
    INFO Cellname=WasStageCell
    INFO Nodename=WasStageNode01
    INFO Running on host server.host.com
    INFO DMGR SOAP connector address returned by wsadmin is: 28880
    INFO Collecting profile information using manageprofiles.sh
    INFO Existing profiles: WasStageMyNode.
    INFO PROFILENAME=WasStageMyNode
    INFO JAVA_HOME=/usr/WebSphere855/AppServer/java
    INFO Display Server's status:
    INFO BPM_Server_01 running
    INFO BPM_Server_02 running
    WARNING server1 not-running Server not running and will not be processed.
    WARNING Server BPM_Server_01 already configured with: 7.2.0.0.14. Server will not be processed
    INFO Server to process: BPM_Server_02
    INFO DMGRSoapPort used= 28880 (returned by tmp.itcamdc.wsadminScript.py)
    INFO DMGRSoapPort used= 28880
    INFO Display alias information
    INFO BPM\_Server\_02 no alias configured
    WARNING No alias found for some server in function "CreateServerAliases". Modify if required and restart the procedure.
    INFO Create silent response file for action=configuration
    INFO Created silent configuration file: tmp.itcamdc.silentinput.txt
    ----
    # ITCAM Data Collector silent response file
    [DEFAULT SECTION\]
    # Integration of the DC with the ITCAM for Transactions
    ttapi.enable=False
    # Integration of the DC with the ITCAM for SOA
    soa.enable=False
    # Integration of the DC with the Tivoli Performance Monitoring
    tpv.enable=False
    # Integration of the DC with the ITCAM Diagnostics Tool
    de.enable=False
    # Backup of the WebSphere configuration
    was.backup.configuration=False
    # Integration with ITCAM Agent for WebSphere Applications:
    temaconnect=True
    tema.host=127.0.0.1
    tema.port=63335
    # Connect to WebSphere Admin Services
    was.wsadmin.connection.host=dmgr.host.com
    was.wsadmin.connection.type=SOAP
    was.wsadmin.connection.port=28880
    was.client.props=true
    # WebSphere Application Server settings
    was.appserver.profile.name=WasStageMyNode
    was.appserver.home=/usr/WebSphere855/AppServer
    was.appserver.cell.name=WasStageMYCell
    was.appserver.node.name=WasStageMyNode
    # WebSphere Application Server runtime instance settings
    [SERVER]
    was.appserver.server.name=BPM_Server_02
    ----
    WARNING Please check the response file created. Also check message flow for errors which may indicate potential issues 
            preventing a successful action execution
    INFO procedure successfully ended
    $ 
