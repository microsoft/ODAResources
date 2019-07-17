Param([Parameter(Mandatory=$true)]$Url,[int]$Timeout=1000)

set-location cert:
$returnobject = $null
$returnobject = New-Object –TypeName PSObject

#$Url = "https://sccmserver/sms_mp/.sms_aut?mplist"

$certs = (Get-ChildItem Cert:\LocalMachine\My | Where-Object {( ($_.HasPrivateKey -eq $true)  -and ($_.NotAfter -ge (Get-Date)) -and ($_.NotBefore -le (Get-Date)) )  })
#$certs = (Get-ChildItem Cert:\LocalMachine\My | Where-Object {( ($_.HasPrivateKey -eq $true) -and (($_.Extensions.EnhancedKeyUsages.Friendlyname -eq "Client Authentication")) ) })
#$certs = (Get-ChildItem Cert:\LocalMachine\My)

$WebRequest = $null
$StatusCode = -1
$StatusCodeDescription = ""
$WebRequest = [Net.WebRequest]::Create($Url)
$WebRequest.Timeout = [int]$Timeout * 1000
$WebRequest.UseDefaultCredentials = $true
$WebRequest.CachePolicy = New-Object System.Net.Cache.RequestCachePolicy([Net.Cache.RequestCacheLevel]::Default)
$WebRequest.AuthenticationLevel = [System.Net.Security.AuthenticationLevel]::None
$WebRequest.ImpersonationLevel = [System.Security.Principal.TokenImpersonationLevel]::Anonymous
$WebRequest.PreAuthenticate = $false
$WebRequest.Method = "GET"


foreach ($cert in $certs) {
    foreach ($ext in $cert.Extensions) {
     foreach ($eku in $ext.EnhancedKeyUsages) {
        if ($eku.FriendlyName -eq "Client Authentication") {
            $tmp = $WebRequest.ClientCertificates.add($cert)
            #write-host $cert 
        }
     }
      
    }
}

if ($WebRequest.ClientCertificates.Count -gt 0) {

    try { 
    
        $Response = $WebRequest.GetResponse()
        Add-Member -InputObject $returnobject -MemberType NoteProperty -Name ErrorOccured -value NO
	Add-Member -InputObject $returnobject -MemberType NoteProperty -Name ResponseUri -value $Response.ResponseUri.AbsoluteUri
        $StatusCode = [int] $Response.StatusCode
        $StatusCodeDescription = $Response.StatusDescription
        #$Response | fl *
    } catch [System.Net.WebException] {
        Add-Member -InputObject $returnobject -MemberType NoteProperty -Name ErrorOccured -value YES
        Add-Member -InputObject $returnobject -MemberType NoteProperty -Name Error1 -value ($Error[0].Exception.Message)
	Add-Member -InputObject $returnobject -MemberType NoteProperty -Name ResponseUri -value ($Error[0].Exception.Message)
        $StatusCode = [int]$_.Exception.Response.StatusCode
        $StatusCodeDescription =  $_.Exception.Response.StatusDescription
    } catch {
       Add-Member -InputObject $returnobject -MemberType NoteProperty -Name Error2 ($Error[0].Exception.Message) 
    }


    Add-Member -InputObject $returnobject -MemberType NoteProperty -Name RequestUri -value $WebRequest.RequestUri.AbsoluteUri   
    Add-Member -InputObject $returnobject -MemberType NoteProperty -Name ContentType -value $Response.ContentType
    Add-Member -InputObject $returnobject -MemberType NoteProperty -Name ContentSize -value ([long] $Response.ContentLength)
    Add-Member -InputObject $returnobject -MemberType NoteProperty -Name PortNumber -value ([int] $Response.ResponseUri.Port)
    Add-Member -InputObject $returnobject -MemberType NoteProperty -Name Scheme -value $Response.ResponseUri.Scheme
    Add-Member -InputObject $returnobject -MemberType NoteProperty -Name ResponseStatus -value ([int] $StatusCode)
    Add-Member -InputObject $returnobject -MemberType NoteProperty -Name ResponseStatusDescription -value $StatusCodeDescription
    Add-Member -InputObject $returnobject -MemberType NoteProperty -Name IsFromCache -value ([bool] $Response.IsFromCache)
    Add-Member -InputObject $returnobject -MemberType NoteProperty -Name IsMutuallyAuthenticated -value ([bool] $Response.IsMutuallyAuthenticated)
} else {
    Add-Member -InputObject $returnobject -MemberType NoteProperty -Name RequestUri -value $WebRequest.RequestUri.AbsoluteUri
    Add-Member -InputObject $returnobject -MemberType NoteProperty -Name ErrorOccured -value YES
    Add-Member -InputObject $returnobject -MemberType NoteProperty -Name Error1 "Proper Certificate is missing on Tools Computer: certificate with Private Key, not expired and with 'Client Authentication' key usage'"
    Add-Member -InputObject $returnobject -MemberType NoteProperty -Name ResponseUri "Proper Certificate is missing on Tools Computer: certificate with Private Key, not expired and with 'Client Authentication' key usage'"
    Add-Member -InputObject $returnobject -MemberType NoteProperty -Name ResponseStatus -value ([int] $StatusCode)
    Add-Member -InputObject $returnobject -MemberType NoteProperty -Name ResponseStatusDescription -value $StatusCodeDescription
}    

$returnobject