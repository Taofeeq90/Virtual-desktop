# data "azurerm_resource_group" "rg-backplane" {
#     name = var.regource_group
# }
# data "azurerm_resource_group" "rg-sessionhosts" {
#   provider = azurerm.hub
#     name = "rg-${var.env}-${var.prefix}-${var.solution}-session-hosts-01"
# }

# data "azurerm_log_analytics_workspace" "law" {
#   provider = azurerm.hub
#     name = "law-hub-jvn-01"
#     resource_group_name = "rg-hub-${var.prefix}-management-01"
# }
# data "azurerm_subnet" "avd-privatelink" {
#    provider = azurerm.hub
#   name = "snet-prd-jvn-avd-privatelink-01"
#   virtual_network_name = "vnet-prd-jvn-avd-we-01"
#   resource_group_name = "rg-prd-jvn-avd-networking-01"
# }
# data "azurerm_virtual_network" "avd-vnet" {
#    provider = azurerm.hub
#   name = "vnet-prd-jvn-avd-we-01"
#   resource_group_name = "rg-prd-jvn-avd-networking-01"
# }