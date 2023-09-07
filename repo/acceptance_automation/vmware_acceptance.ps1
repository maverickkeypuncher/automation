
function sendmail($global:val)
{
    $global:html3 = $global:htmlvar + $global:val
	echo $html3 > acceptance_report.html
	Send-MailMessage -SmtpServer "smtpint.corp.du.ae" -To "dhananjay.rughani@du.ae"  -From "acceptancetest@du.ae" -Subject "Acceptance Entry Criteria Validation" -Body "Dear Team,
           Please find the VM checklist acceptance validation report

	$global:html3" -Attachments "vmware_acceptance_report.html"  -BodyAsHtml
	
}

$global:val = $NULL
function storeValues($global:value)
{
	$global:val = $global:val + $global:value
}

## Append data to html for reporting

function htmlAppend($disk, $vmchecklist)
{
	if ( $firstfunction -eq "True" )
	{
		$firstfunction = "False"
		$global:html1 = "<tr><td>" + $vmchecklist + "</td><td>" + $disk
		storeValues $global:html1
	}
	else
	{
		$global:html2 = "<tr><td>" + $vmchecklist + "</td><td>" + $disk
		storeValues $global:html2
	}
	$disk = $NULL
	$vmchecklist = $NULL	
}

## Below function will check if the virtual machine time sync is disabled with ESXi hosts on whcih it resides
function checkVMTimeSync($vmname)
{
	$vmchecklist = "Time Sync should be disabled from ESXI Level"
	$timesyncstatus = Get-VM -name $vmname  | Select Name,@{N='TimeSync';E={$_.ExtensionData.Config.Tools.syncTimeWithHost}} | Select-Object -ExpandProperty TimeSync
	$createTableTimeSync = "<html><head><body><table class='internal_table' border=2><tr><th align=center>VM</th><th align=center>Time Sync Status</th><th align=center>Comments</th></tr></td></tr>"
	if ( $timesyncstatus = "False" )
	{ 
		$status = "Time Sync Disabled"
		$appendoptimesync = $createTableTimeSync + "<tr><td align=center>" + $vmname + "</td><td bgcolor=66FF99 align=center>" + $status + "</td><td>compliant - Time Sync is Disabled</td></tr>"  
    	}
    	else
    	{
       		$status = "Time Sync Enabled"
		$appendoptimesync = $createTableTimeSync + "<tr><td align=center>" + $vmname + "</td><td bgcolor=#FF7F7F align=center>" + $status + "</td><td>Not compliant - Time Sync is Enabled</td></tr>"
    	}
	$closeHtmlTimeSync = $appendoptimesync + "</table></body></html>"
	htmlAppend $closeHtmlTimeSync $vmchecklist
			
}
## Function for time sync ends here

## Below is the function to check the guest operating system
function checkGuestOS($vmname)
{
	$vmchecklist = "Guest OS version in the VM should match the OS setting in the Vcenter"
	$createTableossync = "<html><head><body><table border=2><tr><th align=center>VM</th><th align=center>Guest OS Match Status</th><th align=center>Comments</th></tr></td></tr>"
	$configuredosstatus = Get-VM -name $vmname | Sort | Get-View -Property @("Name", "Config.GuestFullName", "Guest.GuestFullName") | Select -Property Name, @{N="Configured OS";E=
{$_.Config.GuestFullName}},  @{N="Running OS";E={$_.Guest.GuestFullName}}  | Select-Object -ExpandProperty "Configured OS"
	$runningosstatus = Get-VM -name $vmname | Sort | Get-View -Property @("Name", "Config.GuestFullName", "Guest.GuestFullName") | Select -Property Name, @{N="Configured OS";E={$_.Config.GuestFullName}},  @{N="Running OS";E={$_.Guest.GuestFullName}}  | Select-Object -ExpandProperty "Running OS"
	if ( $configuredosstatus -eq $runningosstatus )
	{
		$status = "Compliant"
		$appendopossync = $createTableosSync + "<tr><td align=center>" + $vmname + "</td><td bgcolor=66FF99 align=center>" + $status + "</td><td>Guest OS in the vCenter matches the Guest operating system. Running OS : $runningosstatus, Configured VC OS : $configuredosstatus</td></tr>" 
         
	}
	else
    {
      	$status = "Not Compliant"
		$appendopossync = $createTableosSync + "<tr><td align=center>" + $vmname + "</td><td bgcolor=#FF7F7F align=center>" + $status + "</td><td>Guest OS in the vCenter matches the Guest operating system. Running OS : $runningosstatus, Configured VC OS : $configuredosstatus</td></tr>" 
	}
    $global:gos = $runningosstatus
	$closeHtmlOsSync = $appendopossync + "</table></body></html>"
	htmlAppend $closeHtmlOsSync $vmchecklist
}
## function for checking the guest OS ends here

