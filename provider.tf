provider "yandex" {
  cloud_id  = var.yc_cloud
  folder_id = var.yc_folder
}

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "~> 0.177.0"
    }
  }
}

