#!/bin/bash # Version 1.12
exec 1> /tmp/command.log 2>&1
set -x
devicenumber=$1
devnumbers="`echo ${devicenumber} | tr , ' '`"
vip=$2
vip_name="vip"
backup_vip=$3
backup_vip_name="backup_vip"
hapassword="HAPassword2019"
ClusterName="HACluster"
VMnames=$4
nodes="`echo $VMnames | tr , ' '`"
val1=""
for node in $nodes
do
        val=`echo -e "$node:$node;"`
        val1=$val1$val
        val2=`echo $val1 | sed 's/;*$//g'`
done
val3=$val2
vcUsername="DUCORP\hcm.vcenter"
vcPassword="P@ssw0rd#2020"
vcHost=$5
host=$6
grp="vggrp"
DB=$7
fnode=`ip a | grep -i "ens192" | grep "inet" | cut -d" " -f6 | cut -d"/" -f1 | xargs`
fnodelastoctect=`ip a | grep -i "ens192" | grep "inet" | cut -d" " -f6 | cut -d"/" -f1 | cut -d"." -f4 | xargs`
fnodefirstthreeoctect=`ip a | grep -i "ens192" | grep "inet" | cut -d" " -f6 | cut -d"/" -f1 | cut -d"." -f1,2,3 | xargs`
snodelastoctect=`expr $fnodelastoctect + 1`
snode=$fnodefirstthreeoctect"."$snodelastoctect
Cluster=$8
log=/tmp/cluster.log
echo "Logging to $log"
> $log
network_address() {
    IFS=/ read base masksize <<< $1
    mask=$(( 0xFFFFFFFF << (32 - $masksize) ))
    IFS=. read a b c d <<< $base
    ip=$(( ($a << 24) + ($b << 16) + ($c << 8) + $d ))
    i=$(( $ip & $mask ))
    echo $i
    # echo $(( ($i & 0xFF000000) >> 24 )).$(( ($i & 0xFF0000) >> 16 )).$(( ($i & 0xFF00) >> 8 )).$(( $i & 0x00FF ))
}
cat /etc/redhat-release | grep "Red Hat Enterprise Linux release 8"
#if [ $? -eq 0 ]; then
#{
#       rhelOSV=8
#       RHELCMDauth="host"
#        RHELCLUSET="sudo pcs cluster setup --force --start ${ClusterName} $nodes"
#}
#else
#{
#       rhelOSV=7
#        RHELCMDauth="cluster"
#       RHELCLUSET="sudo pcs cluster setup --force --start --name ${ClusterName} $nodes"
#}
#fi
#for cmd in "sudo pcs $RHELCMDauth auth $nodes -u hacluster -p '${hapassword}'" \
#           "$RHELCLUSET" \
for cmd in "sudo pcs host auth $nodes -u hacluster -p '${hapassword}'" \
        "sudo pcs cluster setup --force --start ${ClusterName} $nodes" \
           "sudo pcs cluster enable --all"
do
    printf "  ";echo $cmd | sed -e "s/-p\s*'[^']*'/-p '***'/" -e "s/passwd='[^']*'/passwd='***'/"
    echo "$cmd" >> $log
    if ! eval "$cmd" >> $log 2>&1
    then
        echo "Cluster creation failed:"; cat $log
        false; exit 1
    fi
done
sudo pcs property set stonith-enabled=false
resources="echo Creating cluster resources"
for i in "$vip:$vip_name" "$backup_vip:$backup_vip_name"
do
    IFS=: read vipaddr vipname <<< $i
    echo Preparing resource for VIP $vipaddr
    for a in `sudo ip a | awk '/inet\s/{print $2}'`
    do
        IFS=/ read ip2 cidr <<< $a
        if [[ `network_address $vipaddr/$cidr` -eq `network_address $ip2/$cidr` ]]; then
            # echo "$vipaddr/$cidr (`network_address $vipaddr/$cidr`) -eq $ip2/$cidr (`network_address $ip2/$cidr`)"
            break
        fi
        cidr=""
    done
    if [[ -z "$cidr" ]]
    then
        echo "Could not find cidr for $vipaddr"
    else
        resources="$resources;echo '  Creating VIP resource $vipname for $vipaddr/$cidr';printf '  ';sudo pcs resource create $vipname IPaddr2  ip=$vipaddr cidr_netmask=$cidr op monitor timeout=120s start interval=0s timeout=120s stop interval=0s timeout=120s --group $grp;sleep 5"
    fi
