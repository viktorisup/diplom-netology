### cloud vars

variable "cloud_id" {
  type        = string
  default     = "b1g5hav5glefe06sf75l"
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  default     = "b1gk2ihvjor87l9a6e2k"
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

### Service account name

variable "tf_sa_name" {
  type        = string
  description = "Service account name for Terraform"
  default     = "tf-sa"
}

### Bucket

variable "state_bucket_name" {
  type        = string
  description = "Globally unique bucket name for Terraform state"
  default     = "backet-infra-k8s"
}

variable "state_bucket_force_destroy" {
  type        = bool
  description = "Allow terraform to delete non-empty bucket on destroy"
  default     = false
}