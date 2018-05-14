import re
import os
import sys
import java
import java.util as util
import java.io as javaio
import socket

def usage():
 print ""
 print "Usage :   ./wsadmin.sh -lang jython -f jvm_arguments.py {show,add,del,set} [server name] [argToDeleteOrAdd]"
 print "   show  = Display current JVM arguments"
 print "   add   = Add a new JVM argument (!!will be appended). Only one can be added at a time"
 print "   del   = Delete an JVM argument. Only one can be deleted at a time"
 print "   set   = Set an entire new JVM argument string."
 print "   help  = Script usage information"
 print ""
 print " Examples:"
 print ""
 print "  1. To show show JVM arguments of a single instance"
 print "     Single instance:  ./wsadmin.sh -lang jython -f jvm_arguments.py show Iguazu_01"
 print "     List of instancies: ./wsadmin.sh -lang jython -f jvm_arguments.py show Iguazu_01,Cataratas_01"
 print "     Be prompted for instancies: ./wsadmin.sh -lang jython -f jvm_arguments.py show "
 print "  2. To delete an argument from JVM arguments"
 print "     Single instance:  ./wsadmin.sh -lang jython -f jvm_arguments.py del Iguazu_01 -verbosegc"
 print "     List of instancies: ./wsadmin.sh -lang jython -f jvm_arguments.py del Iguazu_01,Cataratas_01 -verbosegc"
 print "     Be prompted for instancies and argument: ./wsadmin.sh -lang jython -f jvm_arguments.py del "
 print "  3. To add an argument to JVM arguments (NEW argument will be appended)"
 print "     Single instance:  ./wsadmin.sh -lang jython -f jvm_arguments.py add Iguazu_01 -verbosegc"
 print "     List of instancies: ./wsadmin.sh -lang jython -f jvm_arguments.py add Iguazu_01,Cataratas_01 -mynewArgument "
 print "     Be prompted for instancies and new argument: ./wsadmin.sh -lang jython -f jvm_arguments.py add "
 print "  4. To set a complete, entire new JVM argument"
 print "     NOTE: You will always be prompted for the entire new JVM Argument!"
 print "      New jvm argument for Single instance:  ./wsadmin.sh -lang jython -f jvm_arguments.py set Iguazu_01"
 print "      New jvm argument for a list of instancies: ./wsadmin.sh -lang jython -f jvm_arguments.py set Iguazu_01,Cataratas_01 "
 print "      Be prompted for the instance and new entrire argument: ./wsadmin.sh -lang jython -f jvm_arguments.py set "
 print ""

def GetShorthostname(provided_name):
    match=re.search("^(\w+)(\.\w+)(\.\w+)*$", provided_name)
    if match:
        shortname=match.group(1)
    else:
        shortname=provided_name
    #endif
    return str(shortname)

def GetServerList():
 if len(sys.argv) > 1:
   temp_list = sys.argv[1]
   server_list=AdminConfig.list('Server').splitlines()
   temp_list=temp_list.split(',')
   rc_jvmid = []
   for srv in temp_list:
     i = 0
     for server in server_list:
       server_name=AdminConfig.showAttribute(server,'name')
       if srv == server_name:
         jvm_id=AdminConfig.list('JavaVirtualMachine',server)
         rc_jvmid.extend([jvm_id])
         i = 1
       continue
     #endfor
     if i == 1:
       continue
     else:
       print "!!! Server \"" + srv + "\" does not exists"
       sys.exit(2)
     #endif
     continue
   #endfor
   return rc_jvmid
 else:
   dmgrname=AdminControl.queryNames('WebSphere:name=DeploymentManager,*')
   #  WebSphere:name=DeploymentManager,process=dmgr,platform=common,node=e200n-z1tl0001,diagnosticProvider=true,version=
   match=re.search("node=([^\,]*)",dmgrname)
   if match:
       dmgrnode=match.group(1)
       print "DmgrNode: " + dmgrnode
   #endif

   system_name = GetShorthostname(socket.gethostname())
   nodes=AdminConfig.list('Node').splitlines()
   for node_id in nodes:
       #node_id=AdminConfig.getid("/Node:"+node_name+"/")
       node_name=AdminConfig.showAttribute(node_id,'name')
       nodehost=AdminConfig.showAttribute(node_id,'hostName')
       dcbindip=nodehost
       nodehost=GetShorthostname(nodehost)
       dmgrmatch=re.search(dmgrnode, node_name)
       if nodehost == system_name:
           if not dmgrmatch:
               nodefound = 1
               print "Running on: " + dcbindip
               break
           #endif
       #endif
   #endfor
   plist = "[-serverType APPLICATION_SERVER -nodeName " + node_name + "]"
   server_list=AdminTask.listServers(plist)
   server_list = AdminUtilities.convertToList(server_list)
   #server_list=AdminConfig.list('Server').splitlines()
   i = 0
   print ""
   print "--- Available Servers are:"
   print ""
   for server in server_list:
     i = i + 1
     server_name=AdminConfig.showAttribute(server,'name')
     node_name=re.search("nodes\/(.*)\/servers", server)
     #print "  " + str(i) + ". " + " (" + node_name.group(1) + ") " + server_name
     print ' %2d. %-20s -> %s' % (str(i),  node_name.group(1), server_name)
     continue
   print "\n"
   ans = 1
   while ans == 1:
     serverOfInterrest=raw_input(">Type the numbers for the server you want to use seperated by comma, or \"q\" to quit procedure. : ")
     se=re.search("^(\d+(,\d+)*)?$", serverOfInterrest)
     if len(serverOfInterrest) == 1 and serverOfInterrest[0] == "q":
         sys.exit(0)
     if se:
         ans = 0
     continue
   rc_jvmid = []
   serverOfInterrest=serverOfInterrest.split(',')
   print "---> Selected Servers are:"
   for nr in serverOfInterrest:
     if nr == " " or nr == "":
       continue
     server_name=AdminConfig.showAttribute(server_list[int(nr)-1],'name')
     jvm_id=AdminConfig.list('JavaVirtualMachine',server_list[int(nr)-1])
     print server_list[int(nr)-1]
     print "----"
     rc_jvmid.extend([jvm_id])
     node_name=re.search("nodes\/(.*)\/servers", jvm_id)
     #print "--->   " + server_name + "(" + node_name.group(1) + ")"
     print '--->   %-32s (%-s)' % ( server_name, node_name.group(1) )
     continue
   print "\n"
   return rc_jvmid
 #endif

