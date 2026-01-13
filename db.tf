locals {
  dbuser     = yandex_mdb_mysql_user.wp_user.name
  dbpassword = yandex_mdb_mysql_user.wp_user.password
  dbhosts    = yandex_mdb_mysql_cluster.wp_mysql.host[*].fqdn
  dbname     = yandex_mdb_mysql_database.wp_db.name
}

resource "yandex_mdb_mysql_cluster" "wp_mysql" {
  name        = "wp-mysql"
  folder_id   = var.yc_folder
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.wp-network.id
  version     = "8.0"

  resources {
    resource_preset_id = "s2.micro"
    disk_type_id       = "network-ssd"
    disk_size          = 16
  }

  # Используем подсеты, которые создаются в network.tf
  host {
    zone      = "ru-central1-b"
    subnet_id = yandex_vpc_subnet.wp_subnet[1].id  # индекс 1 = ru-central1-b
    assign_public_ip = true
  }
  
  host {
    zone      = "ru-central1-d"
    # Добавляем подсеть для зоны C если её нет
    subnet_id = yandex_vpc_subnet.wp_subnet[2].id  # предполагая, что индекс 2 = ru-central1-d
    assign_public_ip = true
  }
}

# Создаем отдельный ресурс для базы данных
resource "yandex_mdb_mysql_database" "wp_db" {
  cluster_id = yandex_mdb_mysql_cluster.wp_mysql.id
  name       = "wpdb"
}

# Создаем отдельный ресурс для пользователя
resource "yandex_mdb_mysql_user" "wp_user" {
  cluster_id = yandex_mdb_mysql_cluster.wp_mysql.id
  name       = "wpuser"
  password   = var.db_password
  
  permission {
    database_name = yandex_mdb_mysql_database.wp_db.name
    roles         = ["ALL"]
  }
}