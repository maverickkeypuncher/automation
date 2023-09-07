#! /bin/bash
# Purpose : This script is used for creation of response file for grid installation and oracle database installation for version 11.2.0.4
# Author : DJ

cd /OracleRAC19C
source /OracleRAC19C/baseConfig.sh

chown -R oracle:dba /oragrid/app/product/19.0.3/grid_1

node2=$2
node1=$1
echo $node2 >> $successLogs
echo $node1 >> $successLogs

#inteth0=eth0
inteth0=ens192
#inteth2=ens256
inteth2=Private

netmasketh0=`/sbin/ifconfig | grep -A2 $inteth0 | grep netmask | head -1 | awk '{ print $4 }' | xargs`
ipeth0=`/sbin/ifconfig | grep -A2 $inteth0 | grep inet | head -1 | awk '{ print $2 }' | xargs`
netmasketh2=`/sbin/ifconfig | grep -A2 $inteth2 | grep netmask | head -1 | awk '{ print $4 }' | xargs`
ipeth2=`/sbin/ifconfig | grep -A2 $inteth2 | grep inet | head -1 | awk '{ print $2 }' | xargs`

IFS=. read -r i1 i2 i3 i4 <<< "$ipeth0"
IFS=. read -r m1 m2 m3 m4 <<< "$netmasketh0"
valeth0=`printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))"`

IFS=. read -r i1 i2 i3 i4 <<< "$ipeth2"
IFS=. read -r m1 m2 m3 m4 <<< "$netmasketh2"
valeth2=`printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))"`


hnode2=`sshpass -p 'oracle' ssh -o StrictHostKeyChecking=no oracle@$node2 'hostname'`

