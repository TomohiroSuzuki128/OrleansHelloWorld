param appName string
param location string
param vnetSubnetFrontEndOutboundId string
param vnetSubnetAppServiceOutbound01Id string
param vnetSubnetAppServiceOutbound02Id string

@secure()
param storageConnectionString string

var httploggingRetentionDays = '7'

// App Service Plans
resource appPlanFrontend 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'Plan${appName}Frontend'
  location: location
  kind: 'app'
  sku: {
    name: 'B1'
    capacity: 1
  }
}

resource appPlanSilo01 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'Plan${appName}Silo01'
  location: location
  kind: 'app'
  sku: {
    name: 'B1'
    capacity: 1
  }
}

resource appPlanSilo02 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'Plan${appName}Silo02'
  location: location
  kind: 'app'
  sku: {
    name: 'B1'
    capacity: 1
  }
}

// Apps
resource appFrontend 'Microsoft.Web/sites@2022-09-01' = {
  name: 'App${appName}Frontend'
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appPlanFrontend.id
    virtualNetworkSubnetId: vnetSubnetFrontEndOutboundId
    httpsOnly: true
    siteConfig: {
      vnetPrivatePortsCount: 2
      webSocketsEnabled: true
      metadata :[
        {
          name:'CURRENT_STACK'
          value:'dotnet'
        }
      ]
      netFrameworkVersion: 'v7.0'
      use32BitWorkerProcess: false
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

resource appSilo01 'Microsoft.Web/sites@2022-09-01' = {
  name: 'App${appName}Silo01'
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appPlanSilo01.id
    virtualNetworkSubnetId: vnetSubnetAppServiceOutbound01Id
    httpsOnly: true
    siteConfig: {
      vnetPrivatePortsCount: 2
      webSocketsEnabled: true
      metadata :[
        {
          name:'CURRENT_STACK'
          value:'dotnet'
        }
      ]
      netFrameworkVersion: 'v7.0'
      use32BitWorkerProcess: false
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

resource appSilo02 'Microsoft.Web/sites@2022-09-01' = {
  name: 'App${appName}Silo02'
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appPlanSilo02.id
    virtualNetworkSubnetId: vnetSubnetAppServiceOutbound02Id
    httpsOnly: true
    siteConfig: {
      vnetPrivatePortsCount: 2
      webSocketsEnabled: true
      metadata :[
        {
          name:'CURRENT_STACK'
          value:'dotnet'
        }
      ]
      netFrameworkVersion: 'v7.0'
      use32BitWorkerProcess: false
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

output silo01AppId string = appSilo01.id
output silo02AppId string = appSilo02.id
