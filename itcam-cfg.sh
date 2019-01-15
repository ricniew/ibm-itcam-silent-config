#!/bin/bash
#set -x
###################################################################
# R. Niewolik IBM AVP
# Procedure creates a silent rsp file and executes an ITCAM DC
# configuration step depending on input (unconfig, config or
# migrate). In case of "config" step, also 
#     - "diag" (DC connection to the ITCAM MS server only) 
#     -  "yndiag" (DC sends data to ITM TEMA for WebSphere and ITCAM MS server
#     -  "yn" (DC sends data to ITM TEMA for WebSphere only
#  can be selected.
#
# Before using the procedure
# 1. Please verify/modify functions below 
#     to meet your requirements for response files created.
#       CreateUnConfigRespFile
#       CreateMigrateRespFile
#       CreateUnConfigRespFile
# 2. Please verify/modify function CreateAmVariables to use the right values 
#      in case of ITCAM Managing Server is used (option -m [yndiag, diag]).
# 3. Optional: Please verify/modify function CreateServerAliases to
#     assure that the right names are displayed in ITM/APM (managed system name)
#     in case of a new  configuration (option "-a config" used).  If not done the real server 
#     name will be used for managed system name creation.
#
###################################################################
# 22.12.2017: R. Niewolik  Initial version V1.0
# 10.01.2018: R. Niewolik  Minor changes  V1.2
# 19.01.2018: R. Niewolik  following changes V1.3:
#             - modfied CreateWsadminScript to get Java home
#             - modfied GetJavaHome (try to use Java from WebSphere)
#             - added GetProfileName
# 23.01.2018: R. Niewolik  following changes V1.4:
#             - modfied message flow
#             - modfied GetJavaHome (check for JAVA_HOME first)
#             - added argument -x -d
# 23.01.2018: R. Niewolik  following changes V1.5:
#             - modfied the way DMgr node and hostname is retrieved
#               CreateWsadminScript
# 02.03.2018: R. Niewolik  following changes V1.6:
#             - minor changes to the echo cmd is used in  
#               CreateMigrateRespFile, CreateConfigRespFile
#               CreateUnconfigRespFile
# 06.03.2018: R. Niewolik  following changes V2.0:
#             - major changes to allow execution without alias configured. 
#               Created functions:
#                    CheckServerNameAndAlias, CheckAndDisplayStatus
#               Deleted functions:
#                   CheckAndDisplaySrvAliasStatus CheckAndDisplaySrvStatus
#               + MAIN section changes 
# 12.03.2018: R. Niewolik  following changes V2.1:
#             - Corrected behavior for "diag"  
#                Modified functions: CreateConfigRespFile, CheckOptions
#             - Modidfied procedure to support ITCAM Version >= 7.3 (APM)
#               Modified functions: 
#                CreateConfigRespFile, CheckOptions, 
#                CreateConfigRespFile, GetWasdcHome
#             - changed  "-m" values from "nodeep,deepdive, deepdiveonly"
#               to "yn,yndiag,diag"
# 04.04.2018: R. Niewolik  following changes V2.2:
#             - Corrected behavior for "diag"  
#               Modified functions: 
#                 CreateWsadminScript (add code the get Dmgr SOAP port)
#                 CheckOptions (chage behavior if -p option is set)
#               Added functions: 
#                  CheckDmgrPort (check DMgr port returned by wasadmin versus -p option)
#                  Post processing (can be used to add a custom post process)
#                CreateConfigRespFile, CheckOptions, 
#
###################################################################
#
echo " INFO Script Version 2.2"
#
PROGNAME=$(basename $0)
USRCMD="$0 $*"
#echo " INFO \"${USRCMD}\" used"

#############
# Functions          #
#############
#--------
Usage()
{ # usage description
echo ""
echo " Usage:"
echo "  $PROGNAME { -h WAS home } [ -p ] { -a [config {-v} { -m [yn|yndiag|diag] } { -e [prod|stage] } | unconfig {-v} | migrate {-f} {-t} ] } [-s servern1,servern2,...} [ -x ] [ -d ]"
echo "  -h WebSPhere home directory"
echo "  -p SOAP port used to connect to Dmgr (optional). Only relevant in case of \"-a config\" "
echo "     By default this port is retrieved by a wsadmin Python script"
echo "     However you can use this option to override the Dmgr port discoverd by the internal Python script"
echo "  -a configuration action [config, unconfig, migrate]"
echo "     -e deployment environment [prod, stage]. Only relevant for iaction \"-a config \""
echo "        Used to verify which MS Server host needs to be used in case of a \"-m [diag,yndiag]\" configuration (function CreateAmVariables)"
echo "     -m configuration mode [yn, yndiag, diag]. Only relevant for action \"-a config\" "
echo "        yn= Data collector (DC) is configured to communicate with the ITCAM Agent only (ITM/APM WebSphere Agent)"
echo "        yndiag= Data collector (DC) is configured to send data to the ITCAM Managing server (MS) and to the ITCAM Agent"
echo "               Function CreateAmVariables must contain the correct values for your environment (MS server host and home directory)"
echo "        diag= Data collector (DC) is configured to send data to the ITCAM Managing server (MS) ONLY"
echo "               Function CreateAmVariables must contain the correct values for your environment (MS server host and home directory)"
echo "     -v version to configure/unconfigure. Only relevant for action \"-a [config,unconfig]\" "
echo "     -f version to migrate from (old version). Only relevant for action \"-a migrate \""
echo "     -t version to migrate to (new version). Only relevant for action \"-a migrate \""
echo "  -s a list of servers to process seperated by comma (!must be without any space after comma)"
echo "     ! All server set in this parameter must be running otherwise not processed!"
echo "  -x if set action is executed (-a argument). By default only the silent response file is going to be created."
echo "     Note that checks to ensure a successfull execution are still performed. Hence check both response file and the message flow"
echo "  -d if set, tempory files are deleted. By default these files are not deleted but overwritten during the next call"
echo ""
echo " Sample executions:"
echo "  Create a silent response file only without execution unconfiguration step for all servers"
echo "    $PROGNAME -h /usr/WebSphere/AppServer -a unconfig -v 7.2.0.0.13"
echo ""
echo "  Unconfigure a list of servers and delete temporary files"
echo "    $PROGNAME -h /usr/WebSphere/AppServer -a unconfig -v 7.3.0.0.02 -d -s \"server1,server2\" -x -d "
echo ""
echo "  Configure two server in prod env with ITCAM Managing Server and TEMA for WebSphere enabled"
echo "    $PROGNAME -h /usr/WebSphere/AppServer -e prod -m yndiag -a config -v 7.3.0.0.02 -s Portal_01,Portal_02 -x"
echo "    If you want to override the Dmgr SOAP_CONNECTOR_ADDRESS Port discoverd automatically use -p option:"
echo "     $PROGNAME -h /usr/WebSphere/AppServer -p 1234 -e prod -m yndiag -a config -v 7.2.0.0.13 -s Portal_01,Portal_02 -x"
echo ""
echo "  Configure all server with TEMA for WebSphere enabled only"
echo "    $PROGNAME -h /usr/WebSphere/AppServer -m yn -a config -v 7.2.0.0.13 -x"
echo ""
echo "  Configure all server in stage env ITCAM Managing Server enabled only"
echo "    $PROGNAME -h /usr/WebSphere/AppServer -e stage -m diag -a config -v 7.2.0.0.13 -x"
echo ""
echo "  Migrate all server to a new version (note that version 7.2.0.0.14 should be installed before"
echo "    $PROGNAME -h /usr/WebSphere/AppServer -a migrate -f 7.2.0.0.13 -t 7.2.0.0.14 -x"
echo ""
echo "  Migrate server \"server1\" to a new version. "
echo "    $PROGNAME -h /usr/WebSphere/AppServer -a migrate -f 7.2.0.0.13 -t 7.2.0.0.14 -s server1 -x"
echo ""
exit 99
}

