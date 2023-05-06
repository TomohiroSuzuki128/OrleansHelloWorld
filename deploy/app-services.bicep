param appName string
param location string
param vnetSubnetFrontEndOutboundId string
param vnetSubnetAppServiceOutbound01Id string
param vnetSubnetAppServiceOutbound02Id string
param storageConnectionString string

var httploggingRetentionDays = '7'

// App Service Plans
resource app_plan_frontend 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'Plan${appName}Frontend'
  location: location
  kind: 'app'
  sku: {
    name: 'B1'
    capacity: 1
  }
}

resource app_plan_silo01 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'Plan${appName}Silo01'
  location: location
  kind: 'app'
  sku: {
    name: 'B1'
    capacity: 1
  }
}

resource app_plan_silo02 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'Plan${appName}Silo02'
  location: location
  kind: 'app'
  sku: {
    name: 'B1'
    capacity: 1
  }
}

// Apps
resource app_frontend 'Microsoft.Web/sites@2022-09-01' = {
  name: 'App${appName}Frontend'
  location: location
  kind: 'app'
  properties: {
    serverFarmId: app_plan_frontend.id
    virtualNetworkSubnetId: vnetSubnetFrontEndOutboundId
    httpsOnly: true
    siteConfig: {
      vnetPrivatePortsCount: 2
      webSocketsEnabled: true
      netFrameworkVersion: 'v7.0'
      appSettings: [
        {
          name: 'ORLEANS_AZURE_STORAGE_CONNECTION_STRING'
          value: storageConnectionString
        }
        {
          name: 'WEBSITE_HTTPLOGGING_RETENTION_DAYS'
          value: httploggingRetentionDays
        }
    ]
      alwaysOn: true
    }
  }
}

resource app_silo01 'Microsoft.Web/sites@2022-09-01' = {
  name: 'App${appName}Silo01'
  location: location
  kind: 'app'
  properties: {
    serverFarmId: app_plan_silo01.id
    virtualNetworkSubnetId: vnetSubnetAppServiceOutbound01Id
    httpsOnly: true
    siteConfig: {
      vnetPrivatePortsCount: 2
      webSocketsEnabled: true
      netFrameworkVersion: 'v7.0'
      appSettings: [
        {
          name: 'ORLEANS_AZURE_STORAGE_CONNECTION_STRING'
          value: storageConnectionString
        }
        {
          name: 'WEBSITE_HTTPLOGGING_RETENTION_DAYS'
          value: httploggingRetentionDays
        }
        {
          name: 'WEBSITE_PRIVATE_IP'
          value: '10.0.10.4'
        }
      ]
      alwaysOn: true
    }
  }
}

resource appServiceSilo02 'Microsoft.Web/sites@2022-09-01' = {
  name: 'App${appName}Silo02'
  location: location
  kind: 'app'
  properties: {
    serverFarmId: app_plan_silo02.id
    virtualNetworkSubnetId: vnetSubnetAppServiceOutbound02Id
    httpsOnly: true
    siteConfig: {
      vnetPrivatePortsCount: 2
      webSocketsEnabled: true
      netFrameworkVersion: 'v7.0'
      appSettings: [
        {
          name: 'ORLEANS_AZURE_STORAGE_CONNECTION_STRING'
          value: storageConnectionString
        }
        {
          name: 'WEBSITE_HTTPLOGGING_RETENTION_DAYS'
          value: httploggingRetentionDays
        }
        {
          name: 'WEBSITE_PRIVATE_IP'
          value: '10.0.10.5'
        }
    ]
      alwaysOn: true
    }
  }
}
