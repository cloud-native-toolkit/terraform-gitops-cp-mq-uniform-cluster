locals {
  
  namespace = var.namespace

  name          = "gitops-cp-mq-uniform-cluster"
  
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
  type  = "instances"
  application_branch = "main"
  
  layer_config = var.gitops_config[local.layer]
}


#MQ Uniform Cluster instance is one of the heavy workload component. Hence It is better to manage this in a separate namespace
resource gitops_namespace ns {
  name = local.namespace
  server_name = var.server_name
  branch = local.application_branch
  config = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}

resource gitops_pull_secret cp_icr_io {
  name = "ibm-entitlement-key"
  namespace = local.namespace
  server_name = var.server_name
  branch = local.application_branch
  layer = local.layer
  credentials = yamlencode(var.git_credentials)
  config = yamlencode(var.gitops_config)
  kubeseal_cert = var.kubeseal_cert


  secret_name     = "ibm-entitlement-key"
  registry_server = "cp.icr.io"
  registry_username = "cp"
  registry_password = var.entitlement_key
}

resource null_resource create_yaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.instance_name}' '${local.instance_chart_dir}' '${local.yaml_dir}' '${local.values_file}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content)
    }
  }
}

resource gitops_module setup_gitops {
  depends_on = [null_resource.create_yaml]


  name = local.name
  namespace = local.namespace
  content_dir = local.yaml_dir
  server_name = var.server_name
  layer = local.layer
  type = local.type
  branch = local.application_branch
  config = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}

