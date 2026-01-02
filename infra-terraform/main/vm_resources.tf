### all vm

resource "yandex_compute_instance" "k8s_vm" {
  for_each = var.vm_config 
  name     = each.key
  hostname = each.key
  zone     = yandex_vpc_subnet.my_subnet[each.value.subnet_name].zone
  platform_id = each.value.platform_id
  allow_stopping_for_update = true

  resources {
    cores  = each.value.cores 
    memory = each.value.memory 
    core_fraction = each.value.core_fraction 
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = each.value.hdd_size 
      type     = each.value.hdd_type
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.my_subnet[each.value.subnet_name].id
    nat       = each.value.nat 
  }

  scheduling_policy {
    preemptible = each.value.preemptible
  }

  metadata = {
    ssh-keys         = "ubuntu:${file("~/.ssh/id_ed25519_yc.pub")}"
    "serial-port-enable" = "1"
  }
}