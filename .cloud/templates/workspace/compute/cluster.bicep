@description('Specifies the name of the Azure Machine Learning Workspace which will contain this compute.')
param workspaceName string

@description('Specifies the name of the Azure Machine Learning Compute cluster.')
param clusterName string

@description(' The maximum number of nodes to use on the cluster. If not specified, defaults to 4.')
param maxNodeCount int = 1

@description('The location of the Azure Machine Learning Workspace.')
param location string

@description('The name of the administrator user account which can be used to SSH into nodes. It must only contain lower case alphabetic characters [a-z].')
@secure()
param adminUserName string

@description('The password of the administrator user account.')
@secure()
param adminUserPassword string

@description(' The size of agent VMs. More details can be found here: https://aka.ms/azureml-vm-details.')
param vmSize string = 'Standard_D2s_v3'

@description('The priority of the virtual machine. The value can be either \'Dedicated\' or \'LowPriority\'.')
@allowed([
  'Dedicated'
  'LowPriority'
])
param vmPriority string = 'LowPriority'

@description('Name of the resource group which holds the VNET to which you want to inject your compute in.')
param vnetResourceGroupName string = ''

@description('Name of the vnet which you want to inject your compute in.')
param vnetName string = ''

@description('Name of the subnet inside the VNET which you want to inject your compute in.')
param subnetName string = ''

var subnet = {
  id: resourceId(vnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
}

resource workspaceName_cluster 'Microsoft.MachineLearningServices/workspaces/computes@2022-10-01' = {
  name: '${workspaceName}/${clusterName}'
  location: location
  properties: {
    computeType: 'AmlCompute'
    properties: {
      vmSize: vmSize
      scaleSettings: {
        minNodeCount: 0
        maxNodeCount: maxNodeCount
      }
      userAccountCredentials: {
        adminUserName: adminUserName
        adminUserPassword: adminUserPassword
      }
      subnet: (((!empty(vnetResourceGroupName)) && (!empty(vnetName)) && (!empty(subnetName))) ? subnet : json('null'))
      vmPriority: vmPriority
    }
  }
}
