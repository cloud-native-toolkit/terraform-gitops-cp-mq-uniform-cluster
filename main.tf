locals {
  # If decided to create the MQ Uniform Cluster instance in the dedicated namepace 
  namespace = var.is_mq_uniform_cluster_required_dedicated_ns ? var.uniform_cluster_instance_namespace : var.namespace

  name          = "gitops-cp-mq-uniform-cluster"
  bin_dir       = module.setup_clis.bin_dir
  
  base_name          = "ibm-mq-uniform-cluster"
  instance_name      = "${local.base_name}-instance"

  instance_chart_dir = "${path.module}/charts/${local.instance_name}"
  yaml_dir           = "${path.cwd}/.tmp/${local.name}/chart/${local.instance_name}"
  

  service_url   = "http://${local.name}.${local.namespace}"


  values_content = {

    mq_uniform_cluster_instance={
      license={
        accept = true
        license = var.license
        metric = "VirtualProcessorCore"
        use = var.license_use
      }
      queueManager={
        name="QM"
        mqsc=[
          {
            configMap={
              name = var.mqsc_configmap
              items= ["common_config.mqsc"]
            }
          }]
        ini=[
          {
            configMap={
              name = var.ini_configmap
              items= ["config.ini"]
            }
          }]
        availability={
          type: var.MQ_AvailabilityType
        }
        logFormat= "Basic"
        resources={
          limits={
            cpu="500m"
            memory="1Gi"
          }
          requests={
            cpu="500m"
            memory="1Gi"
          }

        }
        route={
          enabled = true
        }
        storage={
          defaultClass= var.storageClass
          persistedData={
            enabled = false
          }
          queueManager={
            type="persistent-claim"
            #class= var.storageClass
            deleteClaim= true
          }
          recoveryLogs={
            enabled = false
          }
        }
      }
      securityContext={
        initVolumeAsRoot = false
      }
      template={
        pod={
          containers=[
            {
              env=[
                {
                  name="MQSNOAUT"
                  value= "yes"
                }
              ]
              name="qmgr"
              resources= {}
            }
          ]
        }
      }
      version: var.mq_version
      web={
        enabled=true
      }
      configMap={
        mqsc={name="mq-uniform-cluster-mqsc-cm"}
        ini={
          name="mq-uniform-cluster-ini-cm"
          AutoCluster=[
            "Repository2Conname=uniform-cluster-qm1-ibm-mq.${local.namespace}.svc(1414)",
            "Repository2Name=QM1",
            "Repository1Conname=uniform-cluster-qm2-ibm-mq.${local.namespace}.svc(1414)",
            "Repository1Name=QM2",
            "ClusterName=UNICLUS",
            "Type=Uniform"
          ]
        }
        qm3_mqsc={
          name= "mq-uniform-cluster-qm3-mqsc-cm"
          commands=[
            "alter chl(UNICLUS_QM1) chltype(CLUSSDR) conname('uniform-cluster-qm1-ibm-mq.${local.namespace}.svc(1414)')",
            "alter chl(UNICLUS_QM2) chltype(CLUSSDR) conname('uniform-cluster-qm2-ibm-mq.${local.namespace}.svc(1414)')",
            "alter chl(UNICLUS_QM3) chltype(CLUSRCVR) conname('uniform-cluster-qm3-ibm-mq.${local.namespace}.svc(1414)')"
            ]
          }
        qm2_mqsc={
          name= "mq-uniform-cluster-qm2-mqsc-cm"
          commands=[
            "alter chl(UNICLUS_QM1) chltype(CLUSSDR) conname('uniform-cluster-qm1-ibm-mq.${local.namespace}.svc(1414)')",
            "alter chl(UNICLUS_QM2) chltype(CLUSRCVR) conname('uniform-cluster-qm2-ibm-mq.${local.namespace}.svc(1414)')"
            ]
          }
        qm1_mqsc={
          name= "mq-uniform-cluster-qm1-mqsc-cm"
          commands=[
            "alter chl(UNICLUS_QM1) chltype(CLUSRCVR) conname('uniform-cluster-qm1-ibm-mq.${local.namespace}.svc(1414)')",
            "alter chl(UNICLUS_QM2) chltype(CLUSSDR) conname('uniform-cluster-qm2-ibm-mq.${local.namespace}.svc(1414)')"
            ]
          }
                      

      }
    }
  
  }
  values_file = "values.yaml"
  layer = "services"
  type  = "base"
  application_branch = "main"
  
  layer_config = var.gitops_config[local.layer]
}


#MQ Uniform Cluster instance is one of the heavy workload component. Hence It is better to manage this in a separate namespace
module "mq_uniform_cluster_instance_ns" {
    source = "github.com/cloud-native-toolkit/terraform-gitops-namespace.git"
    

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  name = local.namespace
  
} 

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

module pull_secret {
  source = "github.com/cloud-native-toolkit/terraform-gitops-pull-secret"

  depends_on = [
    module .mq_uniform_cluster_instance_ns
  ]

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  server_name = var.server_name
  kubeseal_cert = var.kubeseal_cert
  #namespace = var.namespace
  namespace= local.namespace
  docker_username = "cp"
  docker_password = var.entitlement_key
  docker_server   = "cp.icr.io"
  secret_name     = "ibm-entitlement-key"
}

resource null_resource create_yaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.instance_name}' '${local.instance_chart_dir}' '${local.yaml_dir}' '${local.values_file}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content)
    }
  }
}

resource null_resource setup_gitops {
  depends_on = [null_resource.create_yaml,module.mq_uniform_cluster_instance_ns]

  triggers = {
    name = local.instance_name
    #namespace = var.namespace
    namespace= local.namespace
    yaml_dir = local.yaml_dir
    server_name = var.server_name
    layer = local.layer
    type = local.type
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
    bin_dir = local.bin_dir
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --delete --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }
}
