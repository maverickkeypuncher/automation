$vcname = "${vcname}"\n
$vcuser = "${vcuser}"\n
$vcpass = '${vcpass}'\n
$server = Connect-VIServer -Server $vcname -User $vcuser -Password $vcpass\n

$DS = Get-ScsiLun -VmHost  ${ESXIhost} -LunType disk | select CanonicalName | Ft -HideTableHeaders  | findstr.exe ${devid}

## Create a New Datastore

New-Datastore -VMHost ${ESXIhost}  -Name "${DatastoreName}"  -Path $DS

## Rescan the HBA’s

## Get-Cluster -name "${VMware_cluster}" | get-vmhost | get-vmhoststorage -RescanAllHba

$servers = get-vmhost -location "${VMware_cluster}" | sort name

#rescan all HBAs
foreach ($srv in $servers)
                {
                                get-VMHostStorage -VMHost $srv -RescanAllHba
                }

