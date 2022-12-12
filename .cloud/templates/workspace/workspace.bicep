// Overall variables
param projectName string
param workspaceName string
param location string
param tagValues object

// Storage variables
@description('Name of the storage account used for the workspace.')
param storageAccountName string = replace(workspaceName, '-', '')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageAccountType string = 'Standard_LRS'

// Keyvault variables
@description('Name of the keyvault used for the workspace, if you want to use a existing keyvault also specify the resource group in keyvaultResourcegroup.')
param keyvaultName string = replace(workspaceName, 'aml', 'kv')
@description('Specifies the resource group of the keyvault with name defined, leave empty to create a new one.')
param keyvaultResourcegroup string = ''
@description('The object id for secrets management.')
@secure()
param secretsManagementObjectId string
@description('URI of item in keyvault for the customer managed key. Can only be used in combination with a existing keyvault.')
param CustomerManagedKeyURI string = ''

// Application insights and container registry variables
param applicationInsightsName string = replace(workspaceName, 'aml', 'log')
@description('The container registry resource id if you want to create a link to the workspace.')
param containerRegistryName string = replace(workspaceName, '-aml', 'acr')

// Workspace variables
@description('Specifies that the Azure Machine Learning workspace holds highly confidential data.')
param confidential_data bool = false
@description('Specifies if the Azure Machine Learning workspace should be encrypted with customer managed key.')
@allowed([
  'Enabled'
  'Disabled'
])
param encryption_status string = 'Disabled'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    supportsHttpsTrafficOnly: true
  }
  tags: tagValues
}

module kv 'keyvault/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    keyvaultName: keyvaultName
    location: location
    tagValues: tagValues
    keyvaultResourceGroup: keyvaultResourcegroup
    secretsManagementObjectId: secretsManagementObjectId
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
  tags: tagValues
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
  tags: tagValues
}

resource workspace 'Microsoft.MachineLearningServices/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    tier: 'Standard'
    name: 'Standard'
  }
  properties: {
    friendlyName: workspaceName
    storageAccount: storageAccount.id
    keyVault: kv.outputs.keyvaultObject.id
    applicationInsights: applicationInsights.id
    containerRegistry: (empty(containerRegistryName) ? json('null') : containerRegistry.id)
    description: 'Workspace for project: ${projectName}.'
    encryption: {
      status: encryption_status
      keyVaultProperties: {
        keyVaultArmId: kv.outputs.keyvaultObject.id
        keyIdentifier: CustomerManagedKeyURI
      }
    }
    hbiWorkspace: confidential_data
  }
  tags: tagValues
}
