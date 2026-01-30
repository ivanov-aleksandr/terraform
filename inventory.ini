# ansible-inventory.tf.tpl
# Автоматически сгенерированный inventory для Ansible
# Создано Terraform: {{ timestamp }}

[wp_app]
{% for instance_name, ip in instance_ips %}
{{ instance_name }} ansible_host={{ ip }}
{% endfor %}

[wp_app:vars]
ansible_user=aivanov
ansible_ssh_private_key_file=~/.ssh/id_ed25519_aivanovvscode
ansible_python_interpreter=/usr/bin/python3
ansible_become=true
ansible_become_method=sudo

# Database configuration from Terraform
wp_db_name={{ db_info.db_name }}
wp_db_user={{ db_info.db_user }}
{% if db_password != "" %}
wp_db_password={{ db_password }}
{% endif %}

# MySQL hosts
{% for host in mysql_hosts %}
mysql_host_{{ loop.index }}={{ host }}
{% endfor %}

# Load balancer IPs
{% for ip_list in load_balancer_external_ips %}
{% for ip in ip_list %}
load_balancer_ip={{ ip }}
{% endfor %}
{% endfor %}

# Instance metadata
{% for instance_name, ip in instance_ips %}
{{ instance_name }}_private_ip={{ network_info.instance_subnets[loop.index0].private_ip }}
{{ instance_name }}_zone={{ network_info.instance_subnets[loop.index0].zone }}
{% endfor %}