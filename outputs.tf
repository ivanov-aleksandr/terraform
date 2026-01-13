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
    database = yandex_mdb_mysql_database.wp_db.name
    user     = yandex_mdb_mysql_user.wp_user.name
  }
  sensitive = true
}