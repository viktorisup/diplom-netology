resource "yandex_vpc_network" "my_net" {
  name = var.network_name
}

resource "yandex_vpc_subnet" "my_subnet" {
  for_each       = var.subnets
  name           = each.key
  zone           = each.value.zone
  network_id     = yandex_vpc_network.my_net.id
  v4_cidr_blocks = [each.value.cidr]
  route_table_id = contains(local.public_names, each.key) ? null : yandex_vpc_route_table.my_route.id
}

