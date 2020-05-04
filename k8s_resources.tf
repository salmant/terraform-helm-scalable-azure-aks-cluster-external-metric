
/*
* 'primary_connection_string' is used by consumer/producer to connect to the queue.
* Create a secret to be used by consumer container using 'primary_connection_string'
*/
resource "kubernetes_secret" "queue_credentials" {
  metadata {
    name = "servicebuskey"
  }

  data   = {
    sb-connection-string = "${azurerm_servicebus_queue_authorization_rule.listen_send_manage.primary_connection_string}"
  }

  type   = "Opaque"

}

/*
* Grant cluster-admin rights to the Tiller Service Account
*/
resource "kubernetes_cluster_role_binding" "tiller" {
  metadata {
    name = "default-view"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "kube-system"
  }
}

/*
* To deploy an Azure Kubernetes Metrics Adapter
* HPA checks in periodically with the Metrics Adapter to get the external/custom metric value.
* Metrics Adapter in turn calls the Azure endpoint to retrieve the metric value and give it back to the HPA. 
*/
resource "helm_release" "metrics_adapter" {
  name    = "metrics-adapter"
  # source: https://github.com/Azure/azure-k8s-metrics-adapter/tree/master/charts/azure-k8s-metrics-adapter
  chart   = "${path.module}/charts/azure-k8s-metrics-adapter"

  set {
    name  = "namespace"
    value = "${var.metrics_adapter_namespace}"
  }

  set {
    name  = "azureAuthentication.method"
    value = "clientSecret"
  }

  set {
    name  = "azureAuthentication.tenantID"
    value = "${data.azurerm_client_config.current.tenant_id}"
  }

  set {
    name  = "azureAuthentication.clientID"
    value = "${azuread_application.app_demo.application_id}"
  }

  set {
    name  = "azureAuthentication.clientSecret"
    value = "${random_string.client_secret.result}"
  }

  set {
    name  = "azureAuthentication.createSecret"
    value = "true"
  }

  depends_on = [kubernetes_cluster_role_binding.tiller]

}

/*
* This helm chart is used to create three items:
* (1): kind: ExternalMetric -> name: queuemessages
* (2): kind: Deployment -> name: consumer
* (3): kind: HorizontalPodAutoscaler -> name: consumer-scaler
*/
resource "helm_release" "scale_consumer" {
  name    = "scale-consumer"
  chart   = "${path.module}/charts/scale-consumer"

  set {
    name  = "queue.name"
    value = "${var.queue_name}"
  }

  set {
    name  = "servicebus.namespace"
    value = "${var.servicebus_namespace}"
  }

  set {
    name  = "resourcegroup.name"
    value = "${var.resource_group_name}"
  }

  set {
    name  = "minreplicas"
    value = "${var.minreplicas}"
  }

  set {
    name  = "maxreplicas"
    value = "${var.maxreplicas}"
  }

  set {
    name  = "externalmetric.name"
    value = "${var.externalmetric_name}"
  }

  set {
    name  = "externalmetric.targetvalue"
    value = "${var.externalmetric_targetvalue}"
  }

  set {
    name  = "containerimage"
    value = "${var.container_image}"
  }

  depends_on = [kubernetes_cluster_role_binding.tiller, helm_release.metrics_adapter]

}

