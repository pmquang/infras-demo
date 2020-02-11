#!/bin/bash

amazon-linux-extras install docker -y

service docker restart
$(aws ecr get-login --no-include-email --region ap-southeast-1)

docker run --name mpi-cluster-api-gateway -it -e APP_PORT=80  -d --network host -v /mnt/efs/share/:/share -v /mnt/efs/compute/tmp/mpi/.ssh/:/tmp/mpi/.ssh/ ${AWS_API_GATEWAY_DOCKER_REPO}:${AWS_API_GATEWAY_DOCKER_TAG}