done
echo "Checking connection to vCenter $vcHost"
result="`sudo fence_vmware_soap -o status -a "$vcHost" -l "$vcUsername" -p "$vcPassword" -n \`hostname\` --ssl --ssl-insecure 2>&1`"
stonith_exitcode=$?
if [[ $stonith_exitcode -eq 0 ]]; then
    echo "Preparing resource for Stonith"
    #resources="$resources;echo '  Creating stonith using fence_vmware_soap';sudo pcs stonith create vmfence fence_vmware_soap pcmk_host_list='$VMnames' ipaddr=$vcHost ssl_insecure=1 login='$vcUsername' passwd='$vcPassword' ; sleep 30"
    resources="$resources;echo '  Creating stonith using fence_vmware_soap';sudo pcs stonith create vmfence fence_vmware_soap pcmk_host_list='"$val3"' ipaddr=$vcHost ssl_insecure=1 login='$vcUsername' passwd='$vcPassword' ; sleep 30"
    sleep 30; sudo pcs stonith create kdump fence_kdump pcmk_reboot_action="off" pcmk_host_list='$VMnames'
else
    stonith_sh="$PWD/stonith.sh"
    echo "Connection to vCenter $vcHost failed: $result"
    echo "Fix the connection, then execute $stonith_sh"
    cat << EOF > $stonith_sh
#!/bin/bash
printf 'Enter password for user DUCORP\hcm.vcenter: '
read -s vcPassword
printf "Checking connection to vCenter $vcHost ... "
result="\`sudo fence_vmware_soap -o status -a "$vcHost" -l "$vcUsername" -p "\$vcPassword" -n `hostname` --ssl --ssl-insecure 2>&1\`"
if [[ \$? -eq 0 ]]; then
    echo "OK, creating vmfence resource"
    sudo pcs stonith create vmfence fence_vmware_soap pcmk_host_list='$VMnames' ipaddr=$vcHost ssl_insecure=1 login='$vcUsername' passwd="\$vcPassword"
    sudo pcs stonith create kdump fence_kdump pcmk_reboot_action="off" pcmk_host_list='$VMnames'
else
    echo "failed with error:"
    echo "\$result"
    echo "Network connection is blocked or wrong password was entered."
    echo "Fix the connection issue, then re-run this script"
fi
EOF
    chmod u+rx,og= $stonith_sh
fi
lvmconf=/etc/lvm/lvm.conf
comment="# TEMPORARILY_DISABLED_BY_OO"
#sudo sed -i -e 's/^\(\s*\)volume_list/\1'"$comment volume_list/" $lvmconf
systemidln=`grep -n "system_id_source" /etc/lvm/lvm.conf | grep -v "#" | cut -d":" -f1`
systemidln1=`expr $systemidln + 1`
sed -i -e 's/^\(\s*\)system_id_source/\1'"# system_id_source/" /etc/lvm/lvm.conf
##sudo sed -i ''$ln1'i system_id_source = "uname"' /etc/lvm/lvm.conf
sudo sed -i  ''$systemidln1'i system_id_source = "uname"' /etc/lvm/lvm.conf
#sudo sed -i '1220i system_id_source = "uname"' /etc/lvm/lvm.conf
sudo sshpass -p 'Passwd!1' scp -o 'stricthostkeychecking no' -rv /etc/lvm/lvm.conf sysadm@$snode:/tmp
sleep 10
sshpass -p 'Passwd!1' ssh -o 'stricthostkeychecking no' sysadm@$snode 'sudo cp -v /tmp/lvm.conf /etc/lvm'

