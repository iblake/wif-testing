# 1. Confidential Application (OAuth Client)
resource "oci_identity_domains_app" "wif_app" {
  idcs_endpoint = var.idcs_endpoint
  schemas       = ["urn:ietf:params:scim:schemas:oracle:idcs:App"]

  display_name    = "GitHub_WIF_App_TF"
  active          = true
  client_type     = "confidential"
  is_oauth_client = true
  allowed_grants  = ["client_credentials", "urn:ietf:params:oauth:grant-type:jwt-bearer"]

  based_on_template {
    # Use the well-known template ID for a custom web app; keep value for compatibility.
    value         = "CustomWebAppTemplateId"
    well_known_id = "CustomWebAppTemplateId"
  }
}

# 2. Identity Propagation Trust
resource "oci_identity_domains_identity_propagation_trust" "github_trust" {
  idcs_endpoint = var.idcs_endpoint
  schemas       = ["urn:ietf:params:scim:schemas:oracle:idcs:IdentityPropagationTrust"]

  name                = "GitHub-Actions-Trust"
  description         = "Trust for GitHub Actions"
  type                = "JWT"
  issuer              = "https://token.actions.githubusercontent.com"
  public_key_endpoint = "https://token.actions.githubusercontent.com/.well-known/jwks"
  subject_type        = "User"
  active              = true
  allow_impersonation = true

  oauth_clients = [oci_identity_domains_app.wif_app.name]

  # Map the GitHub Subject to the Service User
  impersonation_service_users {
    # Rule: Subject matches the repo/branch
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
