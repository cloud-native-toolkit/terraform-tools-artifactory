
locals {
  tmp_dir                = "${path.cwd}/.tmp"
  bin_dir                = module.setup_clis.bin_dir
  ingress_host           = "artifactory-${var.releases_namespace}.${var.cluster_ingress_hostname}"
  ingress_url            = "https://${local.ingress_host}"
  config_name            = "artifactory-config"
  secret_name            = "artifactory-access"
  gitops_dir             = var.gitops_dir != "" ? var.gitops_dir : "${path.cwd}/gitops"
  chart_name             = "artifactory"
  chart_dir              = "${local.gitops_dir}/${local.chart_name}"
  service_name           = "artifactory-artifactory"
  sa_name                = "artifactory-artifactory"
  config_sa_name         = "artifactory-config"
  global_config          = {
    storageClass = var.storage_class
    clusterType = var.cluster_type
    ingressSubdomain = var.cluster_ingress_hostname
    tlsSecretName = var.tls_secret_name
  }
  service_account_config = {
    name = local.sa_name
    create = false
    sccs = ["anyuid", "privileged"]
  }
  config_service_account_config = {
    name = local.config_sa_name
    roles = [
      {
        apiGroups = [
          ""
        ]
        resources = [
          "secrets",
          "configmaps"
        ]
        verbs = [
          "*"
        ]
      }
    ]
  }
  artifactory_config     = {
    nameOverride = "artifactory"
    artifactory = {
      image = {
        registry = "docker.bintray.io"
        repository = "jfrog/artifactory-oss"
      }
      adminAccess = {
        password = "admin"
      }
      persistence = {
        enabled = var.persistence
        storageClassName = var.storage_class
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
      name = local.sa_name
    }
  }
  ocp_route_config       = {
    nameOverride = "artifactory"
    targetPort = "router"
    app = "artifactory"
    serviceName = local.service_name
    termination = "edge"
    insecurePolicy = "Redirect"
    consoleLink = {
      enabled = true
      section = "Cloud-Native Toolkit"
      displayName = "Artifactory"
      imageUrl = "data:image/png;base64,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"
      category = "artifacts"
    }
  }
  tool_config            = {
    name = "Artifactory"
    privateUrl = "http://${local.service_name}.${var.releases_namespace}:8082"
    username = "admin"
    password = "password"
    otherSecret = {
      ENCRYPT_PASSWORD = ""
      ADMIN_USER = "admin-access"
      ADMIN_ACCESS_PASSWORD = "admin"
    }
    applicationMenu = false
  }
  job_config             = {
    name = "artifactory"
    serviceAccountName = local.config_sa_name
    command = "setup-artifactory"
    secret = {
      name = "artifactory-access"
      key  = "ARTIFACTORY_URL"
    }
  }
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"

  clis = ["helm"]
}

resource null_resource print_toolkit_namespace {
  provisioner "local-exec" {
    command = "echo 'Toolkit namespace: ${var.toolkit_namespace}'"
  }
}

resource "null_resource" "setup-chart" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.chart_dir} && cp -R ${path.module}/chart/${local.chart_name}/* ${local.chart_dir}"
  }
}

resource "local_file" "artifactory-values" {
  depends_on = [null_resource.setup-chart]

  content  = yamlencode({
    global = local.global_config
    service-account = local.service_account_config
    config-service-account = local.config_service_account_config
    artifactory = local.artifactory_config
    ocp-route = local.ocp_route_config
    tool-config = local.tool_config
    setup-job = local.job_config
  })
  filename = "${local.chart_dir}/values.yaml"
}

resource null_resource artifactory_helm {
  depends_on = [local_file.artifactory-values]
  count = var.mode != "setup" ? 1 : 0

  triggers = {
    bin_dir = local.bin_dir
    kubeconfig = var.cluster_config_file
    chart_version = var.chart_version
    namespace = var.releases_namespace
    chart_dir = local.chart_dir
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/helm template artifactory ${self.triggers.chart_dir} -n ${self.triggers.namespace} | kubectl apply -n ${self.triggers.namespace} -f -"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.bin_dir}/helm template artifactory ${self.triggers.chart_dir} -n ${self.triggers.namespace} | kubectl delete -n ${self.triggers.namespace} -f -"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
  }
}

resource null_resource wait-for-config-job {
  depends_on = [null_resource.artifactory_helm]
  count = var.mode != "setup" ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl wait -n ${var.releases_namespace} --for=condition=complete --timeout=30m job -l app=artifactory"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}
