#!/bin/bash

#source /oracle/.bash_profile

cd /Oracle_RAC_11G_Scripts
source /Oracle_RAC_11G_Scripts/baseConfig.sh

node2=$1
echo -e "$FCYellow Executing the root scripts on second node : $node2 $FCNoColor" | tee -a $successLogs
sh /oracle/app/product/12.2.0/dbhome_1/root.sh >> /tmp/dj
if [ $? -eq 0 ]; then
{
	sleep 20
        echo -e "$FCGreen Successfully completed execution of root scripts. $FCNoColor" | tee -a $successLogs
}
else
{
	echo -e "$FCRed Error executing root scripts pleas execute manually in $node2" | tee -a $failureLogs
}
fi

