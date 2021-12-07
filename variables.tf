variable "cluster_config_file" {
  type        = string
  description = "Cluster config file for Kubernetes cluster."
}

variable "releases_namespace" {
  type        = string
  description = "Name of the existing namespace where Pact Broker will be deployed."
}

variable "cluster_ingress_hostname" {
  type        = string
  description = "Ingress hostname of the cluster."
}

variable "cluster_type" {
  type        = string
  description = "The cluster type (openshift or ocp3 or ocp4 or kubernetes)"
}

variable "service_account" {
  type        = string
  description = "The service account under which the artifactory pods should run"
  default     = "artifactory-artifactory"
}

variable "tls_secret_name" {
  type        = string
  description = "The name of the secret containing the tls certificate values"
  default     = ""
}

variable "chart_version" {
  type        = string
  description = "The chart version that will be used for artifactory release"
  default     = "12.0.0"
}

variable "storage_class" {
  type        = string
  description = "The storage class of the persistence volume claim"
  default     = ""
}

variable "persistence" {
  type        = bool
  description = "Flag to indicate if PVCs should be used"
  default     = true
}

variable "gitops_dir" {
  type        = string
  description = "Directory where the gitops repo content should be written"
  default     = ""
}

variable "mode" {
  type        = string
  description = "The mode of operation for the module (setup)"
  default     = ""
}

variable "toolkit_namespace" {
  type        = string
  description = "Namespace where the toolkit utilities are installed"
  default     = ""
}
