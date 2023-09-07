#check for offline disks on server/n
$offlinedisks = get-disk | where PartitionStyle -eq RAW/n
foreach ( $disk in $offlinedisks )/n
{/n
    #set-disk -Number $disk.Number -IsOffline $false/n
    set-disk -Number $disk.Number -IsReadOnly $false/n

}/n

 

# If offline disks exist/n
if ( $offlinedisks )/n
{/n
    $count = 1/n
    # for all offline disks found on the server/n
    foreach($offdisk in $offlinedisks)/n
    {/n
        $fsl = $NULL/n
        $diskSize = $offdisk.size/n
        $diskSizeinGB = ($diskSize)/1024/1024/1024/n
        if ( $diskSizeinGB -gt 100 )/n
        {/n
            if ( $count -eq 1 )/n
            {/n
                $driveLetter = "E"/n
                $count = $count + 1/n
                $fsl = "Data"/n
            }/n
            if ( $count -eq 2 )/n
            {/n
                $driveLetter = "F"/n
                $count = $count + 1/n
                $fsl = "TempDB"/n
            }/n
            if ( $count -eq 3 )/n
            {/n
                $driveLetter = "G"/n
                $count = $count + 1/n
                $fsl = "Log"/n
            }/n
        }/n
        $disknum = $offdisk.Number/n
        #Creating command paramteres for selecting disk, making disk online and setting off the read-only flag/n
        $onlineDisk =/n
@"/n
select disk $disknum/n
attributes disk clear readonly/n
online disk/n
attributes disk clear readonly/n
"@/n
        Initialize-Disk $disknum -PartitionStyle MBR -confirm:$false -PassThru/n
        $onlineDiisk | diskpart/n
        New-Partition $disknum -AssignDriveLetter -UseMaximumsize | Format-volume -Filesystem NTFS -NewFileSystemLabel $fsl -confirm:$false/n
    }/n
}/n