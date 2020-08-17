# Home Advisor

## Assignment Requirements
*...use EKS, or just spin up an EC2 instance and use k3s*

*...make sure we can access the instance when you're done*

*...use IaC where possible*

*...take some shortcuts in the name of time*

*...[the] why and how you leverage a particular monitoring product*

## Summary

- Builds a k3s two node cluster using Terraform
- Adds a simple app into the cluster
- Layer on monitoring tools

## Prerequisites

- Terraform installed
- AWS API keys set
- The target VPC_ID
- Location of your SSH public (id_rsa.pub) key

## Install - Bootstrap the cluster
### 1) Build the cluster

Clone this repo. Initialize terraform with:
```
terraform init
```

Build two nodes and apply some config:.
```
terraform apply
```

Example input values:
```
var.resource_prefix
  Enter a value: homeAdvisor

var.ssh_keypair
  Enter a value: ~/.ssh/id_rsa.pub

225 more lines; before #1  2 seconds ago
  Enter a value: ~/.ssh/id_rsa.pub

var.vpc_id
  Enter a value: vpc-64e6e10
```

### 2) Connect the nodes together

1. For each node/vm, ssh in and become root
```sudo su -```

2. Get the shared secret key used to connect nodes to a cluster. ssh into "server" and copy the contents of:
```/var/lib/rancher/k3s/server/node-token```

3. ssh into "worker" and edit script at ```/root/k3s.sh```, replacing the endpoint URL with the internal AWS IP of the "server" and the node token with the token from step 2

4) On the worker, run ```/root/ks3.sh```

### 3) (Optional)  Verify the cluster is up and nodes are connected. On the server...

```
systemctl status k3s
```
...displays the service as active.

```
kubectl get nodes -o wide
```
...displays that two nodes registered

```
kubectl get pods -A -o wide
```
...displays all running pods

### 4) (Optional) Verify the core endpoints are up

As root run:
```
kubectl cluster-info
```
Expected outout:
```console
foo@bar:~$ kubectl cluster-info
Kubernetes master is running at https://127.0.0.1:6443
foo@bar:~$ kubectl cluster-info
Kubernetes master is running at https://127.0.0.1:6443
CoreDNS is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy
foo@bar:~$
```
-----------
## Deploy the sample app

(First super simple app I found on dockerhub)

On the worker, run ```/root/install_app.sh```

Test the app locally on the server node:
```
curl -X GET http://localhost:80
```

Expected output...
```
{"data":"RESTful with two Endpoint /users and /notes - v1.0.0"}
```

ssh port forward and view the app via your browser:

```
ssh -L 12345:127.0.0.01:80 ubuntu@[PUBLIC_IP_OF_SERVER]
....

http://127.0.0.1:12345
```


-----------

## Monitoring
### Cluster-level monitoring / management
**[Kubernetes Dashboard](https://github.com/kubernetes/dashboard)** chosen.

Install Kubernetes dashboard on the server node. Log in to the server as root:
```
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
```

Create a dashboard account:
```
kubectl create serviceaccount dashboard-admin-sa
```

Bind the dashboard-admin-service-account service account to the cluster-admin role:
```
kubectl create clusterrolebinding dashboard-admin-sa --clusterrole=cluster-admin --serviceaccount=default:dashboard-admin-sa
```

Launch dashboard:
```
kubectl proxy&
```
ssh port forward and view the app via your browser:


```
ssh -L 12345:127.0.0.1:8001 ubuntu@[PUBLIC_IP_OF_SERVER]
....

http://localhost:12345/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=default
```

Get token to access the dashboad

```
foo@bar:~$ kubectl get secrets

NAME                             TYPE                                  DATA   AGE
default-token-fc9bv              kubernetes.io/service-account-token   3      75m
dashboard-admin-sa-token-XXXX   kubernetes.io/service-account-token   3      38s
```


Get token using the using your XXX value:
```
kubectl describe secret dashboard-admin-sa-token-XXXX
```

Cut/paste return token into dashboard. You will see the 2 nodes registered and have access to all the features of the kubernetes dashboard

#### _Why Kubernetes Dashboard?_


Pro's:

- Ubiquitous general purpose management tool for k8s and k3s
- Affords management and basic monitoring

Cons:

N/A


### Application-level monitoring

**[Datadog](https://www.datadoghq.com/)**
chosen.

NOTE: not installed due to time constraints, but can easily be done using the **[kubernetes monitoring installation instructions](https://www.datadoghq.com/blog/monitor-kubernetes-docker/)**

#### _Why Datadog?_

Pro's:

- Datadog provides node-level AND cluster level and  application level metrics.
- Comprehensive tracing data is available
Clean UI
- Lightweight agent that's easy to install into the cluster
- Option to install a kubernetes
- Autodiscovery
- Can ingest custom metrics

Cons:

Cost - $15 / node for the basics



### Alerting
**[Victor Ops](https://victorops.com/)** chosen.

Used for multi-tier alerting to on-call teams.


## Authors

Rhys Campbell - *Initial work* -

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments
Hat tip to the guys at Rancher for k3s. It's awesome!
