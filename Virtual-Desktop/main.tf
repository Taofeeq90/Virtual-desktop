resource "azurerm_resource_group" "rg-backplane" {
     name = var.regource_group
     location = var.location
 }


#Create WVD workspace
resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = var.workspace_name
  resource_group_name = azurerm_resource_group.rg-backplane.name #var.resource_name
  location            = var.location
  friendly_name       = var.friendly_name
  description         = var.description
  tags = local.tags
}
resource "azurerm_monitor_diagnostic_setting" "avd-ws-logs" {
  provider = azurerm.hub
  name = "${var.prefix}-monitorhp-${var.environment}"
  target_resource_id =  azurerm_virtual_desktop_workspace.workspace.id 
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  depends_on = [azurerm_virtual_desktop_workspace.ws]
   log {
    category = "Error"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Checkpoint"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Management"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Feed"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
}

# Create host pool registration info  
resource "azurerm_virtual_desktop_host_pool_registration_info" "reg_info" {
  hostpool_id = azurerm_virtual_desktop_host_pool.host-pool.id
  expiration_date = var.expiration_date
}
# Create host pool
resource "azurerm_virtual_desktop_host_pool" "host-pool" {
  resource_group_name      = azurerm_resource_group.rg-backplane.name #var.regource_group
  name                     = "${var.app_id}-hostpool-${var.environment}"
  location                 = var.location
  validate_environment     = var.validate_environment
  custom_rdp_properties    = var.custom_rdp_properties
  type                     = var.hostpool_type
  maximum_sessions_allowed = var.maximum_sessions_allowed
  load_balancer_type       = var.load_balancer_type
  friendly_name            = var.hostpool_friendly_name
  start_vm_on_connect = var.start_vm_on_connect
  tags = local.tags
}
# Create virtual desktop application group
resource "azurerm_virtual_desktop_application_group" "app-group" {
  resource_group_name = azurerm_resource_group.rg-backplane.name #var.regource_group
  host_pool_id        = azurerm_virtual_desktop_host_pool.host-pool.id
  location            = var.location
  type                = var.desktop_appgroup_type
  name                = "${var.app_id}-hostpooldag-${var.environment}"
  friendly_name       = var.hostpooldag_friendly_name
  description         = var.hostpooldag_description
  depends_on          = [azurerm_virtual_desktop_host_pool.host-pool]
  tags = local.tags
}

# Associate Workspace and DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "app-group-ass" {
  application_group_id = azurerm_virtual_desktop_application_group.app-group.id
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
}

