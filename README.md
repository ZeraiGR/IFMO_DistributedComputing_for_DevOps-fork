# IFMO_DistributedComputing_for_DevOps
Distributed Computing course for DevOps 2025

# Лабораторная работа №1 - запустить wordpress в docker

### В качестве облачного провайдера используется yandex cloud со следующими ресурсами

1. Сервисный аккаунт `ansible-inventory-manager`, с ролью `viewer` в каталоге, чтобы `ansible` от его лица смог получать информацию об облачных ресурсах
1. Авторизованный ключ для сервисного аккаунта `ansible-inventory-manager` - нужен для запроса IAM-токена и доступа к YDB через API
1. DNS зона для домена `kirill-gruzdy.ru.` c `A` записью для ip `158.160.137.134`
1. Виртуальная машина с публичным ip `158.160.137.134`, OS `Ubuntu 24.04 LTS`, `1GB RAM`, `2 vCPU`
1. Группы безопасности для настройки входящего и исходящего трафика по портам `22,80,443`

### Про Vagrant
От использования Vagrant отказался по той причине, что компания HashiCorp заблокировала доступ к своим ресурсам из России.

### Запуск

```
ansible-playbook -i inventory.sh site.yml --ask-vault-pass
```

### Технические детали

- Для установки docker на виртуальную машину используется готовая популярная роль `geerlingguy.docker`
- Для установки wordpress используется кастоманя роль `wordpress_app`, с настройкой сертификатов
- Используется динамический `inventory`, для того, чтобы не хардкодить ip виртуальной машины

### Проверка

- Поднятый wordpress доступен по url `https://kirill-gruzdy.ru`
- Данные от админки:
    - login: kirill-gruzdy
    - password: 12345
