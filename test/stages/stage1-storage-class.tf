module "storage" {
  source = "github.com/cloud-native-toolkit/terraform-util-storage-class-manager.git"

  rwo_storage_class = "ibmc-vpc-block-10iops-tier"
  rwx_storage_class = "ocs-storagecluster-cephfs"
  file_storage_class = ""
  block_storage_class = "ibmc-vpc-block-10iops-tier"
}
