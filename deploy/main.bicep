
param appName string
param location string = resourceGroup().location

/*
param actiongroups_application_insights_smart_detection_externalid string
param components_orleanspoc_externalid string
param networkInterfaces_OrleansPoCPEP01_nic_e02393a1_5ed9_4333_bc3b_328eb5bb9645_name string
param networkInterfaces_OrleansPoCPEP02_nic_6b1d3be4_0f85_49fc_914b_0c6cc345e776_name string
param networkInterfaces_OrleansPoCPEPStorage_nic_name string
param privateDnsZones_privatelink_azurewebsites_net_name string
param privateDnsZones_privatelink_table_core_windows_net_name string
param privateEndpoints_OrleansPoCPEP01_name string
param privateEndpoints_OrleansPoCPEP02_name string
param privateEndpoints_OrleansPoCPEPStorage_name string
param serverfarms_OrleansPoC02_name string
param serverfarms_OrleansPoCFrontEnd_name string
param serverfarms_OrleansPoc01_name string
param sites_orleanspoc01_name string
param sites_orleanspoc02_name string
param sites_orleanspocfrontend_name string
param smartdetectoralertrules_failure_anomalies_orleanspoc_name string
param storageAccounts_orleanspoc_name string
*/


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
    storageName: '${appName}storage'
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
