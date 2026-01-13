resource "yandex_vpc_network" "wp-network" {
  name = "wp-network"
}

variable "subnets" {
  description = "Subnets configuration"
  type = list(object({
    zone       = string
    cidr_block = string
  }))
  default = [
    {
      zone       = "ru-central1-a"
      cidr_block = "10.2.0.0/16"
    },
    {
      zone       = "ru-central1-b"
      cidr_block = "10.3.0.0/16"
    },
    {
      zone       = "ru-central1-d"
      cidr_block = "10.4.0.0/16"
    }
  ]
}

resource "yandex_vpc_subnet" "wp_subnet" {
  count = length(var.subnets)
  
  name           = "wp-subnet-${var.subnets[count.index].zone}"
  zone           = var.subnets[count.index].zone
  network_id     = yandex_vpc_network.wp-network.id
  v4_cidr_blocks = [var.subnets[count.index].cidr_block]
}