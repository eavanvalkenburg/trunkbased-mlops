param projectName string
param location string

resource databricks 'Microsoft.Databricks/workspaces@2022-04-01-preview' = {
  name: '${projectName}-adb'
  location: location
}
