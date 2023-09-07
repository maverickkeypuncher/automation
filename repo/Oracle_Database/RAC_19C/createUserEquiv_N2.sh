#!/bin/bash
# Purpose : This script is used for creating user equivalence for user oracle on second node in the cluster
# Author : DJ

node1=$1
node2=$2

#su oracle -c 'echo "passw0rd!" | ssh-keygen -R 12.22.236.29'
su oracle -c 'echo "passw0rd!" | ssh-keygen -R '$node1''
#su oracle -c 'echo "passw0rd!" | ssh-keygen -R 172.22.236.30'
su oracle -c 'echo "passw0rd!" | ssh-keygen -R '$node2''

su oracle -c 'echo "passw0rd!" | ssh-keyscan -H '$node1' >> /oracle/.ssh/known_hosts'
su oracle -c 'echo "passw0rd!" | ssh-keyscan -H '$node2' >> /oracle/.ssh/known_hosts'



#su oracle -c 'echo "passw0rd!" | ssh-keygen -R 172.22.236.29'
#su oracle -c 'echo "passw0rd!" | ssh-keygen -R 172.22.236.30'

#su oracle -c 'echo "passw0rd!" | ssh-keyscan -H 172.22.236.29 >> /oracle/.ssh/known_hosts'
#su oracle -c 'echo "passw0rd!" | ssh-keyscan -H 172.22.236.30 >> /oracle/.ssh/known_hosts'

su - oracle -c 'echo "passw0rd!" | mkdir -p /oracle/.ssh'
cd /oracle/.ssh
touch /oracle/.ssh/known_hosts
chown oracle:dba /oracle/.ssh/known_hosts


su - oracle -c 'echo "passw0rd!" | ssh-keygen -q -t rsa -f /oracle/.ssh/id_rsa -N "" <<<y 2>&1 >/dev/null'
su - oracle -c 'echo "passw0rd!" | cat /oracle/.ssh/id_rsa.pub >> /oracle/.ssh/authorized_keys'
#chmod 777 /oracle/.ssh/authorized_keys
su - oracle -c 'sshpass -p "passw0rd!"  scp /oracle/.ssh/authorized_keys oracle@'$node1':/oracle/.ssh'
#sshpass -p passw0rd!  scp /oracle/.ssh/authorized_keys oracle@$node1:/tmp/

su - oracle -c 'echo "passw0rd!" | ssh '$node1'  date'
su - oracle -c 'echo "passw0rd!" | ssh '$node2'  date'
su - oracle -c 'echo "passw0rd!" | ssh '$node1'.localdomain date'
su - oracle -c 'echo "passw0rd!" | ssh '$node2'.localdomain date'
exec /usr/bin/ssh-agent $SHELL
/usr/bin/ssh-add

cd /Oracle_RAC_11G_Scripts/RAC
