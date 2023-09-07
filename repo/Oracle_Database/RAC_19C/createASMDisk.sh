#!/bin/bash
# Purpose : Script will create primary partition number 1 on newly added disks required for RAC
# Date : 13 Jan 2019
# Author : DJ

exec 1> /tmp/script.log 2>&1

## Details : Scripts expects file to be present which will be passed from the orchestrator

cd /OracleRAC19C
source /OracleRAC19C/baseConfig.sh
dj=1
z=1

touch /tmp/numberofdisksrac
dc=`lsblk | grep ^sd | wc -l`
dcn=`expr $dc - 3`
echo $dcn > /tmp/numberofdisksrac

#/usr/sbin/oracleasm init

## Below function checks if any primary partition is already created on the newly added disks
checkPrimaryPartition()
{
	deviceName=$1
	$CMD -l /dev/$deviceName[0-9] > /dev/null
	return 
}

## Below function checks if a volume group is already created on newly added disks
checkVG()
{
	deviceName=$1
	pvs  | grep $deviceName
	return
}



## check if the file is passed to the server from orchestrator
tmpFile="/tmp/numberofdisksrac"
#mntPointDetails="mountpointdetails"
maxnoOfDisks=`cat $tmpFile`
#maxmntPointDetails=`cat $mntPointDetails | wc -l`
CMD=`which fdisk`
oracleasm="/usr/sbin/oracleasm"
diskCount=`lsblk  | awk '{print $1}' | grep -v ^sr | grep -v ^fd | grep -v [0-9] | grep ^sd | wc -l`
if [ ! -e $tmpFile ]; then
{
        echo -e "$FCYellow The orchestrator did not pass the value for the count of number of disks which needs to be created to the server during deployment $FCNoColor" | tee -a $failureLogs
        exit 1
}
elif [ $diskCount -lt 11 ]; then
{
	echo -e "$FCRed Number of disks are less . A minimum of 12 disks are required for setting up oracle RAC $FCNoColor" | tee -a $failureLogs
	exit 1
}
else
{
        echo -e "$FCYellow Number of disks value : $maxnoOfDisks $FCNoColor" | tee -a $failureLogs
        echo -e "$FCYellow Checking for new disks and creating partitions now $FCNoColor" | tee -a $failureLogs
        noOfDisks=`cat $tmpFile`
        #echo -e "$FCYellow The total number of disks which needs to be created is : $noOfDisks $FCNoColor" | tee -a $successLogs
        ## get the disks present in the system
        command=`which lsblk`
        disktmpFile=/tmp/disktmpFile
        ## getting the name of the disks in the system
        $command  | awk '{print $1}' | grep -v ^sr | grep -v ^fd | grep -v [0-9] | grep ^sd > $disktmpFile
        ### Check if the disk is being used
        max=`cat $disktmpFile | wc -l`
	j=1
	k=1
	for ((i=1; i<=$max; i++))
        do
		## get the device names with below line from the $disktmpFile##
                deviceName=`head -$i $disktmpFile | tail -1`
                ## Check if the device is already in use ##
		checkPrimaryPartition $deviceName
                if [ $? -eq 0 ]; then
                {
                        echo -e "$FCYellow Device $deviceName is already used and cannot be used further $FCNoColor" | tee -a $successLogs
                }
		else
		{
			checkVG $deviceName
                        if [ $? -eq 0 ]; then
                        {
                                echo -e "$FCYellow Device $deviceName is used as a PV and cannot be used further  $FCNoColor" | tee -a $successLogs
                        }
			else
			{
				## Create a Primary partition
                                echo -e "$FCYellow Device $deviceName is not used and is a new disk. Creating a primary partition on same  $FCNoColor" | tee -a $successLogs
                                #echo -e "$FCYellow Creating a physical volume on device $deviceName $FCNoColor" | tee -a $successLogs
				#$pvCmd /dev/$deviceName > /dev/null
				sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/$deviceName
        				o # clear the in memory partition table
        				n # new partition
        				p # primary partition
        				1 # partition number 1
        				# default - start at beginning of disk
        				# default, start immediately after preceding partition
        				# default, extend partition to end of disk
        				p # print the in-memory partition table
        				w # write the partition table
        				q # and we're done
EOF

				if [ $? -eq 0 ]; then
				{
                                	echo -e "$FCGreen successfully created a primary partition on device $deviceName"1" $FCNoColor" | tee -a $successLogs
                                	echo -e "$FCGreen creating a filesystem on $deviceName"1" $FCNoColor" | tee -a $successLogs
					## formatting the file system
					mkfs.xfs -f /dev/$deviceName"1"
					if [ $? -eq 0 ]; then
					{
						echo -e "$FCGreen successfully created filesystem on device $deviceName"1" $FCNoColor" | tee -a $successLogs
						size=`lsblk | grep $deviceName | awk '{ print $4 }' | head -1 | xargs`
						if [ $size = "5G" ]; then
						{
							$oracleasm listdisks | grep "CRSDISK0"$j
							if [ $? -eq 0 ]; then
							{
								echo "CRSDISK0'$j' is already created"
								j=`expr $j + 1`
							}
							else
							{
								### creating ASM disk group
								$oracleasm createdisk CRSDISK0"$j" /dev/$deviceName"1"
								if [ $? -eq 0 ]; then
								{
									echo -e "$FCGreen Successfully created CRSDISK0"$j" on device $deviceName"1" $FCNoColor" | tee -a $successLogs
									j=`expr $j + 1`
								}
								else
								{
									echo -e "$FCRed Error creating CRSDISK0"$j" on device $deviceName"1" $FCNoColor" | tee -a $failureLogs
									j=`expr $j + 1`
								}
								fi
							}
							fi
							#done
						}
						elif [ $size = "100G" ]; then
						{
							$oracleasm createdisk MGMT /dev/$deviceName"1"
						}
						elif [ $size = "30G" ]; then
						{
							#for (( i=1; i<=3; i++ ))
                                                        #do
                                                        $oracleasm listdisks | grep "REDODISK0"$k
                                                        if [ $? -eq 0 ]; then
                                                        {
                         	                               echo "REDODISK0'$k' is already created"
								k=`expr $k+ 1`
                                                        }
                                                        else
                                                       	{
                                                        	### creating ASM disk group
                                                        	$oracleasm createdisk REDODISK0"$k" /dev/$deviceName"1"
                                                                if [ $? -eq 0 ]; then
                                                                {
                                                                	echo -e "$FCGreen Successfully created REDODISK0"$k" on device $deviceName"1" $FCNoColor" | tee -a $successLogs
									k=`expr $k + 1`
                                                                }
                                                                else
                                                                {
                                                                	echo -e "$FCRed Error creating REDODISK0"$k" on device $deviceName"1" $FCNoColor" | tee -a $failureLogs
									k=`expr $k + 1`
                                                                }
                                                                fi
                                                         }
                                                         fi
                                                        #done
						}
						elif [ $size = "500G" ]; then
						{
							if [ $dj = "1" ]; then
							{
								dj=0
								dnm="ORAARCH"
								$oracleasm createdisk $dnm /dev/$deviceName"1"
                                                        	if [ $? -eq 0 ]; then
                                                       		{
                                                               		echo -e "$FCGreen Successfully created $dnm on device $deviceName"1" $FCNoColor" | tee -a $successLogs
                                                        	}
                                                       		else
                                                        	{
                                                                	echo -e "$FCRed Error creating $dnm on device $deviceName"1" $FCNoColor" | tee -a $failureLogs
                                                       	 	}
                                                        	fi

							}
							else
							{
								dnm="DATADISK0"$z
								z=`expr $z + 1`
								$oracleasm createdisk $dnm /dev/$deviceName"1"
								if [ $? -eq 0 ]; then
        	                                                {
                	                                                echo -e "$FCGreen Successfully created $dnm on device $deviceName"1" $FCNoColor" | tee -a $successLogs
                        	                               	}
                                	                       	else
                                        	                {
                                                	        	echo -e "$FCRed Error creating $dnm on device $deviceName"1" $FCNoColor" | tee -a $failureLogs
                                                       		}
								fi
							}
							fi
						}
						fi	
					}
					else
					{
						echo -e "$FCRed Error creating filesystem on device $deviceName"1" $FCNoColor" | tee -a $failureLogs
					}
					fi
				}
				else
				{
                                	echo -e "$FCRed Error creating a partition named on $deviceName"1" $FCNoColor" | tee -a $failureLogs
				}
				fi
			}
			fi
		}
		fi
	done
}
fi
node2=$2
node1=$1
#sshpass -p "oracle" ssh -o StrictHostKeyChecking=no oracle@$node2 'echo oracle | sudo -S /usr/sbin/oracleasm init'
#sshpass -p "oracle" ssh -o StrictHostKeyChecking=no oracle@$node2 'echo passw0rd! | sudo -S /usr/sbin/oracleasm scandisks'

sshpass -p 'Passwd!1' ssh -o StrictHostKeyChecking=no sysadm@$node2 'sudo /usr/sbin/oracleasm init'
sshpass -p 'Passwd!1' ssh -o StrictHostKeyChecking=no sysadm@$node2 'sudo /usr/sbin/oracleasm scandisks'
sshpass -p 'Passwd!1' ssh -o StrictHostKeyChecking=no sysadm@$node2 'sudo chown oracle:dba /dev/oracleasm/disks/*'

sshpass -p 'oracle' ssh -o StrictHostKeyChecking=no oracle@$node2 'rm -frv /oracle/*'
sshpass -p 'oracle' ssh -o StrictHostKeyChecking=no oracle@$node2 'rm -frv /oragrid/*'


chown oracle:dba /dev/oracleasm/disks/*

sh /OracleRAC19C/createRSFG.sh $node1 $node2
#sh /OracleRAC19C/createUserEquiv.sh $node1 $node2