a=`printf '%d' "'a"`  # Convert 'a' to number
fdisk="`sudo fdisk -l`"
vgdisplay="`sudo vgdisplay -v`"
i=1
for n in $devnumbers
do
    if [[ $n -gt 26 ]]; then
        echo "  More than 27 disks was passed, for which sdaa sdab etc needs to be created, exiting"
        false; exit 1
    fi
    ((x=a+n-1))
    dev="/dev/sd`printf \\\\\`printf '%03o' $x\``"
    if echo "$fdisk" | grep -q $dev
    then
        echo  "  $dev exists"
    else
        echo "  $dev does not exist, exiting"
        false; exit 1
    fi
    if [[ $DB == "True" ]]; then
        if [[ $n -eq 3 ]]; then
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
     else
        if [[ $n -gt 1 ]]; then
              data=appdata$i
              i=`expr $i + 1`
        fi
    fi
    if echo "$vgdisplay" | grep -q $dev || ls $dev?* > /dev/null 2>&1
    then
        echo "  $dev already used, exiting"
        false
        exit 1
    else
        vgname=vg-$data
        lvname=lv-$data
        fsname=/dev/$vgname/$lvname
        echo "  Volume Group $vgname on $dev"
        sudo pvcreate $dev > /dev/null
        sudo vgcreate $vgname $dev > /dev/null
        # check system_id
        sudo vgs -o+systemid | grep $vgname
        yes | sudo lvcreate -n $lvname -l+100%FREE $vgname > /dev/null
        sudo mkfs.xfs $fsname > /dev/null
        #resources="$resources;echo '  Creating LVM resource $data';printf '  ';sudo pcs resource create $data  volgrpname=$vgname exclusive=true op monitor timeout=120s start interval=0s timeout=120s stop interval=0s timeout=120s --group $grp;sleep 5"
        resources="$resources;echo '  Creating LVM resource $data';printf '  ';sudo pcs resource create $data LVM-activate vgname=$vgname vg_access_mode=system_id op monitor timeout=120s start interval=0s timeout=120s stop interval=0s timeout=120s --group $grp;sleep 5"
        #resources="$resources;echo '  Creating filesystem resource' \"$data\"_fs;printf '  ';sudo pcs resource create \"$data\"_fs Filesystem device=$fsname directory=/$data fstype=xfs --group $grp; sleep 5"
        resources="$resources;echo '  Creating filesystem resource' \"$data\"_fs;printf '  ';sudo pcs resource create \"$data\"_fs ocf:heartbeat:Filesystem device=$fsname directory=/$data fstype=xfs op monitor timeout=120s start interval=0s timeout=120s stop interval=0s timeout=120s --group $grp; sleep 5"
    fi
