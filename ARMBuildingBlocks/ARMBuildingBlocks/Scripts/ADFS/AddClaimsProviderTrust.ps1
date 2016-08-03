Param(
  [Parameter(Mandatory=$True)]
  [string]$ClaimsProviderName,

  [Parameter(Mandatory=$True)]
  [string]$MetadataUrl,

  [Parameter(Mandatory=$True)]
  [string]$TransformRule

)


# this script will add the claims provider on Resource ADFS
# it must be ran on Resource ADFS 
# it is high privilege operation and needs to be ran as domain admin
# the metadata must point to Account ADFS

# example

# ./AddClaimsProviderTrust -ClaimsProviderName 'Resource Account Adfs' -MetadataUrl 'https://pnpadfs.patternspractices.com/FederationMetadata/2007-06/FederationMetadata.xml' -TransformRule ‘c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"] => issue(claim = c);’
  
   
  Add-AdfsClaimsProviderTrust -Name $ClaimsProviderName `
  -AutoUpdateEnabled $true `
   -MetadataUrl $MetadataUrl  `
   -AcceptanceTransformRules $TransformRule  