resource "azurerm_monitor_diagnostic_setting" "avd-logs" {
  provider = azurerm.hub
    name = "${var.prefix}-monitorhp-${var.environment}"
    target_resource_id = azurerm_virtual_desktop_host_pool.hp.id
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
    depends_on = [azurerm_virtual_desktop_host_pool.hp]
   log {
    category = "Error"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Checkpoint"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Management"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Connection"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "HostRegistration"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "AgentHealthStatus"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "NetworkData"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "SessionHostManagement"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
    
}
resource "azurerm_monitor_diagnostic_setting" "fd-logs" {
  provider = azurerm.hub
  name = "${var.prefix}-monitorappgroup-${var.environment}"
  target_resource_id = azurerm_virtual_desktop_application_group.fd.id 
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id 
  depends_on = [
    azurerm_virtual_desktop_application_group.fd
  ]
  log {
    category = "Checkpoint"
    enabled = "true"

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Error"
    enabled = "true"

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Management"
    enabled = "true"

    retention_policy {
      enabled = false
    }
  }
}

## session hosts

/* resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "${var.vm_name}${count.index + 1}"
  location            = var.location
  resource_group_name = var.regource_group
  size               = "${var.vm_size}"
  network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
  count                 = "${var.vm_count}"
  license_type = "None"
 
  identity {
    type = "SystemAssigned"
  }
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  source_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }

  os_disk {
    name          = "${var.vm_name}${count.index + 1}-c"
    caching = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  
    provision_vm_agent = true
  
  zone = "${(count.index%3)+1}"
  tags = local.tags
}
resource "azurerm_network_interface" "nic" {
  name                = "nic-01-${var.vm_name}${count.index + 1}"
  location            = var.location
  resource_group_name = var.regource_group
  count               = "${var.vm_count}"

  ip_configuration {
    name                                    = "ipc-${var.vm_name}${count.index + 1}"
    subnet_id                               = "${var.subnet_id}"
    private_ip_address_allocation           = "Dynamic"
    }
    tags = {
    "Location" = "We"
    "Costcenter" = "IT"
    "Purpose" = "AVD Session Host Nic"
    "Environment" = "Prd"
  }
}

resource "azurerm_virtual_machine_extension" "AADLoginForWindows" {
  count = "${var.vm_count}"
  depends_on = [
      azurerm_virtual_machine_extension.registersessionhost
  ]

  name                 = "AADLoginForWindows"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm[count.index].id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForWindows"
  type_handler_version = "1.0"

}
resource "azurerm_virtual_machine_extension" "registersessionhost" {
  name                 = "registersessionhost"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm[count.index].id
  depends_on = [
    azurerm_windows_virtual_machine.vm
  ]
  publisher            = "Microsoft.Powershell"
  count                = "${var.vm_count}"
  type = "DSC"
  type_handler_version = "2.73"
  auto_upgrade_minor_version = true
  settings = <<SETTINGS
    {
        "ModulesUrl": "${var.artifactslocation}",
        "ConfigurationFunction" : "Configuration.ps1\\AddSessionHost",
        "Properties": {
            "hostPoolName": "azurerm_virtual_desktop_host_pool.host-pool.name",
            "aadJoin": true
            
        }
    }
    SETTINGS
        protected_settings = <<PROTECTED_SETTINGS
    {
      "properties" : {
            "registrationInfoToken" : "${azurerm_virtual_desktop_host_pool_registration_info.reg_info.token}"
        }
    }
    PROTECTED_SETTINGS

    lifecycle {
        ignore_changes = [settings, protected_settings ]
    }
}
## session hosts extensions

##AzureMonitoringAgent
resource "null_resource" "AzureMonitoringAgent" {
  count                = "${var.vm_count}"
  
  provisioner "local-exec" {
    command = "az vm extension set --name AzureMonitorWindowsAgent --publisher Microsoft.Azure.Monitor --ids ${azurerm_windows_virtual_machine.vm[count.index].id} --enable-auto-upgrade true"
  }
  
}
##dependencyAgent
resource "azurerm_virtual_machine_extension" "da" {
  provider = azurerm.hub
  count                = "${var.vm_count}"
  name                       = "DAExtension"
  virtual_machine_id         =  azurerm_windows_virtual_machine.vm[count.index].id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentWindows"
  type_handler_version       = "9.5"
  auto_upgrade_minor_version = true

}
##MicrosoftMonitoringAgent
resource "azurerm_virtual_machine_extension" "mmaagent" {
  provider = azurerm.hub
  count                = "${var.vm_count}"
  name                  = "MicrosoftMonitoringAgent" 
  virtual_machine_id    = azurerm_windows_virtual_machine.vm[count.index].id
  publisher             = "Microsoft.EnterpriseCloud.Monitoring"
  type                  = "MicrosoftMonitoringAgent"
  type_handler_version  = "1.0"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
        "workspaceId": "${var.workspace_id}"
    }
  SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
    {
      "workspaceKey": "${var.workspace_key}"
    }
  PROTECTED_SETTINGS  

  
}
resource "azurerm_private_dns_zone" "avd" {
  name ="privatelink.wvd.microsoft.com"
  resource_group_name = data.azurerm_virtual_network.avd-vnet.resource_group_name
      tags = local.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "avd-dns-vnet-link" {
  name = "link-privatelink.wvd.microsoft.com-vnet-prd-jvn-avd-we-01"
  private_dns_zone_name = azurerm_private_dns_zone.avd.name
  virtual_network_id = data.azurerm_virtual_network.avd-vnet.id
  resource_group_name = "rg-prd-jvn-avd-networking-01"
  
  depends_on = [azurerm_private_dns_zone.avd]
}

resource "azurerm_private_endpoint" "hostpool" {
  name                = "pe-01-hp-prd-jvn-avd-we-01"
  location            = data.azurerm_resource_group.rg-backplane.location
  resource_group_name = data.azurerm_resource_group.rg-backplane.name
  subnet_id           = data.azurerm_subnet.avd-privatelink.id
  custom_network_interface_name = "nic-01-pe-01-hp-prd-jvn-avd-we-01"
   private_dns_zone_group {
    name = "privatelink.wvd.microsoft.com"
    private_dns_zone_ids = [azurerm_private_dns_zone.avd.id]

  }
    tags = {
    "Location" = "We"
    "Costcenter" = "IT"
    "Purpose" = "AVD Host Pool Private Endpoint"
    "Environment" = "Prd"
  }
  private_service_connection {
    name = "nic-01-pe-01-hp-prd-jvn-avd-we-01"
    private_connection_resource_id = azurerm_virtual_desktop_host_pool.hp.id
    is_manual_connection           = false
    subresource_names = ["connection"]
  }
  depends_on = [azurerm_virtual_desktop_host_pool.hp]
}

resource "azurerm_private_endpoint" "workspace-feed" {
  name                = "pe-01-ws-prd-jvn-avd-we-01"
  location            = data.azurerm_resource_group.rg-backplane.location
  resource_group_name = data.azurerm_resource_group.rg-backplane.name
  subnet_id           = data.azurerm_subnet.avd-privatelink.id
  custom_network_interface_name = "nic-01-01-pe-01-ws-prd-jvn-avd-we-01"
  private_dns_zone_group {
    name = "privatelink.wvd.microsoft.com"
    private_dns_zone_ids = [azurerm_private_dns_zone.avd.id]

  }
  tags = {
    "Location" = "We"
    "Costcenter" = "IT"
    "Purpose" = "AVD Workspace Private Endpoint"
    "Environment" = "Prd"
  }
  private_service_connection {
    name =  "nic-01-pe-01-ws-prd-jvn-avd-we-01"
    private_connection_resource_id = azurerm_virtual_desktop_workspace.ws.id
    is_manual_connection           = false
    subresource_names = ["feed"]
  }
  depends_on = [azurerm_virtual_desktop_workspace.ws]
}
resource "azurerm_private_endpoint" "workspace-global" {
  name                = "pe-02-ws-prd-jvn-avd-we-01"
  location            = data.azurerm_resource_group.rg-backplane.location
  resource_group_name = data.azurerm_resource_group.rg-backplane.name
  subnet_id           = data.azurerm_subnet.avd-privatelink.id
  custom_network_interface_name = "nic-02-pe-02-ws-prd-jvn-avd-we-01"
  private_dns_zone_group {
    name = "privatelink.wvd.microsoft.com"
    private_dns_zone_ids = [azurerm_private_dns_zone.avd.id]

  }
  tags = {
    "Location" = "We"
    "Costcenter" = "IT"
    "Purpose" = "AVD Workspace Private Endpoint"
    "Environment" = "Prd"
  }
  private_service_connection {
    name = "nic-02-pe-02-ws-prd-jvn-avd-we-01"
    private_connection_resource_id = azurerm_virtual_desktop_workspace.ws.id
    is_manual_connection           = false
    subresource_names = ["global"]
    
  }
  depends_on = [azurerm_virtual_desktop_workspace.ws]
}











 */