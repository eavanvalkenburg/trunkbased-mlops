param projectName string
param mlworkspace string
param location string
param tagValues object

param databricksName string = '${projectName}-adb'

@description('The pricing tier of workspace.')
@allowed([
  'standard'
  'premium'
])
param pricingTier string = 'premium'

@description('Specifies whether to deploy Azure Databricks workspace with Secure Cluster Connectivity (No Public IP) enabled or not')
param disablePublicIp bool = false

var managedResourceGroupName = 'databricks-rg-${databricksName}-${uniqueString(databricksName, resourceGroup().id)}'

resource adb 'Microsoft.Databricks/workspaces@2022-04-01-preview' = {
  name: databricksName
  location: location
  sku: {
    name: pricingTier
  }
  properties: {
    managedResourceGroupId: managedResourceGroup.id
    parameters: {
      enableNoPublicIp: {
        value: disablePublicIp
      }
      amlWorkspaceId: {
        value: mlworkspace
      }
    }
  }
  tags: tagValues
}

resource managedResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  scope: subscription()
  name: managedResourceGroupName
}

