#Author:           VMLabblog.com - Aad Lutgert
#Date:             23-09-2024
#Version:          v1.01
#Purpose:          Grant admin consent for a user on an Enterprise Application in Entra ID

#Connect to Graph commandline using scope to assign permissions
Connect-MgGraph -Scopes ("User.ReadBasic.All Application.ReadWrite.All " `
                        + "DelegatedPermissionGrant.ReadWrite.All " `
                        + "AppRoleAssignment.ReadWrite.All")

#Set parameters
$clientAppId = "14d82eec-204b-4c2f-b7e8-296a70dab67e" # Microsoft Graph Command Line
$resourceAppId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph API
$permissions = @("DeviceManagementConfiguration.ReadWrite.All", "profile", "User.Read") #Claim value of the permissions
$userUpnOrId = “<UPNorID>” #User which will get the permissions

#Assign permissions
$clientSp = Get-MgServicePrincipal -Filter "appId eq '$($clientAppId)'"
$user = Get-MgUser -UserId $userUpnOrId
$resourceSp = Get-MgServicePrincipal -Filter "appId eq '$($resourceAppId)'"
$scopeToGrant = $permissions -join " "

$permissionid = (Get-MgOauth2PermissionGrant -All| Where-Object {($_.clientId -eq $clientsp.Id) -and ($user.id -eq $_.PrincipalId)})

if($permissionid -eq $null){
    write-host "No Existing permissions exist, create new permissions."
    $grant = New-MgOauth2PermissionGrant -ResourceId $resourceSp.Id `
                                     -Scope $scopeToGrant `
                                     -ClientId $clientSp.Id `
                                     -ConsentType "Principal" `
                                     -PrincipalId $user.Id    
    } 
    else 
    {
    # If a delegated permission already exist. Add the new permissions
    write-host "Existing permissions found, adding new permission(s)"
    
    # Get current assigned scope for a specific user and add new permissions
    $CurrentScope = $permissionid.Scope
    $UpdatedScopeToGrant = (($CurrentScope -split " ")+($scopeToGrant -split " ") | select-object -unique) -join " "
    
    #$UpdatedScopeToGrant = "DeviceManagementConfiguration.ReadWrite.All" + " " + "Directory.ReadWrite.All"

    $params = @{
        "ClientId" = $clientSp.Id
        "ConsentType" = "Principal"
        "ResourceId" = $resourceSp.Id
        "Scope" = $UpdatedScopeToGrant
        "PrincipalId" = $user.Id
        }
    $grant = Update-MgOauth2PermissionGrant -OAuth2PermissionGrantId $permissionid.Id -BodyParameter $params
    }
