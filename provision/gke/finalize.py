#!/usr/bin/python3
#*****************************************************************************
# Copyright 2020 NVIDIA Corporation. All rights reserved.
#*****************************************************************************

import subprocess
import argparse
import datetime
import json
import time


def get_options():
    parser = argparse.ArgumentParser(
        description='Provision a Kubernetes cluster in GKE.')
    parser.add_argument(
        '-c', '--cluster', type=str, default=None,
        help='K8s cluster to configure'
    )
    parser.add_argument(
        '-i', '--image', type=str, default='',
        help='Base distro OS image used in nodes.'
    )
    parser.add_argument(
        '-z', '--zone', type=str, default=None,
        help='Zone where the GPU cluster is running in.'
    )

    args = parser.parse_args()
    return args


def run_cmd(cmd):
    output = ''
    try:
        output = subprocess.check_output(cmd)
    except subprocess.CalledProcessError as e:
        print("Error running command: {}".format(cmd))

    return output


def wait_for_gpus(cluster_name, timeout=datetime.timedelta(minutes=15)):
    ''' Wait until nodes are available in GPU cluster. '''

    cmd = [
            'kubectl', 'get', 'nodes',
            '-l', 'cloud.google.com/gke-nodepool={}-gpu-pool'.format(cluster_name),
            '-o=jsonpath=\"{.items}\"'
    ]

    end_time = datetime.datetime.now() + timeout
    print('Waiting for GPUs to be ready ', end='')
    while datetime.datetime.now() <= end_time:
        output = run_cmd(cmd)
        items = json.loads(output.decode('UTF-8')[1:-1])

        for i in items:
            gpus = int(i['status']['capacity'].get('nvidia.com/gpu', '0'))
            if gpus > 0:
                print('OK')
                return

        print('.', end='')
        time.sleep(10)
       

if __name__ == '__main__':
    opts = get_options()

    print('Getting credentials for cluster ...')
    run_cmd(['gcloud', 'container', 'clusters', 'get-credentials', opts.cluster, '--zone', opts.zone])

    print('Enabling Application CRD...')
    app_crd_path = 'https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml'
    run_cmd(['kubectl', 'apply', '-f', app_crd_path])

    print('Enabling GPUs in GPU cluster...')
    nv_daemonset = 'https://raw.githubusercontent.com/NVIDIA/nvindex-cloud/master/resources/daemonset-{}-nv.yaml'.format(opts.image.lower())
    run_cmd(['kubectl', 'apply', '-f', nv_daemonset])

    wait_for_gpus(opts.cluster)
