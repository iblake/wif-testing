# OCI Workload Identity Federation (WIF) with Identity Domains

This guide documents the complete process for setting up OCI Workload Identity Federation (WIF) using **Identity Domains** (IDCS) and configuring GitHub Actions to authenticate via **Token Exchange**.

## 1. Prerequisites

Before starting, ensure you have the following:

* **OCI Tenancy**: Must have Identity Domains enabled (default for new tenancies).
* **Terraform**: [Install Terraform](https://developer.hashicorp.com/terraform/downloads) locally to provision resources.
* **OCI CLI**: [Install and Configure OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) locally. This is required for Terraform to authenticate with OCI.
* **GitHub Repository**: A repository where you have admin access to configure Secrets and Actions.

## 2. Terraform Configuration

The Terraform code provisions the necessary OCI resources to enable the federation.

### Resources Explained

* **Confidential Application (`wif_app`)**: Acts as the OAuth2 Client. GitHub exchanges its token for an OCI token *through* this app. It uses the "Client Credentials" grant type.
* **Service User (`wif_user`)**: A specific user identity (`wif-service-user-v2`) that GitHub Actions will "impersonate". All actions performed by the workflow will appear as this user in audit logs.
* **Group (`wif_group`)**: A group (`WIF-Group`) to manage permissions easily. The Service User is a member of this group.
* **Identity Propagation Trust (`github_trust`)**: The critical bridge. It trusts tokens issued by GitHub (`https://token.actions.githubusercontent.com`) and maps them to the Service User based on specific rules (e.g., repository name).
* **Policy**: Grants actual permissions (e.g., `manage all-resources`) to the Group.

### Steps to Provision

1. **Configure Variables**:
    Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your details:

    ```hcl
    tenancy_ocid     = "ocid1.tenancy.oc1..[YOUR_TENANCY_OCID]"
    region           = "eu-frankfurt-1" # Your home region
    idcs_endpoint    = "https://idcs-[YOUR_DOMAIN].identity.oraclecloud.com" # From OCI Console -> Identity -> Domains
    user_ocid        = "ocid1.user.oc1..[YOUR_USER_OCID]" # Your personal user OCID for Terraform auth
    fingerprint      = "[YOUR_FINGERPRINT]" # Fingerprint of your API Key
    private_key_path = "/path/to/your/private_key.pem" # Path to your API Key
    github_org       = "[YOUR_GITHUB_ORG]" # e.g., "my-org"
    github_repo      = "[YOUR_GITHUB_REPO]" # e.g., "my-repo"
    github_branch    = "main" # The branch allowed to authenticate
    ```

2. **Apply Terraform**:
    Initialize and apply the configuration to create the resources in OCI.

    ```bash
    terraform init
    terraform apply
    ```

3. **Note Outputs**:
    Terraform will output values needed for GitHub. **Save these**:
    * `idcs_endpoint`: The URL of your Identity Domain.
    * `wif_app_client_id`: The Client ID of the created App.

## 3. GitHub Configuration

To allow the GitHub Workflow to authenticate, you must store sensitive information as **Repository Secrets**.

1. Navigate to your GitHub Repository.
2. Go to **Settings** > **Secrets and variables** > **Actions**.
3. Click **New repository secret** for each item below:

| Secret Name | Value Source | Description |
| :--- | :--- | :--- |
| `IDCS_ENDPOINT` | Terraform Output | The full URL of your Identity Domain. Ensure no trailing slash. |
| `WIF_APP_CLIENT_ID` | Terraform Output | The unique ID of the Confidential App created by Terraform. |
| `OCI_TENANCY_OCID` | `terraform.tfvars` | Your Tenancy OCID (starts with `ocid1.tenancy...`). |
| `OCI_REGION` | `terraform.tfvars` | The OCI Region identifier (e.g., `eu-frankfurt-1`). |

## 4. GitHub Workflow Implementation

We use a manual script in the GitHub Action because the standard OCI action is designed for the legacy IDCS or IAM OIDC flows, not the Identity Domains Token Exchange.

### How the Script Works (`.github/workflows/test_wif.yml`)

1. **Fetch GitHub Token**:
    The workflow requests an OIDC token from GitHub's internal provider. This token proves the workflow is running in *your* repository.
    * *Requires*: `permissions: id-token: write` in the YAML.

2. **Token Exchange**:
    The script sends a `POST` request to the IDCS `oauth2/v1/token` endpoint.
    * **Grant Type**: `client_credentials`
    * **Client Assertion Type**: `jwt-bearer` (This tells IDCS we are using a token to authenticate)
    * **Client Assertion**: The GitHub OIDC Token.
    * **Client ID**: The `WIF_APP_CLIENT_ID`.
    * **Result**: IDCS validates the GitHub token against the **Identity Propagation Trust** and returns an **OCI Access Token**.

3. **Configure OCI CLI**:
    The script creates a temporary `~/.oci/config` file.
    * **Auth Type**: `security_token_file`
    * **Token File**: Points to the file where we saved the OCI Access Token.

4. **Execute Commands**:
    Any `oci` command run subsequently will use this configuration to authenticate as the `wif-service-user`.

## 5. How to Test

Once everything is configured, verify the setup manually:

1. **Trigger Workflow**:
    * Go to the **Actions** tab in GitHub.
    * Select **Test OCI WIF**.
    * Click **Run workflow** > Select Branch > **Run workflow**.

2. **Monitor Execution**:
    * Click on the running workflow to see the logs.
    * Wait for the **Authenticate to OCI** step to complete.

3. **Verify Results**:
    * Expand the **Verify Access (Get Namespace)** step.
    * You should see a JSON output or a text string with your **Object Storage Namespace**.
    * **Success**: If you see the namespace, the federation is working correctly!

## 6. Troubleshooting

### Common Errors

* **400 Bad Request (Terraform Apply)**:
  * *Error*: `Schema is not recognized`.
  * *Solution*: Check `user.tf`. Ensure you are using `urn:ietf:params:scim:schemas:core:2.0:User` (standard SCIM) and not the Oracle-specific extension URNs for the resource schemas.

* **401 Not Authenticated (GitHub Action)**:
  * *Error*: `Failed to verify the HTTP(S) Signature` or similar.
  * *Solution*:
    * Verify `WIF_APP_CLIENT_ID` matches the Secret.
    * Check the **Identity Propagation Trust** in OCI Console. The **Rule** must exactly match the repo/branch claim (e.g., `sub eq 'repo:my-org/my-repo:ref:refs/heads/main'`).

* **400 Bad Request (Token Exchange)**:
  * *Error*: `invalid_client` or `invalid_grant`.
  * *Solution*:
    * Verify `IDCS_ENDPOINT` is correct.
    * Ensure the GitHub Action has `permissions: id-token: write`.
    * Check if the Confidential App is **Active** in OCI Console.
