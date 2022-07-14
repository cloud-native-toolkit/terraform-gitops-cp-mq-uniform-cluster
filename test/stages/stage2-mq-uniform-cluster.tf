module "gitops_module" {
  source = "./module"
  
  depends_on = [module.gitops-cp-mq]

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  namespace = module.gitops_namespace.name
  #kubeseal_cert = module.gitops.sealed_secrets_cert
  kubeseal_cert = module.cert.cert
  entitlement_key = module.cp_catalogs.entitlement_key

  #Uniform Cluster specifics
  storageClass="ibmc-vpc-block-10iops-tier"


}
