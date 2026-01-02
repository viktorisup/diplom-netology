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

### Network vars

variable "network_name" {
  type        = string
  default     = "main-vpc"
}

variable "subnets" {
  description = "Subnets map: name => { zone, cidr }"
  type = map(object({
    zone = string
    cidr = string
  }))

  default = {
    "publicnet-a" = { zone = "ru-central1-a", cidr = "10.0.0.0/24" }
    "privatnet-a" = { zone = "ru-central1-a", cidr = "10.10.0.0/24" }
    "privatnet-b" = { zone = "ru-central1-b", cidr = "10.20.0.0/24" }
    "privatnet-d" = { zone = "ru-central1-d", cidr = "10.30.0.0/24" }
  }
}

### NAT vars

variable "vm_user_nat" {
  type    = string
  default = "ubuntu"
}

variable "ssh_key_path" {
  type = string
  default = "~/.ssh/id_ed25519_yc.pub"
}

### VM vars

variable "vm_config" {
  type = map(object({
    subnet_name    = string
    platform_id    = string
    cores          = number
    core_fraction  = number
    memory         = number
    hdd_size       = number
    hdd_type       = string
    nat            = bool
    preemptible    = bool
  }))
  default = {
    "k8s-vm1" = { 
      subnet_name = "privatnet-a", 
      platform_id = "standard-v1", 
      cores = 2, 
      core_fraction = 5, 
      memory = 4, 
      hdd_size = 30, 
      hdd_type = "network-hdd", 
      nat = false, 
      preemptible = true }
    "k8s-vm2" = { 
      subnet_name = "privatnet-b", 
      platform_id = "standard-v1", 
      cores = 2, 
      core_fraction = 5, 
      memory = 4, 
      hdd_size = 30, 
      hdd_type = "network-hdd", 
      nat = false, 
      preemptible = true }
    "k8s-vm3" = { 
      subnet_name = "privatnet-d",
      platform_id = "standard-v2", 
      cores = 2, 
      core_fraction = 5, 
      memory = 4, 
      hdd_size = 30, 
      hdd_type = "network-hdd", 
      nat = false, 
      preemptible = true }
  }
}