
/*
* Create an Azure Resource Group for the AKS Cluster
*/
resource "azurerm_resource_group" "standard_demo" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"

  tags = "${merge(
    local.common_tags,
    map(
      "CostAllocation", "300",
      "Reason", "test",
    )
  )}"

}

/*
* Create an application within Azure Active Directory (AD)
* You can think of this as an identity for the application which needs access to Azure resources.
*/
resource "azuread_application" "app_demo" {
  name  = "${var.project}-app_demo"
}

/*
* To allow an AKS cluster to interact with other Azure resources such as Service Bus and Virtual Network, a Service Principal should be created.
*/
resource "azuread_service_principal" "auth" {
  application_id = "${azuread_application.app_demo.application_id}"

  tags = [
    "${var.project}",
    "${var.stage}",
  ]

}

/*
* We need to supply a password for the application registration within Azure Active Directory.
*/
resource "random_string" "client_secret" {
  length           = 32
  special          = true
  override_special = "/@\" "
}

/*
* Duration for which the generated password is valid until is 8760h (1 year).
*/
resource "azuread_service_principal_password" "duration" {
  service_principal_id = "${azuread_service_principal.auth.id}"
  value                = "${random_string.client_secret.result}"
  end_date_relative    = "8760h" # 1 year
  # end_date           = "2021-05-01T01:02:03Z"
}

/*
* Manage a password associated with the application within Azure Active Directory.
*/
resource "azuread_application_password" "duration" {
  application_object_id = "${azuread_application.app_demo.id}"
  value                 = "${random_string.client_secret.result}"
  end_date_relative     = "8760h" # 1 year
  # end_date            = "2021-05-01T01:02:03Z"
}

/*
* Create a private key to connect to the nodes in the AKS cluster
*/
resource "tls_private_key" "key" {
  algorithm   = "RSA"
}

/*
* Save the generated private key in our local workspace
*/
resource "null_resource" "saved_key" {
  triggers = {
    key = tls_private_key.key.private_key_pem
  }

  provisioner "local-exec" {
    command = <<EOF
      mkdir -p ${path.module}/.ssh
      echo "${tls_private_key.key.private_key_pem}" > ${path.module}/.ssh/${var.private_key_name}
      chmod 0600 ${path.module}/.ssh/${var.private_key_name}
EOF
  }

}

data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "current" {}

/*
* Create the Virtual Network (VNet)
*/
resource "azurerm_virtual_network" "main" {
  name                = "${var.project}-aks-network"
  location            = azurerm_resource_group.standard_demo.location
  resource_group_name = azurerm_resource_group.standard_demo.name
  address_space       = ["${var.address_space}"]
  #dns_servers        = ["${var.dns_servers}"]

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "test",
      "Role", "test",
    )
  )}"

}

/*
* Create an AKS Subnet to be used by nodes and pods
* We can define more subnets if required
*/
resource "azurerm_subnet" "first" {
  name                 = "first-subnet"
  resource_group_name  = azurerm_resource_group.standard_demo.name
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix       = "${var.address_prefix_first}"
}

/*
* Service Principal is an identity created for use with applications, hosted services, and automated tools to access Azure resources.
* This access is restricted by the roles assigned to the service principal, giving you control over which resources can be accessed and at which level.
* Grant AKS Cluster permission to read the monitoring data
*/
resource "azurerm_role_assignment" "aks_monitoring_reader" {
  scope                = "${data.azurerm_subscription.primary.id}"
  role_definition_name = "Monitoring Reader"
  principal_id         = "${azuread_service_principal.auth.object_id}"
}

/*
* Grant AKS Cluster permission to access ACR (Azure Container Registry)
*/
resource "azurerm_role_assignment" "aks_container_registry" {
  scope                = "${data.azurerm_subscription.primary.id}/resourceGroups/${var.container_registry_resource_group}/providers/Microsoft.ContainerRegistry/registries/${var.container_registry}"
  role_definition_name = "AcrPull"
  principal_id         = "${azuread_service_principal.auth.object_id}"
}

/*
* Grant AKS Cluster access to join the first AKS subnet
*/
resource "azurerm_role_assignment" "aks_subnet" {
  scope                = "${azurerm_subnet.first.id}"
  role_definition_name = "Network Contributor"
  principal_id         = "${azuread_service_principal.auth.object_id}"
}

/*
* Create an AKS kubernetes cluster
*/
resource "azurerm_kubernetes_cluster" "scalable_aks" {
  name                = "${var.cluster_name}"
  resource_group_name = azurerm_resource_group.standard_demo.name
  location            = azurerm_resource_group.standard_demo.location
  dns_prefix          = "${var.dns_prefix}"
  kubernetes_version  = "${var.kubernetes_version}"
  depends_on          = [azurerm_role_assignment.aks_monitoring_reader, azurerm_role_assignment.aks_container_registry, azurerm_role_assignment.aks_subnet]

  linux_profile {
    admin_username = "${var.admin_username}"

    # SSH key is dynamically generated using "tls_private_key" resource
    ssh_key {
      key_data = "${trimspace(tls_private_key.key.public_key_openssh)}"
    }
  }

  default_node_pool {
    name                    = "default"
    type                    = "VirtualMachineScaleSets"
    enable_auto_scaling     = "${var.enable_auto_scaling}"
    # enable_node_public_ip = "${var.enable_node_public_ip}"
    node_count              = "${var.node_count}"
    max_count               = "${var.max_count}"
    min_count               = "${var.min_count}"
    max_pods                = "${var.max_pods}"
    vm_size                 = "${var.vm_size}"
    os_disk_size_gb         = "${var.os_disk_size_gb}"
    availability_zones      = "${var.availability_zones}"
    vnet_subnet_id          = "${azurerm_subnet.first.id}"
  }

  service_principal {
    client_id     = "${azuread_service_principal.auth.application_id}"
    client_secret = "${random_string.client_secret.result}"
  }

  network_profile {
    network_plugin = "azure"
  }

  role_based_access_control {
    enabled = true
  }

  tags = "${merge(
    local.common_tags,
    map(
      "NodePool", "Single",
      "Reason", "test",
    )
  )}"

  # To configure 'kubectl' in order to point 'kubeconfig' to the cluster.
  provisioner "local-exec" {
    command="az aks get-credentials -g ${azurerm_resource_group.standard_demo.name} -n ${azurerm_kubernetes_cluster.scalable_aks.name} --overwrite-existing"
  }

}

