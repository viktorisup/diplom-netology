data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

data "yandex_compute_image" "nat-instance-ubuntu" {
  family = "nat-instance-ubuntu"
}

data "yandex_compute_image" "mikrotik-chr" {
  family = "mikrotik-chr"
}