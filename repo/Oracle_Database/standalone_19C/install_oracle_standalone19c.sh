#!/bin/bash
# Purpose : To install oracle 19c database software
# Date : 28 Jan 2021
# Contact : dhananjay.rughani@du.ae
exec 1> /tmp/Oraclecommand.log 2>&1
set -x
## Mount the disks
export CV_ASSUME_DISTID=OEL7.6
sudo echo  "/dev/vg-oraclebinaries/lv-oraclebinaries   /oracle  xfs  defaults  0  0" >> / etc/fstab
mount  -a
## Mount the disks if these are provided by end user during provisioning
db="true"
count=1
#dval=`fdisk -l | grep "sd" | tail -1 | awk '{ print $2 }' | sed 's/:*$//g' | cut -d"/" -f3`
dval=`fdisk -l | grep "sd" |  grep -v "sd[a,b]" | cut -d" " -f2 | cut -d"/" -f3 | sed 's/:*$//g' | sort | tail -1 | xargs`
for X in {a..z} 
do
	echo $count:"sd"$X
	count=`expr $count + 1`
done | grep $dval > /tmp/devval
number=`cat /tmp/devval | cut -d":" -f1 | xargs`
list=`for ((i=3;i<=$number;i++)) ; do echo $i | tr '\n' ',' ; done`
devicenumber=`echo $list | sed 's/,$//g'`
#devicenumber=`echo "'$listone'"`
#devicenumber="3,4,5,6,7,8"
devnumbers="`echo ${devicenumber} | tr , ' '`"
echo "Creating volume groups"
#lvmconf=/etc/lvm/lvm.conf
#comment="# TEMPORARILY_DISABLED_BY_OO"
#sudo sed -i -e 's/^\(\s*\)volume_list/\1'"$comment volume_list/" $lvmconf
a=`printf '%d' "'a"`  # Convert 'a' to number
fdisk="`sudo fdisk -l`"
vgdisplay="`sudo vgdisplay -v`"
i=1
for n in $devnumbers
do
    if [[ $n -gt 26 ]]
    then
        echo "  More than 27 disks was passed, for which sdaa sdab etc needs to be created, exiting"
        false
        exit 1
    fi
    # Convert n (1...27) to character (a...z)
    ((x=a+n-1))
    dev="/dev/sd`printf \\\\\`printf '%03o' $x\``"
    # Check if the disk exists
    if echo "$fdisk" | grep -q $dev
    then
        echo  "  $dev exists"
    else
        echo "  $dev does not exist, exiting"
        false
        exit 1
    fi
    echo "This is a DB request"
    if [[ $n -eq 2 ]]; then
        data=oracle
    elif [[ $n -eq 3 ]]; then
        data=oratemp
    elif [[ $n -eq 4 ]]; then
        j=1
        data=oraredo$j
    elif [[ $n -eq 5 ]]; then
        j=2
        data=oraredo$j
    elif [[ $n -eq 6 ]]; then
        j=3
        data=oraredo$j
    elif [[ $n -eq 7 ]]; then
        data=oraarch
    elif [[ $n -gt 7 ]]; then
        data=oradata$i
        i=`expr $i + 1`
    fi

    if echo "$vgdisplay" | grep -q $dev || ls $dev?* > /dev/null 2>&1
    then
        echo "  $dev already used, exiting"
        false
        #exit 1
    else
        vgname=vg-$data
        lvname=lv-$data
        fsname=/dev/$vgname/$lvname
        echo "  Volume Group $vgname on $dev"
        sudo pvcreate $dev > /dev/null
        sudo vgcreate $vgname $dev > /dev/null
        echo "  Creating Logical Volume $lvname"
        yes | sudo lvcreate -n $lvname -l+100%FREE $vgname > /dev/null
        echo
        echo "  Creating filesystem $fsname"
        sudo mkfs.xfs $fsname > /dev/null
        mkdir /$data
        mount /dev/$vgname/$lvname /$data
        chown -R oracle:dba /$data
    fi
