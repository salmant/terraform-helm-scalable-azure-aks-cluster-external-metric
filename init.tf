
terraform {
  required_version = ">= 0.12.24"
}

provider azurerm {
  version = "~>2.7.0"
  features {}
}

provider "azuread" {
  version = "~>0.8.0"
}

provider "null" {
  version = "~>2.1.0"
}

provider "random" {
  version = "~>2.2.0"
}

provider "tls" {
  version = "~>2.1.0"
}

provider "kubernetes" {
  version                = "~> 1.11.1"
  host                   = azurerm_kubernetes_cluster.scalable_aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.scalable_aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.scalable_aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.scalable_aks.kube_config.0.cluster_ca_certificate)
  load_config_file       = false
}

provider "helm" {
  debug   = true
  version = "~> 1.1.1"

  kubernetes {
    host                   = azurerm_kubernetes_cluster.scalable_aks.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.scalable_aks.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.scalable_aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.scalable_aks.kube_config.0.cluster_ca_certificate)
    load_config_file       = false
  }
}

