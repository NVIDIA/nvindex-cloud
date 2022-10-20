#!/usr/bin/bash

REGION=us-east-2
CLUSTER_NAME=kube1

VM_SIZE_GPU=g4dn.xlarge

POOL_SIZE_INIT=1
POOL_SIZE_MIN=1
POOL_SIZE_MAX=7

USER=nvindex
PASSWORD=test123
USE_SPOT=false

usage()
{
    echo "Usage: $0 [options...]"
    echo
    echo "This script starts a EKS cluster that is ready to run the NVIDIA IndeX deployment."
    echo "To stop the cluster use the '--stop' switch."
    echo
    echo "Options:"
    echo "  --stop, --delete  : Delete AKS cluster and associated resources."
    echo "  --spot            : Use spot instances for GPU nodes."
    echo "  --cluster-name    : Use a different cluster name (default: $CLUSTER_NAME)."
    echo "  --gpu-vm-size     : Set a different gpu node type (default: $VM_SIZE_GPU)."
    echo "  --region          : Set a region (default: $REGION)."
    echo "  --username        : Set a different username (default: $USER)."
    echo "  --password        : Set a different password (default: $PASSWORD)."
    echo "  --help            : This help screen."
    echo
}

checktool()
{
    which $1 &> /dev/null
    if [ $? -ne 0 ]; then
		echo "$1 not present. $2"
        exit 1
	fi
}

checkenv()
{
    checktool kubectl "Please install: https://kubernetes.io/docs/tasks/tools/install-kubectl"
    checktool eksctl "Please install: https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html"
    checktool helm "Please install: https://helm.sh/docs/intro/install"
	checktool openssl "Please install via package management."
	checktool htpasswd "Please install via package management."
	checktool jq "Please install via package management."
}

ARGS=("$@") # Work on a local copy of the argument list
NUMARGS=${#ARGS[@]}
for ((i=0; i < $NUMARGS; i++)); do
    ARG=${ARGS[i]}
    case $ARG in
        --stop|--delete)
            STOP=1
            unset ARGS[$i]
            ;;
        --help)
            usage
            unset ARGS[$i]
            exit 0
            ;;
        --spot)
            USE_SPOT=true
            unset ARGS[$i]
            ;;
        --cluster-name)
            unset ARGS[$i]
            let i++
            CLUSTER_NAME=${ARGS[$i]}
            unset ARGS[$i]
            ;;
        --region)
            unset ARGS[$i]
            let i++
            REGION=${ARGS[$i]}
            unset ARGS[$i]
            ;;
        --gpu-vm-size)
            unset ARGS[$i]
            let i++
            VM_SIZE_GPU=${ARGS[$i]}
            unset ARGS[$i]
            ;;
        --username)
            unset ARGS[$i]
            let i++
            USER=${ARGS[$i]}
            unset ARGS[$i]
            ;;
        --password)
            unset ARGS[$i]
            let i++
            PASSWORD=${ARGS[$i]}
            unset ARGS[$i]
            ;;
    esac
done

checkenv

if [[ $STOP == 1 ]]; then
    echo "Stopping EKS cluster $CLUSTER_NAME."
    eksctl delete cluster --region $REGION --name $CLUSTER_NAME
    exit 0
elif [[ $1 == "--help" ]]; then
    echo $0 " [--stop|--help]"
    echo "  Provision a AKS cluster. Default action: start cluster"
    echo "  --stop: delete a previously started cluster"
    echo "  --help: this screen"
    exit 0
fi


cat <<EOF > /tmp/cluster.yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: $CLUSTER_NAME
  region: $REGION

iam:
  withOIDC: true
  serviceAccounts:
  - metadata:
      name: nvindex-access
    attachPolicyARNs:
    - "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
    - "arn:aws:iam::aws:policy/AWSMarketplaceMeteringRegisterUsage"

managedNodeGroups:
  - name: ng-1
    instanceType: $VM_SIZE_GPU
    minSize: $POOL_SIZE_MIN
    maxSize: $POOL_SIZE_MAX
    desiredCapacity: $POOL_SIZE_INIT
    spot: $USE_SPOT
EOF

set -e
eksctl create cluster -f /tmp/cluster.yaml
set +e

echo "Set up Ingress: "

# Install the nginx ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install helm chart
helm install ingress-nginx ingress-nginx/ingress-nginx --wait

# Get the ingress service hostname, as we can't configure it
HOST=$(kubectl get service ingress-nginx-controller -o json | jq -r .status.loadBalancer.ingress[0].hostname)
APP_NAME=$(echo $HOST | cut -d . -f 1)

# set -x

# Now that we have the hostname, self signed certificate + secret can be created:
openssl req -new -x509 \
    -sha256 -nodes \
    -days 365 -newkey rsa:2048 \
    -keyout /tmp/tls.key -out /tmp/tls.crt \
    -subj "/CN=elb.amazonaws.com/O=nvindex" \
    -addext "subjectAltName = DNS:$HOST"

kubectl create secret tls ingress-tls-secret --key /tmp/tls.key --cert /tmp/tls.crt
kubectl annotate secret ingress-tls-secret app.nvindex.io/host="$HOST"

# Update helm chart with the certificate
helm upgrade ingress-nginx ingress-nginx/ingress-nginx \
    --set controller.extraArgs.default-ssl-certificate=default/ingress-tls-secret

# Generate user/pw
htpasswd -b -c /tmp/auth $USER $PASSWORD
kubectl create secret generic nvindex-basic-auth-secret --from-file=/tmp/auth

echo ""
echo "EKS cluster ready deployed at https://$HOST."
echo ""
echo "To start a IndeX session run:"
echo ""
echo "helm install test charts/nvindex \\"
echo "    --values charts/nvindex/eks.yaml \\"
echo "    --set ingress.host=$HOST \\"
echo "    --wait"