#--------------------
CreateServerAliases()
{ # Create aliases as defined by the customer. Only relevant for option "-a config"
   # Alias is only required when you use option "m [yn,yndiad]" and  server name is longer then 18 character.

     # How the server alias is created is customer specific. You can modify this function.
     # At the end array ALIASES must contain the right values: "server;aliasserver", "server2;aliasserver2",...
     # Sample alternativ code:
     # e.g. in case alias can be derived from the jvm name:
     # given name  e.g   jvm  = e52002cl01m_e5201n-z1tl0051
     # aliast should be = e52002cl01mz1tl0051
     #if [ ${SERVER} == "all" ] ; then
         #server=`grep "Server:" ${WAS_CONFDATA} | awk '{ print $2, "," $3 }'`
         #i=0
         #for srv in ${server//,/}
         #do
           #jvm="${srv%%/*}"
           #do something with jvm (servername and create alias $a)
           #y1=`echo $jvm | awk -F "_" '{print $1}'`
           #y2=`echo $jvm | awk -F "_" '{print $2}'`
           #y3=`echo $y2 | awk -F "-" '{print $2}'`
           #y4=`echo $y1 | sed 's/cl/c/g'`
           #y5=`echo $y4 | sed 's/m//g'`
           #a=`echo ${y5}${y3}`
           #ALIASES[$i]="$jvm;$a" ;
           #i=$((i+1))
         #done
     #else
         #IFS=","
         #i=0
         #for s in ${SERVER}
         #do
           #jvm=$s
           #do something with jvm (servername and create alias)
           #must be the same code as in above loop "for srv in ${server//,/}"
           #y1=`echo $jvm | awk -F "_" '{print $1}'`
           #y2=`echo $jvm | awk -F "_" '{print $2}'`
           #y3=`echo $y2 | awk -F "-" '{print $2}'`
           #y4=`echo $y1 | sed 's/cl/c/g'`
           #y5=`echo $y4 | sed 's/m//g'`
           #a=`echo ${y5}${y3}`
           #ALIASES[$i]="$jvm;$a" ;
           #i=$((i+1))
         #done
     #fi
     
     # Syntax:
     #        "realname;aliasname"
     # In case your are not using aliase:
     #        "realname;realname"
     ALIASES=(
       "server1;server1alias"
       "server2;server2alias"
     )

     # check length of Aliases, cannot be longer then 18 byte
     aliasdef=""; lalias=""
     for aliasdef in "${ALIASES[@]}"
     do
       lalias="${aliasdef#*;}"
       l=`echo -n $lalias | wc -m`
       #echo ---$l --- $lalias
       if [ $l -gt 18 ] ; then
           echo " ERROR Alias name \"$lalias\" ($l chars) is too long. Maximal 18 bytes allowed."
           return 5
       fi
     done

     return 0
}

#-------------------------
CheckServerNameAndAlias ()
{
    echo " INFO Display alias information"
    rc=0  
    al=0
    i=0
    for jvm in "${SERVERLIST[@]}"
    do
      GetServerAlias $jvm
      if [ $? -ne 0 ] ; then
          al=1
          SERVERLISTA[$i]="$jvm,none"
          printf " INFO   %-20s %-20s %s\n" $jvm "no alias configured" 
          l=`echo -n $jvm | wc -m`
          #echo ---$l --- $jvm
          if [ $l -gt 18 ] ; then
              echo " ERROR Server name \"$jvm\" ($l chars) is too long. Maximal 18 bytes allowed in ITM and APM."
              echo "       In this case you must use an alias name to have usefull ITM APM managed system name created."
              echo "       Please modify function \"CreateServerAliases\" and restart procedure"
              rc=1
          fi
      else
          SERVERLISTA[$i]="$jvm,${SERVER_ALIAS}"
          printf " INFO   %-20s %-20s %s\n" $jvm ${SERVER_ALIAS} 
      fi
      i=$((i+1))
    done

    if [ $al -ne 0 ] ; then
        echo " WARNING No alias found for some server in function \"CreateServerAliases\". Modify if required and restart the procedure."
    fi 

    SERVERLIST=("${SERVERLISTA[@]}") 
    #echo --- ${SERVERLIST[@]} ---
     
    return $rc
}

