# Cluster Rendering using AWS ParallelCluster and IndeX native web viewer

# Custom Amazon Machine Image (AMI):

- Please go to the [NVIDIA IndeX](TODO) offering in the AWS Marketplace and subscribe to the image.
- Once subscribed, please get the AMI id for your region.
- Note: AMI is associated with an Amazon EC2 Region. An instance needs to be launched in the same region as the AMI. 

## ParallelCluster Configuration:

- If you are new to AWS ParallelCluster refer to this [blog](https://aws.amazon.com/blogs/opensource/aws-parallelcluster/) 
- To install AWS ParallelCluster refer to this [guide](https://docs.aws.amazon.com/parallelcluster/latest/ug/install.html)
  ```sh
  pip3 install aws-parallelcluster==2.8.0 --upgrade --user
  ```
  Important: The custom AMI provided is tied to a specific ParallelCluster version. So make sure to install the specific ParallelCluster version, in this case 2.8.0.

- Please use the parallel cluster configuration [template](pcluster_template.config) to create your config file.
- Once you customized the config file, please copy it to `~/.parallelcluster/config`.
- Note: the template configuration enables remote desktop visualization using NICE DCV. To learn more about about NICE DCV refer [here](https://aws.amazon.com/hpc/dcv/)

## Create the cluster:

- To create the cluster, please run the following command:
  ```sh
  pcluster create <cluster-name> -c <path-to-config-file>
  ```

- The given config template creates a cluster with 4 `p3.8xlarge` instances for the compute nodes (each with 4 V100 GPUs) and 1 `g4dn.4xlarge` instance for the master node. You can always modify the instance types in the configuration through the `compute_instance_type` and `master_instance_type` fields.

## Connect to the Remote desktop (NICE DCV server) on the master instance:

- To start or connect to a NICE DCV session on the master instance, run:
  ```sh
  pcluster dcv connect <cluster-name> -k <your-key.pem>
  ```

- This will start a Remote Desktop session and connect to the master instance using a web browser.

- Note: If the above command doesn't or can't start the browser, please add the `-s` option to get a session url that you can copy into your browser. This url expires after 30 seconds.


## Launch the SLURM script to start cluster rendering and visualize using IndeX viewer:

- Here, we run the Supernova dataset on 4 nodes
  ```sh
  cd /opt/nvidia-index/demo`
  salloc -N4 --exclusivbe
  srun -N4 nvindex-slurm -v ./nvindex-viewer.sh --add /opt/scenes/00-supernova_ncsa_small/scene/scene.prj  -dice::log_timestamp yes
  ```

- You should see the following output once all the data has been loaded:
  ```
  [viewer] Application layer viewer server is running at http://<ip-address>:8080
  ```
- You can run a different datasets by selecting a different scene file by using the `--add` option.

## Connecting to the NVIDIA IndeX viewer:

- Open the Chrome browser in the NICE DCV session.
- Connect to the http address obtained in the previous step.
- You should be able to visualize the output and play with colormap, region of interest etc.
- Preferably use the latest version of the Chrome browser.

## Scaling the node count for NVIDIA IndeX

- Before starting, please note that the provided AMI has the SLURM enabled job expansion (`SchedulerParameters=permit_job_expansion`) enabled. For more information, please look in the SLURM [FAQ](https://slurm.schedmd.com/faq.html#job_size)

- To *add* nodes to the running instance of NVIDIA IndeX a new job will have to be created that _attaches_ to the existing job:
  - Allocate a new job with new nodes:
  ```sh
  salloc -N<new-nodes-to-add> --exclusive
  ```
    This can take a while if new instances need to be spun up to satisfy the node requirement.
  - Find the original job id through the `squeue` command.
  - Create a new job that "attaches" to the initial job id:
  ```sh
  cd /opt/nvidia-index/demo
  srun -N<nodes-to-add> nvindex-slurm -a<initial-job-id> ./nvindex-viewer.sh
  ```

  This will run the `nvindex-slurm` wrapper script which will launch processes only as remote rendering agents that will connect to the head node of the initial job's cluster.
  The `--exclusive` flag for `srun` is required to make sure that the new job is not scheduled on nodes that are already running a job. If `--exclusive` doesn't match your use-case, you can also exclusively launch jobs based on the GPU count requirement: `--gpus=<number-of-gpus-per-compute-node>`.

- To *remove* nodes, you can use SLURM's `scontrol` tool:
  ```sh
  scontrol update JobId=<desired job id> NumNodes=<less-nodes-than-previously>
  ```
