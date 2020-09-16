# Single instance rendering using IndeX native web viewer

## Launch an EC2 instance with the NVIDIA IndeX AMI:

- To launch an instance, please use the following CloudFormation template form: [TODO](link). Alternatively, you can also use the aws cli tool to launch the CloudFormation template:
```sh
aws cloudformation deploy --stack-name single-instance-index-cfn --template-file index-single-gpu.yml --parameter-overrides 'KeyName=<your-keyname>' --capabilities CAPABILITY_IAM
```

- You can launch any type of Amazon EC2 GPU instances (G4 or P3) based on your dataset requirements.
- For this example launch a *p3.8xlarge* instance (which has 4 NVIDIA V100s, total of 64GB of GPU memory) using the custom AMI.
- Please remember your selected NICE DCV password for the step below.

## Accessing

- Open a Linux Terminal and enable SSH tunneling:
```sh
ssh -N -L9999:localhost:8080 ubuntu@<your-public-IP> -i <your-key>.pem
```
This command tells SSH to connect to instance as ubuntu user, open port 9999 on your local laptop, and forward everything from there to localhost:8080 on the instance.
When the tunnel is established, you can point your browser at `http://localhost:9999` to connect to your private web server on port 8080.
- Keep this terminal running

## Connect to instance

- Open a new Linux terminal and login to the instance:
```sh
ssh ubuntu@<your-public-ip> -i <your-key>.pem
```

## Launching the NVIDIA IndeX Viewer

- From the terminal go to the viewer directory and launch the viewer with a sample scene (Core-Collapse Supernova in this example):
```sh
cd /opt/nvidia-index/demo
./nvindex-viewer.sh --add /opt/scenes/00-supernova_ncsa_small/scene/scene.prj
```

- Wait for the scene file to load. You should get the following output once data loading is ready:
```
[viewer] Application layer viewer server is running at http://<your-IP>:8080
```

- Open your browser (preferrably Chrome) on your client (laptop or PC) and point it to `http://localhost:9999`. `9999` being the Port Number you used during SSH tunneling.

- You should be able to visualize the output and play with colormap, region of interest etc.

## Using other samples

The image comes with a few other sample datasets. Here's how to run them:

* Cholla
    - `./nvindex-viewer.sh --add /opt/scenes/03-cholla/scene/scene.prj`
* Fly Brain - Microscopy
    - `./nvindex-viewer.sh --add /opt/scenes/04-microscopy-exllsm/scene/scene.prj`
* Big Brain
    - `./nvindex-viewer.sh —-add /opt/scenes/01-brain/scene/scene.prj`
* Parihaka - Seismic Data - Clipped
    - `./nvindex-viewer.sh --add /opt/scenes/020-parihaka-small/scene/scene.prj`
* Parihaka - Seismic Data - Full Volume
    - `./nvindex-viewer.sh --add /opt/scenes/021-parihaka-large/scene/scene.prj`
* Parihaka - Seismic Data - Slices
    - `./nvindex-viewer.sh —-add /opt/scenes/022-parihaka-planes/scene/scene.prj`

Please note that some datasets require multiple nodes. Please refer to the sample dataset referance page [here](https://github.com/NVIDIA/nvindex-cloud/blob/master/doc/datasets.md).

The datasets are read from the s3 bucket.