## Below function check the VM hardware version
function checkVMHWVersion($vmname)
{
	$vmchecklist = "VM Hardware Version 11 or greater in case of ESXi 6.5"
	$createTableVMHWV = "<html><head><body><table border=2><tr><th align=center>VM</th><th align=center>VM HW Version</th><th align=center>Comments</th></tr></td></tr>"
	#$getesxiversion = Get-vm -name $vmname | Get-VMHost | Select @{Label = "Host"; Expression = {$_.Name}} , @{Label = "ESX Version"; Expression = {$_.version}}, @{Label = "ESX Build" ; Expression = {$_.build}} | Select-Object -ExpandProperty "ESX Version"
	#if ( $getesxiversion -eq "6.5.0" )
	#{
	#	$VMHWV = 13
	#}
	#else
	#{
	#	$VMHWV = 11
	#}
	$getvmhwv = get-vm -name $vmname
	$hwversion = $getvmhwv.HardwareVersion
    $vmhwvdigits = $hwversion.Split('-')[-1]
	if ( $vmhwvdigits -ge 11 )
	{
		$status = "Complaint"
		$appendophwv = $createTableVMHWV + "<tr><td align=center>" + $vmname + "</td><td bgcolor=66FF99 align=center>" + $status + "</td><td>VM Hardware Version : $vmhwvdigits. ESXi 6.5 supports 11 or greater</td></tr>" 
	}
	else
    	{
       		$status = "Not Compliant"
		$appendophwv = $createTableVMHWV + "<tr><td align=center>" + $vmname + "</td><td bgcolor=#FF7F7F align=center>" + $status + "</td><td>VM Hardware Version : $vmhwvdigits</td></tr>"
	}
	$closeHtmlvmhwv = $appendophwv + "</table></body></html>"
	htmlAppend $closeHtmlvmhwv $vmchecklist
}
## Function to check the VM HW version ends here

## Below function checks the VM tools status

Function Get-VMToolsStatus 
	{
 		[CmdletBinding()]
    		param(
        		[Parameter(
            			Position=0,
            			ParameterSetName="NonPipeline"
        			)
			]
        	[Alias("VM", "ComputerName", "VMName")]
        	[string[]]  $Name,
 		[Parameter(
            		Position=1,
            		ValueFromPipeline=$true,
            		ValueFromPipelineByPropertyName=$true,
            		ParameterSetName="Pipeline"
            		)
		]
        	[PSObject[]]  $InputObject
    	)
 	BEGIN 
	{
        	if (-not $Global:DefaultVIServer) 
		{
            		Write-Error "Unable to continue.  Please connect to a vCenter Server." -ErrorAction Stop
        	}
 		#Verifying the object is a VM
        	if ($PSBoundParameters.ContainsKey("Name")) 
		{
            		$InputObject = Get-VM $Name
        	}
 		$i = 1
        	$Count = $InputObject.Count
    	}
 	PROCESS 
	{
        	if (($null -eq $InputObject.VMHost) -and ($null -eq $InputObject.MemoryGB)) 
		{
            		Write-Error "Invalid data type. A virtual machine object was not found" -ErrorAction Stop
        	}
 		foreach ($Object in $InputObject) 
		{
            		try 
			{
                		[PSCustomObject]@{
                    				Name = $Object.name
		        	            	Status = $Object.ExtensionData.Guest.ToolsStatus
                	    			UpgradeStatus = $Object.ExtensionData.Guest.ToolsVersionStatus2
                    				Version = $Object.ExtensionData.Guest.ToolsVersion
                				}
            		} 
			catch 
			{
 		               Write-Error $_.Exception.Message
 			} 
			finally 
			{
                		if ($PSBoundParameters.ContainsKey("Name")) 
				{
		                    $PercentComplete = ($i/$Count).ToString("P")
                		    Write-Progress -Activity "Processing VM: $($Object.Name)" -Status "$i/$count : $PercentComplete Complete" -PercentComplete $PercentComplete.Replace("%","")
					$i++
		                } 
				else 
				{
	                	    Write-Progress -Activity "Processing VM: $($Object.Name)" -Status "Completed: $i"
                    			$i++
                		}
            		}
        	}
    	}
 	END {}
}