#----------------------
CheckAndDisplayStatus()
{
     echo " INFO Display Server's status:"
     rc=0
     if [ ${SERVER} == "all" ] ; then
         server=`grep "Server:" ${WAS_CONFDATA} | awk '{ print $2, "," $3 }'`
         i=0
         for srv in ${server//,/}
         do
           jvm="${srv%%/*}"
           jvmStatus="${srv#*/}"
           jvmStatus=$(echo $jvmStatus | tr -d ' ')
           if [ "$jvmStatus" == "not-running" ] ; then
               printf " WARNING  %-20s %-20s Server not running and will not be processed.\n" $jvm  $jvmStatus
               #SERVERLIST_TMP[$i]="$jvm"
           else
               printf " INFO     %-20s %-20s \n" $jvm  $jvmStatus
               SERVERLIST[$i]="$jvm"
               #SERVERLIST_TMP[$i]="$jvm"
           fi
           i=$((i+1))
         done
     else # Server list was provided 
         IFS=","
         i=0
         for s in ${SERVER}
         do
           jvm=""; jvmStatus=""
           stmp="$s/"
           server=`grep "Server: $stmp" ${WAS_CONFDATA} | awk '{ print $2, $3 }'`
           if [ "$server" == "" ] ; then
               echo " ERROR Server name \"$s\" does not exist"
               rc=1
               continue
           fi
           jvm="${server%%/*}"
           jvmStatus="${server#*/}"
           jvmStatus=$(echo $jvmStatus | tr -d ' ')
           if [ "$jvmStatus" == "not-running" ] ; then
               printf " WARNING  %-20s %-20s Server not running and will not be processed.\n" $jvm  $jvmStatus
               rc=1 
               continue
           else
               printf " INFO      %-20s %-20s \n" $jvm  $jvmStatus
               SERVERLIST[$i]="$jvm"
               i=$((i+1))
           fi
         done
     fi
     
     return $rc
}

#------------------------
function GetServerAlias()
{
     found=1
     for aliasdef in "${ALIASES[@]}" 
     do
       ljvm="" ; lalias="";
       ljvm="${aliasdef%%;*}"
       lalias="${aliasdef#*;}"
       if [ $1 == $ljvm ] ; then
           #printf "Server's %-30s alias is: %s.\n" "$jvm" "$lalias"
           SERVER_ALIAS="$lalias"
           found=0
           break
       fi
     done
     if [ $found -eq 1 ] ; then
         return 1
     fi

     return 0
}

#-----------------------------
CheckRunningServerDcConfig ()
{
     rc=0
     i=0
     array_t=("${SERVERLIST[@]}")
     for srv in "${SERVERLIST[@]}"
     do
       name="$srv"
       dcconfig=`ps -ef| grep java| grep ${name}| awk '{ n=split($0,a); for (x = 1; x <=n ; x++) {if ( match(a[x], "(^-Dam.home=)") ) { sub(/-Dam.home=/," ",a[x]); printf "%s\t", a[x]}} print ""}'`
       configuredVersion=`echo ${dcconfig} |sed 's/.*\/\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}.[0-9]\{1,3\}\)\/.*/\1/'` 

       if [ "$ACTION" == "unconfig" ] ; then
       #-------------- UNCONFIG ----------------------------
           if [ "${configuredVersion}" == "" ] ; then
               echo " WARNING Server $name is not configured hence cannot be unconfigured. Server will not be processed"
               unset array_t[$i]
               rc=1
           else
               echo " INFO Server $name configured: ${configuredVersion} "
               if [ $DCVERSION != $configuredVersion ] ; then
                   echo " ERROR Server $name configured with ${configuredVersion}. You set ${DCVERSION} to be unconfigured. Server will not be processed"
                   unset array_t[$i]
                   rc=2
               fi 
           fi
       elif [ "$ACTION" == "config" ] ; then
       #-------------- CONFIG ------------------------------
           if [ "${configuredVersion}" != "" ] ; then
               echo " WARNING Server $name already configured with: ${configuredVersion}. Server will not be processed"
               unset array_t[$i]
               rc=1
           fi
       elif [ "$ACTION" == "migrate" ] ; then
       #-------------- MIGRATE -----------------------------
           if [ "$configuredVersion" == "" ] ; then
               echo " WARNING Server $name seems to be running but is not DC configured yet. Server will not be processed"
               unset array_t[$i]
               rc=1
           else
               if [ $MIGFROMVERSION != $configuredVersion ] ; then
                   echo " ERROR Server $name configured with ${configuredVersion} which is not equal to the version you want to migrate from. Server will not be processed"
                   unset array_t[$i]
                   rc=2
               fi
           fi
       else
           echo " ERROR in CheckRunningServerDcConfig"
           return 3
       fi
       i=$((i+1))
     done
     SERVERLIST=("${array_t[@]}")

     if [ $rc -eq 2 ] ; then
         echo " ERROR If you are not using the -s and process all server, please note that all server needs to be on the same DC version level."
     fi 

     return 0
}

#---------------------
# Refer to:
# https://www.ibm.com/support/knowledgecenter/en/SS3JRN_7.2.0/com.ibm.itcamfapps_ad.doc_72/ecam_guide_72_new/silent_migrate_was_dc.html
# https://www.ibm.com/support/knowledgecenter/en/SSHLNR_8.1.4/com.ibm.pm.doc/install/was_migrate_dcsilent.htm
CreateMigrateRespFile()
{
     echo " INFO Create silent response file for action=migration"
     echo "# ITCAM Data Collector silent response file " > ${DC_SILENTINPUT}
     {
      echo "[DEFAULT SECTION]"
      # echo "default.hostip=.."
      echo "migrate.type=AD"
      echo "# Location of data collector to be migrated"
      echo "itcam.migrate.home=${DCHOMEFROM}"
      echo "# ITCAM Agent for WebSphere Applications"
      echo "temaconnect=True"
      echo "tema.host=127.0.0.1"
      echo "tema.port=63335"
      echo "#  Connect to WebSphere Admin Services"
      echo "was.wsadmin.connection.host=${CELLMGRHOST}"
      echo "was.wsadmin.connection.type=SOAP"
      echo "was.client.props=true"
      # echo "was.wsadmin.username="
      # echo "was.wsadmin.password="
      echo "#  WebSphere Application Server details"
      echo "was.appserver.profile.name=${PROFILENAME}"
      echo "was.appserver.home=${WASHOME}"
      echo "was.appserver.cell.name=${CELLNAME}"
      echo "was.appserver.node.name=${NODENAME}"
      echo "# WebSphere Application Server runtime instance settings"
     } >> ${DC_SILENTINPUT}

     #echo ${SERVERLIST[*]}
     for srv in "${SERVERLIST[@]}"
     do
       {
        echo "[SERVER]"
        echo "was.appserver.server.name=$srv"
       } >> ${DC_SILENTINPUT}
     done

     return 0
}

#---------------------
# Refer to:
# https://www.ibm.com/support/knowledgecenter/en/SSHLNR_8.1.4/com.ibm.pm.doc/install/was_config_dcsilent_properties_file.htm#was_config_dcsilent_properties_file
# https://www.ibm.com/support/knowledgecenter/en/SS3JRN_7.2.0/com.ibm.itcamfapps_ad.doc_72/ecam_guide_72_new/silent_config_was_dc.html
CreateConfigRespFile()
{
    echo " INFO Create silent response file for action=configuration"
    echo "# ITCAM Data Collector silent response file " > ${DC_SILENTINPUT}
    {
     echo "[DEFAULT SECTION]"
     # echo "default.hostip=.."
     echo  "# Integration of the DC with the ITCAM for Transactions"
     echo "ttapi.enable=False"
     #echo "ttapi.host="
     #echo "ttapi.port="
     echo "# Integration of the DC with the ITCAM for SOA" 
     echo "soa.enable=False"
     echo "# Integration of the DC with the Tivoli Performance Monitoring"
     echo "tpv.enable=False"
     echo "# Integration of the DC with the ITCAM Diagnostics Tool"
     echo "de.enable=False"
     echo "# Backup of the WebSphere configuration"
     echo "was.backup.configuration=False"
     # echo was.backup.configuration.dir=..."
     # echo "# Advanced configuration settings :"
     # echo "was.gc.custom.path="
     # echo "was.gc.file= "
     # echo "was.configure.heap="
    } >> ${DC_SILENTINPUT}
    if [ "$MODE" == "diag" -o "$MODE" == "yndiag" ] ; then
        {
         echo "# ITCAM for Application Diagnostics"
         echo "ms.connect=True"
         echo "ms.kernel.host=${AMHOST}"
         echo "ms.kernel.codebase.port=9122"
         echo "ms.am.home=${AMHOME}"
         echo "ms.am.socket.bindip=${AMSOCKETBIND}"
         echo "ms.probe.controller.rmi.port=8300-8399"
         echo "ms.probe.rmi.port=8200-8299"
         #echo "ms.firewall.enabled="
        } >> ${DC_SILENTINPUT}
     fi
     if [ "$MODE" == "diag" ] ; then
         {
         echo "# Integration with ITCAM Agent for WebSphere Applications:"
         echo "temaconnect=False"
         } >> ${DC_SILENTINPUT}
     else
         {
         echo "# Integration with ITCAM Agent for WebSphere Applications:"
         echo "temaconnect=True"
         echo "tema.host=127.0.0.1"
         echo "tema.port=63335"
         if [ $VERSION -gt 72 ] ; then
             echo "############################################"
             echo "# For DC versions >= 7.3 only (APM)"
             echo "# PMI resource and data collector monitoring"
             echo "tema.appserver=true"
             echo "tema.jmxport=63355"
             echo "# Integration of the data collector with ITCAM Agent for WebSphere version 6 (7.2)"
             echo "config.tema.v6=false"
             #echo "tema.host.v6="
             #echo "tema.port.v6=63336"
             echo "############################################"
         fi
         } >> ${DC_SILENTINPUT}
     fi
     {
      echo "# Connect to WebSphere Admin Services"
      echo "was.wsadmin.connection.host=${CELLMGRHOST}"
      echo "was.wsadmin.connection.type=SOAP"
      echo "was.wsadmin.connection.port=${PORT}"
      echo "was.client.props=true"
      # echo "was.wsadmin.username="
      # echo "was.wsadmin.password="
      echo "# WebSphere Application Server settings"
      echo "was.appserver.profile.name=${PROFILENAME}"
      echo "was.appserver.home=${WASHOME}"
      echo "was.appserver.cell.name=${CELLNAME}"
      echo "was.appserver.node.name=${NODENAME}"
      echo "# WebSphere Application Server runtime instance settings"
     } >> ${DC_SILENTINPUT}
    
     #echo ${SERVERLIST[*]}
     for srv in "${SERVERLIST[@]}"
     do
       name="${srv%%,*}"
       alias="${srv#*,}"
       {
        echo "[SERVER]"
        echo "was.appserver.server.name=$name"
       } >> ${DC_SILENTINPUT}
       if [ "$MODE" == "diag" ] ; then
           continue
       elif [ "$alias" != "none" ] ; then
           echo "tema.serveralias=$alias"  >> ${DC_SILENTINPUT}
       fi
     done

     return 0
}

#---------------------
# Refer to:
# https://www.ibm.com/support/knowledgecenter/en/SS3JRN_7.2.0/com.ibm.itcamfapps_ad.doc_72/ecam_guide_72_new/silent_unconfig_was_dc.html
# https://www.ibm.com/support/knowledgecenter/en/SSHLNR_8.1.4/com.ibm.pm.doc/install/was_unconfigure_dcsilent.htm
CreateUnConfigRespFile()
{
     echo " INFO Create silent response file action=unconfiguration"
     echo "# ITCAM Data Collector silent response file " > ${DC_SILENTINPUT}
     {
      echo "[DEFAULT SECTION]"
      echo "# Backup of the WebSphere configuration"
      echo "was.backup.configuration=False"
      # echo was.backup.configuration.dir=..."
      echo "#Connect to WebSphere Admin Services"
      echo "was.wsadmin.connection.host=${CELLMGRHOST}"
      echo "was.wsadmin.connection.type=SOAP"
      echo "was.client.props=true"
      # echo "was.wsadmin.username="
      # echo "was.wsadmin.password="
      echo "# WebSphere Application Server details"
      echo "was.appserver.profile.name=${PROFILENAME}"
      echo "was.appserver.home=${WASHOME}"
      echo "was.appserver.cell.name=${CELLNAME}"
      echo "was.appserver.node.name=${NODENAME}"
      echo "# WebSphere Application Server runtime instance settings"
     } >> ${DC_SILENTINPUT}

     #echo ${SERVERLIST[*]}
     for srv in "${SERVERLIST[@]}"
     do
       name="${srv%%,*}"
       {
        echo "[SERVER]"
        echo "was.appserver.server.name=$name"
       } >> ${DC_SILENTINPUT}
     done

     return 0
}

#--------------------
CreateWsadminScript()
{
     cat <<EOF > ${WSADMIN_SCRIPT}
import re
import os
import socket
import sys
import java
import java.util as util
import java.io as javaio

def GetShorthostname(provided_name):
    match=re.search("^(\w+)(\.\w+)(\.\w+)*$", provided_name)
    if match:
        shortname=match.group(1)
    else:
        shortname=provided_name
    #endif
    return str(shortname)

rc=0
# get DMGR name
dmgrname=AdminControl.queryNames('WebSphere:name=DeploymentManager,*')
#  WebSphere:name=DeploymentManager,process=dmgr,platform=common,node=e200n-z1tl0001,diagnosticProvider=true,version=
match=re.search("node=([^\,]*)",dmgrname)
if match:
     dmgrnode=match.group(1)
     print "DmgrNode: " + dmgrnode
#endif

# get Cell name
cellname=AdminControl.getCell()
print "Cellname: " + cellname

# get Node name, Dmgr hostname and soap connector port
system_name = GetShorthostname(socket.gethostname())
nodes=AdminConfig.list('Node').splitlines()
nodefound = 0
dmgrhostfound = 0
dmgrportfound = 0
for node_id in nodes:
    #node_id=AdminConfig.getid("/Node:"+node_name+"/")
    node_name=AdminConfig.showAttribute(node_id,'name')
    nodehost=AdminConfig.showAttribute(node_id,'hostName')
    dmgrmatch=re.search(dmgrnode, node_name)
    #print "---" + node_name  + "--" + dmgrnode
    if dmgrmatch:
        dmgrhostfound = 1
        print "CellMgrHostname: " + nodehost
        #print "CellMgrNodeId: " + node_id
        NamedEndPoints = AdminConfig.list( "NamedEndPoint" , node_id).split(lineSeparator)
        for namedEndPoint in NamedEndPoints:
            endPointName = AdminConfig.showAttribute(namedEndPoint, "endPointName" )
	    if endPointName == 'SOAP_CONNECTOR_ADDRESS':
                dmgrportfound = 1
                endPoint = AdminConfig.showAttribute(namedEndPoint, "endPoint" )
                host = AdminConfig.showAttribute(endPoint, "host" )
                port = AdminConfig.showAttribute(endPoint, "port" )
                print "DMGRPort" + endPointName + ": " + port
            #endif
        #endfor
    #endif
    dcbindip=nodehost
    nodehost=GetShorthostname(nodehost)
    if nodehost == system_name:
        if not dmgrmatch:
            nodefound = 1
            print "Running on: " + dcbindip
            #print " INFO: Running on host: " + nodehost
            #print " INFO: Nodename is: " + node_name
            break
        #endif
    #endif
#endfor

if dmgrhostfound == 0:
    print "ERROR: Could not identify DMgr hostname (DmgrNode:" + dmgrnode + ")"
    sys.exit(1)
elif nodefound == 0:
    print "ERROR: Could not identify local node" + node_name + " hostname"
    print "ERROR: HostName (returned by wsadmin showattribute): " + nodehost
    print "ERROR: System's hostname(returned by socket.gethostname): " + system_name
    sys.exit(1)
elif dmgrportfound == 0:
    print "DMGRPortSOAP_CONNECTOR_ADDRESS: notfound" 
else:
    pass
#endif
print  "Nodename: " + node_name

# Get Server Names
plist = "[-serverType APPLICATION_SERVER -nodeName " + node_name + "]"
server_list=AdminTask.listServers(plist)
server_list = AdminUtilities.convertToList(server_list)
servernames=""
for server in server_list:
     server_name=AdminConfig.showAttribute(server,'name')
     plist='cell=' + cellname + ',node=' + node_name + ',name=' + server_name + ',type=Server,*'
     server_status=AdminControl.completeObjectName(plist)
     #print  "Server: " + server_name
     #print "---------------------------" + server_status + "-"
     if server_status == '':
         print  "Server: " + server_name + "/not-running"
         #servernames=servernames + "," + server_name + "!!! Not started"
     else:
         #servernames=servernames + "," + server_name
         javahomeserver=server_name
         print  "Server: " + server_name + "/running"
     #endif
     continue
#endfor

# get java home
arg='[-nodeName ' + node_name + ' -serverName ' + javahomeserver + ']'
javahome=AdminTask.getJavaHome(arg)
print "JavaHome: " + javahome
#sys.exit(rc)
EOF

     if [ $? -ne 0 ] ; then
         rc=$?
         echo " ERROR During creation of wsadmin python input file (rc=$?)"
         return $rc
     fi

     return 0
}

#-----------------
GetWebSphereData()
{
     CreateWsadminScript
     if [ $? -ne 0 ] ; then
         return 1
     fi

     echo " INFO Collecting required data from WebSphere using wsadmin"
     echo " INFO Executing ${WSADMIN_HOME}/wsadmin.sh -lang jython -f ${WSADMIN_SCRIPT} "
     ${WSADMIN_HOME}/wsadmin.sh -lang jython -f ${WSADMIN_SCRIPT} > ${WAS_CONFDATA}
     if [ $? -ne 0 ] ; then
         echo " ERROR during: ${WSADMIN_HOME}/wsadmin.sh -lang jython -f ${WSADMIN_SCRIPT} (rc=$?)!! "
         return 1
     else
         grep "ERROR" ${WAS_CONFDATA}
         if [ $? -ne 0 ] ; then
             echo " INFO Data successfully collected from WebSphere"
         else
             echo " ERROR during: ${WSADMIN_HOME}/wsadmin.sh -lang jython -f ${WSADMIN_SCRIPT}!! "
             return 1
         fi
     fi

     # Save collected data in variables
     CELLMGRHOST=`grep "CellMgrHostname" ${WAS_CONFDATA} | awk '{ print $2 }'`
     echo " INFO   CellMgrHostname=${CELLMGRHOST}"

     CELLNAME=`grep "Cellname" ${WAS_CONFDATA} | awk '{ print $2 }'`
     echo " INFO   Cellname=${CELLNAME}"

     NODENAME=`grep "Nodename" ${WAS_CONFDATA} | awk '{ print $2 }'`
     echo " INFO   Nodename=${NODENAME}"

     THISHOST=`grep "Running on" ${WAS_CONFDATA} | awk '{ print $3 }'`
     echo " INFO   Running on host ${THISHOST}"

     DMGRSOAPPORT=`grep "DMGRPortSOAP_CONNECTOR_ADDRESS" ${WAS_CONFDATA} | awk '{ print $2 }'`
     echo " INFO   DMGR SOAP connector address returned by wsadmin is: ${DMGRSOAPPORT}"

     return 0
}

#------------
GetJavaHome()
{
     # By default JAVA_HOME value is used
     # Java Home is also retrieved by the function CreateWsadminScript
     # You can look in a different way to get JAVA_HOME
     # If you want to do so modify or add code of this function
     # or simply set ${JAVA_HOME} manually before execution

     if [ ! -d "${JAVA_HOME}" ]; then
         javatemp=`grep "JavaHome" ${WAS_CONFDATA} | awk '{ print $2 }'` 
         if [ ! -d "${javatemp}" ]; then
             javatemp=${WASHOME}/java
             if [ ! -d "${javatemp}" ]; then
                 echo " ERROR JAVA_HOME cannot be identified. Please export JAVA_HOME, or modify function GetJavaHome and restart the procedure"
                 return 1
             else
                 JAVA_HOME=${javatemp}
             fi
         else
             JAVA_HOME=${javatemp}
         fi
     else
         #echo " INFO JAVA_HOME variable appears to be exported."
         JAVA_HOME=${JAVA_HOME}
     fi

     echo " INFO JAVA_HOME=${JAVA_HOME}"
     return 0
}

#------------
GetItmHome()
{
     # You can look in a different way to get ITM/APM home
     # If you want to do so modify or add code of this function
     # or simply set ${CANDLEHOME} manually before execution
     if [ -d "${CANDLEHOME}" ]; then
         ITMHOME="${CANDLEHOME}"
     elif [ -d "/opt/IBM/ITM" ]; then
         ITMHOME="/opt/IBM/ITM"
     elif [ -d "/opt/ibm/apm" ]; then
         ITMHOME="/opt/ibm/apm"
     elif [ -d "/itm" ]; then
         ITMHOME="/itm"
     elif [ -d "/apm" ]; then
         ITMHOME="/apm"
     else
         echo " ERROR Cannot find ITM home directory. Please export CANDLEHOME accordingly."
         return 1
     fi

     echo " INFO ITMHOME=${ITMHOME}"
     return 0
}

#------------
GetWasdcHome()
{
     # If this code fails to find the right wasdchome it is most
     # likely caused by a bad ITMHOME value (see GetItmHome)
     WASDCHOME=`find ${ITMHOME} -name yndchome`
     if [ -d "${WASDCHOME}" ]; then
         echo " INFO WASDCHOME=${WASDCHOME}"
     else
         WASDCHOME=`find ${ITMHOME} -name wasdc`
         if [ -d "${WASDCHOME}" ]; then
             echo " INFO WASDCHOME=${WASDCHOME}"
         else
             WASDCHOME=`find ${ITMHOME} -name dchome`
             if [ -d "${WASDCHOME}" ]; then
                 echo " INFO WASDCHOME=${WASDCHOME}"
             else
                 echo " ERROR Cannot find DC home directory (${WASDCHOME}). Verify from CANDLEHOME."
                 return 1
             fi
         fi
     fi

     if [ "${ACTION}" == "migrate" ] ; then
         #-------------- MIGRATE ----------------------------
         if [ -d "${WASDCHOME}/${MIGFROMVERSION}" ]; then
             DCHOMEFROM="${WASDCHOME}/${MIGFROMVERSION}"
             echo " INFO DCHOMEFROM=${DCHOMEFROM}"
         else
             echo " ERROR Cannot find DC home directory ${DCHOMEFROM}. Verify migration arguments (from version)."
             return 1
         fi
         if [ -d "${WASDCHOME}/${MIGTOVERSION}" ]; then
             DCHOME="${WASDCHOME}/${MIGTOVERSION}"
             echo " INFO DCHOME=${DCHOME}"
         else
             echo " ERROR Cannot find DC home directory ${WASDCHOME}/${MIGTOVERSION}. Verify migration arguments (to version)."
             return 1
         fi
     else
	 #-------------- CONFIG and  UNCONFIG ----------------------------
         if [ -d "${WASDCHOME}/${DCVERSION}" ]; then
             DCHOME="${WASDCHOME}/${DCVERSION}"
             echo " INFO DCHOME=${DCHOME}"
         else
             echo " ERROR Cannot find DC home directory ${WASDCHOME}/${DCVERSION}. Verify migration arguments (from version)."
             return 1
         fi
     fi

     return 0
}

#---------------
GetWsadminHome()
{
    temp=`echo ${WASHOME}| awk -F"/AppServer" '{print $1}'`
    wsadmin="${temp}/wp_profile/bin/wsadmin.sh"
    if [ -f "${wsadmin}" ]; then
        WSADMIN_HOME="${temp}/wp_profile/bin/"
    else
        wsadmin="${WASHOME}/bin/wsadmin.sh"
        if [ -f "${wsadmin}" ]; then
            WSADMIN_HOME="${WASHOME}/bin"
        else
            echo " ERROR !!! wsadmin.sh cannot be found. Please verify ${WASHOME}/bin and restart the procedure."
            return 1
        fi
    fi

    echo " INFO WSADMIN_HOME=${WSADMIN_HOME}"
    return 0
}

#---------------
GetProfileName()
{
     # Create profile name (Customer specific, normally equal nodename)
     echo " INFO Collecting profile information using manageprofiles.sh"
     #echo " INFO Executing ${WASHOME}/bin/manageprofiles.sh -listProfiles successfully executed"
     profile=`${WASHOME}/bin/manageprofiles.sh -listProfiles| sed s'/\[//' |  sed s'/\]//' `
     if [ $? -ne 0 ] ; then
         echo " ERROR during: ${WASHOME}/bin/manageprofiles.sh -listProfiles"
         return 1
     else
         echo " INFO Existing profiles: $profile."
     fi
     pffound=0
     c=0
     for pf in $(echo $profile | sed "s/,/ /g")
     do
         c=$((c+1))
         if [ "$pf" == "$NODENAME" ] ; then
             PROFILENAME="${NODENAME}"
             pffound=1 # means profilename equal nodename
             break
         fi
         if [ "$pf" == "wp_profile" ] ; then
             PROFILENAME="wp_profile"
             break
         fi
     done
     if  [ $c == 0 ] ; then
         echo " ERROR manageprofiles.sh does not return any data"
         return 1
     fi
     if  [ $pffound == 0 ] ; then
         PROFILENAME=$pf
     fi

     echo " INFO PROFILENAME=${PROFILENAME}"
     return 0
}

#--------------
CreateAmVariables ()
{
     # Customer specific. Only used for deep dive ITCAM.
     # Create AM variables if diag
     if [ "$ENVIR" == "prod" ] ; then
         AMHOST="prodMShost.com"
     else
         AMHOST="stageMShost.com"
     fi
     echo " INFO AMHOST=${AMHOST}"

     AMHOME="/opt/IBM/itcam/WebSphere/MS"
     echo " INFO AMHOME=${AMHOME}"

     AMSOCKETBIND=`grep "Running on" ${WAS_CONFDATA} | awk '{ print $3 }'`
     echo " INFO AMSOCKETBIND=${AMSOCKETBIND}"

     return 0
}

#--------------
CheckDmgrPort ()
{
     if [ "$PORT" == "false" ] ; then
         if [ "$DMGRSOAPPORT" == "notfound" ] ; then
             echo " ERROR DMGRSoapPort could not be identified by ${WSADMIN_SCRIPT} python script"
             echo "       You must restart the procedure using option -p"
	     return 1
         else 
             echo " INFO DMGRSoapPort used= ${DMGRSOAPPORT} (returned by ${WSADMIN_SCRIPT})"
             PORT=$DMGRSOAPPORT
         fi
     fi
     if [ "$PORT" == "$DMGRSOAPPORT" ] ; then
         echo " INFO DMGRSoapPort used= ${PORT}"
     else
         echo " INFO DMGRSoapPort used=\"${PORT}\" (set by -p option) "
     fi
     return 0
}

#--------------
PostProcessing ()
{
    #  Customer specific post processing can be inserted here
    if [ "${ACTION}" == "config" -o "${ACTION}" == "migrate" ] ; then
    #-------------- CONFIG --SAMPLE --------------------------
        echo " INFO Customer specific post processing for \"-a config\" defined"
        echo " INFO Post processing: \"-verbosegc\" will be deleted from the JVM arguments for all servers configured or migrated previously"
        i=0
        # write server names into a comma seperated string
        for s in ${SERVERLIST[@]}
        do
            if [ $i -eq 0 ] ; then
                SERVERNAMES="${s}"
            else
                SERVERNAMES="${SERVERNAMES},${s}"
            fi
            i=$((i+1))
        done

        echo " INFO Executing: ${WSADMIN_HOME}/wsadmin.sh -lang jython -f jvm_arguments.py del \"${SERVERNAMES[*]}\" -verbosegc"
        ${WSADMIN_HOME}/wsadmin.sh -lang jython -f jvm_arguments.py del "${SERVERNAMES[*]}" -verbosegc
        if [ $? -ne 0 ] ; then
            echo " ERROR During post processing"
            return 1
        fi
        #echo -n
    elif [ "$ACTION" == "unconfig" ] ; then
    #-------------- UNCONFIG ---------------------------
        echo -n
    elif [ "$ACTION" == "migrate" ] ; then
    #-------------- MIGRATE ----------------------------
        echo -n
    fi

    return 0
}
#--------------
CheckOptions ()
{
    echo " INFO Check options"
    if [ ! -d "${WASHOME}" ] ; then
        echo " ERROR \"${WASHOME}\" directory  not existing or not set"
        Usage
    else
        echo " INFO WASHOME=${WASHOME}"
    fi

    if [ -n "$PORT" ] ; then
        echo " INFO DMGRSoapPort set by procedure argument = ${PORT}"
    else
        PORT="false"
    fi

    if [ -n "$ACTION" ] ; then
        if [ "$ACTION" == "config" -o  "$ACTION" == "unconfig" -o  "$ACTION" == "migrate" ] ; then
            echo " INFO ACTION=${ACTION}"
            if [ "$ACTION" == "migrate" ] ; then
                #-------------- MIGRATE ----------------------------
                if [ -n "${MODE}" ] ; then
                echo " INFO MODE=${MODE}  # But is ignored, because not required for migration"
                fi
                if [ -n "${ENVIR}" ] ; then
                    echo " INFO ENVIRONMENT=${ENVIR}  # But is ignored, because not required for migration"
	        fi
	        if [ -n "$MIGFROMVERSION" -o -n "$MIGTOVERSION"  ] ; then
                    echo " INFO MIGFROMVERSION=${MIGFROMVERSION}  to MIGTOVERSION=${MIGTOVERSION}."
                    imigverfrom=$(echo $MIGFROMVERSION | tr -d '.')
                    imigverto=$(echo $MIGTOVERSION | tr -d '.')
                    if [ $imigverfrom -gt $imigverto -o $imigverfrom -eq $imigverto  ] ;  then
                        echo " ERROR The version you want to migrate from ${MIGFROMVERSION} cannot be higher then or equal to the version you want to migrate to ${MIGTOVERSION}."
                        Usage
                    fi 
                else
                    echo " ERROR Action argument \"-a\" is: \"${ACTION}\". Mandatory arguments \"-f\" and  \"-t\"  not set."
                Usage
                fi
            elif [ "$ACTION" == "config" ] ; then
                #-------------- CONFIG ----------------------------
                if [ -n "${DCVERSION}" ] ; then
                    VERSION=`echo ${DCVERSION}| awk -F"." '{print $1$2}'`
                    echo " INFO SHORTVERSION=${VERSION}"
                    echo " INFO VERSION=${DCVERSION}"
                else
                    echo " ERROR Action argument \"-a\" is: \"${ACTION}\". Mandatory argument \"-v\" not set."
                    Usage
                fi
                if [ -n "${MODE}" ] ; then
                    if [ "${MODE}" == "yndiag" -o "${MODE}" == "yn" -o "${MODE}" == "diag" ] ; then
                        echo " INFO MODE=${MODE}"
                        if [ "${MODE}" == "diag" ] ; then
                            if [ -n "$ENVIR" ] ; then
                                if [ "$ENVIR" == "prod" -o  "$ENVIR" == "stage" ] ; then
                                    echo " INFO ENVIRONMENT=\"${ENVIR}\" "
                                else
                                    echo " ERROR Environment argument \"-e\" is: \"${ENVIR}\". Only [prod,stage] are allowed."
                                    Usage
                                fi
                            else
                                echo " ERROR Mandatory argument \"-e\" not set."
                                Usage
                            fi
                        fi
                    else
                        echo " ERROR Mode argument \"-m\" is: \"${MODE}\". Only [yn,yndiag,diag] are allowed."
                        Usage
                    fi
                else
                    echo " ERROR Mandatory argument \"-m\" for \"-a\"=config is not set."
                    Usage
                fi
            elif [ "$ACTION" == "unconfig" ] ; then
                #-------------- UNCONFIG ----------------------------
                if [ -n "${MODE}" ] ; then
                    echo " INFO MODE=${MODE}  # But is ignored, because not required for unconfiguration"
                fi  
                if [ -n "${ENVIR}" ] ; then
                    echo " INFO ENVIRONMENT=${ENVIR}  # But is ignored, because not required for unconfiguration"
	        fi	 
                if [ -n "${DCVERSION}" ] ; then
                    echo " INFO VERSION=${DCVERSION}."
                else
                    echo " ERROR Action argument \"-a\" is: \"${ACTION}\". Mandatory argument \"-v\" not set."
                    Usage
                fi
            fi
        else
            echo " ERROR Action argument \"-a\" is: \"${ACTION}\". Only [config,unconfig,migrate] are allowed"
            Usage
        fi
    else
        echo " ERROR Mandatory argument \"-a\" not set."
        Usage
    fi

    if [ "${DELTMP}" == "true" ] ; then
        echo " INFO DELTMP=${DELTMP}  # Temporary files will be deleted after execution"
        DELTMP="true"
    else
        DELTMP="false"
        echo " INFO DELTMP=${DELTMP}  # Temporary files will NOT be deleted (DEFAULT)"
    fi

    if [ ! -n "${SERVER}" ] ; then
        SERVER="all"
    else
        if [[ "${SERVER}" =~ "," ]] ;then
             SERVER=$(echo $SERVER | tr -d ' ')
        else 
             SERVER=`echo ${SERVER// /,}`
        fi
    fi
     
    echo " INFO SERVER=${SERVER}"

    if [ "${EXECACTION}" == "true" ] ; then
        echo " INFO EXECACTION=${EXECACTION}  # Silent response will be created and ITCAM procedures started"
        EXECACTION="true"
    else
        EXECACTION="false"
        echo " INFO EXECACTION=${EXECACTION}  # Only silent response will be created (DEFAULT)"
    fi

    return 0
}

###############################################
################### MAIN ######################
###############################################
# Temporary files created in current directory:
DC_SILENTINPUT="tmp.itcamdc.silentinput.txt"
WAS_CONFDATA="tmp.itcamdc.websphere_data.conf"
WSADMIN_SCRIPT="tmp.itcamdc.wsadminScript.py"
while getopts "xdh:e:a:p:m:s:f:t:v:" OPTS
do
  case $OPTS in
     h) WASHOME=${OPTARG} ;;
     e) ENVIR=${OPTARG} ;;
     a) ACTION=${OPTARG} ;;
     m) MODE=${OPTARG} ;;
     p) PORT=${OPTARG} ;;
     s) SERVER=${OPTARG} ;;
     v) DCVERSION=${OPTARG} ;;
     f) MIGFROMVERSION=${OPTARG} ;;
     t) MIGTOVERSION=${OPTARG} ;;
     x) EXECACTION="true" ;;
     d) DELTMP="true" ;;
     *) echo "$OPTARG is not a valid switch"; Usage ;;
  esac
