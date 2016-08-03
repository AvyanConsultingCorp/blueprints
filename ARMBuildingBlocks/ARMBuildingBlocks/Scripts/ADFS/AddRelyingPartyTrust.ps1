Param(
  [Parameter(Mandatory=$True)]
  [string]$RpName,

  [Parameter(Mandatory=$True)]
  [string]$MetadataUrl,

  [Parameter(Mandatory=$True)]
  [string]$AuthozRule,

   [Parameter(Mandatory=$True)]
  [string]$TransformRule

)

# this script will add the relying party on Account ADFS
# it must be ran on Account ADFS 
# it is high privilege operation and needs to be ran as domain admin
# the metadata must point to resource ADFS
# example
# ./AddRelyingPartyTrust -RpName 'Corp Account Adfs' -MetadataUrl 'https://pnpadfs.patternspractices.net/FederationMetadata/2007-06/FederationMetadata.xml' -AuthozRule '=> issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", Value = "true");' -TransformRule ‘c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"] => issue(claim = c);’


Add-AdfsRelyingPartyTrust -Name $RpName `
  -AutoUpdateEnabled $true `
   -MetadataUrl $MetadataUrl `
   -IssuanceAuthorizationRules $AuthozRule `
   -IssuanceTransformRules $TransformRule       
   


