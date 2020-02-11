#!/bin/bash

mkdir -p /mnt/efs

grep "/mnt/efs" /etc/fstab || echo "${AWS_EFS_DNS_NAME}:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" >> /etc/fstab

yum install epel-release -y
yum install nfs-utils jq munge munge-libs munge-devel wget mariadb-server libgfortran libquadmath gcc openssh-clients python3 python3-pip -y
pip3 install awscli --upgrade
rpm -i https://s3.amazonaws.com/packages.archanan.io/slurm-17.11.12-1.el7/slurm-17.11.12-1.el7.x86_64.rpm
rpm -i https://s3.amazonaws.com/packages.archanan.io/slurm-17.11.12-1.el7/slurm-libpmi-17.11.12-1.el7.x86_64.rpm
rpm -i https://s3.amazonaws.com/packages.archanan.io/openmpi-3.0.2-1.el7/openmpi-3.0.2-1.el7.x86_64.rpm

mkdir /tmp/installation/ && cd /tmp/installation/

aws s3 cp s3://releases.archanan.io/archanan-api-gateway/rpm/archanan-api-gateway-0.1.0-1689.el7.x86_64.rpm .
aws s3 cp s3://releases.archanan.io/archanan-api-gateway/rpm/archanan-api-gateway-build-service-0.1.0-1689.el7.x86_64.rpm .
aws s3 cp s3://releases.archanan.io/archanan-api-gateway/rpm/archanan-api-gateway-exec-service-0.1.0-1689.el7.x86_64.rpm .
aws s3 cp s3://releases.archanan.io/archanan-api-gateway/rpm/archanan-api-gateway-file-service-0.1.0-1689.el7.x86_64.rpm .

rpm -ivh archanan-api-gateway*.rpm

while true; do
  sleep 5
  mount -a
  df -h | grep "/mnt/efs" && break
done

mkdir -p /mnt/efs/share/
ln -sf /mnt/efs/share /share
mkdir -p /mnt/efs/compute/tmp/mpi/.ssh/
touch /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa
touch /root/.ssh/id_rsa.pub

mkdir -p /var/archanan/mpi-example/

cat << 'EOF' > /usr/local/bin/mpi.sh
#!/bin/bash

for i in `aws elbv2 describe-target-health --target-group-arn ${AWS_MPI_COMPUTE_TARGET_GROUP_ARN} \
| jq -r -c '.TargetHealthDescriptions | .[] | select(.TargetHealth.State=="healthy") | .Target.Id'`
do
  aws ec2 describe-instances --instance-ids $i | jq -r '.Reservations[0].Instances[0].PrivateIpAddress'
done > /etc/hostfile
EOF

chmod +x /usr/local/bin/mpi.sh

echo "export AWS_DEFAULT_REGION=ap-southeast-1" >> /etc/bashrc
echo "export PATH=$PATH:/usr/local/bin/" >> /etc/bashrc

cat << 'EOF' > /etc/systemd/system/multi-user.target.wants/archanan-api-gateway.service
[Unit]
Description=Archanan API Gateway
After=network-online.target docker.socket firewalld.service
Wants=network-online.target
[Service]
Type=simple
Environment=AWS_DEFAULT_REGION=us-east-1
ExecStart=/bin/bash --login -c "/usr/bin/archanan-api-gateway --port 80"
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s
TimeoutSec=200s
[Install]
WantedBy=multi-user.target
EOF

cat << 'EOF' > /etc/systemd/system/multi-user.target.wants/archanan-api-gateway-build-service.service
[Unit]
Description=Archanan API Gateway Build Service
After=network-online.target docker.socket firewalld.service archanan-api-gateway.service
Wants=network-online.target
[Service]
Type=simple
Environment=AWS_DEFAULT_REGION=us-east-1
ExecStart=/bin/bash --login -c "/usr/bin/archanan-build-service --gateway ws://localhost:80"
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s
TimeoutSec=200s
[Install]
WantedBy=multi-user.target
EOF

cat << 'EOF' > /etc/systemd/system/multi-user.target.wants/archanan-api-gateway-exec-service.service
[Unit]
Description=Archanan API Gateway Exec Service
After=network-online.target docker.socket firewalld.service archanan-api-gateway.service
Wants=network-online.target
[Service]
Type=simple
Environment=AWS_DEFAULT_REGION=us-east-1
ExecStart=/bin/bash --login -c "/usr/bin/archanan-exec-service --gateway ws://localhost:80"
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s
TimeoutSec=200s
[Install]
WantedBy=multi-user.target
EOF

cat << 'EOF' > /etc/systemd/system/multi-user.target.wants/archanan-api-gateway-file-service.service
[Unit]
Description=Archanan API Gateway File Service
After=network-online.target docker.socket firewalld.service archanan-api-gateway.service
Wants=network-online.target
[Service]
Type=simple
Environment=AWS_DEFAULT_REGION=us-east-1
ExecStart=/bin/bash --login -c "/usr/bin/archanan-file-service --gateway ws://localhost:80"
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s
TimeoutSec=200s
[Install]
WantedBy=multi-user.target
EOF

cat << 'EOF' > /root/.ssh/config
Host ${AWS_MPI_COMPUTE_HOST}
  Port 2222
  User mpi
  StrictHostKeyChecking no
  LogLevel ERROR
  UserKnownHostsFile /dev/null
EOF

cat << 'EOF' > /root/.ssh/id_rsa
${AWS_MPI_CLUSTER_PRIVATE_KEY}
EOF

cat << 'EOF' > /root/.ssh/id_rsa.pub
${AWS_MPI_CLUSTER_PUBLIC_KEY}
EOF

cat << 'EOF' > /mnt/efs/compute/tmp/mpi/.ssh/authorized_keys
${AWS_MPI_CLUSTER_PUBLIC_KEY}
EOF

systemctl daemon-reload
systemctl start archanan-api-gateway
systemctl start archanan-api-gateway-build-service
systemctl start archanan-api-gateway-exec-service
systemctl start archanan-api-gateway-file-service
