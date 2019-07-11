# https://github.com/solarwinds/OrionSDK/wiki/PowerShell
# https://github.com/solarwinds/OrionSDK/wiki/IPAM-API
$hostname = "ipam.server.name"
$creds = Get-Credential
$swis = Connect-Swis -Credential $creds -Hostname $hostname
Get-SwisData $swis 'SELECT NodeID, Caption FROM Orion.Nodes'