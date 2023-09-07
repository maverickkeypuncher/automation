#!/bin/bash
#Purpose : This script will initiate the execution of RDBMS installer 
# Author : DJ


## Once both the response files are create we will first call the grid installer as below

## Below function checks if the DB installation process is completed
checkProcessCompleted()
{
	grep "$stGring" $logDIR/*.log 2>/dev/null
	if [ $? -eq 0 ]; then
	{
		#echo -e "$FCYellow Executing the root scripts on first node : $node1 $FCNoColor" | tee -a $successLogs
		#sh /oracle/app/product/11.2.0.4/db_1/root.sh >> /tmp/dj
		#if [ $? -eq 0 ]; then
		#{
		#	sleep 20
		#	echo -e "$FCGreen Successfully completed execution of root scripts. Executing ConfigToolCommands on $node1 $FCNoColor" | tee -a $successLogs
		#	## Below is an event to generate a trigger to execute root scripts on second node
		#	echo -e "$FCGreen Successfully generated an event to trigger execution of patch installation and root scripts in $node2 node $FCNoColor" | tee -a $successLogs
		#	sshpass -p "passw0rd!" ssh cluset@$node2 'echo "passw0rd!" | sudo -S sh /OracleRACScripts/RAC/executeRDBMSInstaller_N2.sh '$node2''  > /dev/null &
		#	sleep 300
			sh /OracleRAC19C/createASMDG-Data-Redo.sh $node1 $node2
		#}
		#else
		#{
		#	echo -e "$FCRed Error executing the root scripts. Please execute the same manually in $node1 $FCNoColor" | tee -a $successLogs
		#}
		#fi
	}
	else
	{
		echo -n "."
		sleep 10
		checkProcessCompleted
	}
	fi
}

cd /OracleRAC19C
source /OracleRAC19C/baseConfig.sh
node1=$1
node2=$2
echo $node1 >> $successLogs
echo $node2 >> $successLogs

RSPF="/oracle/app/product/19.3.0/dbhome_1/db.rsp"
#INSTALLER="/oracle/app/product/19.3.0/dbhome_1/database"
INSTALLER="/oracle/app/product/19.3.0/dbhome_1/"
#configFile="cfgrsp.properties"
#configFilePath="/OracleRACScripts/RAC"
logDIR="/oracle/oraInventory/logs"
#string="The installation of Oracle Database 11g was successful."
file="silentInstall"
#patchDIR="/opt/18370031"
su - oracle -c "echo oracle | sed -i -e '1iexport CV_ASSUME_DISTID=8.0\'  '$INSTALLER'runInstaller"
#su - oracle -c 'echo oracle | sh '$INSTALLER'runInstaller -J-Doracle.installer.performRemoteCopyInAPIMode=true -silent -responseFile '$RSPF' -ignorePrereq -ignoreInternalDriverError'  | tee -a $successLogs
su - oracle -c 'echo oracle | sh '$INSTALLER'runInstaller -silent -responseFile '$RSPF' -ignorePrereq -ignoreInternalDriverError'  | tee -a $successLogs
echo -e "$FCYellow Installing Oracle Database 19C ... Please wait $FCNoColor" | tee -a $successLogs
#checkProcessCompleted	
#echo -e "$FCYellow Executing the root scripts on first node : $node1 $FCNoColor" | tee -a $successLogs
#sh /oracle/app/product/19.3.0/dbhome_1/root.sh >> /tmp/dj
#sh /oracle/app/product/19.3.0/db_1/root.sh >> /tmp/dj
if [ $? -eq 0 ]; then
{
	sh /OracleRAC19C/createASMDG-Data-Redo.sh $node1 $node2
#	sleep 20
#        echo -e "$FCGreen Successfully completed execution of root scripts. Executing ConfigToolCommands on $node1 $FCNoColor" | tee -a $successLogs
        ## Below is an event to generate a trigger to execute root scripts on second node
#        echo -e "$FCGreen Successfully generated an event to trigger execution of patch installation and root scripts in $node2 node $FCNoColor" | tee -a $successLogs
#        sshpass -p "Passwd!1" ssh sysadm@$node2 'echo "Passwd!1" | sudo -S sh /OracleRAC19C/executeRDBMSInstaller_N2.sh '$node2''  > /dev/null &
#        sleep 300
#        sh /OracleRAC19C/createASMDG-Data-Redo.sh $node1 $node2
}
else
{
	echo -e "$FCRed Error exexuting rdbms installation . Please execute the same manually in $node1 $FCNoColor" | tee -a $successLogs
	sh /OracleRAC19C/createASMDG-Data-Redo.sh $node1 $node2
}
fi


