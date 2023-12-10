// Main.bicep

param containerRegistryName string
param location string
param webAppName string
param appServicePlanName string
param containerRegistryImageName string
param containerRegistryImageVersion string
param keyVaultName string

param kevVaultSecretNameACRUsername string = 'acr-username'
param kevVaultSecretNameACRPassword1 string = 'acr-password1'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

module servicePlan './ResourceModules-main/modules/web/serverfarm/main.bicep' = {
  name: appServicePlanName
  params: {
    name: appServicePlanName
    location: location
    sku: {
      capacity: 1
      family: 'B'
      name: 'B1'
      size: 'B1'
      tier: 'Basic'
    }
    reserved: true
  }
}

module webApp './ResourceModules-main/modules/web/site/main.bicep' = {
  name: webAppName
  dependsOn: [
    servicePlan
    acr
    keyvault
  ]
  params: {
    name: webAppName
    location: location
    kind: 'app'
    serverFarmResourceId: servicePlan.outputs.resourceId
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/${containerRegistryImageName}:${containerRegistryImageVersion}'
      appCommandLine: ''
    }
    appSettingsKeyValuePairs: {
      WEBSITES_ENABLE_APP_SERVICE_STORAGE: false
    }
    dockerRegistryServerUrl: 'https://${containerRegistryName}.azurecr.io'
    dockerRegistryServerUserName: keyvault.getSecret(kevVaultSecretNameACRUsername)
    dockerRegistryServerPassword: keyvault.getSecret(kevVaultSecretNameACRPassword1)
  }
}
