Домашние задания по курсу "Безопасность Linux"
===============================================

ДЗ 6 - OSSIM
-----------------------------------------------

Загружаем образ Alienvault OSSIM.
Создаем vm otus на базе образа OSSIM(2 сетевых интерфейса eth0 - bridged network, eth1 - internal network "netb")
Устанавливаем OSSIM (IP 192.168.16.69 gw 192.168.16.1)
Конфигурируем eth1 - 10.0.0.5

Создаем [vagrantfile](https://github.com/shizzgar/otus-is-2020-1/blob/master/hw06/Vagrantfile) для metasploitable3 (образ rapid7/metasploitable3-ub1404, eth1 - internal network "netb" ip 10.0.0.51), запускаем vm

Проводим первоначальные настройки в визарде вебинтерфейса ossim 
Добавляем агента HIDS в менеджере агентов для asset'a 10.0.0.51, копируем ключ

В vm metasplitable прописываем репозиторий ossec и устанавливаем агента HIDS. Запускаем менеджер агентов и устанавлмваем скопированный ранее ключ
Перезапускаем сервисы ossec. В вебинтерфейсе ossim убеждаемся, что hids агент от metasploitable подключен (active). [Скриншот] прилагается.

В вебинтерфейсе ossim создаем scan job (immediate) для сканера уязвимостей. Дожидаемся окончания сканирования (~40 мин)
В отчете видим следующие уязвимости катерории high:
1. Drupal Coder Remote Code Execution
2. Drupal Core SQL Injection Vulnerability
3. ProFTPD `mod_copy` Unauthenticated Copying Of Files Via SITE CPFR/CPTO
4. Detection of backdoor in UnrealIRCd
5. SSH Brute Force Logins With Default Credentials Reporting
6. HTTP dangerous methods

Устраняем уязвимости 4 и 6 - установка обновленной версии unrealircd (5.0) и запретом методов PUT и DELETE в конфигах apache2.
Повторно осуществляем сканирование уязвимостей vm metasploitable3, убеждаемся, что данные уязвимости в отчете отсутствуют (отчет прилагается).


Создаем [vagrantfile](https://github.com/drJabber/otus_is_2020_01/blob/master/hw02/Vagrantfile) под 2 витруальные машины. 
1. на основе образа Centos/7 (nodevictim, ip 192.168.99.101)
2. на основе образа ubuntu (nodebuntu, ip 192.168.99.102)

Конфиги для vm задаются в файле [boxes_config.yml](https://github.com/drJabber/otus_is_2020_01/blob/master/hw02/boxes_config.yml)
К vm nodevictim поключается виртуальный диск sata_v.vdi с помощью плагина vagrant-newdisk (необходимо установить) как /dev/sdb
На стадии provivion в файлы /etc/hosts прописываются ip:hostname обеих машин. Используется плагин vagrant-hosts
На стадии provision в каждой плейбуком ansible на vm nodevictim производятся следующие действия:
1. Создание раздела /dev/sdb1 и файловой системы на /dev/sdb 
2. В папку /etc/polkit-1/rules.d копируется [правило политики policykit](https://github.com/drJabber/otus_is_2020_01/blob/master/hw02/ansible/nodevictim/polkit/10-mount-sdb1-for-user-otus.rules), которое позволяет пользователю otus монтировать раздел /dev/sdb1 
3. Создается группа otus и пользователи otus, otus2, otus3 в этой группе с паролем vic!!vak, для пользователей копируются открытые ключи из [папки ansible/nodevictim/ssh](https://github.com/drJabber/otus_is_2020_01/tree/master/hw02/ansible/nodevictim/ssh)
4. Создается ограниченное chroot-окружение [скриптом ansible/chroot/make_chroot.sh](https://github.com/drJabber/otus_is_2020_01/blob/master/hw02/ansible/nodevictim/chroot/make_chroot.sh), в sshd_config прописывается использование chroot-окружения для пользователя otus3
5. Создается pam.d политика, которая запрещает пользователю otus2 вход через ssh. в pam.d в конфиге sshd создается запись, которая требует строго положительного ответа от модуля pam_time.so, в конфиге time.conf создается запись, которая запрещает пользователю otus2 любые действия 24/7
6. Скопипастил профиль nginx для докера [тут](https://docs.docker.com/engine/security/apparmor/), он лежит в локальной папке [ansible/nodebuntu/apparmor] и установил его в /etc/apparmor.d/containers/docker-nginx. Включил его в apparmor. развернул образ докера с nginx с включенным профилем 

Проверка выполнения задания:
1. polkit:
- ssh -i ./ansible/nodevictim/ssh/otus3_key otus@192.168.99.101 //зашли пользователем otus на vm nodevictim
- udisksctl mount -b /dev/sdb1    // /dev/sdb1 монтируется в папку /run/media/otus/<some uuid>

2. chroot
- ssh -i ./ansible/nodevictim/ssh/otus3_key otus3@192.168.99.101 //зашли пользователем otus на vm nodevictim - попадаем с chroot directori, видим только то, что в /var/chroot/otus

3. pamd
- ssh -i ./ansible/nodevictim/ssh/otus3_key otus2@192.168.99.101  //пытаемся зайти пользователем otus2 на vm nodevictim - получаем connection closed

4. apparmor
- vagrant ssh nodebuntu
- docker exec -it apparmor-nginx bash
- top // получаем permission denied
- exit 
- aa-complain /etc/apparmor.d/containers/docker-nginx
- docker exec -it apparmor-nginx bash
- top // top выполняется

