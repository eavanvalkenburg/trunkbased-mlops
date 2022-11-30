param projectName string
param workspaceName string
param location string
param tagValues object

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
param keyVaultName string = replace(workspaceName, 'mlw', 'kv')
param applicationInsightsName string = replace(workspaceName, 'mlw', 'log')

@description('The container registry resource id if you want to create a link to the workspace.')
param containerRegistryName string = replace(workspaceName, '-', '')

@description('Specifies that the Azure Machine Learning workspace holds highly confidential data.')
param confidential_data bool = false

@description('Specifies if the Azure Machine Learning workspace should be encrypted with customer managed key.')
@allowed([
  'Enabled'
  'Disabled'
])
param encryption_status string = 'Disabled'

@description('Specifies the customer managed keyVault arm id.')
param cmk_keyvault string = ''

@description('Specifies if the customer managed keyvault key uri.')
param resource_cmk_uri string = ''

var tenantId = subscription().tenantId

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

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
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

// resource Azure_Role_Key_Vault_Administrator_servicePrincipalObjectId_Microsoft_KeyVault_vaults_keyVault 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
//   scope: keyVault
//   name: guid('Azure Role Key Vault Administrator', servicePrincipalObjectId, keyVault.id)
//   properties: {
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
//     principalId: servicePrincipalObjectId
//     principalType: 'ServicePrincipal'
//   }
//   dependsOn: [
//     keyVault_var
//   ]
// }

resource applicationInsights 'Microsoft.Insights/components@2018-05-01-preview' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
  tags: tagValues
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2019-05-01' = {
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
    keyVault: keyVault.id
    applicationInsights: applicationInsights.id
    containerRegistry: (empty(containerRegistryName) ? json('null') : containerRegistry.id)
    description: 'Workspace for project: ${projectName}.'
    encryption: {
      status: encryption_status
      keyVaultProperties: {
        keyVaultArmId: cmk_keyvault
        keyIdentifier: resource_cmk_uri
      }
    }
    hbiWorkspace: confidential_data
  }
  tags: tagValues
}

output workspaceId string = workspace.id
