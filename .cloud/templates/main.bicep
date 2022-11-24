targetScope = 'subscription'

@description('Name of the project, will feed into all other names.')
param projectName string

@description('Specifies the location for all resources.')
param location string

@description('The VM size for the CPU compute train cluster. More details can be found here: https://aka.ms/azureml-vm-details.')
@allowed([
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_D8s_v3'
  'Standard_E4a_v4'
  'Standard_E8a_v4'
  'Standard_E48a_v4'
  'Standard_HB120rs_v3'
])
param cpuTrainComputeSize string = 'Standard_D4s_v3'

@description('The VM size for the GPU compute train cluster. More details can be found here: https://aka.ms/azureml-vm-details.')
@allowed([
  'Standard_NC6s_v3'
  'Standard_NC12s_v3'
  'Standard_ND40rs_v2'
  'Standard_NV12s_v3'
  'Standard_NV24s_v3'
  'Standard_NV48s_v3'
  'Standard_ND96asr_v4'
])
param gpuTrainComputeSize string = 'Standard_NC6s_v3'

@description('The maximum number of nodes for the CPU compute train cluster')
@minValue(1)
@maxValue(100)
param cpuTrainNodeCount int

@description('The maximum number of nodes for the CPU compute train cluster')
@minValue(1)
@maxValue(12)
param gpuTrainNodeCount int

@description('The priority of the CPU compute train cluster, default is LowPriority.')
@allowed([
  'Dedicated'
  'LowPriority'
])
param cpuPriority string = 'LowPriority'

@description('The priority of the GPU compute train cluster, default is LowPriority.')
@allowed([
  'Dedicated'
  'LowPriority'
])
param gpuPriority string = 'LowPriority'

@description('The name of the administrator user account which can be used to SSH into nodes. It must only contain lower case alphabetic characters [a-z].')
@secure()
param computeAdminUserName string

@description('The password of the administrator user account.')
@secure()
param computeAdminUserPassword string

var workspaceDeploymentName = 'azureml-${deployment().name}'
var resourceGroupName = '${projectName}-rg'
var workspaceName = '${projectName}-aml'


resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module workspaceDeployment 'workspace/workspace.bicep' = {
  name: workspaceDeploymentName
  scope: rg
  params: {
    projectName: projectName
    location: rg.location
    workspaceName: workspaceName
    tagValues: {
      workspace: workspaceName
      project: projectName
    }
  }
}

module cpu_compute_workspaceDeployment 'workspace/compute/cluster.bicep' = {
  name: 'cpu-compute-${workspaceDeploymentName}'
  scope: rg
  params: {
    workspaceName: workspaceName
    clusterName: 'cpu_cluster'
    location: rg.location
    maxNodeCount: cpuTrainNodeCount
    vmSize: cpuTrainComputeSize
    vmPriority: cpuPriority
    adminUserName: computeAdminUserName
    adminUserPassword: computeAdminUserPassword
  }
  dependsOn: [
    workspaceDeployment
  ]
}

module gpu_compute_workspaceDeployment 'workspace/compute/cluster.bicep' = {
  name: 'gpu-compute-${workspaceDeploymentName}'
  scope: rg
  params: {
    workspaceName: workspaceName
    clusterName: 'gpu_cluster'
    location: rg.location
    maxNodeCount: gpuTrainNodeCount
    vmSize: gpuTrainComputeSize
    vmPriority: gpuPriority
    adminUserName: computeAdminUserName
    adminUserPassword: computeAdminUserPassword
  }
  dependsOn: [
    workspaceDeployment
  ]
}
