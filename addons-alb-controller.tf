# ---------------------------------------------------------------------------
# B3 - AWS Load Balancer Controller (IRSA + Helm)
# Reconciles Ingress/Service objects into ALB/NLB resources and, in our setup,
# registers the oficina-api pod IPs into the Terraform-owned target group via a
# TargetGroupBinding.
# ---------------------------------------------------------------------------
module "irsa_aws_load_balancer_controller" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name                              = "${local.name_prefix}-alb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.chart_version_aws_load_balancer_controller
  namespace  = "kube-system"

  values = [yamlencode({
    clusterName  = module.eks.cluster_name
    region       = var.region
    vpcId        = local.vpc_id
    replicaCount = 1
    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller"
      annotations = {
        "eks.amazonaws.com/role-arn" = module.irsa_aws_load_balancer_controller.iam_role_arn
      }
    }
  })]

  # The controller registers a mutating webhook that intercepts EVERY Service in the
  # cluster. Until its pods have endpoints, any chart creating a Service fails with
  # "no endpoints available for service aws-load-balancer-webhook-service". wait=true
  # makes Terraform hold here until the pods are ready, and the other add-ons depend
  # on this release so they are never installed into that window.
  wait          = true
  wait_for_jobs = true
  timeout       = 900

  depends_on = [module.eks]
}
