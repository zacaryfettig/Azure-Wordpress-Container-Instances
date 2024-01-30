/*
//creating Resource Group
resource "azurerm_resource_group" "resourceGroup" {
  name     = var.resourceGroupName
  location = var.location
}
*/
/*
resource "random_id" "front_door_endpoint_name" {
  byte_length = 8
}



locals {
  frontDoorEndpointName     = "afd-${lower(random_id.front_door_endpoint_name.hex)}"
}

resource "azurerm_cdn_frontdoor_profile" "frontDoorProfile" {
  name                = "frontDoorProfile"
  resource_group_name = "rg1"
  sku_name            = "Premium_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "my_endpoint" {
  name                     = local.frontDoorEndpointName
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontDoorProfile.id
}

resource "azurerm_cdn_frontdoor_origin_group" "frontDoorOriginGroup1" {
  name                     = "frontDoorOrginGroup1"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontDoorProfile.id
  session_affinity_enabled = true

  

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_route" "frontdoorRouteDefault" {
  name                          = "frontdoorRouteDefault"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.my_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontDoorOriginGroup1.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.westusServiceOrigin.id]
  enabled                       = true

  forwarding_protocol    = "MatchRequest"
  https_redirect_enabled = false
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  link_to_default_domain          = true

  cache {
    query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
    query_strings                 = ["account", "settings"]
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/javascript", "text/xml"]
  }
}


resource "azurerm_cdn_frontdoor_origin" "westusServiceOrigin" {
  name                          = "westusServiceOrigin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontDoorOriginGroup1.id

  enabled                        = true
  host_name                      = azurerm_container_group.containerGroup.ip_address
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_container_group.containerGroup.ip_address
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
  
  private_link {
    location = "westus"
    private_link_target_id = azurerm_container_group.containerGroup.id
  }
}

resource "azurerm_lb" "containerInstancesLb" {
  name                = "containerInstancesLb"
  location            = "westus"
  resource_group_name = "rg1"

  frontend_ip_configuration {
    name                 = "PrivateIPLb"
    private_ip_address = "10.0.1.6"
    private_ip_address_allocation = "static"
    subnet_id = azurerm_subnet.subnetContainer.id
  }
}

resource "azurerm_lb_backend_address_pool" "backEndAddressPool" {
  loadbalancer_id = azurerm_lb.containerInstancesLb.id
  name            = "BackEndAddressPool"
  virtual_network_id = azurerm_virtual_network.wordpressVnet.id
}

resource "azurerm_lb_backend_address_pool_address" "example-1" {
  name                                = "address1"
  backend_address_pool_id             = azurerm_lb_backend_address_pool.backEndAddressPool.id
  backend_address_ip_configuration_id = azurerm_lb.backend-lb-R1.frontend_ip_configuration[0].id
} 

data "azurerm_subscription" "subscription" {
  
}

resource "azurerm_private_link_service" "frontDoorPrivateLinkService" {
  name                = "frontDoorPrivateLinkService"
  resource_group_name = "rg1"
  location            = "westus"

  auto_approval_subscription_ids              = azurerm_subscription.subscription
  visibility_subscription_ids                 = azurerm_subscription.subscription
  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.containerInstancesLb.frontend_ip_configuration.0.id]

  nat_ip_configuration {
    name                       = "primary"
    private_ip_address         = "10.0.1.7"
    private_ip_address_version = "IPv4"
    subnet_id                  = azurerm_subnet.subnetContainer.id
    primary                    = true
  }
}




//resource "azurerm_cdn_frontdoor_origin" "ukSouthServiceOrigin" {
//  name                          = "ukSouthServiceOrigin"
//  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontDoorOriginGroup1.id
//
//  enabled                        = true
//  host_name                      = azurerm_windows_web_app.app.default_hostname
//  http_port                      = 80
//  https_port                     = 443
//  origin_host_header             = azurerm_windows_web_app.app.default_hostname
//  priority                       = 1
//  weight                         = 1000
//  certificate_name_check_enabled = true
//}

*/

resource "random_string" "random" {
  length = 6
  special = false
  upper = false
}

