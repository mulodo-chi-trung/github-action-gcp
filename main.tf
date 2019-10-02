provider "google" {
  # credentials = file("trung-terraform-3cd1a0f0d60e.json") 
  project = var.project
  region  = var.region
}

resource "google_container_cluster" "gcp_kubernetes" {
  name               = var.cluster_name
  location           = var.zone
  initial_node_count = var.gcp_node_count

  master_auth {
    username = var.username
    password = var.password
  }

  node_config {
    machine_type = "n1-standard-2"
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = "dev-cluster"
    }

    tags = ["dev", "demo"]
  }
}

provider "kubernetes" {
  host                   = var.host
  username               = var.username
  password               = var.password
  cluster_ca_certificate = var.cluster_ca_certificate
}

resource "kubernetes_service" "svc_kube_elastic_search" {
  depends_on = [google_container_cluster.gcp_kubernetes]
  metadata {
    name = "es-nodes"
    labels = {
      service = "elasticsearch"
    }
  }
  spec {
    type = "NodePort"
    selector = {
      service = "elasticsearch"
    }
    port {
      name        = "external"
      port        = 9200
      protocol    = "TCP"
      target_port = 9200
    }
    port {
      name        = "internal"
      port        = 9300
      protocol    = "TCP"
      target_port = 9300
    }
  }
}

resource "kubernetes_stateful_set" "sfs_kube_elastic_search" {
  depends_on = [google_container_cluster.gcp_kubernetes]
  metadata {
    name = "elasticsearch"
    labels = {
      service = "elasticsearch"
    }
  }
  spec {
    service_name = "es-nodes"
    replicas     = 2
    selector {
      match_labels = {
        service = "elasticsearch"
      }
    }
    template {
      metadata {
        labels = {
          service = "elasticsearch"
        }
      }
      spec {
        termination_grace_period_seconds = 300
        init_container {
          name    = "ulimit"
          image   = "busybox"
          command = ["sh", "-c", "ulimit", "-n", "65536"]
          security_context {
            privileged = "true"
          }
        }
        init_container {
          name    = "vm-max-map-count"
          image   = "busybox"
          command = ["sysctl", "-w", "vm.max_map_count=262144"]
          security_context {
            privileged = "true"
          }
        }
        init_container {
          name    = "volume-permission"
          image   = "busybox"
          command = ["chown", "-R", "1000:1000", "/usr/share/elasticsearch/data"]
          security_context {
            privileged = "true"
          }
          volume_mount {
            name       = "data"
            mount_path = "/usr/share/elasticsearch/data"
          }
        }
        container {
          name  = "elasticsearch"
          image = "docker.elastic.co/elasticsearch/elasticsearch:6.4.3"
          port {
            container_port = 9200
            name           = "http"
          }
          port {
            container_port = 9300
            name           = "tcp"
          }
          resources {
            requests {
              memory = "400Mi"
            }
            limits {
              memory = "1Gi"
            }
          }
          env {
            name  = "cluster.name"
            value = "elasticsearch-cluster"
          }
          env {
            name = "node.name"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
          env {
            name  = "discovery.zen.ping.unicast.hosts"
            value = "elasticsearch-0.es-nodes.default.svc.cluster.local,elasticsearch-1.es-nodes.default.svc.cluster.local,elasticsearch-2.es-nodes.default.svc.cluster.local"
          }
          env {
            name  = "ES_JAVA_OPTS"
            value = "-Xms512m -Xmx512m"
          }
          volume_mount {
            name       = "data"
            mount_path = "/usr/share/elasticsearch/data"
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "data"
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "standard"
        resources {
          requests = {
            storage = "5Gi"
          }
        }
      }
    }
  }
}