## VMtools
function checkVMtools($vmname)
{
	$vmtoolsstatus = Get-VMToolsStatus -Name $vmname | select-object -ExpandProperty Status
	$c = Get-VMToolsStatus -Name $vmname
	$vmchecklist = "vmware Tools updated"
	$createTablevmtools = "<html><head><body><table border=2><tr><th align=center>VM</th><th align=center>Tools Updated</th><th align=center>Comments</th></tr></td></tr>"
	if ( $vmtoolsstatus -eq "toolsOK" )
	{
		
		$status = "Compliant"
		$appendoptools = $createTablevmtools + "<tr><td align=center>" + $vmname + "</td><td bgcolor=66FF99 align=center>" + $status + "</td><td>" + $c + "</td></tr>" 
	}
	else
    	{
       		$status = "Not Compliant"
		$appendoptools = $createTablevmtools + "<tr><td align=center>" + $vmname + "</td><td bgcolor=#FF7F7F align=center>" + $status + "</td><td>" + $c + "</td></tr>" 
	}
	$closeHtmltools = $appendoptools + "</table></body></html>"
	htmlAppend $closeHtmltools $vmchecklist
}
## function to check VM tools ends here

## Below function checks the Memory hot add is enabled or not
function checkMemoryHotAdd($vmname)
{
	$vmchecklist = "Memory Hot Add Enabled"
	$m = (Get-VM -name $vmname | select ExtensionData).ExtensionData.config | Select Name, MemoryHotAddEnabled
	$createTablememhadd = "<html><head><body><table border=2><tr><th align=center>VM</th><th align=center>Memory Hot Add Enabled</th><th align=center>Comments</th></tr></td></tr>"
	$memoryhotadd = (Get-VM -name $vmname | select ExtensionData).ExtensionData.config | Select Name, MemoryHotAddEnabled, CpuHotAddEnabled, CpuHotRemoveEnabled | select-object -ExpandProperty MemoryHotAddEnabled
	if ( $memoryhotadd -eq "True" )
	{
		$status = "Compliant"
		$appendopmemhadd = $createTablememhadd + "<tr><td align=center>" + $vmname + "</td><td bgcolor=66FF99 align=center>" + $status + "</td><td>" + $m + "</td></tr>" 
	}
	else
    	{
		$status = "Not Compliant"
		$appendopmemhadd = $createTablememhadd + "<tr><td align=center>" + $vmname + "</td><td bgcolor=#FF7F7F align=center>" + $status + "</td><td>" + $m + "</td></tr>" 
       	}
	$closeHtmlmemhadd = $appendopmemhadd + "</table></body></html>"
	htmlAppend $closeHtmlmemhadd $vmchecklist
}
## function for memory hot add ends here

## Below function checks the CPU hot add is enabled or not
function checkCPUHotAdd($vmname)
{
	$vmchecklist = "CPU Hot Add Enabled"
	$cpu = (Get-VM -name $vmname | select ExtensionData).ExtensionData.config | Select Name, CpuHotAddEnabled
	$createTablecpuhadd = "<html><head><body><table border=2><tr><th align=center>VM</th><th align=center>Memory Hot Add Enabled</th><th align=center>Comments</th></tr></td></tr>"
	$cpuhotadd = (Get-VM -name $vmname | select ExtensionData).ExtensionData.config | Select Name, MemoryHotAddEnabled, CpuHotAddEnabled, CpuHotRemoveEnabled | select-object -ExpandProperty CpuHotAddEnabled
	if ( $cpuhotadd -eq "True" )
	{
		$status = "Compliant"
		$appendopcpuhadd = $createTablecpuhadd + "<tr><td align=center>" + $vmname + "</td><td bgcolor=66FF99 align=center>" + $status + "</td><td>" + $cpu + "</td></tr>" 
	}
	else
    	{
		$status = "Not Compliant"
		$appendopcpuhadd = $createTablecpuhadd + "<tr><td align=center>" + $vmname + "</td><td bgcolor=#FF7F7F align=center>" + $status + "</td><td>" + $cpu + "</td></tr>" 
       	}
	$closeHtmlcpuhadd = $appendopcpuhadd + "</table></body></html>"
	htmlAppend $closeHtmlcpuhadd $vmchecklist
}
## function for CPU hot add ends here

