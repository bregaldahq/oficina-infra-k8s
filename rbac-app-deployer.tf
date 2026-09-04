# ---------------------------------------------------------------------------
# RBAC for the application pipeline's custom resources.
#
# AmazonEKSAdminPolicy grants the core API group inside the namespace, but says
# nothing about CRDs. The application deploys a TargetGroupBinding (AWS Load
# Balancer Controller) and an ExternalSecret (External Secrets Operator), and
# both came back "forbidden" even with the access entry in place.
#
# Granted per namespace, to the group the access entry carries.
# ---------------------------------------------------------------------------

resource "kubernetes_role" "app_deployer_crds" {
  for_each = local.app_namespaces

  metadata {
    name      = "oficina-app-deployer-crds"
    namespace = each.value
  }

  rule {
    api_groups = ["elbv2.k8s.aws"]
    resources  = ["targetgroupbindings"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["external-secrets.io"]
    resources  = ["externalsecrets", "secretstores"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  depends_on = [kubernetes_namespace.app]
}

resource "kubernetes_role_binding" "app_deployer_crds" {
  for_each = local.app_namespaces

  metadata {
    name      = "oficina-app-deployer-crds"
    namespace = each.value
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.app_deployer_crds[each.key].metadata[0].name
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = local.app_deployer_group
  }
}