def CurrentJvmArguments(jvm_id):
 current_arguments=AdminConfig.showAttribute(jvm_id,"genericJvmArguments")
 print "--- Current  Generic JVM Arguments are :"
 print str(current_arguments) + "\n"
 return str(current_arguments)


def DeleteArgumentFromGenericJVM(jvm_id, jvm_arg, arg_toDelete):
 se=re.search(arg_toDelete, jvm_arg)
 if se:
   print "--- \"" + arg_toDelete + "\" ist set, removing it..."
   new_arg=re.sub(arg_toDelete, '', jvm_arg)
   print "--- New Generic JVM Arguments are :"
   print new_arg + "\n"
   ModifySaveChanges(jvm_id, new_arg)
   return 0
 else:
   print "--- The argument \"" + arg_toDelete + "\" doest not exists. No action performed."
   return 2
 #endif


def AddArgumentToGenericJVM(jvm_id, jvm_arg, arg_toAdd):
 se=re.search(arg_toAdd, jvm_arg)
 if se:
   print "--- The argument \"" + arg_toAdd + "\" exists already. No action performed."
   return 2
 else:
   print "--- \"" + arg_toAdd + "\" adding to generic JVM Args..."
   new_arg= jvm_arg + " " + arg_toAdd
   print "--- New Generic JVM Arguments are :"
   print new_arg + "\n"
   ModifySaveChanges(jvm_id, new_arg)
   return 0
 #endif


def SetNewGenericJVMString(jvm_id, jvm_arg):
 print "--- New Generic JVM Arguments are :"
 print jvm_arg + "\n"
 ModifySaveChanges(jvm_id, new_arg)
 return 0

def ModifySaveChanges(jvm_id, new_arg):
 print "--- Modifying configuration: \"genericJvmArguments\" ..."
 AdminConfig.modify(jvm_id,[['genericJvmArguments',new_arg]])
 print "--- Saving configuration ..."
 AdminConfig.save()
 return 0

##############
# MAIN #######
##############
print "------ Procedure started ------"

if not (len(sys.argv) >= 1 ) or not (len(sys.argv) < 4):
 usage()
 sys.exit(1)
#endif
#print sys.argv[1]
#test=sys.argv[1]
#server_list=test.split(',')
#print server_list

jvm_act=sys.argv[0]
if jvm_act == "help":
  usage()
  sys.exit(0)
#endif

if jvm_act == "set" or jvm_act == "del" or jvm_act == "add" or jvm_act == "show":
  print "------ Parameter OK"
else:
  print "!!!!! Unsupported parameter used!"
  usage()
  sys.exit(1)
#endif

a_jvmList=GetServerList()

if jvm_act == "show":
  for jvm_id in a_jvmList:
    print "------ JVM Server ID is", jvm_id, "-------"
    jvm_arg=CurrentJvmArguments(jvm_id)
    print "====================================================================="
    continue
  #endFor
elif jvm_act == "del":
  if len(sys.argv) == 3:
    arg_toDelete=sys.argv[2]
  else:
    arg_toDelete=raw_input(">Provide the argument to delete: ")
  #endif
  print "---> Argument to delete is: \"", arg_toDelete, "\""
  print "\n"
  for jvm_id in a_jvmList:
    print "------ JVM Server ID is", jvm_id, "-------"
    jvm_arg=CurrentJvmArguments(jvm_id)
    DeleteArgumentFromGenericJVM(jvm_id, jvm_arg, arg_toDelete)
    print "====================================================================="
    continue
  #endFor
elif jvm_act == "add":
  if len(sys.argv) == 3:
    arg_toAdd=sys.argv[2]
  else:
    arg_toAdd=raw_input(">Provide the argument to add: ")
  #endif
  print "---> Argument to add is: \"", arg_toAdd, "\""
  print "\n"
  for jvm_id in a_jvmList:
    print "------ JVM Server ID is", jvm_id, "-------"
    jvm_arg=CurrentJvmArguments(jvm_id)
    AddArgumentToGenericJVM(jvm_id, jvm_arg, arg_toAdd)
    print "====================================================================="
    continue
  #endFor
elif jvm_act == "set":
  if len(sys.argv) == 3:
    print "ERROR You cannot use argument \"set\" together with paramter: ", sys.argv[2]
    print "ERROR Only two arguments allowed:  ./wsadmin.sh -lang jython -f jvm_arguments.py set [Iguazu_01]"
    usage()
    sys.exit(1)
  #endif
  new_arg=raw_input(">Provide the new arguments: ")
  for jvm_id in a_jvmList:
    print "------ JVM Server ID is", jvm_id, "-------"
    jvm_arg=CurrentJvmArguments(jvm_id)
    SetNewGenericJVMString(jvm_id, new_arg)
    print "====================================================================="
    continue
  #endFor
else:
  print "!!!!! Something goes wrong !"
  print "====================================================================="
  sys.exit(1)
#endif

print "------ Procedure ended  ------"
sys.exit(0)