## Below function checks the datastore details where the VM resides
function getDSDetails($vmname)
{
	$vmchecklist = "Datastore details where the VM disk is stored"
	$ds = Get-VM -name $vmname | get-datastore
	$createTablegetds = "<html><head><body><table border=2><tr><th align=center>VM</th><th align=center>Datastore</th><th align=center>Comments</th></tr></td></tr>"
	$dsdetails = Get-VM -name $vmname | get-datastore | select-object -expandproperty Name
	$appendopdsdetails = $createTablegetds + "<tr><td align=center>" + $vmname + "</td><td bgcolor=66FF99 align=center>" + $dsdetails + "</td><td>" + $ds + "</td></tr>" 
	$closeHtmldsdetails = $appendopdsdetails + "</table></body></html>"
	htmlAppend $closeHtmldsdetails $vmchecklist	
}
## Get datastore details ends here

## Below function checks if round robin is enabled for the datastore on which the vm resides.

function checkRoundRobinDSPolicy($vmname)
{
	$vmchecklist = "Round Robin enabled on new datastores"
	$createTablerr = "<html><head><body><table border=2><tr><th align=center>VM</th><th align=center>Datastore</th><th align=center>Device ID</th><th align=center>Round Robin Status</th><th align=center>Comments</th></tr></td></tr>"

	$dscanonicalname = get-vm -name $vmname | Get-Datastore | Select Name,@{N='CanonicalName';E={$_.Extensiondata.Info.Vmfs.Extent[0].DiskName}} | Select-Object -ExpandProperty CanonicalName
	$dsname = get-vm -name $vmname | Get-Datastore | Select Name,@{N='CanonicalName';E={$_.Extensiondata.Info.Vmfs.Extent[0].DiskName}} | Select-Object -ExpandProperty Name
	$ds = get-vm -name $vmname | Get-VMHost  | Get-ScsiLun -LunType disk | Where {$_.MultipathPolicy -notlike "RoundRobin"} | Select-String -Pattern $dscanonicalname
	$dstrim = $ds -replace '(?m)^\s*?\n'
	echo "This is dstrim $dstrim"
	if ( ! $dstrim  )
	{
			$status = "Compliant"
			$ccc = get-vm -name $vmname | Get-VMHost  | Get-ScsiLun -LunType disk | Where {$_.MultipathPolicy -like "RoundRobin"} | Select-Object CanonicalName,MultipathPolicy | Select-String $dscanonicalname
			$appendoprr = $createTablerr + "<tr><td align=center>" + $vmname + "</td><td align=center>" + $dsname + "</td><td>" + $dscanonicalname + "<td bgcolor=66FF99 align=center>" + $status + "</td><td>" + $ccc + "</td></tr>" 
	}
	else
    	{
		##FF7F7F
		$status = "Not Compliant"
		$ccc = get-vm -name $vmname | Get-VMHost  | Get-ScsiLun -LunType disk | Where {$_.MultipathPolicy -like "RoundRobin"} | Select-Object CanonicalName,MultipathPolicy | Select-String $dscanonicalname
		$appendoprr = $createTablerr + "<tr><td align=center>" + $vmname + "</td><td align=center>" + $dsname + "</td><td>" + $dscanonicalname + "<td bgcolor=#FF7F7F align=center>" + $status + "</td><td>" + $ccc + "</td></tr>" 
			
	}
	$closeHtmlrr = $appendoprr + "</table></body></html>"
	htmlAppend $closeHtmlrr $vmchecklist
}