done

# Check argmuments provided
CheckOptions

GetItmHome  # Required by ITCAM procedures
if [ $? -ne 0 ] ; then
    exit 1
fi

GetWsadminHome # Get "wsadmin.sh" Home directory
if [ $? -ne 0 ] ; then
    exit 3
fi

GetWasdcHome # Required by ITCAM procedures
if [ $? -ne 0 ] ; then
    exit 4
fi

# Retrieve data from WebSphere required by the ITCAM procedures.
# Used in the input file for silent execution.
GetWebSphereData
if [ $? -ne 0 ] ; then
    exit 5
fi

# get Websphere profile name
GetProfileName
if [ $? -ne 0 ] ; then
    exit 6
fi

GetJavaHome  # Required by ITCAM procedures
if [ $? -ne 0 ] ; then
    exit 7
fi

# Display, check server status and create variable SERVERLIST to be used later
CheckAndDisplayStatus
if [ $? -ne 0 -a "${EXECACTION}" == "true" ] ; then
    echo " ERROR during CheckAndDisplaySrvStatus"
    exit 8
fi
if [ "${#SERVERLIST[@]}" == "0" ] ; then
    echo " ERROR Nothing to process. None of the selected server are running, check messages"
    exit 9
fi

# Check running servers. Server deleted from SERVERLIST under certain conditions 
CheckRunningServerDcConfig
if [ $? -ne 0 -a "${EXECACTION}" == "true" ] ; then
    echo " ERROR during CheckRunningServerDcConfig"
    exit 10