#INSTALLER="/OracleRACScripts/grid-11.2.0.4/grid"
INSTALLER="/OracleRAC19C"
filePath="/OracleRAC19C/"
file="grid_install.rsp"
fileDB="db.rsp"
scanname=`cat /etc/hosts | grep -i scan | grep -v "#" | cut -d" " -f2 | head -1 | xargs`
#val=`printf '%s\n' "${hostn//[[:digit:]]/}" | xargs`
hostn=`hostname`
val=`printf '%s\n' "${hostn//[[:digit:]]/}" | xargs`
#val="testnodedjtestnodedj"
## Check if the $val is not more than 15 chars
if [ `echo $val | wc -c` -le 7 ]; then
{
	mainVal=$val
}
else
{
	a=`echo $val | wc -c`
	b=`expr $a - 8`
	length=${#val}
	endindex=$(expr $length - $b)
	mainVal=`echo ${val:0:$endindex}`
}
fi

#lineNo=`grep -n ORACLE_HOSTNAME $filePath/$file | cut -d":" -f1`
#line=`grep  ORACLE_HOSTNAME $filePath/$file`
#sed -i ''$lineNo'd' $filePath/$file
#if [ $? -eq 0 ]; then
#{
#	echo -e "$FCYellow Deleted the line $line. Now adding it $FCNoColor" | tee -a $successLogs
#}
#fi
#sed -i "${lineNo}i ORACLE_HOSTNAME=$hostn" $filePath/$file 
#if [ $? -eq 0 ]; then
#{
#	echo -e "$FCGreen Successfully added new line $line $FCNoColor" | tee -a $successLogs
#}
#fi

### Below will change the oracle_hostname variable value in db.rsp , which is a response file for database creation

#ORACLE_HOSTNAME=work1
#lineNo=`grep -n ORACLE_HOSTNAME $filePath/$fileDB | cut -d":" -f1`
#line=`grep ORACLE_HOSTNAME $filePath/$fileDB`
#sed -i ''$lineNo'd' $filePath/$fileDB
#if [ $? -eq 0 ]; then
#{
#        echo -e "$FCYellow Deleted the line $line. Now adding it $FCNoColor" | tee -a $successLogs
#}
#fi
#sed -i "${lineNo}i ORACLE_HOSTNAME=$hostn" $filePath/$fileDB
#if [ $? -eq 0 ]; then
#{
#	echo -e "$FCGreen Successfully added new line $line $FCNoColor" | tee -a $successLogs
#}
#fi


#oracle.install.crs.config.gpnp.scanName=work-scan
lineNo=`grep -n "oracle.install.crs.config.gpnp.scanName" $filePath$file | cut -d":" -f1`
line=`grep -n "oracle.install.crs.config.gpnp.scanName" $filePath$file`
sed -i ''$lineNo'd' $filePath/$file
if [ $? -eq 0 ]; then
{
        echo -e "$FCYellow Deleted the line $line. Now adding it $FCNoColor" | tee -a $successLogs
}
fi
sed -i "${lineNo}i oracle.install.crs.config.gpnp.scanName=$scanname" $filePath$file
if [ $? -eq 0 ]; then
{
	echo -e "$FCGreen Successfully added new line $line $FCNoColor" | tee -a $successLogs
}
fi

#oracle.install.crs.config.clusterName=work-cluster

lineNo=`grep -n "oracle.install.crs.config.clusterName" $filePath$file | cut -d":" -f1`
line=`grep -n "oracle.install.crs.config.clusterName" $filePath$file`
sed -i ''$lineNo'd' $filePath/$file
if [ $? -eq 0 ]; then
{
        echo -e "$FCYellow Deleted the line. Now adding it $FCNoColor" | tee -a $successLogs
}
fi
#clsname=`cat /etc/hosts | grep -i scan | grep -v "#" | cut -d" " -f2 | xargs`
clsname=`cat /etc/hosts | grep -i scan | grep -v "#" | cut -d" " -f2 | cut -d"-" -f1 | head -1 | xargs`
sed -i "${lineNo}i oracle.install.crs.config.clusterName=$clsname" $filePath$file
if [ $? -eq 0 ]; then
{
	echo -e "$FCGreen Successfully added new line $line $FCNoColor" | tee -a $successLogs
}
fi



#oracle.install.crs.config.clusterNodes=work1:work1-vip,work2:work2-vip
lineNo=`grep -n "oracle.install.crs.config.clusterNodes" $filePath$file | grep -v "#" | grep -v "Example" | cut -d":" -f1`
line=`grep -n "oracle.install.crs.config.clusterNodes" $filePath$file | grep -v "#" | grep -v "Example"`
sed -i ''$lineNo'd' $filePath/$file
if [ $? -eq 0 ]; then
{
        echo -e "$FCYellow Deleted the line. Now adding it $FCNoColor" | tee -a $successLogs
}
fi
sed -i "${lineNo}i oracle.install.crs.config.clusterNodes="$hostn":"$hostn"-vip:HUB,"$hnode2":"$hnode2"-vip:HUB" $filePath/$file
if [ $? -eq 0 ]; then
{
	echo -e "$FCGreen Successfully added new line $line $FCNoColor" | tee -a $successLogs
}
fi

#Below will change the value in db.rsp file
#oracle.install.db.CLUSTER_NODES=node1,node2

lineNo=`grep -n "oracle.install.db.CLUSTER_NODES" $filePath$fileDB | grep -v "Example" | cut -d":" -f1`
line=`grep -n "oracle.install.db.CLUSTER_NODES" $filePath$fileDB | grep -v "Example"`
sed -i ''$lineNo'd' $filePath$fileDB
if [ $? -eq 0 ]; then
{
        echo -e "$FCYellow Deleted the line. Now adding it $FCNoColor" | tee -a $successLogs
}
fi
#sed -i "${lineNo}i oracle.install.db.CLUSTER_NODES="$hostn","$hnode2"" $filePath/$fileDB | grep -v "Example" | cut -d":" -f1
sed -i "${lineNo}i oracle.install.db.CLUSTER_NODES="$hostn","$hnode2"" $filePath$fileDB
if [ $? -eq 0 ]; then
{
	echo -e "$FCGreen Successfully added new line $line $FCNoColor" | tee -a $successLogs
}
fi



#oracle.install.crs.config.networkInterfaceList=eth0:172.22.236.0:1,eth2:172.22.235.0:2

lineNo=`grep -n "oracle.install.crs.config.networkInterfaceList" $filePath$file | cut -d":" -f1`
line=`grep -n "oracle.install.crs.config.networkInterfaceList" $filePath$file`
sed -i ''$lineNo'd' $filePath$file
if [ $? -eq 0 ]; then
{
        echo -e "$FCYellow Deleted the line. Now adding it $FCNoColor" | tee -a $successLogs 
}
fi
sed -i "${lineNo}i oracle.install.crs.config.networkInterfaceList="$inteth0":"$valeth0":1,"$inteth2":"$valeth2":5" $filePath/$file
if [ $? -eq 0 ]; then
{
	echo -e "$FCGreen Successfully added new line $line $FCNoColor" | tee -a $successLogs
}
fi



### Change the qwnership of the grid.rsp file
chown oracle:dba $filePath$file
#cp -v $filePath$file /oragrid/inventory/Scripts/
cp -v $filePath$file /oragrid/app/product/19.3.0/grid_1/inventory/Scripts
#/oragrid/app/product/19.0.3/grid_1/inventory/Scripts/grid_install.rsp
#chmod 777 /oragrid/inventory/Scripts/$file
chmod 777 /oragrid/app/product/19.3.0/grid_1/inventory/Scripts/$file

## Change permission of database response file db.rsp
chown oracle:dba $filePath$fileDB
cp -v $filePath$fileDB /oracle/app/product/19.3.0/dbhome_1/
chmod 777 /oracle/app/product/19.3.0/dbhome_1/$fileDB

## Call the grid installation script
sh -x /OracleRAC19C/executeGridInstallable.sh $node1 $node2
