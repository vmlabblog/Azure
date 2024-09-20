Connect-MgGraph -Scopes ("User.ReadBasic.All Application.ReadWrite.All " `
#                        + "DelegatedPermissionGrant.ReadWrite.All " `
#                        + "AppRoleAssignment.ReadWrite.All")

#set parameters
$clientAppId = "14d82eec-204b-4c2f-b7e8-296a70dab67e" # Microsoft Graph Command Line
$resourceAppId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph API
$permissions = @("DeviceManagementConfiguration.ReadWrite.All", "profile", "User.Read") #Claim value of the permissions
$userUpnOrId = “<UPNorID>” #User which will get the permissions



$clientSp = Get-MgServicePrincipal -Filter "appId eq '$($clientAppId)'"
$user = Get-MgUser -UserId $userUpnOrId
$resourceSp = Get-MgServicePrincipal -Filter "appId eq '$($resourceAppId)'"
$scopeToGrant = $permissions -join " "


#testscope
$NewArray = @("profile", "User.Read")
$demoscopeToGrant = $NewArray -join " "


$permissionid = (Get-MgOauth2PermissionGrant -All| Where-Object {($_.clientId -eq $clientsp.Id) -and ($user.id -eq $_.PrincipalId)})

if($permissionid -eq $null){
    write-host "No Existing delegated permission grant, creating new grant."
    $grant = New-MgOauth2PermissionGrant -ResourceId $resourceSp.Id `
                                     -Scope $demoscopeToGrant `
                                     -ClientId $clientSp.Id `
                                     -ConsentType "Principal" `
                                     -PrincipalId $user.Id    
    } 
    else 
    {
    # If a delegated permission already exist. Add the new permissions
    write-host "Existing delegated permission grant does already exist, update existing"
    
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
