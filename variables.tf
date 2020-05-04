
variable "project" {
  description = "The name of the project."
  type        = string
  default     = "DemoProject"
}

variable "department" {
  description = "The department who works on the project."
  type        = string
  default     = "Engineering"
}

variable "team" {
  description = "The team who works on the project."
  type        = string
  default     = "DevOps"
}

variable "stage" {
  description = "Development, Staging, Production, etc."
  type        = string
  default     = "Development"
}

# Changing this forces a new Resource Group to be created.
variable "resource_group_name" {
  description = "The name of the Resource Group in which all resources should exist."
  type        = string
  default     = "ResourceGroupDemo"
}

# Changing this forces a new Resource Group to be created.
variable "location" {
  description = "The Azure Region where the Resource Group should exist."
  type        = string
  default     = "France Central"
}

# To protect the application and data from datacenter failures.
variable "availability_zones" {
  description = "A list of Availability Zones across which the Node Pool should be spread."
  type        = list(number)
  default     = [1, 2]
}

# It identifies the cluster which is created on the resource group.
variable "cluster_name" {
  description = "The name of the managed cluster."
  type        = string
  default     = "ManagedClusterDemo"
}

# Changing this forces a new resource to be created.
variable "dns_prefix" {
  description = "It can contain only letters, numbers, and hyphens."
  type        = string
  default     = "ManagedClusterDemo-dns"
}

# If not specified, the latest recommended version will be used at provisioning time (but will not auto-upgrade).
variable "kubernetes_version" {
  description = "Version of Kubernetes specified when creating the AKS managed cluster."
  type        = string
  default     = "1.14.7"
}

# This must be between 1 and 100 and between 'min_count' and 'max_count'.
variable "node_count" {
  description = "The initial number of nodes which should exist in this Node Pool."
  type        = number
  default     = 2
}

# If required!
variable "enable_node_public_ip" {
  description = "If the Kubernetes Auto Scaler should be enabled for this Node Pool."
  type        = bool
  default     = false
}

# If it is set to false both 'min_count' and 'max_count' fields need to be set to null.
variable "enable_auto_scaling" {
  description = "If the Kubernetes Auto Scaler should be enabled for this Node Pool."
  type        = bool
  default     = true
}

# This must be between 1 and 100.
variable "max_count" {
  description = "The maximum number of nodes which should exist in this Node Pool."
  type        = number
  default     = 4
}

# This must be between 1 and 100.
variable "min_count" {
  description = "The minimum number of nodes which should exist in this Node Pool."
  type        = number
  default     = 2
}

# Changing this forces a new resource to be created.
variable "max_pods" {
  description = "The maximum number of pods that can run on each agent."
  type        = number
  default     = 30
}

# It should be carefully selected according to the use case.
variable "vm_size" {
  description = "The size of the Virtual Machine in this Node Pool."
  type        = string
  default     = "Standard_D2s_v3"
}

# Changing this forces a new resource to be created. It should be carefully selected according to the use case.
variable "os_disk_size_gb" {
  description = "The size of the OS Disk which should be used for each agent in the Node Pool."
  type        = number
  default     = 80
}

# This username is used to connect to the nodes in the AKS Cluster via SSH
variable "admin_username" {
  description = "The admin username for the Linux OS of the nodes in the cluster."
  type        = string
  default     = "ubuntu"
}

# This private key is used to connect to the nodes in the AKS Cluster via SSH
variable "private_key_name" {
  description = "The private key for the Linux OS of the nodes in the cluster."
  type        = string
  default     = "id_rsa"
}

# Changing this forces a new resource to be created.
variable "address_space" {
  description = "The address space that is used by the virtual network."
  type        = string
  default     = "10.0.0.0/8"
}

# To add the subnet to the virtual network, we need to provide an address prefix. The address prefix is again in CIDR format.
variable "address_prefix_first" {
  description = "The address prefix to use for the subnet."
  type        = string
  default     = "10.240.0.0/16"
}

# A Service Bus namespace is a scoping container for all messaging components.
variable "servicebus_namespace" {
  description = "Multiple queues and topics can reside within a single namespace."
  type        = string
  default     = "sb-external-ns-demo"
}

# Messages are sent to and received from a queue.
variable "queue_name" {
  description = "Queue stores messages until the consumer application receives and processes them."
  type        = string
  default     = "externalq"
}

# It is used to create a queue auth rule used to create primaryConnectionString.
variable "queue_rule_name" {
  description = "The name for queue authorization rule."
  type        = string
  default     = "demorule"
}

# The namespace for Azure Kubernetes Metrics Adapter.
variable "metrics_adapter_namespace" {
  description = "The namespace for Metrics Adapter."
  type        = string
  default     = "custom-metrics"
}

# The HPA cannot go below this value.
variable "minreplicas" {
  description = "The minimum number of consumer pods."
  type        = number
  default     = 1
}

# The HPA cannot go above this value.
variable "maxreplicas" {
  description = "The maximum number of consumer pods."
  type        = number
  default     = 3
}

# It is used for cluster sizing.
variable "externalmetric_name" {
  description = "Number of messages in the queue."
  type        = string
  default     = "queuemessages"
}

# The HPA defines the cluster size based on this value.
variable "externalmetric_targetvalue" {
  description = "The target value per consumer pod to decide for scaling actions."
  type        = number
  default     = 10
}

# Every container registry resides in its own resource group.
variable "container_registry_resource_group" {
  description = "Dedicated resource group."
  type        = string
  default     = "salmant_container_registry_resource_group"
}

# A fully managed, geo-replicated instance of OCI distribution.
variable "container_registry" {
  description = "The container registry where the container image is located."
  type        = string
  default     = "salmant"
}

# Consumer is responsible for fetching messages from the Service Bus queue.
variable "container_image" {
  description = "The name of container image for the consumer container."
  type        = string
  default     = "salmant.azurecr.io/jsturtevant-queue-consumer-external-metric:latest"
}

