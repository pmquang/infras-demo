image:
  repository: k8s.gcr.io/cluster-autoscaler
  tag: v1.14.7
  pullPolicy: IfNotPresent

autoDiscovery:
  clusterName: ${AWS_EKS_CLUSTER_NAME}

podAnnotations:
  cluster-autoscaler.kubernetes.io/safe-to-evict: "false"

awsRegion: ${AWS_EKS_CLUSTER_REGION}


rbac:
  create: true
  serviceAccountAnnotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::${AWS_ACCOUNT_ID}:role/cluster-autoscaler"

extraArgs:
  balance-similar-node-groups: true
  skip-nodes-with-system-pods: true