## Below function checks if a disk is multi-writer in case of DB
function checkDiskMultiWriter($vmname)
{
	$vmchecklist = "If share disk , all SCSI is set to sharing and Multi-write (to add shared disk in future without downtime)"
	$createTablemulti = "<html><head><body><table border=2><tr><th align=center>VM</th><th align=center>Disks with Multi-Writer enabled</th><th align=center>Comments</th></tr></td></tr>"
	
		$multidisk = Get-VM -name $vmname | Get-HardDisk | %{$ctrl = Get-ScsiController -HardDisk $_
		$_ | Select @{N='VM';E={$_.Parent.Name}},Name,StorageFormat,FileName,@{N='Multi-Writer';E={$_.ExtensionData.Backing.Sharing}} } | select-object -expandproperty Multi-Writer
	
		if ( $multidisk -eq "sharingMultiWriter" )
		{
			$status = Get-VM -name $vmname | Get-HardDisk | %{
									$ctrl = Get-ScsiController -HardDisk $_
									$_ | Select @{N='VM';E={$_.Parent.Name}},Name,StorageFormat,FileName,@{N='Multi-Writer';E=									{$_.ExtensionData.Backing.Sharing}} }  | where { $_.'Multi-Writer' -eq "sharingMultiwriter" }
			#echo "This is : SSSSSSSS  ---  $status"
			$appendopmultidisk = $createTablemulti + "<tr><td align=center>" + $vmname + "</td><td bgcolor=#FFFF00 align=center>" + $status + "</td><td>VM has shared disks with multi-writer enabled</td></tr>" 
		}
		else
    		{
			#$status = "Not Compliant"
			$appendopmultidisk = $createTablemulti + "<tr><td align=center>" + $vmname + "</td><td bgcolor=#FFFF00 align=center> NA </td><td>VM does not have any shared disks and hence multi-writer is not enabled</td></tr>" 
		}
	
	$closeHtmlmulti = $appendopmultidisk + "</table></body></html>"
	htmlAppend $closeHtmlmulti $vmchecklist
}
## Multi writer disk function ends here

## Below function will check if the VM has any affinity rule
function checkVMAffinityRule($vmname)
{
	$vmchecklist = "Affinity Rule (Enabled/Disabled)"
	$esxicluster = get-vmhost -vm $vmname | get-cluster
	$DRSRules = get-cluster $esxicluster | get-drsrule
	$createTable = "<html><head><body><table border=2><tr><th align=center>VM</th><th align=center>Status</th><th align=center>Comments</th></tr></td></tr>"
	if ( $DRSRules -ne $NULL )
	{
		ForEach ($DRSRule in $DRSRules)
		{	 
			$vmss = "" | Select-Object -Property @{N="VMs";E={((Get-View -Id $DRSRules.VMIds).Name)}}
			$vmsss = echo $vmss | Select-Object -ExpandProperty VMs
			if ( $vmsss -imatch $vmname )
    			{
			        $status = "Enabled"
				$appendop = $createTable + "<tr><td align=center>" + $vmname + "</td><td bgcolor=66FF99 align=center>" + $status + "</td><td>Affinity rule is present</td></tr>"  
    			}
    			else
    			{
        			$status = "Disabled"
				$appendop = $createTable + "<tr><td align=center>" + $vmname + "</td><td bgcolor=#FFFF00 align=center>" + $status + "</td><td>No Affinity rules present</td></tr>"
    			}
		}
	}
	else
    	{
       		$status = "Disabled"
		$appendop = $createTable + "<tr><td align=center>" + $vmname + "</td><td bgcolor=#FFFF00 align=center>" + $status + "</td><td>No Affinity rules present</td></tr>"
    	}
	$closeHtml = $appendop + "</table></body></html>"
	htmlAppend $closeHtml $vmchecklist
}
## Function to check VM affinity rule ends here

