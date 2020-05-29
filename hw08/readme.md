Домашние задания по курсу "Безопасность Linux"
===============================================

ДЗ 8 - Wazuh
-----------------------------------------------

# Развертывание стенда

0. Поставил Wazuh 3.12.3 в virtualbox на ubuntu 18.04 / 8GB/4 ядра, ip 192.168.16.119/bridge
1. добавил в wazuh агентов (agent_manage), скопировал ключи:
- ub232 - ip 192.168.16.232 
- ub234 - ip 192.168.16.234
2. В vagrant/virtualbox поднял две виртуалки ub2 - ip 192.168.16.232 и ub4 - ip 192.168.16.234
3. На ub2 и ub4 поднял агентов wazuh, установил скопированные ранее ключи (agent_manage).
4. Сделал рестарт сервисам wazuh и агентам
5. Агенты появились в web-интерфейсе wazuh (см. [скриншот](artifacts/screensho-agetns.png)).
6. Развернул виртуалку (ub3, ip 192.168.16.233) с ubuntu для реализации брутфорса подопытных машин. Поставил туда гидру.

# Active Response
1. На хосте с wazuh в /var/ossec/etc/ossec/conf - нашел команду drop-firewall.
2. Прописал в ossec.conf настройки active response - запуск команды  drop-firewall на всех машинах с агентом, если сыграло правило 5712 брутфорс ssh (см. [конфиг](artifacts/ossec.conf)).
3. Перезапустил сервисы wazuh на машине с менеджером. 
4. На машине ub3 в двух терминалах запустил гидру:
```bash
vagrant@ub3:~$ hydra -V -f -t 4 -l test -P ./7-more-passwords.txt ssh://192.168.16.234
Hydra v8.6 (c) 2017 by van Hauser/THC - Please do not use in military or secret service organizations, or for illegal purposes.

Hydra (http://www.thc.org/thc-hydra) starting at 2020-05-29 16:20:49
[WARNING] Restorefile (you have 10 seconds to abort... (use option -I to skip waiting)) from a previous session found, to prevent overwriting, ./hydra.restore
[DATA] max 4 tasks per 1 server, overall 4 tasks, 528136 login tries (l:1/p:528136), ~132034 tries per task
[DATA] attacking ssh://192.168.16.234:22/
[ATTEMPT] target 192.168.16.234 - login "test" - pass "Ainslie1" - 1 of 528136 [child 0] (0/0)
[ATTEMPT] target 192.168.16.234 - login "test" - pass "jessica18" - 2 of 528136 [child 1] (0/0)
[ATTEMPT] target 192.168.16.234 - login "test" - pass "jessie12" - 3 of 528136 [child 2] (0/0)
[ATTEMPT] target 192.168.16.234 - login "test" - pass "jessie17" - 4 of 528136 [child 3] (0/0)
[ATTEMPT] target 192.168.16.234 - login "test" - pass "jets1234" - 5 of 528136 [child 3] (0/0)
[ATTEMPT] target 192.168.16.234 - login "test" - pass "jezebel1" - 6 of 528136 [child 0] (0/0)
[ATTEMPT] target 192.168.16.234 - login "test" - pass "jht1966" - 7 of 528136 [child 1] (0/0)
[ATTEMPT] target 192.168.16.234 - login "test" - pass "jimbob85" - 8 of 528136 [child 2] (0/0)
[ATTEMPT] target 192.168.16.234 - login "test" - pass "Archer01" - 63 of 528143 [child 0] (0/7)
[RE-ATTEMPT] target 192.168.16.234 - login "test" - pass "Angel!123" - 63 of 528143 [child 3] (0/7)
[ATTEMPT] target 192.168.16.234 - login "test" - pass "Archie10" - 64 of 528144 [child 1] (0/8)
[RE-ATTEMPT] target 192.168.16.234 - login "test" - pass "Annabel1" - 64 of 528144 [child 2] (0/8)
[ATTEMPT] target 192.168.16.234 - login "test" - pass "Ashley12" - 65 of 528145 [child 0] (0/9)
```

```bash
hydra -V -f -t 4 -l test -P ./7-more-passwords.txt ssh://192.168.16.234
```

5. В веб интерфейсе вазуха посмотрел Discovery panel для агентов ub232 и ub234 - увидел, что появились события - сработало правило 5710 - попытка залогиниться с несуществующим пользователем (см [скриншот](artifacts/screenshot-5710.png)). Через некоторое время появились события 5712 - брутфорс ssh (см [скриншот](artifacts/screenshot-5712.png)).
6. Посмотрел логи [active-responses.log](artifacts/active-responses_log) на агентах. Увидел, что команда firewall-drop сработала для ip 192.168.16.233 от правила 5712. 
```
Команда поначалу не срабатывала, в ossec.log сыпались ошибки - "не найден файл ar.conf" и "передана неверная команда *firewall-drop900*" . 
Видимо, по какой-то причине на агент не перадавался файл ar.conf с менеджера. 
Как workaround - создал руками на агентских виртуалках ar.conf - как копию ar.conf в менеджере и всё заработало.
```
7. Посмотрел вывод iptables -L на машинах с агентами - правило для фаервола создается. :
```bash
root@ub4:/var/ossec/logs# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         
DROP       all  --  192.168.16.233       anywhere            

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination         
DROP       all  --  192.168.16.233       anywhere            

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         
root@ub4:/var/ossec/logs# 
```

```bash
root@ub2:/var/ossec/logs# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         
DROP       all  --  192.168.16.233       anywhere            

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination         
DROP       all  --  192.168.16.233       anywhere            

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         
root@ub2:/var/ossec/logs# 
```


# Who-data

0. Установил и включил auditd на агентских машинах
1. Включил в агентских конфигах [ossec.conf](artifacts/ub234/ossec.conf) в разделах syscheck атрибуты check_all и whodata в тегах directories
2. Перезапустил сервисы ossec на агентах
3. Проверил - появилось ли правило auditd на контроль записи в папки /etc, /bin etc.
```bash
root@ub4:/var/ossec/bin# auditctl -l | grep wazuh_fim
-w /etc -p wa -k wazuh_fim
-w /usr/bin -p wa -k wazuh_fim
-w /usr/sbin -p wa -k wazuh_fim
-w /bin -p wa -k wazuh_fim
-w /sbin -p wa -k wazuh_fim
-w /boot -p wa -k wazuh_fim
```
4. сделал на машине ub4 sudo из-под пользователя vagrant. создал скрытый файл .hidden в директории /etc
5. В веб-интерфейсе вазуха в разделе security events по агенту ub4 фильтром по syscheck.event=added нашел запись о событии добавления файла в контролируемую директорию. rule.id=554. в этой записи видно, что syscheck.audit.login_user.name=vagrant, т.е. файл был создан пользователем vagrant (см [скриншот](artifacts/screenshot-who-data.png))
