
variable "gitops_config" {
  type        = object({
    boostrap = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
    })
    infrastructure = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
    services = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
    applications = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
  })
  description = "Config information regarding the gitops repo structure"
}

variable "git_credentials" {
  type = list(object({
    repo = string
    url = string
    username = string
    token = string
  }))
  description = "The credentials for the gitops repo(s)"
  sensitive   = true
}

variable "namespace" {
  type        = string
  description = "The namespace where the application should be deployed"
}

variable "kubeseal_cert" {
  type        = string
  description = "The certificate/public key used to encrypt the sealed secrets"
  default     = ""
}

variable "server_name" {
  type        = string
  description = "The name of the server"
  default     = "default"
}

variable "license" {
  type = string
  description = "The Licesence for MQ on CP4i"
  default = "L-RJON-C7QG3S"
}
variable "license_use" {
  type = string
  description = "License use. Production or NonProduction"
  default = "NonProduction"
}

variable "mqsc_configmap" {
  type = string
  description = "Name of the config map which holds the MQSC configuration"
  default = "mq-uniform-cluster-mqsc-cm"
}

variable "ini_configmap" {
  type = string
  description = "Name of the config map which holds the ini configuration"
  default = "mq-uniform-cluster-ini-cm"
}

variable "MQ_AvailabilityType" {
  type = string
  description = "AvailabilityType of MQ. Possible Values are (SingleInstance/MultiInstance/NativeHA)"
  default = "SingleInstance"
  
}
variable "storageClass" {
  type = string
  description = "Incase of SingleInstance use RWO storage class. In case of MultiInstance use RWX. Here we chose SingleInstance."
  default = "ibmc-block-gold"
  
}

variable "mq_version" {
  type=string
  description = "Version of MQ server"
  default = "9.2.4.0-r1"
  
}
variable "entitlement_key" {
  type        = string
  description = "The entitlement key required to access Cloud Pak images"
  sensitive   = true
}



