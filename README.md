# IFMO_DistributedComputing_for_DevOps
Distributed Computing course for DevOps 2025

# Лабораторная работа №1 - запустить wordpress в docker

## Требования к целевому хосту:

1. Linux (Debian/Ubuntu, x86_64)
1. Доступ по SSH с sudo для пользователя Ansible
1. Открыты порты 80, 443
1. Включен порт 80 на стороне роутера если хотите получение сертификата Let's Encrypt из интернета
1. Домен, который указывает на IP хоста (я использовал для проверки `kirill-gruzdy.ru`, который указывает на `158.160.137.134`)
1. Python, pip последний (Ansible сам подтянет python-docker)
1. 2 ГБ RAM, 10 ГБ+ на диск

## Как запустить:

1. Заполнить файл `inventory.ini` вашими значениями:

```
all:
  hosts:
    carrier:
      ansible_host: 192.168.XXX.XXX
      ansible_user: XXXXXXX
      ansible_password: XXXXXXX
      ansible_become_method: sudo
      ansible_become_pass: XXXXXXX
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
```

1. В файле playbook (или в vars/ файле) укажите переменные под себя:
   
   - `swag_domain`: укажите ваш реальный домен
   - `swag_email`: ваш email для Let's Encrypt
   - `db_pass`, `db_root_pass` - придумайте сложные

1. Установить зависимости к себе на управляющую машину (рекомендуется использовать виртуальное окружение):

```
pip install ansible
ansible-galaxy collection install community.docker
```

1. Запустить плейбук:

```
ansible-playbook -i inventory.ini playbook1.yml
```

## Как создать и активировать виртуальное Python-окружение, чтобы запустить плейбук

1. Установи `python3` и `pip`, если ещё не стоят

```
sudo apt update
sudo apt install python3 python3-pip python3-venv
```

1. Создай виртуальное окружение и активируй его

```
python3 -m venv venv-ansible
source venv-ansible/bin/activate
# (должна появиться приставка (venv-ansible) перед $)
```

1. Установи `ansible` и нужные коллекции внутри виртуального окружения

```
python3 -m pip install --upgrade pip
pip install ansible
ansible-galaxy collection install community.docker
```

1. Запусти плейбук

```
ansible-playbook -i inventory.yml playbook1.yml
```

# Лабораторная работа №2 - заменить БД на кластер, и обеспечить синхронизацию данных

## Как запустить:

1. Изучить как запустить лабораторнау работу №1 и плейбук `playbook1.yml`, он был обновлён и теперь запускает не просто БД, а мастер БД.

```
ansible-playbook -i inventory.ini playbook1.yml
```

1. Далее необходимо запустить следующий плейбук. Он добавит контейнер `mariadb-replica` и настроит его на синхронизацию с мастером.

```
ansible-playbook -i inventory.ini playbook2.yml
```

После успешного выполнения обоих плейбуков инфраструктура будет полностью развернута.

## Как вручную проверить работоспособность репликации

Благодаря тому, что мы в плейбуках пробросили порты баз данных на localhost хост-машины (127.0.0.1), мы можем подключаться к ним напрямую, не заходя в контейнеры.

- Мастер-база (mariadb-master) доступна на порту 3306.
- Реплика (mariadb-replica) доступна на порту 3307.

Для проверки необходимо подключиться к целевому серверу по SSH.

### 1. Проверка статуса реплики

Подключитесь к контейнеру реплики и проверьте статус.

```bash
# Подключаемся к клиенту MariaDB реплики (порт 3307)
# Пароль будет запрошен (указан в inventory.yml как db_root_pass)
mysql -u root -p -h 127.0.0.1 -P 3307

# Внутри клиента выполняем команду
SHOW SLAVE STATUS\G
```

Убедитесь, что в выводе присутствуют строки:
- `Slave_IO_Running: Yes`
- `Slave_SQL_Running: Yes`
- `Seconds_Behind_Master: 0`

### 2. Практическая проверка синхронизации данных

Откройте два терминала с SSH-подключением к серверу.

**В первом терминале (Мастер):**
```bash
# Подключаемся к мастер-базе (порт 3306)
mysql -u root -p -h 127.0.0.1 -P 3306

# Создаем тестовую базу
CREATE DATABASE replication_test;

# Проверяем, что она создалась
SHOW DATABASES;
```

**Во втором терминале (Реплика):**
```bash
# Подключаемся к реплике (порт 3307)
mysql -u root -p -h 127.0.0.1 -P 3307

# Проверяем, появилась ли база
SHOW DATABASES;
```
База данных `replication_test` должна появиться в списке.

**Очистка (в терминале Мастера):**
```sql
DROP DATABASE replication_test;
```