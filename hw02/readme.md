Домашние задания по курсу "Безопасность Linux"
===============================================
### ДЗ 2:
    centos(polkit, pam.d, chroot);
    ubuntu(apparmor)
-----------------------------------------------
### Создаем 2 витруальные машины:
* на основе образа Centos/7 (nodeCent, ip 192.168.99.101)
* на основе образа ubuntu/bionic64 (nodeUbu, ip 192.168.99.102)
-----------------------------------------------
```
homework
├── Vagrantfile                     Вагрант файл 
├── readme.md                       Прочти меня, пожалуйста!
├── boxes_config.yml                Конфиги для vm
└── bootstrap                       
    ├── ubu                         Provision окружение для ubuntu
    │   ├── inst_docker.yaml        Задания для установки docker на убунуту
    │   ├── bootstrap.yaml          Bootstrap включающий в себя все задачи для поднятия окружения
    │   └── aa_nginx_conf.yaml      Задания для настройки apparmor профайла под nginx контейнер
    ├── rules
    │   ├── docker-nginx            Аpparmor профайла под nginx
    │   └── 0-udisks2.rules         Правило, разрешающее пользователю otus монтировать диски
    ├── keys                        Ключики
    │   ├── otus                          #
    │   ├── otus.pub                      #
    │   ├── otus1                         #
    │   ├── otus1.pub                     #
    │   ├── otus2                         #
    │   └── otus2.pub                     #
    └── cent                        Provision окружение для centos
        ├── user_manage.yaml        Создание группы, пользователей и пропброс ключей
        ├── udisk_policy.yaml       Задачи для настройки политики монтирования пользователем otus
        ├── setup_chroot.yaml       Задачи для настройик chroot окружения для логина via ssh пользователю otus3
        ├── ping_disableSSH.yaml    Пинг и отключение ssh login via root
        ├── manageSSH_pamd.yaml     Задачи на запрет авторизации пользователю otus2 via ssh с помощью time_conf 
        ├── chroot_env.sh           Help bash script для настройик chroot окружения
        └── bootstrap.yml           Bootstrap содержащий переменные и задачи для поднятия окружения
```

Конфиги для vm задаются в файле boxes_config.yml
В папке bootstrap содержатся инструкции provosion для каждой машины. 