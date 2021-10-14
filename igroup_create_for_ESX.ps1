<#'-----------------------------
ScriptName: igroup_create.ps1

'Description: From a CSV File, Create igroups, 
              add initiators to the igroup and map existing Luns to the igroup
'--------------------------------
#>

#Paremeterisation
[CmdletBinding()]
Param(
    [parameter(Mandatory=$true, Helpmessage = "the Cluster name" )][string]$cluster,
    [parameter(Mandatory=$true, Helpmessage = "the Cluster admin user name" )][string]$user,
    [parameter(Mandatory=$true, Helpmessage = "the Cluster admin user password" )][string]$password,
    [parameter(Mandatory=$true, Helpmessage = "the SVM name" )][string]$svm,    
    [parameter(Mandatory =$false,Helpmessage = "OS type for the NEW LUn and iGroup")][string]$ostype = "vmware",
    [parameter(Mandatory =$false,Helpmessage = "portset name")][string]$portset = "ps_esx",
    [parameter(Mandatory=$false, Helpmessage = "CSV file path details")][string]$lpath = "C:\variable\igroup_esx.csv",
    [parameter(Mandatory=$false, Helpmessage = "LUN CSV file path details")][string]$lunpath ="C:\variable\Lun_ESX.csv"
)

#variable
$adminCred = New-Object System.Management.Automation.PSCredential ($user, (ConvertTo-SecureString $password -AsPlainText -Force))
$igr= import-csv -path $lpath
$lun= import-csv -path $lunpath

# Load ONTAP module and connect to Cluster
Import-Module DataONTAP
try
{
Connect-NcController -Name $cluster -Credential $adminCred -ErrorAction Stop |Out-Null
write-host "connected to " $cluster -ForegroundColor green}
catch
{
Write-Warning -Message $("Failed connecting to cluster ""$cluster"". Error " + $_.Exception.Message)
Exit
}

foreach ($l in $igr)
{
    $igrpname = $l.igrpname
    $ini1 = $l.ini1
    $ini2 = $l.ini2

 <#
    #***********create iGroup**********
 try 
 {
    New-NcIgroup -Name $igrpname -vserverContext $svm -Type $ostype -Protocol fcp -Portset $portset -ErrorAction stop | Out-Null
     Write-Host "creating igroup" $igrpname  -ForegroundColor green
 }

Catch
{
     Write-Warning -Message $("Unable to create igroup ""$igrpname"". Error " + $_.Exception.Message)
Break;
}
#*********Add Initiators to igroup**************
try 
{
    Add-NcIgroupInitiator -Name $igrpname -VserverContext $svm -Initiator $ini1 -ErrorAction stop | Out-Null
    Write-Host "adding initiator """$ini1"""to igroup " $igrpname   -ForegroundColor green
}

Catch
{
    Write-Warning -Message $("Unable to add initiator ""$ini1"". Error " + $_.Exception.Message)
Break;
}
#>
#initiator 2
try 
{
    Add-NcIgroupInitiator -Name $igrpname -VserverContext $svm -Initiator $ini2 -ErrorAction stop | Out-Null
    Write-Host "adding initiator """$ini2"""to igroup " $igrpname  -ForegroundColor green
}

Catch
{
    Write-Warning -Message $("Unable to add initiator ""$ini2"". Error " + $_.Exception.Message)
Break;
}

#Map the Lun to the initiator group

foreach ($i in $lun)
{
    $lunname = $i.lun
    $id = $i.id

try 
{
    Add-NcLunMap -path $lunname -InitiatorGroup $igrpname -VserverContext $svm -Id $id -ErrorAction stop | Out-Null
    Write-Host "Mapping Lun """$lunname"""to igroup " $igrpname  -ForegroundColor green
}

Catch
{
    Write-Warning -Message $("Unable to map Lun ""$lunname"" to igroup. Error " + $_.Exception.Message)
Break;
}
}
write-host "================================" -ForegroundColor Yellow
   
}



    <#
    new-nclun -Path /vol/vol_61_11b_rep/lun623_zuxdc2q -size 30gb -osType AIX -Unreserved -comment zuxdc2q_rootvg01 -VserverContext dcsansvm11 
    New-NcIgroup -Name zuxdc2q -vserverContext dcsansvm11 -Type AIX -Protocol fcp -Portset ps_aix
    Add-NcIgroupInitiator -Name zuxdc2q -VserverContext dcsansvm11 -Initiator c0:50:76:0a:cd:31:00:4e
    Add-NcIgroupInitiator -Name zuxdc2q -VserverContext dcsansvm11 -Initiator c0:50:76:0a:cd:31:00:4c
    Add-NcLunMap -path /vol/vol_61_11b_rep/lun623_zuxdc2q -InitiatorGroup zuxdc2q -VserverContext dcsansvm11 
    #>
   

