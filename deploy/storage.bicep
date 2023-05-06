param storageName string
param location string
param vnetSubnetFrontEndOutboundId string
param vnetSubnetAppServiceOutbound01Id string
param vnetSubnetAppServiceOutbound02Id string

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      resourceAccessRules: []
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: vnetSubnetAppServiceOutbound01Id
        }
        {
          action: 'Allow'
          id: vnetSubnetAppServiceOutbound02Id
        }
        {
          action: 'Allow'
          id: vnetSubnetFrontEndOutboundId
        }
      ]
    }
  }
}

var key = listKeys(storage.name, storage.apiVersion).keys[0].value
var protocol = 'DefaultEndpointsProtocol=https'
var accountBits = 'AccountName=${storage.name};AccountKey=${key}'
var endpointSuffix = 'EndpointSuffix=${environment().suffixes.storage}'

output connectionString string = '${protocol};${accountBits};${endpointSuffix}'
