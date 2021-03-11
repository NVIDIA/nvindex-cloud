# Running NVIDIA IndeX in Google Kubernetes Engine

This application allows you to run NVIDIA IndeX in a Kubernetes cluster. The
viewer that comes bundled with the NVIDIA IndeX release is used. By default, the viewer offers
the choice sample datasets. Users can also load their own data in
NVIDIA IndeX as described in the [Loading your own data](#loading-your-own-data) section.

The Kubernetes cluster in which the NVIDIA IndeX application is installed requires
NVIDIA GPUs for the application to run correctly.

The application can be launched either by "Click to Deploy" directly from the
Google Marketplace or by using the command line. Both launch choices are described in this
document.


## Architecture 

![Architecture diagram](images/nvindex-k8s-app-architecture.png)

The application starts an NVIDIA IndeX cluster instance, available from the
exposed viewer service on HTPP and HTTPS. The session is protected by a user ID
(nvindex) and a password. The password can be entered manually when launching the application 
from the command line interface or generated automatically when using "Click To Deploy".

The TLS certificates are generated automatically for "Click to Deploy" (self
signed). When using the command line interface, they have to be provided by the user. More details are
provided in the [Update your SSL certificate](#update-your-ssl-certificate)
section.

To achieve scaling of large volume data, NVIDIA IndeX runs in a cluster. For a cluster
of N pods, one node has the additional responsibility of serving the
UI (viewer?). All the other pods are workers. That means there is one viewer and N-1 workers
in a cluster of N nodes. In Kubernetes, this is modeled using two deployments:
    - The viewer stateful set: which has one replica.
    - The worker deployment: which has N-1 replicas.

For a cluster of size 1 (N=1), there is one viewer and zero workers.

A ClusterIP service is provided to provide the worker nodes with a discovery node address.
For public access, a LoadBalancer service is provided that points to the viewer
pod.

Loading your own data is covered in the [Loading your own data](#loading-your-own-data) section.


# Installation

## Provisioning a Kubernetes Cluster with GKE

A Kubernetes cluster in GKE is a pre-requuisite. Please follow the [GKE Provisioning](doc/gke-provisioning.md)
guide to get a demo cluster up and running.

## Quick Install using Google Cloud Marketplace

For a quick look at NVIDIA IndeX, you can launch it directly from the Google
Cloud Marketplace. Follow the
[on-screen instructions](https://console.cloud.google.com/marketplace/details/google/nvindex).

Before launching, make sure that you have NVIDIA GPUs available in the cluster.

## Command Line Installation

### Prerequisites

You will need the following tools in your development environment. If you are
using Cloud Shell, `gcloud`, `kubectl`, Docker, and Git are installed in your
environment by default.

-   [gcloud](https://cloud.google.com/sdk/gcloud/)
-   [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/)
-   [docker](https://docs.docker.com/install/)
-   [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
-   [helm](https://helm.sh/)

Configure `gcloud` as a Docker credential helper:

```shell
gcloud auth configure-docker
```

### Install the Application

The application is installed by expanding a Helm chart as shown in the next section.

### Expanding the manifest template

Use `helm template` to expand the template. It is recommended that you save the
expanded manifest file for future updates to the application. Here's an example
of expanding the template:

```shell
helm template chart/nvindex \
    --name nvindex-app \
    --set "name=nvindex-app" \
    --set "nodeCount=2" \
    --set "gpuCount=8" \
    --set "viewerGeneratedPassword=testme123" \
    --set "tls.base64EncodedPrivateKey=$TLS_CERTIFICATE_KEY" \
    --set "tls.base64EncodedCertificate=$TLS_CERTIFICATE_CRT" \
    --set "dataLocation=$NVINDEX_DATA_LOCATION" \
    --set "imageNvindex=$NVINDEX_IMAGE" \
    > nvindex_app_manifest.yaml
```

Here are the relevant template parameters:

  * Mandatory parameters:
    - name: Name of the application.
    - nodeCount: Number of nodes (n = 1 x viewer + (n-1) x workers) for the deployment
    - gpuCount: Number of gpus per deployment replica.
    - viewerGeneratedPassword: The password to be used for connecting to the viewer.

  * Optional parameters:
    - tls.base64EncodedCertificateKey: sets TLS Certificate. See the [TLS certificate section](#TLS-certificates)
    - tls.base64EncodedPrivateKey: sets TLS Private Key. See the [TLS certificate section](#TLS-certificates)
    - dataLocation: Path to a Google Storage Bucket that contains a custom dataset.
      More in the [Loading your own Data](#loading-your-own-data) section.

### TLS certificates

If you have your own certificate you can use that. Otherwise here's how to create
a test certificate:

```shell
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /tmp/tls.key \
    -out /tmp/tls.crt \
    -subj "/CN=nginx/O=nginx"

```

Set the `TLS_CERTIFICATE_CRT` and `TLS_CERTIFICATE_KEY` variables to your certificate:

```shell
export TLS_CERTIFICATE_KEY="$(cat /tmp/tls.key | base64)"
export TLS_CERTIFICATE_CRT="$(cat /tmp/tls.crt | base64)"
```

#### Install the application - apply the manifest

Use `kubectl` to apply the manifest to your Kubernetes cluster:

```shell
kubectl apply -f "nvindex_app_manifest.yaml" --namespace "${NAMESPACE}"
```

After the deployment is ready, check that the viewer service has a external
IP assigned and proceed to the next section.

*Optional*: It's possible to create the application in a namespace:

```shell
kubectl create namespace my-namespace
kubectl apply -f "nvindex_app_manifest.yaml" --namespace my-namespace
```

#### Connecting to the NVIDIA IndeX viewer

By default, the IndeX viewer is protected by basic HTTP authentication. The
username is `nvindex` and the password is stored in the password secret object.

The Application is available in the Google Cloud Console in the  Application
section of the Kubernetes Engine. You will get connection information on that
page.

You can also query it from the command line by getting the external ip of the
load balancer service.

HTTP is available. HTTPS is available only if TLS was configured.

Once logged in, you should see the NVIDIA IndeX application running, with a
sample dataset selection list.

### Delete the Application from the Kubernetes cluster

To stop the application, just remove the Kubernetes objects from the cluster,
by using the generated manifest:

```shell
kubectl delefe -f "nvindex_app_manifest.yaml"
```

# Loading your own data

If you want to load and visualize your own data, you must:

* Upload your data to a Google Storage Bucket.
* Write a scene file configuring where your data is located and how it should
  be rendered.
* Upload the scene data and meta-data to the same bucket as the data.


## Directory structure

The scene file location must respect a certain directory structure relative to the
selected `dataLocation`. For example, having `gs://your-bucket/root/` set as
`dataLocation`, the directory structure would be:

```
gs://your-bucket/root/example_dataset1/scene/
```

The scene file and metadata must go into `gs://your-bucket/root/example_dataset1/scene`.
The root directory `gs://your-bucket/root` is copied to the `/scenes`
directory in the container (except the data, which is accessed directly). The application
looks into the `/scenes` directory and scans for first level directories that
contain the path `scene/scene.prj` and that path contains a valid scene file.
All the directories matching this criteria are shown in the scene selector.

The data directory is not copied inside the container; the NVIDIA IndeX application
reads it directly from the bucket. This means that the data can be stored
in a different location/bucket.

## Scene file

When loading your own data, a scene configuration is required (`scene.prj`).
This file and it's dependencies (colormaps, xac shaders, etc) have to be
present in the same directory. 

The below section represents a skeleton scene file that can be used as a
starting point to load your own data. Just copy to a simple text file
and then upload it to the Google Storage bucket (as described in the previous
section).

```
#! index_app_project 0
# -*- mode: Conf; -*-

index::region_of_interest = 0 0 0 500 500 1500

app::scene::info::name = My Scene

app::scene::root::children = sparse_volume_data

#------------------------------------------------------------
app::scene::sparse_volume_data::type     = static_scene_group
app::scene::sparse_volume_data::children = svol_render_props svol_cmap xac_program sparse_volume_uint8

app::scene::xac_program::type        = rendering_kernel_program
app::scene::xac_program::target      = volume_sample_program
app::scene::xac_program::enabled     = true
app::scene::xac_program::source_string << (END)
class Volume_sample_program
{
    NV_IDX_VOLUME_SAMPLE_PROGRAM

    const nv::index::xac::Colormap colormap = state.self.get_colormap();

public:
    NV_IDX_DEVICE_INLINE_MEMBER
    void initialize() {}

    NV_IDX_DEVICE_INLINE_MEMBER
    int execute(
        const Sample_info_self& sample_info,
              Sample_output&    sample_output)
    {
        using namespace nv::index;

        const auto& svol         = state.self;
        const auto  svol_sampler = svol.generate_sampler<float,
                                                         xac::Volume_filter_mode::TRILINEAR>(
                                                            0u,
                                                            sample_info.sample_context);

        const float v = svol_sampler.fetch_sample(sample_info.sample_position_object_space);

        sample_output.set_color(colormap.lookup(v));

        return NV_IDX_PROG_OK;
    }
};
(END)

# setup rendering properties
app::scene::svol_render_props::type                 = sparse_volume_rendering_properties
app::scene::svol_render_props::filter_mode          = trilinear
app::scene::svol_render_props::sampling_distance    = 0.5

# map_type : procedural, lookup_table
app::scene::svol_cmap::type                 = colormap
app::scene::svol_cmap::map_index            = 0
app::scene::svol_cmap::map_type             = lookup_table
app::scene::svol_cmap::domain               = 0.0 1.0
app::scene::svol_cmap::domain_boundary_mode = clamp_to_edge

# The volume type. A sparse volume is able to manage dense and sparse volume datasets as well as multi-resolution data.
app::scene::sparse_volume_uint8::type                        = sparse_volume

# This option selects a specific data importer. The importer reads raw voxel data in a given order (see below).
app::scene::sparse_volume_uint8::importer                    = raw

# The voxel format. The present dataset's voxels are of type uint8. Currently, valid types are uint8, uint16, sint16, rgba8, float32.
app::scene::sparse_volume_uint8::voxel_format                = uint8

# By default, raw data is assumed to be stored in z-first/x-last order. In those cases, the option
# 'app::scene::sparse_volume_uint8::zyx_to_xyz' needs to be set to 'true'.
# The present dataset is assumed to be in x-first/z-last order:
app::scene::sparse_volume_uint8::convert_zyx_to_xyz                  = false

# The size of the dataset in the datasets local space:
app::scene::sparse_volume_uint8::size                        = 500 500 1500

# The bounding box defines the space the volume is defined in:
app::scene::sparse_volume_uint8::bbox                         = 0 0 0 500 500 1500

# Import directory:
# app::scene::sparse_volume_uint8::input_directory             = <YOUR_DIRECTORY>
app::scene::sparse_volume_uint8::input_directory             = /h/my/dataset/directory

# Name of the file:
#app::scene::sparse_volume_uint8::input_file_base_name        = <YOUR_FILE_NAME_WITHOUT_FILE_EXTENSION>
app::scene::sparse_volume_uint8::input_file_base_name        = my_file_name

# File extension:
app::scene::sparse_volume_uint8::input_file_extension        = .extension

# Cache data on disk for future accelerated data imports:
app::scene::sparse_volume_uint8::use_cache                       = false
```

Some examples scene files can be found in the sample dataset bucket:
`gs://nvindex-data-samples/scenes`.
