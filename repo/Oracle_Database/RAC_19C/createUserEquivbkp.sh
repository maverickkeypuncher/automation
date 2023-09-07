#!/bin/bash
# Purpose : Create password less login for oracle user on both the nodes
# Author : DJ

#cd /OracleRACScripts/RAC/
source ./baseConfig.sh

node2=$2
node1=$1

mkdir /oracle/.ssh

su oracle -c 'echo "passw0rd!" | ssh-keygen -R '$node1''
if [ $? -eq 0 ]; then
{
	echo -e "$FCGreen 1 Successfully removed if any existing entries in known_hosts files $FCNoColor" | tee -a $successLogs
}
else
{
	echo -e "$FCYellow 1 Unable to remove existing entries in known_hosts file $FCNoColor" | tee -a $errorLogs
}
fi
su oracle -c 'echo "passw0rd!" | ssh-keygen -R '$node2''
if [ $? -eq 0 ]; then
{
	echo -e "$FCGreen 2 Successfully removed if any existing entries in known_hosts files $FCNoColor" | tee -a $successLogs
}
else
{
	echo -e "$FCYellow 2 Unable to remove existing entries in known_hosts file $FCNoColor" | tee -a $errorLogs
}
fi

#su oracle -c 'echo "passw0rd!" | ssh-keyscan -H 172.22.236.29 >> /oracle/.ssh/known_hosts'
#su oracle -c 'echo "passw0rd!" | ssh-keyscan -H 172.22.236.30 >> /oracle/.ssh/known_hosts'
su oracle -c 'echo "passw0rd!" | ssh-keyscan -H '$node1' >> /oracle/.ssh/known_hosts'
su oracle -c 'echo "passw0rd!" | ssh-keyscan -H '$node2' >> /oracle/.ssh/known_hosts'

su - oracle -c 'echo "passw0rd!" | mkdir -p /oracle/.ssh'
cd /oracle/.ssh
touch /oracle/.ssh/known_hosts
chown oracle:dba /oracle/.ssh/known_hosts


su - oracle -c 'echo "passw0rd!" | ssh-keygen -q -t rsa -f /oracle/.ssh/id_rsa -N ""'
if [ $? -eq 0 ]; then
{
	echo -e "$FCGreen 1 Successfully generated the public key  for node1 $FCNoColor" | tee -a $successLogs
}
else
{
	echo -e "$FCRed 1 Error creating a public key for $node1 $FCNoColor" | tee -a $errorLogs
}
fi
su - oracle -c 'echo "passw0rd!" | cat /oracle/.ssh/id_rsa.pub >> /oracle/.ssh/authorized_keys'
sshpass -p "passw0rd!"  scp /oracle/.ssh/authorized_keys oracle@$node2:/oracle/.ssh

sshpass -p "passw0rd!" ssh -o StrictHostKeyChecking=no oracle@$node2 "echo passw0rd! | sudo -S -s /bin/bash /Oracle_RAC_11G_Scripts/createUserEquiv_N2.sh $node1 $node2"

su - oracle -c 'echo "passw0rd!" | ssh '$node1'  date'
su - oracle -c 'echo "passw0rd!" | ssh '$node2'  date'
su - oracle -c 'echo "passw0rd!" | ssh '$node1'.localdomain date'
su - oracle -c 'echo "passw0rd!" | ssh '$node2'.localdomain date'

hnode2=`sshpass -p 'passw0rd!' ssh -o StrictHostKeyChecking=no oracle@$node2 'hostname'`
hnode1=`hostname`

#sh /OracleRACScripts/RAC/createRSFG.sh $hnode1 $hnode2


