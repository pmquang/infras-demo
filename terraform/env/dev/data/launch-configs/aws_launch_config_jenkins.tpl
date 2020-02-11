#!/bin/bash

amazon-linux-extras install docker -y

service docker restart
systemctl enable docker

mkdir -p /mnt/efs

grep "/mnt/efs" /etc/fstab || echo "${AWS_JENKINS_EFS_DNS_NAME}:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" >> /etc/fstab

while true; do
  sleep 5
  mount -a
  df -h | grep "/mnt/efs" && break
done

mkdir -p /mnt/efs/jenkins/jenkins_home

$(aws ecr get-login --no-include-email --region ap-southeast-1)
docker run --name jenkins-master --restart always --log-opt awslogs-create-group=true --log-driver=awslogs --log-opt awslogs-region=${AWS_JENKINS_AWS_LOG_REGION} --log-opt awslogs-group=${AWS_JENKINS_AWS_LOG_GROUP} --log-opt awslogs-stream=${AWS_JENKINS_AWS_LOG_STREAM} --privileged -it -d -p 8080:8080 -v /tmp:/tmp -v /mnt/efs/jenkins/jenkins_home:/var/jenkins_home/ ${AWS_JENKINS_MASTER_DOCKER_REPO}:${AWS_JENKINS_MASTER_DOCKER_TAG}
