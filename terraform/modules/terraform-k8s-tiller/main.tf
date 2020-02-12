resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = "${var.namespace}"
  }
}

# Terraform doesn't support role/rolebinding resource for now
# So we use cluster-amdin for all tiller
# FIXME: Use role for tiller which has less privileges
resource "kubernetes_cluster_role_binding" "tiller" {
  metadata {
    name = "tiller-${var.namespace}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "User"
    name      = "system:serviceaccount:${var.namespace}:tiller"
  }
}

resource "kubernetes_deployment" "tiller-deploy" {
  metadata {
    name      = "tiller-deploy"
    namespace = "${var.namespace}"

    labels = {
      app  = "helm"
      name = "tiller"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app  = "helm"
        name = "tiller"
      }
    }

    template {
      metadata {
        labels = {
          app  = "helm"
          name = "tiller"
        }
      }

      spec {
        service_account_name = "tiller"

        container {
          image = "${var.tiller_image}:${var.tiller_version}"
          name  = "tiller"

          env {
            name  = "TILLER_NAMESPACE"
            value = "${var.namespace}"
          }

          env {
            name  = "TILLER_HISTORY_MAX"
            value = "${var.max_history}"
          }

          port {
            name           = "tiller"
            container_port = "${local.tiller_port}"
          }

          port {
            name           = "http"
            container_port = "${local.http_port}"
          }

          liveness_probe {
            failure_threshold     = 3
            period_seconds        = 10
            initial_delay_seconds = 1
            success_threshold     = 1
            timeout_seconds       = 1

            http_get {
              path = "/liveness"
              port = "${local.http_port}"
            }
          }

          # terraform doesn't allow service account to auto mount secret into pod
          # So we have to mount it manually
          # see https://github.com/terraform-providers/terraform-provider-kubernetes/issues/38
          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = "${kubernetes_service_account.tiller.default_secret_name}"
            read_only  = true
          }
        } # containers

        volume {
          name = "${kubernetes_service_account.tiller.default_secret_name}"

          secret {
            secret_name = "${kubernetes_service_account.tiller.default_secret_name}"
          }
        } # volume
      } # template.spec
    }
  }
}

resource "kubernetes_service" "tiller-deploy" {
  metadata {
    name = "tiller-deploy"
    namespace = "${var.namespace}"
  }
  spec {
    selector = {
      app  = "helm"
      name = "tiller"
    }
    session_affinity = "None"
    port {
      port = 44134
      target_port = "tiller"
    }

    type = "ClusterIP"
  }
}