resource "azurerm_public_ip" "appGatewayPublicIP" {
  name                = "appGatewayPublicIP"
  resource_group_name = "rg1"
  location            = "westus"
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_application_gateway" "appGateway" {
  name                = "appGateway"
  resource_group_name = "rg1"
  location            = "westus"

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "gatewayIPConfiguration"
    subnet_id = azurerm_subnet.applicationGatewaySubnet.id
  }

  frontend_port {
    name = "gatewayFrontendPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "gatewayFrontEndName"
    public_ip_address_id = azurerm_public_ip.appGatewayPublicIP.id
  }

  backend_address_pool {
    name = "gatewayBackendAddressPool"
    ip_addresses = [azurerm_container_group.containerGroup.ip_address]
  }

  backend_http_settings {
    name                  = "gatewayHTTPSetting"
    cookie_based_affinity = "Disabled"
    path                  = ""
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "gatewayHTTPListener"
    frontend_ip_configuration_name = "gatewayFrontEndName"
    frontend_port_name             = "gatewayFrontendPort"
    protocol                       = "Http"
  }

    request_routing_rule {
    name                       = "gatewayRoutingRule"
    rule_type                  = "Basic"
    http_listener_name         = "gatewayHTTPListener"
    backend_address_pool_name  = "gatewayBackendAddressPool"
    backend_http_settings_name = "gatewayHTTPSetting"
    priority = 1
  }
}






locals {
 mySqlServerName = "mysqlserver${random_string.random.result}"
}

/*
resource "azurerm_private_dns_zone" "dnsPrivateZone" {
  name                = "wordpress.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.resourceGroup.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszonelink" {
  name = "dnszonelink"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  virtual_network_id = azurerm_virtual_network.wordpressVnet.id
  private_dns_zone_name = azurerm_private_dns_zone.dnsPrivateZone.name
}
*/


resource "azurerm_private_dns_zone" "fileDnsPrivateZone" {
  name                = "file.core.windows.net"
  resource_group_name = "rg1"
}

resource "azurerm_private_dns_zone_virtual_network_link" "fileDnsZoneLink" {
  name = "dnszonelink"
  resource_group_name = "rg1"
  virtual_network_id = azurerm_virtual_network.wordpressVnet.id
  private_dns_zone_name = azurerm_private_dns_zone.fileDnsPrivateZone.name
}

resource "azurerm_private_dns_a_record" "storageDNS" {
  name                = azurerm_storage_account.storageAccount.name
  zone_name           = azurerm_private_dns_zone.fileDnsPrivateZone.name
  resource_group_name = "rg1"
  ttl                 = 300
  records             = ["10.0.5.10"]
  depends_on = [ azurerm_private_endpoint.storageAccountEndpoint ]
}

resource "azurerm_container_group" "containerGroup" {
  name                = "containerGroup"
  location            = "westus"
  resource_group_name = "rg1"
  ip_address_type     = "Private"
  os_type             = "Linux"

  subnet_ids = [azurerm_subnet.subnetContainer.id]

  container {
    name   = "wordpress"
    image  = "wordpress"
    cpu    = "0.5"
    memory = "0.5"

        ports {
      port     = 80
      protocol = "TCP"
    }

            ports {
      port     = 443
      protocol = "TCP"
    }

    environment_variables = {
      "WORDPRESS_DB_HOST" = local.mySqlServerName
      "WORDPRESS_DB_USER" = "mysqladmin"
      "WORDPRESS_DB_PASSWORD" = var.sqlPassword
      "WORDPRESS_DB_NAME" = "mysqldb"
    }

    volume {
      name = "wordpress"
      storage_account_name = azurerm_storage_account.storageAccount.name
      mount_path = "/var/www/html"
      share_name = "wordpress"
      storage_account_key = azurerm_storage_account.storageAccount.primary_access_key

    }
  }
  
        depends_on = [
    azurerm_storage_share.storageShareFile,
    azurerm_private_endpoint.storageAccountEndpoint
  ]
}

resource "azurerm_storage_account" "storageAccount" {
  name                     = "storage${random_string.random.result}"
  resource_group_name      = "rg1"
  location                 = "westus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = true
}