fi
if [ "${#SERVERLIST[@]}" == "0" ] ; then
    echo " ERROR Nothing to process. Please check messages"
    exit 11
fi

SERVERJVM=("${SERVERLIST[@]}") 
echo " INFO Server to process: ${SERVERLIST[@]}"
# Create response files to be used
if [ "${ACTION}" == "config" ] ; then
    #-------------- CONFIG ----------------------------
    CheckDmgrPort
    if [ $? -ne 0 ] ; then
        echo " ERROR During CheckDmgrPort"
        exit 12
    fi
    # Create the array ALIASES containing server's name and alias
    CreateServerAliases
    if [ $? -ne 0 -a "${EXECACTION}" == "true" ] ; then
        echo " ERROR during CreateServerAliases"
        exit 13
    fi
    # Check server alias or name. Variable SERVERLIST modified"
    CheckServerNameAndAlias
    if [ $? -ne 0 -a "${EXECACTION}" == "true" ] ; then
         echo " ERROR during CheckServerNameAndAlias"
         exit 14
    fi
    if [ "${MODE}" == "yndiag" -o  "${MODE}" == "diag" ] ; then
         CreateAmVariables
    fi
    CreateConfigRespFile 
    if [ $? -ne 0 ] ; then
        exit 15
    fi
elif  [ "${ACTION}" == "unconfig" ] ; then
    #-------------- UNCONFIG ----------------------------
    CreateUnConfigRespFile
    if [ $? -ne 0 ] ; then
        exit 16
    fi
