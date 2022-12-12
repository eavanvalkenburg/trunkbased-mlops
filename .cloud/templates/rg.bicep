targetScope = 'subscription'

@description('Name of the project, will feed into all other names.')
param projectName string

@description('Specifies the location for all resources.')
param location string

@description('Specifies the name of the resource group.')
param resourceGroupName string = '${projectName}-rg'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  tags: {
    project: projectName
  }
}
