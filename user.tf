resource "oci_identity_domains_user" "wif_user" {
  idcs_endpoint = var.idcs_endpoint
  schemas       = ["urn:ietf:params:scim:schemas:core:2.0:User"]

  user_name = var.service_user_name
  emails {
    value   = var.service_user_email
    type    = "work"
    primary = true
  }
  name {
    given_name  = "WIF"
    family_name = "ServiceUser"
  }
  active = true
}

resource "oci_identity_domains_group" "wif_group" {
  idcs_endpoint = var.idcs_endpoint
  schemas       = ["urn:ietf:params:scim:schemas:core:2.0:Group"]

  display_name = var.service_group_name
  members {
    value = oci_identity_domains_user.wif_user.id
    type  = "User"
  }
}

# Policy to allow the group to do things
resource "oci_identity_policy" "wif_policy" {
  compartment_id = var.tenancy_ocid
  name           = "wif-policy"
  description    = "Policy for WIF Group"

  statements = [
    "Allow group ${var.service_group_name} to manage all-resources in tenancy"
    # Note: In Identity Domains, group names are unique. 
    # If using 'oci_identity_domains_group', the IAM policy refers to it by name.
    # Ensure the group name is unique in the domain.
  ]
}
