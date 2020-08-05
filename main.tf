provider "helm" {
  version = ">= 1.1.1"
  kubernetes {
    config_path = var.cluster_config_file
  }
}

locals {
  tmp_dir                = "${path.cwd}/.tmp"
  ingress_host           = "artifactory-${var.releases_namespace}.${var.cluster_ingress_hostname}"
  ingress_url            = "https://${local.ingress_host}"
  config_name            = "artifactory-config"
  secret_name            = "artifactory-access"
  gitops_dir             = var.gitops_dir != "" ? var.gitops_dir : "${path.cwd}/gitops"
  chart_name             = "artifactory"
  chart_dir              = "${local.gitops_dir}/${local.chart_name}"
  service_name           = "artifactory-artifactory"
  global_config          = {
    storageClass = var.storage_class
    clusterType = var.cluster_type
    ingressSubdomain = var.cluster_ingress_hostname
    tlsSecretName = var.tls_secret_name
  }
  service_account_config = {
    name = "artifactory-artifactory"
    create = false
    sccs = ["anyuid", "privileged"]
  }
  artifactory_config     = {
    nameOverride = "artifactory"
    artifactory = {
      image = {
        repository = "docker.bintray.io/jfrog/artifactory-oss"
      }
      adminAccess = {
        password = "admin"
      }
      persistence = {
        enabled = var.persistence
        storageClass = var.storage_class
        size = "5Gi"
      }
      uid = 0
    }
    ingress = {
      enabled = var.cluster_type == "kubernetes"
      defaultBackend = {
        enabled = false
      }
      hosts = [
        local.ingress_host
      ]
      tls = [{
        secretName = var.tls_secret_name
        hosts = [
          local.ingress_host
        ]
      }]
    }
    postgresql = {
      enabled = false
    }
    nginx = {
      enabled = false
    }
    serviceAccount = {
      create = true
      name = "artifactory-artifactory"
    }
  }
  ocp_route_config       = {
    nameOverride = "artifactory"
    targetPort = "router"
    app = "artifactory"
    serviceName = local.service_name
    termination = "edge"
    insecurePolicy = "Redirect"
  }
  tool_config            = {
    name = "Artifactory"
    url = local.ingress_url
    privateUrl = "http://${local.service_name}.${var.releases_namespace}:8082"
    username = "admin"
    password = "password"
    otherSecret = {
      ENCRYPT_PASSWORD = ""
      ADMIN_USER = "admin-access"
      ADMIN_ACCESS_PASSWORD = "admin"
    }
    applicationMenu = true
  }
  job_config             = {
    name = "artifactory"
    command = "setup-artifactory"
    secret = {
      name = "artifactory-access"
      key  = "ARTIFACTORY_URL"
    }
  }
}

resource "null_resource" "setup-chart" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.chart_dir} && cp -R ${path.module}/chart/${local.chart_name}/* ${local.chart_dir}"
  }
}

resource "null_resource" "delete-consolelink" {
  count = var.cluster_type != "kubernetes" ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl delete consolelink -l grouping=garage-cloud-native-toolkit -l app=artifactory || exit 0"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "local_file" "artifactory-values" {
  depends_on = [null_resource.setup-chart, null_resource.delete-consolelink]

  content  = yamlencode({
    global = local.global_config
    service-account = local.service_account_config
    artifactory = local.artifactory_config
    ocp-route = local.ocp_route_config
    tool-config = local.tool_config
    setup-job = local.job_config
  })
  filename = "${local.chart_dir}/values.yaml"
}

resource "null_resource" "print-values" {
  provisioner "local-exec" {
    command = "cat ${local_file.artifactory-values.filename}"
  }
}

resource "null_resource" "scc-cleanup" {
  depends_on = [local_file.artifactory-values]
  count = var.mode != "setup" ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl delete scc -l app.kubernetes.io/name=artifactory-artifactory --wait 1> /dev/null 2> /dev/null || true"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "helm_release" "artifactory" {
  depends_on = [local_file.artifactory-values, null_resource.scc-cleanup]
  count = var.mode != "setup" ? 1 : 0

  name              = "artifactory"
  chart             = local.chart_dir
  namespace         = var.releases_namespace
  timeout           = 1200
  dependency_update = true
  force_update      = true
  replace           = true

  disable_openapi_validation = true
}
