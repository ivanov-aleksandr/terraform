variable "yc_cloud" {
  type = string
  description = "Yandex Cloud ID"
}

variable "yc_folder" {
  type = string
  description = "Yandex Cloud folder"
}

variable "db_password" {
  description = "MySQL user pasword"
}

variable "instance_count" {
  description = "Number of WordPress instances"
  type        = number
  default     = 2
}

variable "instance_zones" {
  description = "List of zones for instances"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b"]
}

variable "instance_name_prefix" {
  description = "Prefix for instance names"
  type        = string
  default     = "wp-app"
}

variable "instance_resources" {
  description = "Resources configuration for instances"
  type = object({
    cores  = number
    memory = number
  })
  default = {
    cores  = 2
    memory = 2
  }
}