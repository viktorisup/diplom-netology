### Service account

# Создаем сервисный аккаунт
resource "yandex_iam_service_account" "tf" {
  name        = var.tf_sa_name
  description = "Service account used by Terraform to manage infrastructure"
}

# Даем права на vpc
resource "yandex_resourcemanager_folder_iam_member" "tf_vpc_admin" {
  folder_id = var.folder_id
  role      = "vpc.admin"
  member    = "serviceAccount:${yandex_iam_service_account.tf.id}"
}

# Даем права на storage
resource "yandex_resourcemanager_folder_iam_member" "tf_storage_admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.tf.id}"
}

# Создаем ключи
resource "yandex_iam_service_account_static_access_key" "tf_s3_key" {
  service_account_id = yandex_iam_service_account.tf.id
  description        = "Static access key for Terraform S3 backend"
}

### Bucket

# Создаем бакет
resource "yandex_storage_bucket" "tfstate" {
  bucket        = var.state_bucket_name
  force_destroy = var.state_bucket_force_destroy

  # Используем созданные ключи
  access_key = yandex_iam_service_account_static_access_key.tf_s3_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.tf_s3_key.secret_key

  versioning {
    enabled = true
  }

  anonymous_access_flags {
    read        = false
    list        = false
    config_read = false
  }

  lifecycle_rule {
    id      = "cleanup-old-versions"
    enabled = true

    noncurrent_version_expiration {
      days = 30
    }
  }
}

