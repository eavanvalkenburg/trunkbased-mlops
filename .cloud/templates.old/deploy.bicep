@description('Resource group where \'Data\' resources will be provisioned')
param resourceGroupName string

@description('Specifies the location for all resources.')
param location string

@description('Specifies the name of the Azure Machine Learning workspace.')
param workspaceName string

@description('The name of the administrator user account which can be used to SSH into nodes. It must only contain lower case alphabetic characters [a-z].')
@secure()
param computeAdminUserName string

@description('The password of the administrator user account.')
@secure()
param computeAdminUserPassword string

@description('The VM size for the CPU compute train cluster')
param cpuTrainComputeSize string

@description('The VM size for the CPU compute train cluster')
param gpuTrainComputeSize string

@description('The number of nodes for the CPU compute train cluster')
param cpuTrainNodeCount int

@description('The number of nodes for the CPU compute train cluster')
param gpuTrainNodeCount int

@description('The priority of the CPU compute train cluster')
param cpuPriority string

@description('The priority of the GPU compute train cluster')
param gpuPriority string

@description('Name of the storage account where datasets will be placed')
param datasetsAccountName string

@description('Name of the resource group where the storage account for datasets is placed')
param datasetsResourceGroup string

@description('Name of the file system where datasets will be placed')
param datasetsFileSystem string

@description('Client ID used to query data from the account')
@secure()
param datasetsClientId string

@description('Client secret used to query data from the account')
@secure()
param datasetsClientSecret string

@description('Object ID used for managing secrets in Key Vault')
@secure()
param secretsManagementObjectId string

var workspaceDeploymentName = 'azureml-${deployment().name}'

module workspaceDeployment 'workspace/workspace.bicep' = {
  name: workspaceDeploymentName
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    resourceGroupName: resourceGroupName
    workspaceName: workspaceName
    servicePrincipalObjectId: secretsManagementObjectId
    tagValues: {
      workspace: workspaceName
    }
  }
}

module cpu_compute_workspaceDeployment 'workspace/compute/cluster.bicep' = {
  name: 'cpu-compute-${workspaceDeploymentName}'
  scope: resourceGroup(resourceGroupName)
  params: {
    workspaceName: workspaceName
    clusterName: 'cpuprdev'
    location: location
    adminUserName: computeAdminUserName
    adminUserPassword: computeAdminUserPassword
    maxNodeCount: cpuTrainNodeCount
    vmSize: cpuTrainComputeSize
    vmPriority: cpuPriority
  }
  dependsOn: [
    workspaceDeploymentName
  ]
}

module gpu_compute_workspaceDeployment 'workspace/compute/cluster.bicep' = {
  name: 'gpu-compute-${workspaceDeploymentName}'
  scope: resourceGroup(resourceGroupName)
  params: {
    workspaceName: workspaceName
    clusterName: 'gpuprdev'
    location: location
    adminUserName: computeAdminUserName
    adminUserPassword: computeAdminUserPassword
    maxNodeCount: gpuTrainNodeCount
    vmSize: gpuTrainComputeSize
    vmPriority: gpuPriority
  }
  dependsOn: [
    workspaceDeploymentName
  ]
}

module datasource_trusted_workspaceDeployment 'workspace/source/adlg2.bicep' = {
  name: 'datasource-trusted-${workspaceDeploymentName}'
  scope: resourceGroup(resourceGroupName)
  params: {
    workspaceName: workspaceName
    datastoreName: 'trusted'
    storageAccountResourceGroup: datasetsResourceGroup
    accountName: datasetsAccountName
    fileSystem: datasetsFileSystem
    clientId: datasetsClientId
    clientSecret: datasetsClientSecret
  }
  dependsOn: [
    workspaceDeploymentName
  ]
}