variable "tenancy_ocid" {
  description = "OCID of the tenancy"
  type        = string
}

variable "region" {
  description = "OCI Region (e.g., us-ashburn-1)"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the user calling the API"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint for the API Key"
  type        = string
}

variable "private_key_path" {
  description = "Local path to the private key file (.pem)"
  type        = string
}

variable "idcs_endpoint" {
  description = "The IDCS Endpoint URL"
  type        = string
}

variable "github_org" {
  description = "GitHub Organization or User name"
  type        = string
}

variable "github_repo" {
  description = "GitHub Repository name"
  type        = string
}

variable "github_branch" {
  description = "Branch to allow"
  type        = string
  default     = "main"
}

variable "compartment_ocid" {
  description = "OCID of the compartment (defaults to tenancy if not set)"
  type        = string
  default     = null
}

variable "service_user_name" {
  description = "Name of the Service User to create"
  type        = string
  default     = "wif-service-user-v2"
}

variable "service_user_email" {
  description = "Email of the Service User"
  type        = string
  default     = "wif-service-user-v2@example.com"
}

variable "service_group_name" {
  description = "Name of the Group for the Service User"
  type        = string
  default     = "WIF-Group"
}
