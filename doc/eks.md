# Running NVIDIA IndeX in AWS EKS

This guide will explain how to deploy the NVIDIA IndeX container in a EKS cluster with further
instructions on how to load a sample dataset. The idea is simple: set up a EKS cluster (or use
and existing one) and install the NVIDIA IndeX via the helm chart.

## Provisioning a EKS cluster

To run the NVIDIA IndeX container, an EKS cluster with NVIDIA GPU nodes is required. The simplest way to
provision an EKS cluster (if you don't have one) is to use the provisioning script from this repository:

```
./provision/eks.sh --password mypassword
```

(Tested with awscli 2.7.21 and eksctl 0.107.0.)

Once the script is done, you will find instructions how to install the helm chart:
```
2022-08-10 11:56:16 [ℹ]  eksctl version 0.66.0
2022-08-10 11:56:16 [ℹ]  using region us-east-1

...

EKS cluster ready deployed at https://a3ade41bbf77749e492276bd456c625b-155198297.us-east-1.elb.amazonaws.com.

To start a IndeX session run:

helm install test charts/nvindex \
    --values charts/nvindex/eks.yaml \
    --set ingress.host=a3ade41bbf77749e492276bd456c625b-155198297.us-east-1.elb.amazonaws.com \
    --wait
```

The provisioning script does the following steps:
- Starts a EKS cluster with GPU instances (g4dn.xlarge by default).
- Attaches the required IAM policies to allow S3 and AWS Marketplace API access.
- Installs a ingress-nginx ingress with SSL termination and basic HTTP authentication.
- Creates a secret for for HTTP authentication.

The following steps will assume that this provisioning script has been used. Please take note of
ingress address, as this will be the entrypoint for the deployments.

If you already have an existing EKS cluster with NVIDIA GPUs, you can have a look at the provisioning
script to pick and choose what you need. For example, an ingress might not be required for your case.


## Starting up a NVIDIA IndeX Session

Starting a NVIDIA IndeX session is easy, it's just a matter of following the instructions
provided by the provisioning script:
```sh
helm install mysession charts/nvindex \
    --values charts/nvindex/eks.yaml \
    --set ingress.host=a3ade41bbf77749e492276bd456c625b-155198297.us-east-1.elb.amazonaws.com \
    --wait
```

And you would get something like this:
```
NAME: test
...
NOTES:
You have successfully installed the NVIDIA IndeX application in your cluster as "test".It should
be accessible under:
https://a3ade41bbf77749e492276bd456c625b-155198297.us-east-1.elb.amazonaws.com/test-nvindex
```

Once the deployment is ready, you can access it via the browser (Google Chrome). The provided password
and username (default: nvindex) should be used. Once logged in, you should be able to see a synthetic dataset
(it might take some seconds before it shows up):

![screenshot](images/synthetic_data.png).

Stopping the session is as simple as deleting the chart:
```sh
helm uninstall mysession
```

## Loading data

Loading data with NVIDIA IndeX can be done either statically via a project file or dynamically using
the WebSocket based JSONRPC API.

For this exercise we have provided [sample datasets](datasets.md) to work with. Please have a look at
the dataset documentation for GPU sizing information. All the sample scenes
are shipped with the helm chart under `charts/nvindex/scenes`

### Loading Data via a Project File

Let's pick the Supernova dataset:

```sh
helm install mysession charts/nvindex \
    --values charts/nvindex/eks.yaml \
    --set ingress.host=a3ade41bbf77749e492276bd456c625b-155198297.us-east-1.elb.amazonaws.com \
    --set scene=scenes/00-supernova_ncsa_small \
    --wait
```

The project directory is mounted as a Kubernetes ConfigMap to the viewer Pod. The data itself will
be loaded from the S3 bucket.

Please take note of the GPU requirements documented in the [datasets](datasets.md) document. Also
be aware that loading the dataset can take minutes, depending on how large the datafile is.

If all went well, you should see the rendering:

![screenshot](images/supernova.png)

You can also start with an empty scene by setting the scene option to `scene=scenes/empty`.

### Loading Data with the WebSocket JSONRPC API

To demonstrate how to use the WebSocket based JSONRPC API, we will use a Jupyter Notebook. The notebook
is located under `notebooks/dataset.ipynb`. Please note that it has some pre-requisites:
    - The `websocket-client` python package installed.
    - The `notebooks/nvindex_util.py` file in the path of the Jupyter Notebook.

With these pre-requisites ready, and having the session url (from the helm install output) and password
(from the EKS cluster setup) at hand, you are ready to load the Notebook. You can use an existing session
or start a new one, as described above.

Forther information can be found in the notebook itself.

## Stopping the EKS cluster

To stop the cluster, just run:
```sh
./provision/eks.sh
```

If you used your own name and/or region, you would need to specify them via the command line:
```sh
./provision/eks.sh --name myclustername --region us-west-2
```

## Useful Options

These options can be found in `charts/nvindex/values.yaml`.

### Multi-Node and Multi-GPU deployments

To deploy the NVIDIA IndeX on multiple nodes, you can use the `nodeCount` and `gpuCount` options.

### Disabling Ingress

To deploy NVIDIA IndeX without an Ingress, just set the `ingress.enabled` option to `false`. This
will expose the Viewer Service into a LoadBalancer service which can be accessed directly.


## Architecture

A simplified overview of all the used components can be seen in the following diagram:

![architecture](images/eks_diagram.svg)



The provisioned EKS cluster contains the following additional components:

- The NVINX controller is used for doing TLS termination, handling basic authentication and most
importanly putting all sessions behind one LoadBalancer endpoint.

- The `nvindex-basic-auth-secret` is used as a secret for basic authentication.

- The `ingress-tls-secret` is used for storing a (self-signed) certificate.

