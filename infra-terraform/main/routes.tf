 resource "yandex_vpc_route_table" "my_route" {
  name       = "my-route"
  network_id = yandex_vpc_network.my_net.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "10.10.0.254"
  }
}