resource "azurerm_private_endpoint" "storageAccountEndpoint" {
  name                = "storageAccountEndpoint"
  location            = "westus"
  resource_group_name = "rg1"
  subnet_id           = azurerm_subnet.storageAccountSubnet.id
  ip_configuration {
    name = "StorageAccountIP"
    private_ip_address = "10.0.5.10"
    subresource_name = "file"
    member_name = "file"
  }

  private_service_connection {
    name                           = "storageEndpoint"
    private_connection_resource_id = azurerm_storage_account.storageAccount.id
    is_manual_connection           = false
    subresource_names = ["file"]
  }
  depends_on = [ azurerm_storage_share.storageShareFile ]
}

resource "azurerm_storage_account_network_rules" "storageNetworkRule" {
  storage_account_id = azurerm_storage_account.storageAccount.id
  default_action             = "Deny"
  /*
  bypass                     = ["AzureServices"]
  */
  depends_on = [ azurerm_redis_cache.redisCacheMysql,
  azurerm_storage_share.storageShareFile,
  null_resource.parameterChange,
  null_resource.storageUploadConfig
  //null_resource.storageUpload
  ]
}


resource "azurerm_storage_share" "storageShareFile" {
  name                 = "wordpress"
  storage_account_name = azurerm_storage_account.storageAccount.name
  quota                = 50

  depends_on = [ azurerm_storage_account.storageAccount ]
}

/*
//networking resources
resource "azurerm_network_security_group" "containerSubnetNsg" {
  name                = "containerSubnetNsg"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
}

resource "azurerm_network_security_group" "sqlSubnetNsg" {
  name                = "sqlSubnetNsg"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
}

resource "azurerm_subnet_network_security_group_association" "ContainernsgAssociation" {
  subnet_id                 = azurerm_subnet.subnetContainer.id
  network_security_group_id = azurerm_network_security_group.containerSubnetNsg.id
}

resource "azurerm_subnet_network_security_group_association" "sqlNsgAssociation" {
  subnet_id                 = azurerm_subnet.sqlSubnet.id
  network_security_group_id = azurerm_network_security_group.sqlSubnetNsg.id
}
*/

resource "azurerm_virtual_network" "wordpressVnet" {
  name                = "vnet"
  location            = "westus"
  resource_group_name = "rg1"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnetContainer" {
  name = "subnetContainer"
  resource_group_name = "rg1"
  virtual_network_name = azurerm_virtual_network.wordpressVnet.name
  address_prefixes     = ["10.0.1.0/24"]

    delegation {
    name = "delegation"

    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"
    }
  }
}

resource "azurerm_subnet" "sqlSubnet" {
  name                 = "sqlSubnet"
  resource_group_name  = "rg1"
  virtual_network_name = azurerm_virtual_network.wordpressVnet.name
  address_prefixes     = ["10.0.2.0/24"]

      delegation {
    name = "delegation"

    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
    }
  }
}

resource "azurerm_subnet" "applicationGatewaySubnet" {
  name = "applicationGatewaySubnet"
  resource_group_name = "rg1"
  virtual_network_name = azurerm_virtual_network.wordpressVnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_subnet" "redisCacheSubnet" {
  name = "redisCacheSubnet"
  resource_group_name = "rg1"
  virtual_network_name = azurerm_virtual_network.wordpressVnet.name
  address_prefixes     = ["10.0.4.0/24"]
}

resource "azurerm_subnet" "storageAccountSubnet" {
  name = "storageAccountSubnet"
  resource_group_name = "rg1"
  virtual_network_name = azurerm_virtual_network.wordpressVnet.name
  address_prefixes     = ["10.0.5.0/24"]
  service_endpoints = [ "Microsoft.storage" ]
}


//SQL resources
resource "azurerm_mysql_flexible_server" "mySqlServer" {
  name                   = local.mySqlServerName
  resource_group_name    = "rg1"
  location               = "westus"
  administrator_login    = "mysqladmin"
  administrator_password = azurerm_key_vault_secret.vaultSecret.value
  sku_name               = "B_Standard_B1s"
  delegated_subnet_id    = azurerm_subnet.sqlSubnet.id
  backup_retention_days = 20
  high_availability {
    mode = "sameZone"
}

 depends_on = [azurerm_key_vault.keyVault]
}

