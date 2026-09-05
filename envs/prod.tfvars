environment     = "prod"
region          = "us-east-1"
cluster_version = "1.30"

# Graded delivery runs on ON_DEMAND so a spot reclaim cannot break the demo.
capacity_type = "ON_DEMAND"
# t3.medium, nao t3.small: o limite de pods por node do VPC CNI e uma funcao de
# ENIs x IPs, nao de CPU. t3.small suporta 11 pods e os add-ons (ALB Controller,
# metrics-server, External Secrets, nri-bundle, CoreDNS, kube-proxy, aws-node)
# consomem praticamente todos — a aplicacao e o Job de migration ficavam Pending
# com "Too many pods".
#
# t3.medium tem os mesmos 2 vCPU (portanto nao consome quota adicional) e suporta
# 17 pods. A alternativa sem custo seria prefix delegation no addon vpc-cni, que
# leva t3.small a 110 pods, mas exige reciclar os nodes — vale como proximo passo.
node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 2
node_max_size       = 4

cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

ecr_repository_name       = "oficina-api"
ecr_image_retention_count = 10

newrelic_enabled = true
app_ci_role_arn  = "arn:aws:iam::474717634842:role/oficina-gha-oficina-mecanica-tech-challenge"
