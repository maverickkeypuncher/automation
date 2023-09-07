#!/bin/bash
# Purpose : Script will do a hostfile entry on the nodes
# Author : DJ
# Date : 14 Jan 2019


## Below function will do host file entry on both the nodes

hostEntry()
{
	for i in ens192 ens161
	do
		ip=`/sbin/ifconfig | grep -A2 $i | grep inet | head -1 | awk '{ print $2 }' | xargs`
		if [ $i = "ens192" ]; then
		{ 
			echo $ip `hostname` >> /etc/hosts
        		sshpass -ppassw0rd! ssh -o StrictHostKeyChecking=no cluset@$cluNode2 'echo "passw0rd!" | sudo -S -s /bin/bash -c "echo '$ip'  '$hostnode1' >> /etc/hosts"'
        		ipaddr=`sshpass -ppassw0rd! ssh -o StrictHostKeyChecking=no cluset@$cluNode2 /sbin/ifconfig | grep -A2 $i | grep inet | head -1 |  awk '{ print $2 }' | xargs`
			echo $ipaddr $hostnamenode2 >> /etc/hosts
			sshpass -ppassw0rd! ssh -o StrictHostKeyChecking=no cluset@$cluNode2 'echo "passw0rd!" | sudo -S -s /bin/bash -c "echo '$ipaddr'  '$hostnamenode2' >> /etc/hosts"'
		}
		#elif [ $i = "eth1" ]; then
		#{
	#		echo $ip `hostname`"-vip" >> /etc/hosts
        #		sshpass -ppassw0rd! ssh -o StrictHostKeyChecking=no cluset@$cluNode2 'echo "passw0rd!" | sudo -S -s /bin/bash -c "echo '$ip'  '$hostnode1'"-vip" >> /etc/hosts"'
        #		ipaddr=`sshpass -ppassw0rd! ssh -o StrictHostKeyChecking=no cluset@$cluNode2 /sbin/ifconfig | grep -A2 $i | grep inet | head -1 |  awk '{ print $2 }' | xargs`
	#		echo $ipaddr $hostnamenode2"-vip" >> /etc/hosts
	#		sshpass -ppassw0rd! ssh -o StrictHostKeyChecking=no cluset@$cluNode2 'echo "passw0rd!" | sudo -S -s /bin/bash -c "echo '$ipaddr'  '$hostnamenode2'="vip" >> /etc/hosts"'
	#	}
		elif [ $i = "ens161" ]; then
		{
			## HB IP
			echo $ip `hostname`"-priv" >> /etc/hosts
        		sshpass -ppassw0rd! ssh -o StrictHostKeyChecking=no cluset@$cluNode2 'echo "passw0rd!" | sudo -S -s /bin/bash -c "echo '$ip'  '$hostnode1'"-priv" >> /etc/hosts"'
        		ipaddr=`sshpass -ppassw0rd! ssh -o StrictHostKeyChecking=no cluset@$cluNode2 /sbin/ifconfig | grep -A2 $i | grep inet | head -1 |  awk '{ print $2 }' | xargs`
			echo $ipaddr $hostnamenode2"-priv" >> /etc/hosts
			sshpass -ppassw0rd! ssh -o StrictHostKeyChecking=no cluset@$cluNode2 'echo "passw0rd!" | sudo -S -s /bin/bash -c "echo '$ipaddr'  '$hostnamenode2'="priv" >> /etc/hosts"'
		}
		else
		{
			echo "Not a valid interface : $i"
		}
		fi
		
	done
}
clear
source ./baseConfig.sh

hostnode1=`hostname`
cluNode2="$2"
#echo $cluNode2
hostnamenode2=`sshpass -ppassw0rd! ssh -o StrictHostKeyChecking=no cluset@$cluNode2 'hostname' | xargs`
if  [ X$cluNode2 = X ]; then
{
	echo -e "$FCRed Please provide IP address or FQDN of node or nodes in the RAC cluster $FCNoColor" | tee -a $failureLogs
	exit 1
}
fi
ipaddr=`sshpass -ppassw0rd! ssh -o StrictHostKeyChecking=no cluset@$cluNode2 /sbin/ifconfig | grep -A2 ens | grep inet | head -1 | tail -1 | awk '{ print $2 }' | xargs`
hostEntry
#sh /OracleRACScripts/RAC/createASMDisk.sh $hostnode1 $cluNode2
