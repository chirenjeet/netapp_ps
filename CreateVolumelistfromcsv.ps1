<#'-----------------------------
ScriptName: CreateVolume.ps1

'Description: Create a new volume and CIFS share 
'--------------------------------
#>

# ---------------------
# Parameters
#----------------------
[cmdletbinding()]
param(
[parameter(Mandatory = $True, HelpMessage = "The Cluster name or IP Address")] [STRING]$clustername,
[parameter(Mandatory = $True, HelpMessage = "The Cluster login userID")] [STRING]$userID,
[parameter(Mandatory = $True, HelpMessage = "The Cluster password for" )] [SecureString]$password ,
[parameter(Mandatory = $True, HelpMessage = "The cvs sheet with Vservername, Volume and Volume size details")]
[ValidateScript({test-path -path $_ })] [string] $vollistpath,
[parameter(Mandatory = $False, HelpMessage = "The aggregate name")][string] $Aggrname
)

#-----------------------------
# Variables
#-----------------------------
$credentials = New-Object System.Management.Automation.PScredential ($userID,$password)

#load NetApp Modules
Import-Module DataONTAP -Force

#---------------------------
#Login to Cluster
#----------------------------
try
{
Connect-NcController -Name $clustername -Credential $credentials -ErrorAction Stop |Out-Null
write-host "connected to " $clustername -ForegroundColor green}
catch
{
Write-Warning -Message $("Failed connecting to cluster ""$clusterName"". Error " + $_.Exception.Message)
Exit
}

#------------
#find agregate with max space available if no aggregate name is provided
#--------------------
<#
if ($Aggrname -eq "")
{
$aggr= Get-NcAggr | select name, used, Available | Sort-Object -Property available | Select-Object -Last 1

if ($aggr.used -ge 90)
{
write-warning -Message "Aggregate with max space available is already more than 90% utilized"
EXIT
}
else { Write-Host "Aggr" ""$aggr.name"" "will be used to provision the new vol" -ForegroundColor Green}
}
else {
$aggr = get-ncaggr -Name $Aggrname 
}
#>
#-----------------
#initialize the variables from the CSV file
#-------------------

$vollist = import-csv -Path $vollistpath
foreach ($x in $vollist)
{
$vservername = $x.Vserver
$volname = $x.volname
$volsize = $x.size +"gb"
$junctionpath = "/" + $volname
$aggr = $x.aggr

try {
New-NcVol -Name $volname -Aggregate $aggr -VserverContext $vservername -JunctionPath $junctionpath -SpaceReserve none -Size $volsize -ErrorAction stop | Out-null
write-host " Volume ""$volname"" has been created" -ForegroundColor Green
}
catch {
write-warning -message $("Unable to create new volume. Error:" + $_.Exception.Message )
}
#----------------------
#create the cifs share
#----------------------

try{
Add-NcCifsShare -Name $volname -VserverContext $vservername -Path $junctionpath -ErrorAction Stop | Out-null
Write-Host "CIFS share" ""$volname"" "has been created" -ForegroundColor green 
}
catch {
write-warning -message $("unable to create the CIFS share. Error:" + $_.Exception.Message )
}
}
#--------------------
#END
#----------------------



