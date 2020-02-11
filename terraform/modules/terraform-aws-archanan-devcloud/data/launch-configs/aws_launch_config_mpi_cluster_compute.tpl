#!/bin/bash

amazon-linux-extras install docker -y

service docker restart

mkdir -p /mnt/efs/

grep "/mnt/efs" /etc/fstab || echo "${AWS_EFS_DNS_NAME}:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" >> /etc/fstab

while true; do
  sleep 5
  mount -a
  ls /mnt/efs | grep "compute" && break
done

$(aws ecr get-login --no-include-email --region ap-southeast-1)

docker run --name mpi-cluster-compute -it -d --network host -v /mnt/efs/share/:/share -v /mnt/efs/compute/tmp/mpi/.ssh/:/tmp/mpi/.ssh/ ${AWS_MPI_COMPUTE_DOCKER_REPO}:${AWS_MPI_COMPUTE_DOCKER_TAG}
