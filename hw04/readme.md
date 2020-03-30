Домашние задания по курсу "Безопасность Linux"
===============================================

ДЗ 4 - docker hardening
-----------------------------------------------

1. Образ

Dockerfile - в директории ./setup-hardening-for-cis-benchmarks/server-app

образ создается на основе образа python:3.8.3-alpine3.11
Далее: 
- создаем пользователя webapp
- создаем директорию app, 
- копируем туда requirements.txt, приложение signal_server.py, скрипт для запуска приложения - entrypoint, 
- устанавливаем владельца всех файлов пользователя webapp
- устанавливаем необходимые пакеты (aiohttp), 
- конфигурируем скрипт HEALTHCHECK
- выставляем наружу порт 8188
- устанавливаем точку входа от пользователя webapp


2. Хост

Конфиг для вагранта имеет следующую структуру:

```


global:
    provider: 'vmware' #'vbox'          какой провайдер должен использовать вагрант для поднятия машин
                                        варианты: virtualBox | vmware-esxi
                                        если vmware, то необходимо задать переменные для подключения к esxi хосту

    store: '10'                         размер дополнительно подключаемого диска для машин
                                        так же этот параметр можно указать для каждой из
                                        машин по отдельности. Если провайдер vbox, то диск создается локально. 
                                        Если провайдер vmware, то диск создается на esxi хосте.

    ip_pattern: '192.168.100.10'        паттерн ip адреса для поднимаемых машин

    esxi_hostname: 'ip.or.host.fqdn'
    esxi_username: 'someuser'
    esxi_password: 'somepass'

boxes:
    nodeDoc18:
        box:
            box: 'bento/ubuntu-18.04'
            cpus: '4'
            mem: '4096'
            provision: ./ansible/nodebuntu/bootstrap.yml
            # disk_path: './sata.vdi'  <--- если провайдер vbox, то можно указать путь для создаваемоего диска, def ./sata_u.vdi


```

Управление esxi хостом осуществляется посредством
[vagrant-vmware-esxi plugin](https://github.com/josenk/vagrant-vmware-esxi)
Я буду использовать vmware-esxi провайдер. 

С помощью Vagrant поднимаем vm Ubuntu 18.04 из образа bento/ubuntu-18.04 (nodeDoc18, ip 192.168.100.101), создаем отдельный диск.
Далее плейбуками ansible (bootstrap.yml)
- (role startup) прописываем репозитории ubuntu 
- (role startup) создаем раздел, файловую систему, монтируем раздел в папку /var/lib/docker
- (role startup) создаем на vm nodeDoc18 пользователя otus с обычными правами и паролем vic!!vak (на всякий случай)
- (role setup_docker) устанавливаем docker, docker-compose, docker.py, docker-compose.py
- (role docker-tls) конфигурим подключение к сервису докера по TLS (исходник тут: https://github.com/ansible/role-secure-docker-daemon)
- (role setup-hardening-for-cis-benchmarks) загружаем проверочный скрипт docker-bench-security
- (role setup-hardening-for-cis-benchmarks) выполняем действия по харденингу хоста. т.к. хранилище контейнеров (/var/lib/docker) рамещается в отдельной партиции согласно CIS 1.2.1 (см примечание ниже), то остается сконфигурить auditd - устанавливаем и включаем демона, копируем на место файл audit.rules, в котором прописываем логирование попыток доступа к файлам и директориям докера.  
        Примечание:
        CIS banchmark 1.2.1 в скрипте docker-bench-security реализован как анализ вывода команды mountpoint. но если в docker.service прописан флаг --userns-remap, то дефолнтая директория докера - /var/lib/docker/xxxxx.xxxxx и скрипт выдает
        [WARN] 1.2.1 - Ensure a separate partition for containers has been created
        несмотря на то, что директория /var/lib/docker смонтирована в отдельной партиции
- (role setup-hardening-for-cis-benchmarks) выполняем действия по харденингу сервиса докера. Создаем конфигурацию для брокера авторизации twistedlock authz-broker. Создаем безопасную конфигурацию сервиса докера согласно CIS 1 и 2 (см. примечание ниже), включаем плагин authz-broker. Устанавливаем необходимые переменные окружения для плагина авторизации докера и клиента докера. Перезагружаем сервис докера.
        Примечание:
        CIS benchmark 2.6  в скрипте  docker-bench-security реализован как анализ командной строки dockerd или анализ daemon.json. у меня почему-то всегда срабатывает 
        [INFO] 2.6  - Ensure TLS authentication for Docker daemon is configured
        [INFO]      * Docker daemon not listening on TCP

        хотя в командной строке и в docker.service явно прописано -H tcp://192.168.100.101:2376 и при запуске sudo lsof -i :2376 выдает 

        COMMAND  PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
        dockerd 7029 root    3u  IPv4 101700      0t0  TCP nodeDoc18:2376 (LISTEN)

- (./dep_task/deployServApp.yaml) запускаем контейнер из образа в безопасной конфигурации согласно CIS 4 и 5
- (./dep_task/auditChecks.yaml) стартуем задания наших проверок:
1. Запуск скрипта docker-bench-security и вывод всей инфы в benchInfo.log
2. Аналогично для Trivy, с дампом в trivyInfo.log
-------------------------------------------------
Для проверки содержимого запустить 
vagrant ssh -c "cat benchInfo.log && cat trivyInfo.log"

