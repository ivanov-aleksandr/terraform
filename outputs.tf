# outputs.tf - только самое необходимое
output "instance_ips" {
  description = "WordPress instances public IPs"
  value = { 
    for instance in yandex_compute_instance.wp_app : 
    instance.name => instance.network_interface[0].nat_ip_address
  }
}

output "load_balancer_external_ips" {
  description = "Load balancer external IPs"
  value = [
    for listener in yandex_lb_network_load_balancer.wp_lb.listener :
    [for spec in listener.external_address_spec : spec.address]
  ]
}

output "mysql_hosts" {
  description = "MySQL cluster hosts"
  value = [for host in yandex_mdb_mysql_cluster.wp_mysql.host : host.fqdn]
}

output "db_info" {
  description = "Database information"
  value = {
    db_name   = yandex_mdb_mysql_database.wp_db.name
    db_user   = yandex_mdb_mysql_user.wp_user.name
    
    cluster_hosts = [for host in yandex_mdb_mysql_cluster.wp_mysql.host : {
      name = host.name
      fqdn = host.fqdn
      zone = host.zone
    }]
  }
  sensitive = true
}


# Новый вывод: информация о системных пользователях
output "system_users_info" {
  description = "System users information for connections"
  value = {
    # SSH пользователь для доступа к инстансам WordPress
    ssh_user = "aivanov"  # Из metadata в wp-app.tf
    
    # Пользователь базы данных (из db_info)
    db_user  = yandex_mdb_mysql_user.wp_user.name
    db_name  = yandex_mdb_mysql_database.wp_db.name
    
    # Целевая группа балансировщика для мониторинга
    target_group_name = yandex_lb_target_group.wp_tg.name
    
    # Имена инстансов для удобства
    instance_names = [for inst in yandex_compute_instance.wp_app : inst.name]
  }
}

# Новый вывод: информация о сетевых настройках
output "network_info" {
  description = "Network configuration information"
  value = {
    # Зоны размещения инстансов
    instance_zones = var.instance_zones
    
    # Подсети, используемые инстансами
    instance_subnets = [
      for inst in yandex_compute_instance.wp_app : {
        name    = inst.name
        zone    = inst.zone
        subnet  = inst.network_interface[0].subnet_id
        private_ip = inst.network_interface[0].ip_address
      }
    ]
    
    # Порты балансировщика
    lb_ports = [
      for listener in yandex_lb_network_load_balancer.wp_lb.listener :
      listener.port
    ]
  }
}

# Новый вывод: summary информация
output "deployment_summary" {
  description = "Summary of the WordPress deployment"
  value = {
    # Количество развернутых инстансов
    instance_count = var.instance_count
    
    # Ресурсы инстансов
    instance_resources = var.instance_resources
    
    # Префикс имен инстансов
    instance_prefix = var.instance_name_prefix
    
    # Статус балансировщика
    load_balancer_name = yandex_lb_network_load_balancer.wp_lb.name
    
    # Целевая группа
    target_group_size = length(yandex_lb_target_group.wp_tg.target)
  }
}

# Новый вывод: информация о пользователях для подключения
output "connection_info" {
  description = "Connection information for WordPress instances"
  value = {
    ssh_user = "aivanov"  # Имя пользователя для SSH подключения к инстансам
    # Или можно получить из конфигурации инстанса
    # instance_ssh_user = yandex_compute_instance.wp_app[0].metadata.ssh_user
  }
}

# inventory for ansible 
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/ansible-inventory.tf.tpl", {
    timestamp                 = timestamp()
    instance_ips              = { for k, v in yandex_compute_instance.wp_app : k => v.network_interface[0].nat_ip_address }
    db_info                  = {
      db_name = yandex_mdb_mysql_database.wp_db.name
      db_user = yandex_mdb_mysql_user.wp_user.name
    }
    db_password              = var.db_password
    mysql_hosts              = [for host in yandex_mdb_mysql_cluster.wp_mysql.host : host.fqdn]
    load_balancer_external_ips = [
      for listener in yandex_lb_network_load_balancer.wp_lb.listener :
      [for spec in listener.external_address_spec : spec.address]
    ]
    network_info = {
      instance_subnets = [
        for inst in yandex_compute_instance.wp_app : {
          name       = inst.name
          zone       = inst.zone
          subnet     = inst.network_interface[0].subnet_id
          private_ip = inst.network_interface[0].ip_address
        }
      ]
    }
  })
  
  filename = "${path.module}/inventory.ini"
  
  # Обновлять при каждом изменении ресурсов
  depends_on = [
    yandex_compute_instance.wp_app,
    yandex_mdb_mysql_cluster.wp_mysql,
    yandex_lb_network_load_balancer.wp_lb
  ]
}
# Вывод пути к inventory
output "inventory_path" {
  value = local_file.ansible_inventory.filename
}

output "inventory_content" {
  value = local_file.ansible_inventory.content
  sensitive = true
}