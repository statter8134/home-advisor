# Home Advisor

## Assignment Requirements
*...use EKS, or just spin up an EC2 instance and use k3s*
 
*...make sure we can access the instance when you're done*

*...use IaC where possible*

*...take some shortcuts in the name of time*
 
*...[the] why and how you leverage a particular monitoring product*

## Summary

- Builds a k3s two node cluster using Terraform.
- Add a simple app into the cluster
- Layer on monitoring tools

## Prerequisites

Terraform installed
AWS account and access variables set 
A target VPC ID
The location of your SSH public key 

## Installing
### 1) Build the cluster
 
Clone this repo. Initialize terraform with...
```
terraform init
```
 
Build two nodes and apply some configuration...  
```
terraform apply
```
 
Supply your own variables...
```
var.resource_prefix
  Enter a value: homeAdvisor
 
var.ssh_keypair
  Enter a value: ~/.ssh/id_rsa.pub
 
var.vpc_id
  Enter a value: vpc-64e6e10
```
 
 
Connect to both nodes, unminimize both nodes, and reboot
```
ssh ubuntu@[IP_ADDR]
sudo unminimize;reboot
```
 
### 2) Connect the nodes together
 
1. For each node/vm, log in as root as a shortcut 
```sudo su -```
 
2. Get the shared secret key used to connect nodes to a cluster. ssh into "server" and copy the contents of: 
```/var/lib/rancher/k3s/server/node-token```
 
3. ssh into "worker" and edit script at ```/root/k3s.sh```, replacing the endpoint URL with the internal AWS IP of the "server" and the node token with the token from step 2 
 
4) On the worker, run the ```/root/ks3.sh``` script
 
### 3) Verify the cluster is up and nodes are connected. On the server...

```
systemctl status k3s
```
displays the service as active. 
 
```
kubectl get nodes -o wide
```
will display two nodes registered
 
```
kubectl get pods -A -o wide
```   
Views all running pods
 
### 4) Verify the core endpoints are up (Optional)
 
NOTE: In the interests of time (and security) external access into the cluster endpoints is done using ssh port forward 
 
ssh port forward
```ssh -L 12345:127.0.0.1:6443 ubuntu@[PUBLIC_IP_OF_SERVER]```
 
Run...
```
kubectl cluster-info
```
Expected outout:
```bash
Kubernetes master is running at https://127.0.0.1:6443
CoreDNS is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy
```

### App Deployment

Create the namespace:
```
kubectl create namespace retail-project-dev
```
 
Download the manifest:
```
curl -X GET -L https://gist.githubusercontent.com/fransafu/4075cdcaf2283ca5650e71c7fd8335cb/raw/19d7cfa0f82f1b66af6e39389073bcb0108c494c/simple-rest-golang.yaml > simple-rest-golang.yaml
```
 
Create ingress, service, and deployment:
```
k3s kubectl apply -f simple-rest-golang.yaml
```
 
Check ingress (its show your IP), service and pods:
```
k3s kubectl get ingress,svc,pods -n retail-project-dev
```
 
Test the cluster locally on the servers
```
curl -X GET http://localhost
```
 
This is the output...
```
{"data":"RESTful with two Endpoint /users and /notes - v1.0.0"}
```

-----------

## Monitoring 
### Core cluster management
Chose to use kubernetes dashboard for cluster management


### Cluster monitoring
https://www.datadoghq.com/dg/monitor/kubernetes-monitoring-benefits/?utm_source=Advertisement&utm_medium=GoogleAds&utm_campaign=GoogleAds-KubernetesBroad&utm_keyword=%2Bkubernetes&utm_matchtype=b&gclid=Cj0KCQjwg8n5BRCdARIsALxKb95YjXuQgtpj2tcHJMJlDJ8WDSTkKz14Sn3vAjzo52-4BEywFTxdfpkaAtLSEALw_wcB

### Cluster alerting (on-call etc)
victor ops

## Authors

* **Rhys Campbell ** - *Initial work* - 

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acks
* Hat tip to the guys at Rancher for k3s.

