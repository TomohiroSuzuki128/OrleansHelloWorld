param appName string
param location string = resourceGroup().location

var storageName = 'storage${toLower(appName)}'

// VNet
resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: 'VNet${appName}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      // 0
      {
        name: 'FrontEndOutbound'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: [
            {
              locations: [
                location
              ]
              service: 'Microsoft.Storage'
            }
          ]
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      // 1
      {
        name: 'AppServiceInbound'
        properties: {
          addressPrefix: '10.0.10.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: []
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      // 2
      {
        name: 'AppServiceOutbound01'
        properties: {
          addressPrefix: '10.0.21.0/24'
          delegations: [
            {
              name: 'Microsoft.Web.serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: [
            {
              locations: [
                location
              ]
              service: 'Microsoft.Storage'
            }
          ]
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      // 3
      {
        name: 'AppServiceOutbound02'
        properties: {
          addressPrefix: '10.0.22.0/24'
          delegations: [
            {
              name: 'Microsoft.Web.serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: [
            {
              locations: [
                location
              ]
              service: 'Microsoft.Storage'
            }
          ]
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      // 4
      {
        name: 'StorageInbound'
        properties: {
          addressPrefix: '10.0.30.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: []
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
  }
}

module storageModule 'storage.bicep' = {
  name: 'orleansStorageModule'
  params: {
    storageName: storageName
    location: location
    vnetSubnetFrontEndOutboundId: vnet.properties.subnets[0].id
    vnetSubnetAppServiceOutbound01Id: vnet.properties.subnets[2].id
    vnetSubnetAppServiceOutbound02Id: vnet.properties.subnets[3].id
  }
}

module appModule 'app-services.bicep' = {
  name: 'orleansSiloModule'
  params: {
    appName: appName
    location: location
    vnetSubnetFrontEndOutboundId: vnet.properties.subnets[0].id
    vnetSubnetAppServiceOutbound01Id: vnet.properties.subnets[2].id
    vnetSubnetAppServiceOutbound02Id: vnet.properties.subnets[3].id
    storageConnectionString: storageModule.outputs.connectionString
  }
}

// Private Endpoint
resource privateEndpointSilo01 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: 'Pep${appName}Silo01'
  location: location
  properties: {
    subnet: {
      id: vnet.properties.subnets[1].id
    }
    privateLinkServiceConnections: [
      {
        name: 'Pep${appName}Silo01'
        properties: {
          privateLinkServiceId: appModule.outputs.silo01AppId
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource privateEndpointSilo02 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: 'Pep${appName}Silo02'
  location: location
  properties: {
    subnet: {
      id: vnet.properties.subnets[1].id
    }
    privateLinkServiceConnections: [
      {
        name: 'Pep${appName}Silo02'
        properties: {
          privateLinkServiceId: appModule.outputs.silo02AppId
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource privateEndpointTableStorage 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: 'Pep${appName}TableStorage'
  location: location
  properties: {
    subnet: {
      id: vnet.properties.subnets[4].id
    }
    privateLinkServiceConnections: [
      {
        name: 'Pep${appName}TableStorage'
        properties: {
          privateLinkServiceId: storageModule.outputs.storageId
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneApp 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurewebsites'
  location: 'global'
  properties: {}
  dependsOn: [
    vnet
  ]
}

resource privateDnsZoneTableStorage 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.table.core'
  location: 'global'
  properties: {}
    dependsOn: [
      vnet
    ]
}

resource privateDnsZoneLinkApp 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZoneApp
  name: 'VNetLinkPrivateDnsZoneApp'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource privateDnsZoneLinkTableStorage 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZoneTableStorage
  name: 'VNetLinkPrivateDnsZoneTableStorage'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource privateEndpointDnsGroupSilo01 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: privateEndpointSilo01
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurewebsites-net'
        properties: {
          privateDnsZoneId: privateDnsZoneApp.id
        }
      }
    ]
  }
}

resource privateEndpointDnsGroupSilo02 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: privateEndpointSilo02
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurewebsites-net'
        properties: {
          privateDnsZoneId: privateDnsZoneApp.id
        }
      }
    ]
  }
}

resource privateEndpointDnsGroupTableStorage 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: privateEndpointTableStorage
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurewebsites-net'
        properties: {
          privateDnsZoneId: privateDnsZoneApp.id
        }
      }
    ]
  }
}

// https://learn.microsoft.com/ja-jp/azure/app-service/networking/private-endpoint#dns
// Private Endpoint DNS レコード

resource privateDnsZonesRecordTableStorage 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZoneTableStorage
  name: storageName
  properties: {
    aRecords: [
      {
        ipv4Address: '10.0.30.4'
      }
    ]
    ttl: 10
  }
}

resource privateDnsZonesRecordSilo01 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZoneApp
  name: toLower('App${appName}Silo01')
  properties: {
    aRecords: [
      {
        ipv4Address: '10.0.10.4'
      }
    ]
    ttl: 10
  }
}

resource privateDnsZonesRecordSilo01Scm 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZoneApp
  name: toLower('App${appName}Silo01.scm')
  properties: {
    aRecords: [
      {
        ipv4Address: '10.0.10.4'
      }
    ]
    ttl: 10
  }
}

resource privateDnsZonesRecordSilo02 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZoneApp
  name: toLower('App${appName}Silo02')
  properties: {
    aRecords: [
      {
        ipv4Address: '10.0.10.5'
      }
    ]
    ttl: 10
  }
}

resource privateDnsZonesRecordSilo02Scm 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZoneApp
  name: toLower('App${appName}Silo02.scm')
  properties: {
    aRecords: [
      {
        ipv4Address: '10.0.10.5'
      }
    ]
    ttl: 10
  }
}
