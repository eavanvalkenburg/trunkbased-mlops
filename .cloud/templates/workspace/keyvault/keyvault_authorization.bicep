param keyvaultName string

@secure()
param secretsManagementObjectId string

resource keyvault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyvaultName
}

resource Azure_Role_Key_Vault_Administrator_servicePrincipalObjectId_Microsoft_KeyVault_vaults_keyVault 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyvault
  name: guid('Azure Role Key Vault Administrator', secretsManagementObjectId, keyvault.id)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
    principalId: secretsManagementObjectId
    principalType: 'ServicePrincipal'
  }
}
