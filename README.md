# Scalable AKS (Azure Kubernetes Service) Cluster based on External Metric

In this demo, there are procuders which generate messages sent to a queue implemented by the Azure Service Bus. And consumers process these messages received from the queue. Consumers are responsible for processing messages coming from a hosted queue service.
We are going to set up a scalable system in which the necessary number of consumer pods running in an AKS (Azure Kubernetes Service) Cluster is dynamically increased or decreased based on the number of messages in the queue. This is important because it is necessary to allocate enough number of container instances to process the data before the workload intensity surges at runtime. 
<br>

![Image](https://github.com/salmant/terraform-helm-scalable-azure-aks-cluster-external-metric/blob/master/azure-aks-cluster.png)

<br>

## Availability Zones in Azure

To provide a higher level of availability to our application, consumer pods running in the AKS Cluster are distributed among multiple availability zones in one region in this demo. The `location` in `variables.tf` is set to the region of `France Central` along with its two availability zones since we have defined the variable named `availability_zones` as `[1, 2]`. These parameters should be selected carefully according to the use case limitations and also many other criteria such as region availability intrinsic to the Azure cloud provider itself, availability of our preferred VM size in the region, etc.

<br>

```
variable "location" {
  description = "The Azure Region where the Resource Group should exist."
  type        = string
  default     = "France Central"
}
```

<br>

```
# To protect the application and data from datacenter failures.
variable "availability_zones" {
  description = "A list of Availability Zones across which the Node Pool should be spread."
  type        = list(number)
  default     = [1, 2]
}
```

<br>

More information about `Availability Zones in Azure` can be found here: 
<br>
https://docs.microsoft.com/en-us/azure/aks/availability-zones

<br>

## Geo-replication in Azure Container Registry

In this demo, an Azure geo-replicated container registry is used to store the consumer container image on different places at the same time. Locations are: `UK South` and `East US 2`.

<br>

It is better to choose these locations close to the AKS Cluster, where our containers are running. This provides a fast container image pull for the application. However, in this demo, we select these locations different from the AKS Cluster's place just to show the Azure cloud capabilities.

<br>

Geo-replication for container images is considered as one of disaster recovery policies in Azure Kubernetes Service (AKS). Moreover, this geo-replicated registry provides various benefits including network-close registry access from regional deployments as well as single management of a registry across multiple regions from the provider viewpoint.

<br>

More information about `Geo-replication in Azure Container Registry` can be found here: 
<br>
https://docs.microsoft.com/en-gb/azure/container-registry/container-registry-geo-replication

<br>

## Azure CNI Networking in AKS

In this demo, `Azure CNI Networking` is used to deploy AKS Cluster into the virtual network. `Azure CNI Networking` employs the `Azure Container Networking Interface (CNI)` Kubernetes plugin. In this case, all pods receive individual IPs that can route to other network services or on-premises resources. With CNI, every pod gets an IP address from the subnet and can be accessed directly. These IP addresses must be unique across your network space, and must be planned in advance. 

<br>

Each node has a configuration parameter for the maximum number of pods that it supports. The subnet must be large enough to provide IP addresses for every node, pods, and network resources that we are going to deploy. 

<br>

When you use `Azure CNI Networking`, the virtual network resource is in a separate resource group to the AKS Cluster. Therefore, the service principal used by the AKS Cluster must have at least `Network Contributor` permission on the subnet within the virtual network. 

<br>

One prerequisite for using `Azure CNI Networking` is that the AKS Cluster may not use `169.254.0.0/16`, `172.30.0.0/16`, `172.31.0.0/16` or `192.0.2.0/24` for the Kubernetes service address range. The address space which we use in this demo is `10.0.0.0/8`.

<br>

```
variable "address_space" {
  description = "The address space that is used by the virtual network."
  type        = string
  default     = "10.0.0.0/8"
}
```

<br>

In order to add the subnet to the virtual network, we need to provide an address prefix for the subnet. The address prefix is in CIDR format that is set to `10.240.0.0/16`.

<br>

```
variable "address_prefix_first" {
  description = "The address prefix to use for the subnet."
  type        = string
  default     = "10.240.0.0/16"
}
```

<br>

More information about `Azure CNI Networking in AKS` can be found here:
<br>
https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni

<br>

If you would like to create and manage multiple node pools for a cluster in AKS:
<br>
https://docs.microsoft.com/en-us/azure/aks/use-multiple-node-pools

<br>

## Horizontal Pod Auto-scaling (HPA)

For `Horizontal Pod Auto-scaling`, the following two references are important:

<br>

Horizontal Pod Autoscaler Walkthrough: 
<br>
https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/

<br>

Service Bus Queue External Metric Scaling:
<br>
https://github.com/Azure/azure-k8s-metrics-adapter/tree/master/samples/servicebus-queue

<br>

At first, we have only two nodes in the AKS Cluster, and each one in a different availability zone.

<br>

```
# This must be between 1 and 100 and between 'min_count' and 'max_count'.
variable "node_count" {
  description = "The initial number of nodes which should exist in this Node Pool."
  type        = number
  default     = 2
}
```

<br>

The number of nodes in the AKS Cluster can be increased or decreased according to the workload density.

<br>

```
# This must be between 1 and 100.
variable "max_count" {
  description = "The maximum number of nodes which should exist in this Node Pool."
  type        = number
  default     = 4
}
```

<br>

```
# This must be between 1 and 100.
variable "min_count" {
  description = "The minimum number of nodes which should exist in this Node Pool."
  type        = number
  default     = 2
}
```

<br>

We can define the maximum number of pods that can run on each node in the AKS Cluster.

<br>

```
variable "max_pods" {
  description = "The maximum number of pods that can run on each agent."
  type        = number
  default     = 30
}
```

<br>

We also determine the minimum and maximum number of consumer pods running in the AKS Cluster, so the HPA will not go below or above these values, respectively.

<br>

```
# The HPA cannot go below this value.
variable "minreplicas" {
  description = "The minimum number of consumer pod."
  type        = number
  default     = 1
}
```

<br>

```
# The HPA cannot go above this value.
variable "maxreplicas" {
  description = "The maximum number of consumer pods."
  type        = number
  default     = 3
}
```

<br>

The Kubernetes Horizontal Pod Autoscaler (HPA) dynamically decides how many consumer pods should be run in our AKS Cluster in order to be able to handle the whole messages in the queue. In this regard, the HPA defines the cluster size based on the number of messages in the queue, which is called `External Metric` in our demo. This metric is averaged together across pods and compared with a target value to determine the number of consumer pods. It is called `External Metric` since the Service Bus queue is a none-cluster object. In our demo, we would like to set the target value to `10`, which implies that we need one consumer pod per `10` messages.

<br>

```
variable "externalmetric_targetvalue" {
  description = "The target value per consumer pod to decide for scaling actions."
  type        = number
  default     = 10
}
```

<br>

## Results

<br>

If we list the nodes in the cluster, the output shows the two nodes distributed across the specified region and availability zones: `francecentral-1` and `francecentral-2`

<br>

```
$ kubectl describe nodes | grep -e "Name:" -e "failure-domain.beta.kubernetes.io/zone"
Name:               aks-default-23183483-vmss000000
                    failure-domain.beta.kubernetes.io/zone=francecentral-1
Name:               aks-default-23183483-vmss000001
                    failure-domain.beta.kubernetes.io/zone=francecentral-2
```

<br>

If any additional node will be manually or automatically added to the agent pool, the Azure platform automatically distributes the underlying VMs across the specified availability zones.

<br>

When we check the IP address of nodes in the cluster, the output shows IPs in the range of `10.240.0.0/16`, as we already defined for the address prefix of the subnet assigned to the virtual network in this demo.

<br>

```
$ kubectl get nodes -o wide
NAME                              STATUS   ROLES   AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
aks-default-23183483-vmss000000   Ready    agent   54m   v1.14.7   10.240.0.4    <none>        Ubuntu 16.04.6 LTS   4.15.0-1077-azure   docker://3.0.10+azure
aks-default-23183483-vmss000001   Ready    agent   54m   v1.14.7   10.240.0.35   <none>        Ubuntu 16.04.6 LTS   4.15.0-1077-azure   docker://3.0.10+azure
```

<br>

Since the minimum number of consumer pods running in the AKS Cluster is set to `1`, we expect one running cosumer.

<br>

```
$ kubectl get deployments consumer -o wide
NAME       READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                                                                 SELECTOR
consumer   1/1     1            1           8m    consumer     salmant.azurecr.io/jsturtevant-queue-consumer-external-metric:latest   app=consumer
```

<br>

If we check the IP address of consumer pod, the output shows the IP again in the range of `10.240.0.0/16`. This is because with Azure Container Networking Interface (CNI), every pod gets an IP address from the subnet and can be accessed directly. IP addresses for the pods and the cluster's nodes are assigned from the specified subnet within the virtual network. 

<br>

```
$ kubectl get pods -o wide
NAME                                                         READY   STATUS    RESTARTS   AGE   IP            NODE                              NOMINATED NODE   READINESS GATES
consumer-7774df6f48-q8nr5                                    1/1     Running   0          11m   10.240.0.20   aks-default-23183483-vmss000000   <none>           <none>
metrics-adapter-azure-k8s-metrics-adapter-86959655f4-g6d6m   1/1     Running   0          54m   10.240.0.49   aks-default-23183483-vmss000001   <none>           <none>
```

<br>

If we deliberately delete the current consumer pod and check the running pods again, we see a new consumer pod has immediately showed up automatically. This is because the minimum number of consumer pods running in the AKS Cluster was set to `1` and if the consumer pod would be terminated, the Horizontal Pod Autoscaler (HPA) will automatically instantiate a new one.

<br>

```
$ kubectl delete pod consumer-7774df6f48-q8nr5
pod "consumer-7774df6f48-q8nr5" deleted
```

<br>

```
$ kubectl get pods -o wide
NAME                                                         READY   STATUS    RESTARTS   AGE   IP            NODE                              NOMINATED NODE   READINESS GATES
consumer-7774df6f48-lzhjr                                    1/1     Running   0          9s    10.240.0.10   aks-default-23183483-vmss000000   <none>           <none>
metrics-adapter-azure-k8s-metrics-adapter-86959655f4-g6d6m   1/1     Running   0          55m   10.240.0.49   aks-default-23183483-vmss000001   <none>           <none>
```

<br>

Now, we check the list of all external metric. If everything has gone well, we should see the following output.

<br>

```
$ kubectl get aem
NAME            AGE
queuemessages   9m28s
```

<br>

If we check the queue in order to know how many messages in the queue that are not yet received by any consumer, we should see the value of `0` since no producer has sent any message so far.

<br>

```
$ export RESOURCEGROUP_NAME=ResourceGroupDemo
$ export SERVICEBUS_NS=sb-external-ns-demo
$ export QUEUE_NAME=externalq
$ az servicebus queue show --resource-group $RESOURCEGROUP_NAME --namespace-name $SERVICEBUS_NS --name $QUEUE_NAME -o json | jq .messageCount
0
```

<br>

Every consumer and producer needs to know `connection_string` which is used to connect to the queue. Therefore, the following command gives us the value of `connection_string`.

<br>

```
$ ./terraform output connection_string
Endpoint=sb://sb-external-ns-demo.servicebus.windows.net/;SharedAccessKeyName=demorule;SharedAccessKey=zhKheLhXUlMAFBY5DuFlFD8MEPS91ItmhvSzbNggBIE=;EntityPath=externalq
```

<br>

We need to use `connection_string` to prepare a very simple producer to send a few messages to the queue.

<br>

```
root@station1:~# python3 producer.py
```

<br>

Now, we check if the current consumer would be able to receive messages. Remember that the consumer included a lable named `app` with the value of `consumer`. 

<br>

```
$ kubectl logs -l app=consumer
connecting to queue:  externalq
setting up listener
received message:  Message 0
received message:  Message 1
received message:  Message 2
received message:  Message 3
received message:  Message 4
received message:  Message 5
received message:  Message 6
```

<br>

Validating the HPA, please note that the current number of unprocessed messages in the queue is `0` as we are not sending any messages to the queue, the TARGET column in the following output shows the average across all the current pods is zero. If the TARGETS shows <unknown>, wait longer and try again.

<br>

```
$ kubectl get hpa consumer-scaler
NAME              REFERENCE             TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
consumer-scaler   Deployment/consumer   0/10      1         3         1          15m
```

<br>

You can also manually check the value of external metric, which is the current number of unprocessed messages in the queue.

<br>

```
$ kubectl  get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/default/queuemessages" | jq .
{
  "kind": "ExternalMetricValueList",
  "apiVersion": "external.metrics.k8s.io/v1beta1",
  "metadata": {
    "selfLink": "/apis/external.metrics.k8s.io/v1beta1/namespaces/default/queuemessages"
  },
  "items": [
    {
      "metricName": "queuemessages",
      "metricLabels": null,
      "timestamp": "2020-04-30T18:59:20Z",
      "value": "0"
    }
  ]
}
```

<br>

Now, we are going to see how the autoscaler reacts to increased load. First, we prepare a producer able to send an infinite loop of messages to the queue to increase the workload and see what will happen. Within a couple of minutes, we should see a higher number of unprocessed messages in the queue.

<br>

```
root@station1:~# python3 multi-thread-producer.py
```

<br>

```
$ kubectl get hpa consumer-scaler
NAME              REFERENCE             TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
consumer-scaler   Deployment/consumer   4/10      1         3         1          17m
```

<br>

Here, the number of unprocessed messages in the queue has increased to 73. As a result, the deployment was resized to the maximum replicas, which is `3`.

<br>

```
$ kubectl  get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/default/queuemessages" | jq .
{
  "kind": "ExternalMetricValueList",
  "apiVersion": "external.metrics.k8s.io/v1beta1",
  "metadata": {
    "selfLink": "/apis/external.metrics.k8s.io/v1beta1/namespaces/default/queuemessages"
  },
  "items": [
    {
      "metricName": "queuemessages",
      "metricLabels": null,
      "timestamp": "2020-04-30T19:03:10Z",
      "value": "73"
    }
  ]
}
```

<br>

```
$ kubectl get hpa consumer-scaler
NAME              REFERENCE             TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
consumer-scaler   Deployment/consumer   73/10     1         3         3          19m
```

<br>

```
$ kubectl get pods
NAME                                                         READY   STATUS    RESTARTS   AGE
consumer-7774df6f48-8lhwx                                    1/1     Running   0          61s
consumer-7774df6f48-d677t                                    1/1     Running   0          45s
consumer-7774df6f48-lzhjr                                    1/1     Running   0          7m22s
metrics-adapter-azure-k8s-metrics-adapter-86959655f4-g6d6m   1/1     Running   0          62m
```

<br>

If we verify the nodes where the consumer pods are running, we see that the pods are automatically distributed on the nodes corresponding to different availability zones. 

<br>

```
$ kubectl get pods -o wide
NAME                                                         READY   STATUS    RESTARTS   AGE     IP            NODE                              NOMINATED NODE   READINESS GATES
consumer-7774df6f48-8lhwx                                    1/1     Running   0          75s     10.240.0.59   aks-default-23183483-vmss000001   <none>           <none>
consumer-7774df6f48-d677t                                    1/1     Running   0          59s     10.240.0.18   aks-default-23183483-vmss000000   <none>           <none>
consumer-7774df6f48-lzhjr                                    1/1     Running   0          7m36s   10.240.0.10   aks-default-23183483-vmss000000   <none>           <none>
metrics-adapter-azure-k8s-metrics-adapter-86959655f4-g6d6m   1/1     Running   0          62m     10.240.0.49   aks-default-23183483-vmss000001   <none>           <none>
```

<br>

```
$ kubectl describe pod | grep -e "^Name:" -e "^Node:"
Name:           consumer-7774df6f48-8lhwx
Node:           aks-default-23183483-vmss000001/10.240.0.35
Name:           consumer-7774df6f48-d677t
Node:           aks-default-23183483-vmss000000/10.240.0.4
Name:           consumer-7774df6f48-lzhjr
Node:           aks-default-23183483-vmss000000/10.240.0.4
Name:           metrics-adapter-azure-k8s-metrics-adapter-86959655f4-g6d6m
Node:           aks-default-23183483-vmss000001/10.240.0.35
```

<br>

If we finish our example by stopping the load, the deployment will be resized to the minimum replica, which is `1`.


