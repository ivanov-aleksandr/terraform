Обзор
Данная конфигурация создает инфраструктуру для развертывания WordPress в Яндекс Облаке с использованием:

Масштабируемых виртуальных машин WordPress

Managed MySQL кластера

Сетевого балансировщика нагрузки

Виртуальной сети и подсетей

1. provider.tf - Конфигурация провайдера
   Назначение: Определяет провайдера Yandex Cloud и его настройки.
   Что делает:

Настраивает подключение к Яндекс Облаку

Указывает требуемую версию провайдера

Определяет cloud_id и folder_id для работы с ресурсами

2. variables.tf - Переменные конфигурации
   Назначение: Определяет все переменные, используемые в конфигурации.
   Что делает:

Определяет параметры конфигурации, которые можно менять без изменения кода

Позволяет масштабировать инфраструктуру через переменные

Содержит чувствительные данные (пароли)

3. network.tf - Сетевая инфраструктура
   Назначение: Создает виртуальную сеть и подсети.

Что делает:

Создает виртуальную сеть для всей инфраструктуры

Создает подсети в разных зонах доступности

Определяет IP-диапазоны для каждой подсети

4. wp-app.tf - Виртуальные машины WordPress
   Назначение: Создает масштабируемые инстансы WordPress.

Что делает:

Создает указанное количество виртуальных машин WordPress

Распределяет машины по зонам доступности

Настраивает сетевые интерфейсы с внешними IP

Устанавливает SSH ключи для доступа

Использует готовый образ с предустановленным WordPress

5. db.tf - Managed MySQL база данных
   Назначение: Создает управляемый кластер MySQL для WordPress.

6. lb.tf - Балансировщик нагрузки
   Назначение: Создает сетевой балансировщик нагрузки для WordPress инстансов

7. outputs.tf - Вывод информации
   Назначение: Выводит важную информацию после развертывания.

Порядок развертывания
Настройка провайдера (provider.tf) - подключение к Яндекс Облаку

Создание сети (network.tf) - виртуальная сеть и подсети

Развертывание БД (db.tf) - MySQL кластер, база данных, пользователь

Создание инстансов (wp-app.tf) - виртуальные машины WordPress

Настройка балансировщика (lb.tf) - распределение трафика

Вывод информации (outputs.tf) - данные для подключения

Использование

# Инициализация
terraform init
# Планирование развертывания
terraform plan
# Применение конфигурации
terraform apply -auto-approve
# Просмотр выходных данных
erraform output
# Уничтожение инфраструктуры
terraform destroy 

Работа выполнялась на ОС windows
При первом подключении к ЯО:

terraform init
terraform initInitializing the backend...
Initializing provider plugins...

Finding yandex-cloud/yandex versions matching ">= 0.70.0"...╷│ Error: Invalid provider registry host││ The host " registry.terraform.io " given in provider source address " registry.terraform.io/yandex-cloud/yandex " does not│ offer a Terraform provider registry.

Уппс…

Ошибка указывает на то, что Terraform пытается найти провайдер Yandex в официальном реестре HashiCorp (registry.terraform.io), но его там нет — потому что провайдер Yandex Cloud публикуется в собственном реестре Yandex, а не в общем реестре HashiCorp. Нужно создать файл terraform.rc каталоге %APPDATA% Чтобы узнать абсолютный путь к папке %APPDATA%, echo %APPDATA% для cmd или $env:APPDATA для PowerShell.

terraform.rc

provider_installation {
network_mirror {
url = "https://terraform-mirror.yandexcloud.net/"
include = ["registry.terraform.io/*/*"]
}
direct {
exclude = ["registry.terraform.io/*/*"]
}
}

Для подключения с помощью служебного пользователя необходимо получить ключ
Ключ сервис аккаунта ЯО terrafotm (я опечатался, когда создавал пользователя.)
yc iam access-key create --service-account-id aje5762i.......8283
yc iam access-key create --service-account-name terrafotm
посмотреть пользователя ЯО
yc iam service-account list
yc iam key list --service-account-id
какие права уже есть у сервисного аккаунта
yc resource-manager folder list-access-bindings <folder_id>
Переменная $env:YC_SERVICE_ACCOUNT_KEY_FILE="C:\otus\terraform\terraform\key1.json" указывает ключ для подключения к ЯО часть содержания файла:
"created_at": "2026-01-09T10:48:27.162669042Z",
"key_algorithm": "RSA_2048",
"public_key": "-----BEGIN PUBLIC KEY-----\nMIIBIjA....
