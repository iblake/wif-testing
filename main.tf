data "oci_identity_tenancy" "test" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_regions" "test" {

}

output "tenancy_name" {
  value = data.oci_identity_tenancy.test.name
}

output "home_region_key" {
  value = data.oci_identity_tenancy.test.home_region_key
}

output "current_region" {
  value = var.region
}

output "auth_success" {
  value = "If you see this output, OCI WIF authentication is WORKING!"
}