## Below function will only execute if the VM is a database VM and will check if the disks are thick provisioned or not
function checkThickDisks($vmname)
{ 
	$firstfunction = "True"
	$vm = Get-VM $vmname
	$opthickprov = $vm.ExtensionData.Config.Hardware.Device | 
	where {$_ -is [VMware.Vim.VirtualDisk]} | 
	Select @{N="VM";E={$vm.Name}},
	@{N="HD";E={$_.DeviceInfo.Label}},
	@{N="Type";E={$_.Backing.GetType().Name}},
	@{N="EagerlyScrub";E={$_.Backing.EagerlyScrub}},
	@{N="ThinProvisioned";E={$_.Backing.ThinProvisioned}} | select VM, HD, ThinProvisioned
	$opthickprov | select-object -ExpandProperty HD
	$virtualmachinename = $opthickprov | select-object -ExpandProperty VM | select -First 1 
	$rowcount = ($opthickprov | select-object -ExpandProperty HD).count
	$rowcount += 1
	$vmchecklist = "For DB Servers disk type should be thick provisioning, for APP and WEB servers thin provisioning"
	$disk = $NULL
	$harddisk = "<html><head><body><table border=2><tr><th align=center>VM</th><th align=center>Hard Disk</th><th align=center>Thin Provisioned</th><th align=center>Comments</th></tr><tr><td align=center rowspan = $rowcount>" + $virtualmachinename + "</td></tr>"
	foreach ( $op in $opthickprov )
	{
		
		$hdd = "<tr><td align=center>" 
		$a = $op | select-object -ExpandProperty HD 
		$b = $hdd + $a + "</td><td align=center "
		$c = $op | select-object -ExpandProperty ThinProvisioned
		if ( $vmname -imatch '.db\d\d'  -and  $c -eq 'True')
		{
			if ( $a -eq 'Hard disk 1' )
			{
				## For DB disk first OS disk should be thin provisioned
				## green color
				$d = $b + "bgcolor=66FF99>" + $c
			}
			else
			{
				## Red color
				$d = $b + "bgcolor=#FF7F7F>" + $c
			}
		}
		elseif ( $vmname -imatch '.app\d\d'  -and  $c -eq "True" )
		{
			#checking for app vm and should be thin provisioned
			## Green color
			$d = $b + "bgcolor=66FF99>" + $c
		}
		elseif ( $vmname -imatch '.app\d\d'  -and  $c -eq "False" )
		{
			#checking for app vm and should be thin provisioned
			## Red color
			$d = $b + "bgcolor=#FF7F7F>" + $c
		}
		else
		{
			## Green color
			$d = $b + "bgcolor=66FF99>" + $c	
		}
		$e = $d + "</td>"
		if (( $vmname -imatch '.db\d\d') -and  ($c -eq "True" ))
		{
			$commentshdd = $op | select-object -ExpandProperty HD
			if ( $commentshdd -eq 'Hard disk 1' )
			{
				$comments = "<td>" + $commentshdd + " is compliant (OS Disk)</td></tr>"
			}
			else
			{
				$comments = "<td>" + $commentshdd + " is not compliant</td></tr>"
			}
		}
		elseif ( $vmname -imatch '.app\d\d'  -and  $c -eq "True" )
		{
			$commentshdd = $op | select-object -ExpandProperty HD
			$comments = "<td>" + $commentshdd + " is compliant</td></tr>"
		}
		elseif ( $vmname -imatch '.app\d\d'  -and  $c -eq "False" )
		{
			$commentshdd = $op | select-object -ExpandProperty HD
			$comments = "<td>" + $commentshdd + " is not compliant</td></tr>"	
		}
		else
		{
			$commentshdd = $op | select-object -ExpandProperty HD
			$comments = "<td>" + $commentshdd + " is compliant</td></tr>"
		} 
		$disk += $e + $comments	
	}
	$disk = $harddisk + $disk + "</table></body></html>"
	htmlAppend $disk $vmchecklist
}
## Check if DB disks are thick provisioned function ends above