elif  [ "${ACTION}" == "migrate" ] ; then
    #-------------- MIGRATE ----------------------------
    CreateMigrateRespFile
    if [ $? -ne 0 ] ; then
        exit 17
    fi
fi

if [ "${EXECACTION}" == "true" ] ; then
    echo " INFO Execute configuration based on arguments provided"
    echo " INFO Executing: ${DCHOME}/bin/${ACTION}.sh -silent ${DC_SILENTINPUT}"
    export JAVA_HOME=$JAVA_HOME
    ${DCHOME}/bin/${ACTION}.sh -silent ${DC_SILENTINPUT}
    if [ $? -ne 0 ] ; then
        echo " ERROR During execution of: ${DCHOME}/bin/${ACTION}.sh -silent ${DC_SILENTINPUT} (rc=$?)"
        exit 18
    fi

    # By default no post processing defined.
    # You can uncomment the line below and modify function PostProcessing
    #PostProcessing
    if [ $? -ne 0 ] ; then
        echo " ERROR During Post proccessing"
        exit 19
    fi

else
    echo " INFO Created silent configuration file: ${DC_SILENTINPUT}"
    echo "----"
    cat ${DC_SILENTINPUT}
    echo "----"
    echo " WARNING Please check the response file created. Also check message flow for errors which may indicate potential issues preventing a successful action execution"
fi

if [ "${DELTMP}" == "true" ] ; then
     rm tmp.itcamdc.*
     if [ $? -ne 0 ] ; then
         echo " ERROR During file deletion: rm tmp.itcamdc.*"
         exit 20
     fi
fi

echo " INFO procedure successfully ended"
exit 0
