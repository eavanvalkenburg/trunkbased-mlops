param location string
@description('Name for the keyvault.')
param keyvaultName string
param tagValues object
@description('Resource group of the existing keyvault.')
param keyvaultResourceGroup string = ''
@secure()
param secretsManagementObjectId string

var tenantId = subscription().tenantId
var newOrExisting = empty(keyvaultResourceGroup) ? 'new' : 'existing'

var rg_name = empty(keyvaultResourceGroup) ? resourceGroup().name : keyvaultResourceGroup

resource keyvault_new 'Microsoft.KeyVault/vaults@2022-07-01' = if (newOrExisting == 'new') {
  name: keyvaultName
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableRbacAuthorization: true
    accessPolicies: []
  }
  tags: tagValues
}

resource keyvault_existing 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (newOrExisting == 'existing') {
  name: keyvaultName
  scope: resourceGroup(rg_name)
}

module auth 'keyvault_authorization.bicep' = {
  name: keyvaultName
  scope: resourceGroup(rg_name)
  params: {
    keyvaultName: keyvaultName
    secretsManagementObjectId: secretsManagementObjectId
  }
}

output keyvaultObject object = keyvault_new ?? keyvault_existing
