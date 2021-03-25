# Single instance rendering using IndeX for ParaView plugin

## Launch an EC2 instance with the NVIDIA IndeX AMI:

- Go to the [NVIDIA IndeX](http://aws.amazon.com/marketplace/pp/B08H4D3QZR) offering in the AWS Marketplace and subscribe to the image.
- To launch an instance, please use the following CloudFormation template [form](https://console.aws.amazon.com/cloudformation/home?#/stacks/create/template?templateURL=https://s3.amazonaws.com/awsmp-fulfillment-cf-templates-prod/2d798e89-e16a-4f0c-832f-938c342f6c29.3e0d1257-5054-4b23-b8be-a53904a6fd68.template). Alternatively, you can also use the aws cli tool to launch the CloudFormation template:
```
aws cloudformation deploy --stack-name single-instance-index-cfn --template-file resources/index-single-ami-cloud-formation-template.yaml --parameter-overrides 'KeyName=<your-keyname>' --capabilities CAPABILITY_IAM
```

- You can launch any type of Amazon EC2 GPU instances (G4 or P3) based on your dataset requirements.
- For this example launch a *p3.8xlarge* instance (which has 4 NVIDIA V100s, total of 64GB of GPU memory) using the custom AMI.
- Please remember your selected NICE DCV password for the step below.

## Configure Security groups on your EC2 instance

- By default, the NICE DCV server is configured to communicate over port 8443.

- During the "Configure Security Group" of instance launch, add `Custom TCP` and enter Port `8443` in inbound rules of the security group for the instance. You might want to add the SSH port as well at this stage.

## Connect to the instance using the DCV Client or Web-browser:

- Note: You can download the NICE DCV Client from [here](https://download.nice-dcv.com/)
- OR Open your preferred web browser and enter the NICE DCV server URL in the following format `https://<server_public-ip>:8443`
- To log in, enter `ubuntu` as username and the password selected in the CloudFormation template (default value: `IndeXonAW$`).

If the DCV client/browser session can't log in because the session doesn't exist, you will have to ssh into the node and start a session yourself:
```sh
dcv create-session mysession
dcv list-sessions
```

Now you should be able to log in.

## Download and Start ParaView

- Run the utility script to install ParaView with NVIDIA IndeX enabled:
```sh
/opt/scripts/install-paraview.sh
```

- Start ParaView:
```sh
ParaView-5.8.1-MPI-Linux-Python3.7-64bit/bin/paraview
```

## Opening the sample dataset

- Fetch the sample supernova dataset:
```sh
cd ~/Downloads
wget https://nvindex-datasets-us-west2.s3-us-west-2.amazonaws.com/scenes/00-supernova_ncsa_small/data/Export_entropy_633x633x633_uint8_T1074.raw 
```

- Click on `File → Open → <path-to> → Export_entropy_633x633x633_uint8_T1074.raw`
    - Click OK
    - Open Data with `Image Reader`

- Update the properties for this data set.
    - The data set used here is `unsigned char` data type
    - Confirm the Data Byte Order for your system (LittleEndian vs. BigEndian). You can use [this](https://www.geeksforgeeks.org/little-and-big-endian-mystery/) to find out. For example, on a x86 system you would select Little Endian.
    - Data Extent is the X, Y, Z dimension of the dataset (its specified in the name of file). For this dataset it would be [0, 632] for X, Y and Z dimensions.

- Change colouring from `SolidColor` to `ImageFile`.

- Change representation to use the NVIDIA Index renderer: Click on the `Outline` dropdown and select `NVIDIA IndeX`.

- At this point you should see a colured cube. Change the data range (via colormap or `Rescale to Data Range` button) to  to `[25, 255]`.

- At this point you should see the features of the dataset. Feel free to use the colormap to highlight different features.

- Here's a sample rendering screenshot:
![](images/paraview_supernova.jpeg)

- The dataset shown here is a time step in a core-collapse supernovae simulation. [Credits](https://github.com/NVIDIA/nvindex-cloud/blob/master/doc/datasets.md#core-collapse-supernova)