resource "null_resource" "parameterChange" {
  provisioner "local-exec" {
command = "az mysql flexible-server parameter set --resource-group rg1 --server-name ${azurerm_mysql_flexible_server.mySqlServer.name} --name require_secure_transport --value OFF"
  }
}

resource "azurerm_mysql_flexible_database" "mySqlDB" {
  name                = "mySqlDB"
  resource_group_name = "rg1"
  server_name         = azurerm_mysql_flexible_server.mySqlServer.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
      depends_on = [
    azurerm_mysql_flexible_server.mySqlServer
  ]
}
/*
resource "azurerm_mysql_flexible_server_firewall_rule" "mysqlFirewallRule" {
  name                = "mysqlFirewallRule"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  server_name         = azurerm_mysql_flexible_server.mySqlServer.name
  start_ip_address    = "10.0.2.1"
  end_ip_address      = "10.0.2.254"
      depends_on = [
    azurerm_mysql_flexible_server.mySqlServer,
    azurerm_mysql_flexible_database.mySqlDB
  ]
}
*/


resource "azurerm_redis_cache" "redisCacheMysql" {
  name                = "redisCacheMysql"
  location            = "westus"
  resource_group_name = "rg1"
  capacity            = 1
  family              = "P"
  sku_name            = "Premium"
  enable_non_ssl_port = true
  public_network_access_enabled = "false"

  redis_configuration {
    aof_backup_enabled = false
 aof_storage_connection_string_0 = "DefaultEndpointsProtocol=https;BlobEndpoint=${azurerm_storage_account.storageAccount.primary_blob_endpoint};AccountName=${azurerm_storage_account.storageAccount.name};AccountKey=${azurerm_storage_account.storageAccount.primary_access_key}"
  }
}

/*
resource "null_resource" "storageUpload" {
  provisioner "local-exec" {
command = "az storage file upload-batch --destination https://storagegocif5.file.core.windows.net/wordpress --destination-path /wp-content/plugins --source ./redisCachePlugin --account-name ${azurerm_storage_account.storageAccount.name} --account-key ${azurerm_storage_account.storageAccount.primary_access_key}"
  }
}
*/

resource "null_resource" "storageDeleteConfig" {
  provisioner "local-exec" {
command = "az storage file delete --path ./wp-config.php --account-name ${azurerm_storage_account.storageAccount.name} --account-key ${azurerm_storage_account.storageAccount.primary_access_key} --share-name wordpress"
  }
  depends_on = [ azurerm_storage_share.storageShareFile,
  azurerm_container_group.containerGroup
   ]
}

resource "null_resource" "storageUploadConfig" {
  provisioner "local-exec" {
command = "az storage file upload --source ./wp-config.php --account-name ${azurerm_storage_account.storageAccount.name} --account-key ${azurerm_storage_account.storageAccount.primary_access_key} --share-name wordpress"
  }
  depends_on = [ null_resource.storageDeleteConfig ]
}

resource "azurerm_private_endpoint" "redisEndpoint" {
  name                = "redisEndpoint"
  location            = "westus"
  resource_group_name = "rg1"
  subnet_id           = azurerm_subnet.redisCacheSubnet.id

  private_service_connection {
    name                           = "redisPrivateServiceConnection"
    private_connection_resource_id = azurerm_redis_cache.redisCacheMysql.id
    is_manual_connection           = false
  subresource_names = ["redisCache"]
  }
}

//keyvautl resources
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyVault" {
  name                        = "keyVault-${random_string.random.result}"
  location                    = "westus"
  resource_group_name         = "rg1"
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
    ]
  }
}

resource "azurerm_key_vault_secret" "vaultSecret" {
  name         = "sqlPassword"
  value        = var.sqlPassword
  key_vault_id = azurerm_key_vault.keyVault.id
  depends_on = [
    azurerm_key_vault.keyVault,
  var.sqlPassword
  ]
}

resource "azurerm_log_analytics_workspace" "logAnalytics" {
  name                = "logAnalytics"
  location            = "westus"
  resource_group_name = "rg1"
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_workspace" "monitorWorkspace" {
  name                = "monitorWorkspace"
  resource_group_name = "rg1"
  location            = "westus"
}