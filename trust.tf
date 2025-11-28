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
  # Using public_certificate directly instead of JWKS endpoint due to IDCS not caching the cert
  public_certificate  = <<-EOT
    -----BEGIN CERTIFICATE-----
    MIIDKzCCAhOgAwIBAgIUDnwm6eRIqGFA3o/P1oBrChvx/nowDQYJKoZIhvcNAQEL
    BQAwJTEjMCEGA1UEAwwaYWN0aW9ucy5zZWxmLXNpZ25lZC5naXRodWIwHhcNMjQw
    MTIzMTUyNTM2WhcNMzQwMTIwMTUyNTM2WjAlMSMwIQYDVQQDDBphY3Rpb25zLnNl
    bGYtc2lnbmVkLmdpdGh1YjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
    AOTGp5svs8LJN8BH7VzXShWXnOK0lhDVuI0xnr5bwHFPc924CwaIEFb6mC7bvW2l
    Ztgd633uaJ2naG6vKaOVGpCdGLE4ohH11nUk+2CNknZL7/oTmDHGSmGeHRb7kjtb
    0Ng4BJMPzmTYmCNUudfDFhHDcZz1Obuu85GsABrC5ZlzWzspYFXwUSaxvII+rHK/
    rAbOC2gmt5IOSLmgh3taQfp0mB6Lxlf89HoBPNwtPfBX8DtXTWQVnqODm4W+WfmW
    BSyXGX54DGNMyZwlTZqR0FjoMXxopId3MIuDGKxa2weDU5cW60N2y/qxikeV99fL
    3sg5aPA8s9iljKG0+MAfVNUCAwEAAaNTMFEwHQYDVR0OBBYEFIPALo5VanJ6E1B9
    eLQgGO+uGV65MB8GA1UdIwQYMBaAFIPALo5VanJ6E1B9eLQgGO+uGV65MA8GA1Ud
    EwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAGS0hZE+DqKIRi49Z2KDOMOa
    SZnAYgqq6ws9HJHT09MXWlMHB8E/apvy2ZuFrcSu14ZLweJid+PrrooXEXEO6azE
    akzCjeUb9G1QwlzP4CkTcMGCw1Snh3jWZIuKaw21f7mp2rQ+YNltgHVDKY2s8AD2
    73E8musEsWxJl80/MNvMie8Hfh4n4/Xl2r6t1YPmUJMoXAXdTBb0hkPy1fUu3r2T
    +1oi7Rw6kuVDfAZjaHupNHzJeDOg2KxUoK/GF2/M2qpVrd19Pv/JXNkQXRE4DFbE
    rMmA7tXpp1tkXJRPhFui/Pv5H9cPgObEf9x6W4KnCXzT3ReeeRDKF8SqGTPELsc=
    -----END CERTIFICATE-----
  EOT
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