done
## Install software
## check if the directory for db home already exists, else create it
dbhome='/oracle/app/product/19.3.0/db_1'
resfile='db.rsp'
if [ ! -e $dbhome ]; then
{
        mkdir -p $dbhome
}
fi
## xtract the instaler and software file in db home
SWPACKAGE='/opt/LINUX.X64_193000_db_home.tar.gz'
if [ ! -e $SWPACKAGE ]; then
{
        echo "Installer does not exists"
        exit 1
}
else
{
        if [ -e $dbhome/$resfile ]; then
        {
                echo "Extract of the software is already present"
                ## copy the response file
                /bin/chmod 777 $dbhome/$resfile
                /bin/cp -v $dbhome/$resfile $dbhome/inventory/Scripts/
                echo "Proceeding with the installation"
        }
        else
        {
                /bin/tar -zxvf $SWPACKAGE -C $dbhome
                if [ -e $dbhome/$resfile ]; then
                {
                        echo "Extract of the software was successfull"
                        ## copy the response file
                        /bin/chmod 777 $dbhome/$resfile
                        /bin/cp -v $dbhome/$resfile $dbhome/inventory/Scripts/
                        echo "Proceeding with the installation"
                }
                else
                {
                        echo "Extract of the software was not successfull. EXIT 1"
                        exit 1
                }
                fi
        }
        fi
}
fi
## Add bash_profile
#chown -R sysadm /oracle
touch /oracle/.bash_profile
echo "ORACLE_BASE=/oracle/app" >> /oracle/.bash_profile
echo "export ORACLE_BASE" >> /oracle/.bash_profile
echo "ORACLE_HOME=/oracle/app/product/19.3.0/db_1/" >> /oracle/.bash_profile
echo "export ORACLE_HOME" >> /oracle/.bash_profile
echo "ORACLE_TERM=xterm" >> /oracle/.bash_profile
echo "export ORACLE_TERM" >> /oracle/.bash_profile
echo "export PATH=$PATH:/oracle/app/product/19.3.0/db_1/bin:/oracle/app/product/19.3.0/db_1/OPatch" >> /oracle/.bash_profile
echo "export LD_LIBRARY_PATH=/oracle/app/product/19.3.0/db_1/lib:/lib" >> /oracle/.bash_profile
echo "export PS1='[\u@\h:$ ] '" >> /oracle/.bash_profile
echo "umask 022" >> /oracle/.bash_profile
echo "ulimit -f unlimited" >> /oracle/.bash_profile
echo "export ORACLE_SID=dummy" >> /oracle/.bash_profile

sudo echo "oracle   soft      memlock          unlimited" >> /etc/security/limits.conf 
sudo echo "oracle   hard     memlock          unlimited"  >> /etc/security/limits.conf

#hn=`hostname`
#hostEntry=`printf '%s\n' "${hn//[[:digit:]]/}"`
#echo "${VIP} $hostEntry ${hostEntry}.corp.su.ae" >> /etc/hosts

#myIP=`ip a | grep -i ens192 | grep inet | cut -d" " -f6 | cut -d"/" -f1 | xargs`
#myipthreeoctect=`echo $myIP | cut -d":" -f1,2,3`
#myiplastoctect=`echo $myip | cut -d"." -f4`
#secnodeiplastoctect=`echo $myiplastoctect + 1`
#secondnodeip=$myipthreeoctect"."secnodeiplastoctect

#sshpass -P'Passwd!1' ssh -o 'stricthostkeychecking no' sysadm@$secondnodeip 'sudo echo "'${VIP}' '$hostEntry' '${hostEntry}'.corp.su.ae" >> /etc/hosts'

chown -R oracle:dba /oracle

## login with oracle user to run the installer
su  oracle -c 'echo 'Passwd!1' | sh -x '$dbhome'/runInstaller -ignorePrereq -waitforcompletion -silent -responseFile '$dbhome'/inventory/Scripts/db.rsp'
if  [[ $? -eq 0 ]]; then
{
	echo "Oracle 19C standalone setup successfully"
	echo "0" > /tmp/clusetstatus
	chmod 777 /tmp/clusetstatus
	true
}
else
{
	false
}
fi
## Remove the installers from server
rm -frv /opt/LINUX.X64_193000_db_home.tar.gz