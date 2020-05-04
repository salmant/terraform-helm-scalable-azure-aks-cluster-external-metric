
/*
* Outputs
*/

output "cluster_id" {
  description = "The Kubernetes Managed Cluster ID"
    value = "${azurerm_kubernetes_cluster.scalable_aks.id}"
}

output "client_key" {
  description = "Base64 encoded private key used by clients to authenticate to the Kubernetes cluster"
  value = "${azurerm_kubernetes_cluster.scalable_aks.kube_config.0.client_key}"
}

output "client_certificate" {
  description = "Base64 encoded public certificate used by clients to authenticate to the Kubernetes cluster"
  value = "${azurerm_kubernetes_cluster.scalable_aks.kube_config.0.client_certificate}"
}

output "cluster_ca_certificate" {
  description = "Base64 encoded public CA certificate used as the root of trust for the Kubernetes cluster"
  value = "${azurerm_kubernetes_cluster.scalable_aks.kube_config.0.cluster_ca_certificate}"
}

output "kube_config" {
  description = "Raw Kubernetes config to be used by kubectl and other compatible tools"
  value = azurerm_kubernetes_cluster.scalable_aks.kube_config_raw
}

output "host" {
  description = "The Kubernetes cluster server host"
  value = azurerm_kubernetes_cluster.scalable_aks.kube_config.0.host
}

output "app_id" {
  description = "the Application ID of the Azure Active Directory Application"
  value = "${azuread_application.app_demo.application_id}"
}

output "client_secret" {
  description = "A key generated for the application registration"
  value = "${random_string.client_secret.result}"
}

output "tenant_id" {
  description = "A globally unique identifier within the subscription"
  value = "${data.azurerm_client_config.current.tenant_id}"
}

output "connection_string" {
  description = "Connection string for the Azure Service Bus Queue created"
  value = "${azurerm_servicebus_queue_authorization_rule.listen_send_manage.primary_connection_string}"
}

output "subscription_id" {
  description = "The ID of the subscription"
  value = "${data.azurerm_subscription.primary.id}"
}

