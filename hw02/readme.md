Домашние задания по курсу "Безопасность Linux"
===============================================
### ДЗ 2:
    centos (polkit, pam.d, chroot);
    ubuntu (apparmor);
    
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
-----------------------------------------------
### Описание работы

Создаем [vagrantfile](https://github.com/drJabber/otus_is_2020_01/blob/master/hw02/Vagrantfile) под 2 витруальные машины. 
0. на основе образа Centos/7 (nodevictim, ip 192.168.99.101)
1. на основе образа ubuntu (nodebuntu, ip 192.168.99.102)

Конфиги для vm задаются в файле [boxes_config.yml](https://github.com/shizzgar/otus-is-2020-1/blob/master/hw02/Vagrantfile)
К vm nodecent подключается виртуальный диск disk.vdi с помощью плагина vagrant-newdisk (необходимо установить) как /dev/sdb
На стадии provivion в файлы /etc/hosts прописываются ip:hostname обеих машин. Используется плагин vagrant-hosts
На стадии provision каждый плейбук ansible производит над vm nodevictim следующие действия:
0. Пинг, отключение возможности авторизации по паролю, и из под root 
1. Создается группа otus и пользователи otus, otus2, otus3 в этой группе, для пользователей копируются открытые ключи из папки [bootstrap/keys/](https://github.com/shizzgar/otus-is-2020-1/tree/master/hw02/bootstrap/keys) 
2. Создание раздела /dev/sdb1 и файловой системы на /dev/sdb
3. В папку /etc/polkit-1/rules.d копируется [правило политики policykit](https://github.com/shizzgar/otus-is-2020-1/blob/master/hw02/bootstrap/rules/0-udisks2.rules), которое позволяет пользователю otus монтировать раздел /dev/sdb1
4. Создается ограниченное chroot-окружение [скриптом ansible/chroot/chroot_env.sh](https://github.com/shizzgar/otus-is-2020-1/blob/master/hw02/bootstrap/cent/chroot_env.sh), в sshd_config прописывается использование chroot-окружения для пользователя otus3
5. Создается pam.d политика, которая запрещает пользователю otus2 вход через ssh. в pam.d в конфиге sshd создается запись, которая требует строго положительного ответа от модуля pam_time.so, в конфиге time.conf создается запись, которая запрещает пользователю otus2 любые действия 24/7
6. Скопипастил профиль nginx для докера [тут](https://docs.docker.com/engine/security/apparmor/), он лежит в локальной папке [bootstrap/rules/](https://github.com/shizzgar/otus-is-2020-1/tree/master/hw02/bootstrap/rules) и установил его в /etc/apparmor.d/containers/docker-nginx. Включил его в apparmor. Развернул образ докера с nginx с включенным профилем 

***

### Проверка выполнения задания:
* polkit:
- ssh -i ./bootstrap/keys/otus otus@192.168.99.101 //зашли пользователем otus на vm nodecent
- udisksctl mount -b /dev/sdb1    // /dev/sdb1 монтируется в папку /run/media/otus/<some uuid>

* chroot
- ssh -i ./bootstrap/keys/otus3 otus3@192.168.99.101 //зашли пользователем otus на vm nodecent - попадаем с chroot directori, видим только то, что в /var/chroot/otus

* pamd
- ssh -i ./bootstrap/keys/otus2 otus2@192.168.99.101  //пытаемся зайти пользователем otus2 на vm nodecent - получаем connection closed

* apparmor
- vagrant ssh nodeubu
- docker exec -it apparmor-nginx bash
- cd ~ 
- touch ./some //permission denied
- exit 
- aa-complain /etc/apparmor.d/containers/docker-nginx
- docker exec -it apparmor-nginx bash
- top // top выполняется
