@description('Specifies the name of the Azure Machine Learning workspace which will hold this datastore target.')
param workspaceName string

@description('The name of the datastore, case insensitive, can only contain alphanumeric characters and underscore')
param datastoreName string

@description('The name of the storage account.')
param accountName string

@description('The file system name of the ADLS Gen2.')
param fileSystem string

@description('The service principal Tenant ID.')
param tenantId string = subscription().tenantId

@description('The service principal\'s client/application ID.')
param clientId string

@description('The service principal\'s secret.')
@secure()
param clientSecret string

@description('Optional : The subscription ID of the storage account. Defaults to selected subscription')
param storageAccountSubscriptionId string = subscription().subscriptionId

@description('Optional : The resource group of the storage account. Defaults to selected resource group')
param storageAccountResourceGroup string = resourceGroup().name

@description('Optional : Determines what operations will be performed on the data lake store.')
param resourceUrl string = 'https://storage.azure.com/'

@description('Optional : Authority url used to authenticate the user.')
param authorityUrl string = 'https://login.microsoftonline.com'

@description('Optional : If set to true, the call will skip Datastore validation. Defaults to false')
param skipValidation bool = false

@description('The location of the Azure Machine Learning Workspace.')
param location string = resourceGroup().location

var tenantId_var = subscription().tenantId

resource workspaceName_datastore 'Microsoft.MachineLearningServices/workspaces/datastores@2020-05-01-preview' = {
  name: '${workspaceName}/${datastoreName}'
  location: location
  properties: {
    dataStoreType: 'adls-gen2'
    SkipValidation: skipValidation
    ClientId: clientId
    ClientSecret: clientSecret
    FileSystem: fileSystem
    AccountName: accountName
    TenantId: tenantId_var
    ResourceUrl: resourceUrl
    AuthorityUrl: authorityUrl
    SubscriptionId: storageAccountSubscriptionId
    ResourceGroupName: storageAccountResourceGroup
  }
}