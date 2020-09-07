# Provisioning a Google Kubernetes Cluster with NVIDIA GPUs

This document describes how to provision a GKE cluster with NVIDIA GPUs that
will allow you to use the NVIDIA IndeX App from the GCP Marketplace.

Please note that this cluster is just for demonstration purposes and should not
be used as a production cluster.

The [GKE GPU Guide](https://cloud.google.com/kubernetes-engine/docs/how-to/gpus)
contains more information.

## Install the required tools

The following tools are required for provisioning the cluster:

- [gcloud](https://cloud.google.com/sdk/docs/quickstarts)
- [terraform](https://www.terraform.io/downloads.html)

## Counfigure the cloud environment 

Please run the following command to initialize the Google Cloud SDK:
```sh
gcloud init
```

And then this command to set up the application default credentials:
```sh
gcloud auth application-default login
```

## Spin up the GKE cluster

Go to the provisioning directory and initialize terraform:
```sh
cd provision/gke
terraform init
```

Now we are ready to create the deployment:
```sh
terraform apply
```

This cluster will be provisioned by default in zone `us-central1-a` and it
contains 2 node pools:
* A CPU node pool used to run the Kubernetes control plane.
* A GPU node pool used to run the NVIDIA IndeX applications.

By default, the GPU node pool will contain 1 `n1-standard-8` node with 1 T4 GPU.
There are some pre-baked configurations in the `configs` directory. For example,
`condifs/8xV100.tfvars` provisions nodes with 8xV100s:

```sh
terraform apply -var-file=configs/8xv100.tfvars
```

Provisioning includes a finalize step which does the follwing:
- Enables the Application CRD in the cluster (required for the Application).
- Configures the NVIDIA GPUs in the Kubernetes cluster with a CUDA 10.2
  compatible driver.

## Destroyinf the GKE cluster

Destroying the cluster is simply a matter of running:
```sh
terraform destroy
```