## Below function checks if the ESXi hosts on which the VM which is being validated has sufficient memory and CPU resources
function checkESXiMemoryAvailablity($vmname)
{
	$ehost = get-vm -name $vmname | Get-VMHost | select-object -expandproperty name
	$percentageRAM = get-vm -name $vmname | Get-VMHost 
	Select Name,
	@{N='CPU GHz Capacity';E={[math]::Round($_.CpuTotalMhz/1000,2)}},
	@{N='CPU GHz Used';E={[math]::Round($_.CpuUsageMhz/1000,2)}},
	@{N='CPU GHz Free';E={[math]::Round(($_.CpuTotalMhz - $_.CpuUsageMhz)/1000,2)}},
	@{N='Memory Capacity GB';E={[math]::Round($_.MemoryTotalGB,2)}},
	@{N='Memory Used GB';E={[math]::Round($_.MemoryUsageGB,2)}},
	@{N='Memory Free GB';E={[math]::Round(($_.MemoryTotalGB - $_.MemoryUsageGB),2)}}

	$memoryUsageGB = $percentageRAM | Select-Object -ExpandProperty MemoryUsageGB
	$TotalmemoryGB = $percentageRAM | select-object -ExpandProperty MemoryTotalGB
	$percentageFreeMemory = ( $memoryUsageGB / $TotalmemoryGB ) * 100
	$vmchecklist = "Enough resources are available on the ESXI hosts where VMs Exist (80%-20%)"
	$output = "<html><head><body><table border=3><tr><th align=center>ESXi Host</th><th align=center>Memory Value (%)</th><th align=center>Comments</th></tr>"
	if ( $percentageFreeMemory -gt 80 )
	{
		$output += "<tr><td align=center>" + $ehost + "</td><td align=center>" + [math]::Round($percentageFreeMemory,2) + "</td><td align=center bgcolor=#FF7F7F>" + $ehost + " is Not compliant</td></tr>"
	}
	else
	{
		$output += "<tr><td align=center>" + $ehost + "</td><td align=center>" + [math]::Round($percentageFreeMemory,2) + "</td><td align=center bgcolor=66FF99>" + $ehost + " is compliant</td></tr>"
		
	}
	$sendtohtml = $output + "</table></body></html>" 
	htmlAppend $sendtohtml $vmchecklist
}
	
## Check ESXi memory function ends here

$global:disk = $NULL
$global:vmchecklist = $NULL
$global:html3 = $NULL
$global:html4 = $NULL
$global:htmlvar =  "<html>                                
                    <head><title>ACCEPTANCE REPORT</title>
                    <style>

    h1 {

        font-family: Arial, Helvetica, sans-serif;
        color: #e68a00;
        font-size: 28px;

    }

    
    h2 {

        font-family: Arial, Helvetica, sans-serif;
        color: #000099;
        font-size: 16px;

    }

    
    
   table {
		font-size: 12px;
		border: 0px; 
		font-family: Arial, Helvetica, sans-serif;
        width:100%;
	} 
	
    td {
		padding: 4px;
		margin: 0px;
		border: 0;
        width:20%;
	}
	
    th {
        background: #395870;
        background: linear-gradient(#49708f, #293f50);
        color: #fff;
        font-size: 11px;
        text-transform: uppercase;
        padding: 10px 15px;
        vertical-align: middle;
	}

    tbody tr:nth-child(even) {
        background: #f0f0f2;
    }

        #CreationDate {

        font-family: Arial, Helvetica, sans-serif;
        color: #ff3300;
        font-size: 12px;

    }
    



</style>
                     </head>
                    <body>
		    <table border = `1`>
                    <tr><td bgcolor='#DCDCDC' align='center'><b>VM Checklist</b></td><td bgcolor='#DCDCDC' align='center'><b>Compliance Check</b></td></tr>"

## Below function calls all the vmware related components
function vmware($vmname)
{
    Connect-VIServer -server 10.175.69.6 -User ducorp\hcm.vcenter -Password  'P@ssw0rd#2020' | out-null
   # if ( $? -eq 0 )
   # {
        checkThickDisks $vmname
	    checkESXiMemoryAvailablity $vmname
	    checkVMAffinityRule $vmname
    	checkVMTimeSync $vmname
    	checkGuestOS $vmname
    	checkVMHWVersion $vmname
    	checkVMtools $vmname
    	checkMemoryHotAdd $vmname
    	checkCPUHotAdd $vmname
    	checkDiskMultiWriter $vmname
        getDSDetails $vmname
    	checkRoundRobinDSPolicy $vmname
}


if ( ! $args[0] )
{
	echo "No Parameter Passed"
}
else
{
	vmware $args[0]
    if ( $global:gos -imatch "linux" )
    {
        linux $args[0]
    }
    else
    {
        windows $args[0]
    }
}


#meyclvaptddb01 - DB VM
#MEYLVIOTCORE1 - VM has rules
#meyclvaloeweb01 - web VM
#meyclvddcmdb01 - Multi-writer disk

