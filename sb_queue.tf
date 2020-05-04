
/*
* Create a ServiceBus Namespace
*/
resource "azurerm_servicebus_namespace" "main_scope" {
  name                = "${var.servicebus_namespace}"
  location            = azurerm_resource_group.standard_demo.location
  resource_group_name = azurerm_resource_group.standard_demo.name
  sku                 = "Standard"

  tags = "${merge(
    local.common_tags,
    map(
      "Data", "JSON",
      "Reason", "test"
    )
  )}"

}

/*
* Create a ServiceBus queue
*/
resource "azurerm_servicebus_queue" "main_messaging_service" {
  name                = "${var.queue_name}"
  resource_group_name = azurerm_resource_group.standard_demo.name
  namespace_name      = azurerm_servicebus_namespace.main_scope.name
  enable_partitioning = true
}

/*
* Manage a ServiceBus queue
* This gives full access to the queue for ease of use in this demo.
* You should create more fine grained control for each component of your application.
* For example the consumer app should only have 'listen' right and the producer app should only have 'send' right.
*/
resource "azurerm_servicebus_queue_authorization_rule" "listen_send_manage" {
  name                = "${var.queue_rule_name}"
  namespace_name      = azurerm_servicebus_namespace.main_scope.name
  queue_name          = azurerm_servicebus_queue.main_messaging_service.name
  resource_group_name = azurerm_resource_group.standard_demo.name

  listen = true
  send   = true
  manage = true

}

