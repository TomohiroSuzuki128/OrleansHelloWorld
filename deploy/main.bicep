
param appName string
param location string = resourceGroup().location

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
    storageName: 'storage${toLower(appName)}'
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

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.${appName}.net'
  location: 'global'
  properties: {}
  dependsOn: [
    vnet
  ]
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'VNetLinkPrivateDnsZone${appName}'
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
          privateDnsZoneId: privateDnsZone.id
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
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

resource networkInterfacePepSilo01 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: '${appName}PepSilo01.nic'
  location: location
  tags: {
    name: '${appName}PepSilo01.nic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'privateEndpointIpConfig.${appName}PepSilo01'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet.properties.subnets[1].id
          }
        }
      }
    ]
  }
}

resource networkInterfacePepSilo02 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: '${appName}PepSilo02.nic'
  location: location
  tags: {
    name: '${appName}PepSilo02.nic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'privateEndpointIpConfig.${appName}PepSilo02'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet.properties.subnets[1].id
          }
        }
      }
    ]
  }
}

// https://learn.microsoft.com/ja-jp/azure/app-service/networking/private-endpoint#dns
// Private Endpoint DNS レコード

/*
resource privateDnsZones_privatelink_table_core_windows_net_name_orleanspoc 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones_privatelink_table_core_windows_net_name_resource
  name: 'orleanspoc'
  properties: {
    aRecords: [
      {
        ipv4Address: '10.0.30.4'
      }
    ]
    metadata: {
      creator: 'created by private endpoint OrleansPoCPEPStorage with resource guid d73a4673-f57a-4360-bed2-68b1e3a29ecf'
    }
    ttl: 10
  }
}
*/

/*
resource privateDnsZones_privatelink_azurewebsites_net_name_orleanspoc01 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones_privatelink_azurewebsites_net_name_resource
  name: 'orleanspoc01'
  properties: {
    aRecords: [
      {
        ipv4Address: networkInterfacePepSilo01.properties.ipConfigurations[0].properties.privateIPAddress
      }
    ]
    metadata: {
      creator: 'created by private endpoint OrleansPoCPEP01 with resource guid 5af9b01e-8020-431d-8293-ba61e94eb368'
    }
    ttl: 10
  }
}

resource privateDnsZones_privatelink_azurewebsites_net_name_orleanspoc01_scm 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones_privatelink_azurewebsites_net_name_resource
  name: 'orleanspoc01.scm'
  properties: {
    aRecords: [
      {
        ipv4Address: networkInterfacePepSilo01.properties.ipConfigurations[0].properties.privateIPAddress
      }
    ]
    metadata: {
      creator: 'created by private endpoint OrleansPoCPEP01 with resource guid 5af9b01e-8020-431d-8293-ba61e94eb368'
    }
    ttl: 10
  }
}

resource privateDnsZones_privatelink_azurewebsites_net_name_orleanspoc02 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones_privatelink_azurewebsites_net_name_resource
  name: 'orleanspoc02'
  properties: {
    aRecords: [
      {
        ipv4Address: '10.0.10.5'
      }
    ]
    metadata: {
      creator: 'created by private endpoint OrleansPoCPEP02 with resource guid 01320938-280d-42cb-ba89-a2c4ec3d4abb'
    }
    ttl: 10
  }
}

resource privateDnsZones_privatelink_azurewebsites_net_name_orleanspoc02_scm 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateDnsZones_privatelink_azurewebsites_net_name_resource
  name: 'orleanspoc02.scm'
  properties: {
    aRecords: [
      {
        ipv4Address: '10.0.10.5'
      }
    ]
    metadata: {
      creator: 'created by private endpoint OrleansPoCPEP02 with resource guid 01320938-280d-42cb-ba89-a2c4ec3d4abb'
    }
    ttl: 10
  }
}

resource Microsoft_Network_privateDnsZones_SOA_privateDnsZones_privatelink_azurewebsites_net_name 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
  parent: privateDnsZones_privatelink_azurewebsites_net_name_resource
  name: '@'
  properties: {
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
    ttl: 3600
  }
}

resource Microsoft_Network_privateDnsZones_SOA_privateDnsZones_privatelink_table_core_windows_net_name 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
  parent: privateDnsZones_privatelink_table_core_windows_net_name_resource
  name: '@'
  properties: {
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
    ttl: 3600
  }
}

*/
