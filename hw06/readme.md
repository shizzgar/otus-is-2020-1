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
Перезапускаем сервисы ossec. В вебинтерфейсе ossim убеждаемся, что hids агент от metasploitable подключен (active). [Скриншот](https://github.com/shizzgar/otus-is-2020-1/blob/master/hw06/data/hids.png) прилагается.

В вебинтерфейсе ossim создаем scan job (immediate) для сканера уязвимостей. Дожидаемся окончания сканирования (~40 мин)
В отчете видим следующие уязвимости катерории high ([см. отчет](https://github.com/shizzgar/otus-is-2020-1/blob/master/hw06/data/ScanResult_20200509_before_repair.pdf)):
1. Drupal Coder Remote Code Execution
2. Drupal Core SQL Injection Vulnerability
3. ProFTPD `mod_copy` Unauthenticated Copying Of Files Via SITE CPFR/CPTO
4. Detection of backdoor in UnrealIRCd
5. SSH Brute Force Logins With Default Credentials Reporting
6. HTTP dangerous methods

Устраняем уязвимости 4 и 6 - установка обновленной версии unrealircd (5.0) и запретом методов PUT и DELETE в конфигах apache2.
Повторно осуществляем сканирование уязвимостей vm metasploitable3, убеждаемся, что данные уязвимости в отчете отсутствуют ([см.отчет](https://github.com/shizzgar/otus-is-2020-1/blob/master/hw06/data/ScanResult_20200509_after_repair.pdf)).

Проблемы в данной работе вызвало то, что БД mysql OSSIM постоянно ломается, если неожиданно выключается виртуалка с OSSIM (а выключается она часто, т.к. ноут слабенький). Про то, как чинить БД в таких случаях - информацию не нашел, поэтому обошелся снапшотом vm - но в реальной работе - придется постоянно бэкапить БД и при авариях восстанавливать из бекапа.