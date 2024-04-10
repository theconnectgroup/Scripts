Function Get-AttachmentsFromEmailWithGraphAPI(){
    [Cmdletbinding()]
    param(
       [Parameter(Mandatory=$true)]
       [string]$clientappid, 
       [Parameter(Mandatory=$true)]
       [string]$tenantid,
       [Parameter(Mandatory=$true)]
       [string]$appsecret,
       [Parameter(Mandatory=$true)]
       [string]$useremail,
       [Parameter(Mandatory=$true)]
       [string]$senderemail,
       [Parameter(Mandatory=$true)]
       [string]$output
    )
<#
.Synopsis
This function downloads attachments sent to a specified account from a specified email and converts them from base64 to the correct type(only tested with PDF) and saves them to the a specified output 
.Example
Random IDs substituted below obviously
Get-AttachmentsFromEmailWithGraphApi -ClientAppId "3396ff7b-ee07-4257-b70c-8e1bf8a15c56" -TenantID "dfe2ed63-f018-47e5-938a-f8400382af2f" -AppSecret "uF6Au4OQgVzCXV!SAf8oWdImy%fc0It^cXMtPav7" -Useremail "example@mydomain.com" -Senderemail "example@senderdomain.com" -Output "C:\Temp"
#>
    $clientId = $clientappid
    $tenant = $tenantid
    $secret = ConvertTo-SecureString $appsecret -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $secret
    Connect-AzAccount -ServicePrincipal -TenantId $Tenant -Credential $Credential
    $authresult = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com/"
    $authHeader = @{
                    'Content-Type'='application/json'
                    'Authorization'="Bearer $($authResult.Token)"
                    'ExpiresOn'=$authResult.ExpiresOn
                    }
    $messages = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$useremail/mailFolders/inbox/messages?=from/emailAddress/address%20eq%20'$senderemail'" -Method Get -Headers $authheader
    $IdArray = [System.Collections.Generic.List[object]]::new()
    foreach($m in $($messages).value)
        {
            if($($m).hasattachments -eq "True")
                {
                    [void]$IdArray.Add([PSCustomObject]@{
                        ID = $($m).ID
                        })
                }
        }
    $aidarray = [System.Collections.Generic.List[object]]::new()
    foreach($id in $IdArray)
        { 
            #mid obviously short for message id
            $mid = $($id).id
            $attachmentids = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$useremail/mailFolders/inbox/messages/$mid/attachments" -Method Get -Headers $authheader
            #aids obviously short for attachment ids
            $aids = $($attachmentids).value.id
            foreach($aid in $aids)
                {
                    [void]$aidarray.Add([PSCustomObject]@{
                    MID = $mid
                    AID = $aid
                    })
                }
        }
    Write-Host $aidarray | FL
    $filearray = [System.Collections.Generic.List[object]]::new()
    foreach($attach in $aidarray)
        {
            $attid = $attach.AID
            $mesid = $attach.MID
            $files = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$useremail/mailFolders/inbox/messages/$mesid/attachments/$attid/$value" -Method Get -Headers $authheader
            foreach($file in $files)
                {
                    [void]$filearray.Add([PSCustomObject]@{
                        Name = $file.Name
                        Bytes = $file.Contentbytes
                    })
                }    
        }
    if(!(Test-Path $Output))
        {
            New-Item -ItemType Directory -Path $output -Force
            foreach($content in $filearray)
                {
                    $B64 = $($Content).Bytes
                    $Name = $($content).Name
                    $bytes = [Convert]::FromBase64String($B64)
                    [IO.File]::WriteAllBytes("$output\$Name", $bytes)
                }
        }
}
