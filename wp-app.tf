locals {
  # Преобразуем список подсетей в мапу: зона -> ID подсети
  subnet_map = {
    for subnet in yandex_vpc_subnet.wp_subnet : subnet.zone => subnet.id
  }
  
  # Безопасное получение подсети для зоны
  get_subnet_id = {
    for idx, zone in var.instance_zones : 
    zone => lookup(local.subnet_map, zone, "subnet-not-found")
  }
}

resource "yandex_compute_instance" "wp_app" {
  count = var.instance_count
  
  name = "${var.instance_name_prefix}-${count.index + 1}"
  zone = element(var.instance_zones, count.index % length(var.instance_zones))

  resources {
    cores  = var.instance_resources.cores
    memory = var.instance_resources.memory
  }

  boot_disk {
    initialize_params {
      image_id = "fd878mk5p0ao0vmo0ld8" # Ubuntu 24
    }
  }

  network_interface {
    # Получаем ID подсети для текущей зоны из мапы
    subnet_id = local.subnet_map[element(var.instance_zones, count.index % length(var.instance_zones))]
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("C:/Users/aivanov/.ssh/id_ed25519_aivanovvscode.pub")}"
  }
    # Зависимость от создания подсетей
  depends_on = [yandex_vpc_subnet.wp_subnet]
}