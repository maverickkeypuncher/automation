#!/bin/bash
# Purpose : Script will initiate execution of oracle 11G grid setup
# Author : DJ


## Once both the response files are create we will first call the grid installer as below

checkProcessCompleted()
{
	grep "$string" $logDIR/*.log 2>/dev/null
	if [ $? -eq 0 ]; then
	{
		echo -e "$FCYellow $string Please check $file for more information $FCNoColor" | tee -a $successLogs
		echo "--------------------------------------------------------------------------------------------------------------"
		echo -e "$FCYellow Performing Patch installation for RHEL 7 , PATCH # 18370031. This will be performed using the oracle user $FCNoColor" | tee -a $successLogs
		echo "--------------------------------------------------------------------------------------------------------------"
		su - oracle -c 'echo oracle | echo Y | '$GRID_HOME'/OPatch/opatch apply -oh '$GRID_HOME' -local '$patchDIR''
		if [ $? -eq 0 ]; then
		{
			echo -e "$FCGreen Successfully applied patch on $node1 $FCNoColor" | tee -a $successLogs
			echo -e "$FCYellow Executing the root scripts on first node $FCNoColor" | tee -a $successLogs
			sh /oracle/oraInventory/orainstRoot.sh >> /tmp/dj
			if [ $? -eq 0 ]; then
			{
				sh $GRID_HOME/root.sh >> /tmp/dj
				sleep 60
				grep "Configure Oracle Grid Infrastructure for a Cluster ... succeeded" /oragrid/app/product/11.2.0.4/grid_1/install/root_*.log 2>/dev/null
				if [ $? -eq 0 ]; then
				{
					echo -e "$FCGreen Successfully completed execution of root scripts. Executing ConfigToolCommands $FCNoColor" | tee -a $successLogs
					su - oracle -c 'echo oracle | sh '$GRID_HOME'/cfgtoollogs/configToolAllCommands RESPONSE_FILE='$configFilePath'/'$configFile'' | tee -a $successLogs
					## Below is an event to generate a trigger to execute root scripts on second node
					sshpass -p oracle ssh cluset@$node2 'echo oracle | sudo -S sh /OracleRACScripts/RAC/executeRootScripts_N2.sh '$node2'' > /dev/null &
					if [ $? -eq 0 ]; then
					{
						## Call the RDBMS script execution
						echo -e "$FCYellow Please wait ... Root script execution in progress in $node2 $FCNoColor" | tee -a $successLogs
						sleep 600
						echo -e "$FCGreen Successfully generated an event to trigger execution of patch installation and root scripts in $node2 node $FCNoColor" | tee -a $successLogs
						sh /OracleRACScripts/RAC/executeRDBMSInstaller.sh $node1 $node2 | tee -a $successLogs
					}
					else
					{
						echo -e "$FCRed Please execute the root scripts manually on second node : $node2 $FCNoColor" | tee -a $failureLogs
					}
					fi
							
				}
				else
				{
					echo -e "$FCRed Error executing $GRID_HOME/root.sh. Please check /tmp/dj for more details and execute manually $FCNoColor" | tee -a $failureLogs
				}
				fi
			}
			else
			{
				echo -e "$FCRed Error executing /oracle/oraInventory/orainstRoot.sh . Please check /tmp/dj for more details and execute manually $FCNoColor" | tee -a $failureLogs
			}
			fi
		}
		else
		{
			echo -e "$FCRed Could not apply patch $patchDIR and hence could not execute root scripts on both the nodes. Please patch the nodes and then execute the root scripts manually $FCNoColor" | tee -a $failureLogs
		}
		fi
	}
	else
	{
		echo -n "."
		sleep 10
		checkProcessCompleted
	}
	fi
}
clear
cd /OracleRAC19C/
source ./baseConfig.sh
node1=$1
node2=$2
echo $node1 >> $successLogs
echo $node2 >> $successLogs

## Below is due to a bug for openssh for RHEL 8 and user equivalency fails due to same
if [ -e /usr/bin/scp.original ]; then
{
	echo "SCP OKAY"
}
else
{
	mv -f /usr/bin/scp /usr/bin/scp.original
	chmod 777 /usr/bin/scp.original
	echo -e "/usr/bin/scp.original -T \$*" > /usr/bin/scp
	chmod 555 /usr/bin/scp
}
fi
su - oracle -c 'echo oracle | ssh-keygen -p -m PEM -f /oracle/.ssh/id_rsa -q -N ""'
sshpass -p Passwd!1 ssh sysadm@$node2 'echo oracle | sudo ssh-keygen -p -m PEM -f /oracle/.ssh/id_rsa -q -N ""'

chown -R oracle:dba /oracle
chown -R oracle:dba /oragrid
RSPF="/oragrid/app/product/19.3.0/grid_1/inventory/Scripts"
INSTALLER="/oragrid/app/product/19.3.0/grid_1"
#configFile="cfgrsp.properties"
configFilePath="/OracleRAC19C/"
logDIR="/oracle/oraInventory/logs"
string="The installation of Oracle Grid Infrastructure 11g was successful."
file="silentInstall"
#patchDIR="/opt/18370031"
#su - oracle -c 'echo oracle | sh '$INSTALLER'/runInstaller -silent -responseFile '$RSPF' -ignorePrereq' | tee -a $successLogs
#checkProcessCompleted
echo "Installing Grid Infrastructure ... Please wait " | tee -a $successLogs
grep "CV_ASSUME_DISTID"  /oracle/.bash_profile 
if [ $? -ne 0 ]; then
{
	su - oracle -c 'echo CV_ASSUME_DISTID=8.0 >> /oracle/.bash_profile' 
}
fi
su - oracle -c "echo oracle | sed -i -e '1iexport CV_ASSUME_DISTID=8.0\'  '$INSTALLER'/gridSetup.sh"
#source /oracle/.bash_profile
su - oracle -c 'echo oracle | sh '$INSTALLER'/gridSetup.sh -silent -responseFile '$RSPF'/grid_install.rsp -ignorePrereqFailure' | tee -a $successLogs
#if [ $? -eq 0 ]; then
#{
	#mv /oragrid/app/product/19.3.0/grid_1/usm /oragrid/app/product/19.3.0/grid_1/usm_orig
	#echo -e "$FCYellow Executing the root scripts on first node $FCNoColor" | tee -a $successLogs
	#sh /oracle/oraInventory/orainstRoot.sh >> /tmp/dj
	#echo "Executing Root Scripts" >> /tmp/dj
	#echo "------------------------------------------------------------------" >> /tmp/dj
	#sh -x /oragrid/app/product/19.3.0/grid_1/root.sh >> /tmp/dj
	#sleep 60
	#grep "Configure Oracle Grid Infrastructure for a Cluster ... succeeded" /oragrid/app/product/19.3.0/grid_1/install/root_*.log 2>/dev/null
cd /oragrid/oraInventory/logs/
grep "Configure Oracle Grid Infrastructure for a Cluster ... succeeded" GridSetupActions2021-*/GridSetupActions2021-*.log 2>/dev/null
if [ $? -eq 0 ]; then
{                               
	echo -e "$FCGreen Successfully completed execution gridSetup.sh $FCNoColor" | tee -a $successLogs
                #su - oracle -c 'echo oracle | sh /oragrid/app/product/19.3.0/grid_1/cfgtoollogs/configToolAllCommands RESPONSE_FILE='$configFilePath'/'$configFile'' | tee -a $successLogs
                ## Below is an event to generate a trigger to execute root scripts on second node
        #        sshpass -p Passwd!1 ssh sysadm@$node2 'echo oracle | sudo -S sh /OracleRAC19C/executeRootScripts_N2.sh '$node2'' > /dev/null &
        #        if [ $? -eq 0 ]; then
        #        {
        #       		## Call the RDBMS script execution
        #                echo -e "$FCYellow Please wait ... Root script execution in progress in $node2 $FCNoColor" | tee -a $successLogs
        #                sleep 600
        echo -e "$FCGreen started DB binaries installation  $FCNoColor" | tee -a $successLogs
        sh /OracleRAC19C/executeRDBMSInstaller.sh $node1 $node2 | tee -a $successLogs
        #        }
        #        else
        #        {
        #        	echo -e "$FCRed Please execute the root scripts manually on second node : $node2 $FCNoColor" | tee -a $failureLogs
        #        }
       # 	 fi
}
else
{
	echo -e "$FCRed Error executing Grid Setup Please check /tmp/dj for more details and execute manually $FCNoColor" | tee -a $failureLogs 
        sh /OracleRAC19C/executeRDBMSInstaller.sh $node1 $node2 | tee -a $successLogs
}
fi
#}
#else
#{
#	#echo -e "$FCRed Error executing /oracle/oraInventory/orainstRoot.sh . Please check /tmp/dj for more details and execute manually $FCNoColor" | tee -a $failureLogs
#	echo -e "$FCRed Error executing gridSetup.sh . Please check /tmp/dj for more details and execute manually $FCNoColor" | tee -a $failureLogs
#}
#fi


		