done
tag=0
if [ ${Cluster} == "true" ] && [ ${DB} == "True" ]; then
{
        tag=1
        sudo umount /oracle
        sudo sed -i -e 's/^\/dev\/vg-oraclebinaries\/lv-oraclebinaries/#/g' /etc/fstab
        lvchange -ay /dev/vg-oraclebinaries/lv-oraclebinaries
        sshpass -p 'Passwd!1' ssh -o 'stricthostkeychecking no' sysadm@$snode   'sudo umount /oracle
                                                                                comment="# TEMPORARILY_DISABLED_BY_OO"
                                                                                sudo sed -i -e 's/^\\/dev\\/vg-oraclebinaries\\/lv-oraclebinaries/\#/g' /etc/fstab
                                                                                sudo lvchange -ay /dev/vg-oraclebinaries/lv-oraclebinaries'
        sudo pcs resource create oracle LVM volgrpname=vg-oraclebinaries exclusive=true op monitor timeout=120s start interval=0s stop interval=0s timeout=120s --group $grp
        sleep 10
        sudo pcs resource create oracle_fs filesystem device=/dev/vg-oraclebinaries/lv-oraclebinaries fstype=xfs  directory=/oracle op monitor timeout=120s start interval=0s stop interval=0s timeout=120s --group $grp
        sudo pcs cluster stop # Enable volume_list in lvm.conf
        sudo sed -i -e "s/$comment\s*//" $lvmconf
        sudo sed -i -e 's/^\(\s*\)volume_list/\1'"$comment volume_list/" $lvmconf
        ln=`grep -n "activation {" /etc/lvm/lvm.conf | cut -d":" -f1 | grep -v "#"`
        ln1=`expr $ln + 1`
        sed -i  ''$ln1'i volume_list = [ "rhel" ]' /etc/lvm/lvm.conf
        sudo sshpass -p 'Passwd!1' scp -rv /etc/lvm/lvm.conf sysadm@$snode:/tmp
        sshpass -p 'Passwd!1' ssh -o 'stricthostkeychecking no' sysadm@$snode 'sudo cp -v /tmp/lvm.conf /etc/lvm'
}
fi
sudo pcs cluster stop # Enable volume_list in lvm.conf
#if [ $tag == 0 ]; then
#{
#        sudo sed -i -e "s/$comment\s*//" $lvmconf
#}
#fi
#if [ $rhelOSV -eq 8 ]; then
#{
#       sudo lvmconf --enable-halvm --services --startstopservices
#}
#else
#{
#       sudo lvmconf --enable-halvm --services --startstopservices
#}
#fi
sudo dracut -H -f /boot/initramfs-$(uname -r).img $(uname -r)
sudo bash -c 'echo "I WAS REBOOTED NOW" > /opt/filetobedeleted'
sudo systemctl stop pcsd;sleep 5;sudo systemctl start pcsd
sleep 5;sudo pcs cluster start;sleep 5
echo "$resources" | sed -e "s/-p\s*'[^']*'/-p '***'/" -e "s/passwd='[^']*'/passwd='***'/"
eval "$resources"
sleep 30
status="`sudo pcs status 2>&1`"
exitcode=$?
if [[ $exitcode -eq 0 ]]; then
    if echo "$status" | grep -q "Failed Actions:"
    then
        sudo pcs cluster stop &
        pid=$!
        sleep 30
        if sudo pcs status > /dev/null 2>&1
        then
            echo "Cluster still running, killing pacemaker,corosync"
            sudo kill -2 $pid
            sudo kill -2 `ps -ef | grep -v -e awk -e grep|awk '/pacemaker|corosync/{print $2}'`
            sudo pcs cluster stop
        fi
        sudo pcs cluster start; sleep 30
        sudo pcs resource move $vipname `hostname`; sleep 30
        status="`sudo pcs status 2>&1`"
        exitcode=$?
        if [[ $exitcode -eq 0 ]]; then
            echo "$status" | grep -q "Failed Actions:" && exitcode=1
        fi
    fi
fi
if [[ $exitcode -eq 0 ]] && [[ $stonith_exitcode -eq 0 ]]; then
    echo Cluster created successfully
     true
fi
for node in `echo $VMnames | tr , ' '`
    do
        sudo pcs stonith level add 1 $node kdump; sudo pcs stonith level add 2 $node vmfence

    done
corosyncconf="/etc/corosync/corosync.conf"
lineno=`grep -n "transport" $corosyncconf | cut -d":" -f1 | xargs`
lineno=`expr $lineno + 1`
#sudo /bin/sed -i ''$lineno'i token: 30000' $corosyncconf
sudo /bin/sed -i ''$lineno'i token: 120000' $corosyncconf
sudo pcs cluster sync
sudo pcs cluster reload corosync
sudo pcs resource defaults resource-stickiness=10000
sudo pcs property set stonith-enabled=true
sudo pcs stonith update vmfence meta failure-timeout=120
rm -- "$0"
