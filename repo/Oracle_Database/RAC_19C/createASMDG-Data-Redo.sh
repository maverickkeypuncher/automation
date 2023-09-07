#!/bin/bash
# Purpose : Script will create the disk groups for data disk and redo disks
# Author : DJ
# Date : 4 Feb 2019

exec 1> /tmp/commandlast.log 2>&1


#CREATE DISKGROUP REDODISK03 EXTERNAL REDUNDANCY DISK '\''/dev/oracleasm/disks/REDODISK03'\'';


ORACLE_HOME="/oragrid/app/product/19.3.0/grid_1"
su - oracle -c 'touch /oracle/.bash_profile'
echo "ORACLE_SID=+ASM1" >> /oracle/.bash_profile 
               echo "export ORACLE_SID" >> /oracle/.bash_profile
               echo "ORACLE_HOME=/oragrid/app/product/19.3.0/grid_1"  >> /oracle/.bash_profile
               echo "export ORACLE_HOME" >> /oracle/.bash_profile
               echo "PATH=$PATH:$ORACLE_HOME/bin" >> /oracle/.bash_profile
               echo "export PATH" >> /oracle/.bash_profile
  

source /oracle/.bash_profile

#source /oracle/.bash_profile
cd /OracleRAC19C
source /OracleRAC19C/baseConfig.sh
touch /tmp/results.txt
#touch /tmp/selectDiskGroup.sql
chown oracle:dba /tmp/results.txt
cp -v /OracleRAC19C/selectDiskGroup.sql /tmp/
chmod 777 /tmp/selectDiskGroup.sql
chown oracle:dba /tmp/selectDiskGroup.sql
touch /tmp/selectQuery.sql
chown oracle:dba /tmp/selectQuery.sql


node1=$1
node2=$2

valu=`ps -ef | grep -v grep | grep "asm_smon_" | tail -1 | awk '{ print $NF }' | cut -d"+" -f2`


su - oracle -c '	source /oracle/.bash_profile 
			sqlplus / as sysasm' <<-EOF
			spool /tmp/results.txt
			set echo off 
			set heading off
			@/tmp/selectDiskGroup.sql
			spool off
			exit
EOF
touch /tmp/datadiskgroup
chown oracle:dba /tmp/datadiskgroup
for i in `ls -lrth /dev/oracleasm/disks/* | awk '{print $NF}' | cut -d"/" -f5`
do
	echo "In For"
	device=`grep -w $i -B1 /tmp/results.txt | grep -A2 "CANDIDATE" | grep -v "\[" | xargs`
	#if [[ $device =~ "DATADISK" ]]; then
	#{
	#	echo "In IF"
#		#devicee=`grep -w $i -B1 /tmp/results.txt | grep -A2 "CANDIDATE" | grep -v "\[" | cut -d" " -f1 | xargs`
#		devicee=`grep -w $i -B1 /tmp/results.txt | grep -A2 "CANDIDATE" | grep -v "\[" | xargs`
#		echo "'$devicee'" >> /tmp/datadiskgroup
#	}
#	else
#	{ 
	diskGrpName=`grep -w $i -B1 /tmp/results.txt | grep -A2 "CANDIDATE" | grep -v "\[" | cut -d"/" -f5 | xargs`
	if [[ $diskGrpName != DATADISK* ]]; then
	{
		if [[ $diskGrpName == "REDODISK01" ]]; then
		{
			diskGrpName="REDO1"
		}
		fi
		if [[ $diskGrpName == "REDODISK02" ]]; then
		{
			diskGrpName="REDO2"
		}
		fi
		if [[ $diskGrpName == "REDODISK03" ]]; then
		{
			diskGrpName="REDO3"
		}
		fi
		echo -n "CREATE DISKGROUP $diskGrpName EXTERNAL REDUNDANCY DISK '$device' ATTRIBUTE 'compatible.asm' = '19.0';" > /tmp/selectQuery.sql
		su - oracle -c 	'	source /oracle/.bash_profile
					sqlplus / as sysasm' <<-EOF
					spool /tmp/results1.txt
					set echo off
					set heading off
					@/tmp/selectQuery.sql
					spool off
					exit;
		EOF
		if [ $? -eq 0 ]; then
		{
			echo -e "$FCGreen Successfully created ASM disk group for $device with $diskGrpName $FCNoColor" | tee -a $successLogs
		}
		else
		{
			echo -e "$FCRed Error creating diskgroup $diskGrpName on device $device $FCNoColor" | tee -a $failureLogs
		}
		fi
	}
	fi
done

#dd=`cat /tmp/datadiskgroup | tr '\n' ',' | cut -d"," -f1,2`

echo -n "CREATE DISKGROUP DATA EXTERNAL REDUNDANCY DISK '/dev/oracleasm/disks/DATADISK*' ATTRIBUTE 'compatible.asm' = '19.0';" > /tmp/selectQuery.sql
#echo -n "CREATE DISKGROUP DATA EXTERNAL REDUNDANCY DISK $dd;" > /tmp/selectQuery.sql
su - oracle -c '	source /oracle/.bash_profile
			sqlplus / as sysasm' <<-EOF
                	spool /tmp/results1.txt
	                set echo off
	                set heading off
	                @/tmp/selectQuery.sql
        	        spool off
               		exit;
EOF


/oragrid/app/product/19.3.0/grid_1/bin/asmcmd mount -a
sshpass -p 'Passwd!1' ssh -o StrictHostKeyChecking=no sysadm@$node2 'sudo /usr/sbin/oracleasm scandisks'
sshpass -p 'Passwd!1' ssh -o StrictHostKeyChecking=no sysadm@$node2 'sudo /oragrid/app/product/19.3.0/grid_1/bin/asmcmd mount -a'

echo "+ASM1 : /oragrid/app/product/19.3.0/grid_1:N" > /etc/oratab
sshpass -p 'Passwd!1' ssh -o StrictHostKeyChecking=no sysadm@$node2 'sudo echo "+ASM1 : /oragrid/app/product/19.3.0/grid_1:N" > /etc/oratab'
true > /oracle/.bash_profile
cp -v /OracleRAC19C/bashEntry.sh /tmp/
chmod 777 /tmp/bashEntry.sh
sh /tmp/bashEntry.sh $node1 $node2

