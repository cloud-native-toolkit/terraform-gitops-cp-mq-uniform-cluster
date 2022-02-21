module "gitops_module" {
  source = "./module"
  
  depends_on = [module.gitops-cp-mq]

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  namespace = module.gitops_namespace.name
  kubeseal_cert = module.gitops.sealed_secrets_cert
  entitlement_key = module.cp_catalogs.entitlement_key

  #Uniform Cluster specifics
  is_mq_uniform_cluster_required_dedicated_ns = true
  uniform_cluster_instance_namespace="gitops-cp-mq-uniform-cluster"
  storageClass="portworx-db2-rwo-sc"


}
