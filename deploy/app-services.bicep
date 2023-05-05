param appNameFrontend string
param appNameSilo01 string
param appNameSilo02 string
param location string
param vnetSubnetId string
param appInsightsInstrumentationKey string
param appInsightsConnectionString string
param storageConnectionString string

resource appServicePlanFrontend 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${appNameFrontend}-plan'
  location: location
  kind: 'app'
  sku: {
    name: 'B1'
    capacity: 1
  }
}

resource appServicePlanSilo01 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${appNameSilo01}-plan'
  location: location
  kind: 'app'
  sku: {
    name: 'B1'
    capacity: 1
  }
}

resource appServicePlanSilo02 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${appNameSilo02}-plan'
  location: location
  kind: 'app'
  sku: {
    name: 'B1'
    capacity: 1
  }
}


resource appServiceSilo01 'Microsoft.Web/sites@2021-03-01' = {
  name: appNameSilo01
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlanSilo01.id
    virtualNetworkSubnetId: vnetSubnetId
    httpsOnly: true
    siteConfig: {
      vnetPrivatePortsCount: 2
      webSocketsEnabled: true
      netFrameworkVersion: 'v7.0'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ORLEANS_AZURE_STORAGE_CONNECTION_STRING'
          value: storageConnectionString
        }
        {
          name: 'ORLEANS_CLUSTER_ID'
          value: 'Default'
        }
      ]
      alwaysOn: true
    }
  }
}


resource appServiceSilo02 'Microsoft.Web/sites@2021-03-01' = {
  name: appNameSilo02
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlanSilo02.id
    virtualNetworkSubnetId: vnetSubnetId
    httpsOnly: true
    siteConfig: {
      vnetPrivatePortsCount: 2
      webSocketsEnabled: true
      netFrameworkVersion: 'v7.0'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ORLEANS_AZURE_STORAGE_CONNECTION_STRING'
          value: storageConnectionString
        }
        {
          name: 'ORLEANS_CLUSTER_ID'
          value: 'Default'
        }
      ]
      alwaysOn: true
    }
  }
}

resource slotConfig 'Microsoft.Web/sites/config@2021-03-01' = {
  name: 'slotConfigNames'
  parent: appService
  properties: {
    appSettingNames: [
      'ORLEANS_CLUSTER_ID'
    ]
  }
}

resource appServiceConfig 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: appService
  name: 'metadata'
  properties: {
    CURRENT_STACK: 'dotnet'
  }
}
