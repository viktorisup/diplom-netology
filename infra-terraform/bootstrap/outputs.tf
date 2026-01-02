output "service_account_id" {
  value = yandex_iam_service_account.tf.id
}

output "state_bucket_name" {
  value = yandex_storage_bucket.tfstate.bucket
}

output "s3_access_key_id" {
  value = yandex_iam_service_account_static_access_key.tf_s3_key.access_key
}

output "s3_secret_access_key" {
  value     = yandex_iam_service_account_static_access_key.tf_s3_key.secret_key
  sensitive = true
}