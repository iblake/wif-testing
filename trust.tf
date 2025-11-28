# 1. Confidential Application (OAuth Client)
resource "oci_identity_domains_app" "wif_app" {
  idcs_endpoint = var.idcs_endpoint
  schemas       = ["urn:ietf:params:scim:schemas:oracle:idcs:App"]

  display_name    = "GitHub_WIF_App_TF"
  active          = true
  client_type     = "confidential"
  is_oauth_client = true
  allowed_grants  = ["client_credentials"]

  based_on_template {
    value = "CustomWebAppTemplateId"
  }
}

# 2. Identity Propagation Trust
resource "oci_identity_domains_identity_propagation_trust" "github_trust" {
  idcs_endpoint        = var.idcs_endpoint
  issuer               = "https://token.actions.githubusercontent.com"
  name                 = "GitHub-Actions-Trust"
  schemas              = ["urn:ietf:params:scim:schemas:oracle:idcs:IdentityPropagationTrust"]
  type                 = "JWT"
  active               = true
  allow_impersonation  = true
  oauth_clients        = [oci_identity_domains_app.wif_app.name]
  public_key_endpoint  = "https://token.actions.githubusercontent.com/.well-known/jwks"
  subject_type         = "User"
  description          = "Trust for GitHub Actions"

  impersonation_service_users {
    rule  = "sub eq 'repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}'"
    value = oci_identity_domains_user.wif_user.id
  }
}

output "wif_app_client_id" {
  value = oci_identity_domains_app.wif_app.name
}

# Client Secret is not exported by the resource for security.
# You must retrieve it from the OCI Console after creation.

output "idcs_endpoint" {
  value = var.idcs_endpoint
}
