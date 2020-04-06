Домашние задания по курсу "Безопасность Linux"
===============================================

ДЗ 5 - SELinux
==============

Vagrantfile
------------
* Для сведения: Использован плагин vagrant-hosts

в vagrantfile поднимаем vm из образа centos/7 (nodevictim, ip 192.168.99.101)
Далее плейбуками ansible (bootstrap.yml)
- (role startup) прописываем репозитории epel-release 
- (role startup) устанавливаем необходимые пакеты (для работы с selinux, etc)
- (role startup) создаем на vm nodebuntu пользователя otus с обычными правами и паролем vic!!vak (на всякий случай)
- (role nginx) ставим nginx и конфиги. в конфиге nginx_vhosts.conf прописывам порт <b>8188</b>, 
- (role nginx) стартуем сервис nginx - видим, что он не стартовал.

Задание 1
-----------
Запустить nginx на нестандартном порту тремя способами.

### Исходные условия: 
- Centos 7 с вкюченным SELinux
- nginx настроен на запуск на порту 8188 (см ansible/nodevictim/roles/templates/nginx_vhosts.conf + ansible/nodevictim/bootstrap.yml переменная nginx_port)
- в директорию /var/www/{{ virtual_domain}} помещается файл index.html для использования в проверке работоспособности nginx 
- для выполнения запуска nginx в том или ином режиме используется переменная окружения NGINX_CUSTOM_PORT_SELINUX_MODE, возможные значения:
  selinux_setsebool - для изменения заначения флага selinux (nis_enabled)
  selinux_add_port_to_existing_type - для добавления нестандартного порта к имеющемуся типу (http_port_t)
  selinux_semodule - для создания кастомного модуля 

1. Разрешение запуска nginx на порту 8188, используя  переключатель setsebool (nis_enabled=1). 
   Для изменения значения флага используется роль selinux_setsebool. 

   выполняем :

   #vagrant destroy --force && NGINX_CUSTOM_PORT_SELINUX_MODE=selinux_setsebool vagrant up --provision  

   в выводе vagrant получаем:
   "nginx start OK (setsebool)
   <body>nginx works fine</body> (selinux_setsebool)

   т.е. nginx стартует на нестандартном порту 8188 и отдает index.html без ошибок

2. Разрешение запуска nginx на порту 8188 добавлением порта в существующий тип
   Для добавления порта используется роль selinux_add_port_to_existing_type. В main.yml используется модуль ansible seport, который выполняет задачу, аналогичную semanage port -a -t http_port_t -p tcp 8188

   выполняем :

   #vagrant destroy --force && NGINX_CUSTOM_PORT_SELINUX_MODE=selinux_add_port_to_existing_type vagrant up --provision  

   в выводе vagrant получаем:
   "nginx start OK (seport)
   <body>nginx works fine</body> (selinux_add_port_to_existing_type)

   т.е. nginx стартует на нестандартном порту 8188 и отдает index.html без ошибок

3.   Разрешение запуска nginx на порту 8188 созданием кастомного модуля
   Создаем кастомный модуль nginx_custom_module.te (см. ansible/nodevictim/roles/selinux_semodule/templates/nginx_custom_module.te),
   который позволит nginx слушать порт, помеченный как nginx_custom_port_t, соберем новый модуль и активируем его, затем добавим порт 8188 к типу nginx_custom_port_t (см. роль selinux_semodule)

   выполняем :

   #vagrant destroy --force && NGINX_CUSTOM_PORT_SELINUX_MODE=selinux_semodule vagrant up --provision  

   в выводе vagrant получаем:
   "nginx start OK (semodule)
   <body>nginx works fine</body> (selinux_semodule)

   т.е. nginx стартует на нестандартном порту 8188 и отдает index.html без ошибок


Задание 2
-----------
Найти проблему с обновлением зоны в конфигах named, предложить варианты решений . Стенд находится в директории part_ii/selinux_dns_problems

- Инженер делает vagrant up, затем после поднятия всех машин делает vagrant ssh client. на клиенте он выполняет тестовый кейс с обновлением зоны. 
- в другой консоли он делает vagrant ssh ns01, затем выполняет $sudo cat /var/log/audit/audit.log | audit2why и получает
```bash
   type=AVC msg=audit(1585672748.000:2688): avc:  denied  { create } for  pid=31228 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

      Was caused by:
         Missing type enforcement (TE) allow rule.

         You can use audit2allow to generate a loadable module to allow this access.

```
<b>делаем вывод, что, возможно, named не может создать файл журнала<b>

- на первый взгляд логичным решением было бы сдлеать политику 
```java
module bind-named-etc 1.0;

require {
    type etc_t;
    type named_t;
    class file { read write };
}

allow named_t etc_t : file { read write };
```
которая позволит named писать в /etc, и соответственно, дописать  playbook.yml в конце раздела "hosts: ns01"

```yml
  - name: copy module template
    template:
      src: "files/ns01/bind-named-etc.te"
      dest: "/var/lib/selinux/bind-named-etc.te"
    register:   semodule_te

  - name: build and install selinux nginx_custom_module
    command: "{{ item }}"
    args: 
      chdir: /var/lib/selinux
    with_items:
      - "checkmodule -M -m bind-named-etc.te -o bind-named-etc.mod "
      - "semodule_package -o bind-named-etc.pp -m bind-named-etc.mod"
      - "semodule -i bind-named-etc.pp"
    register: semodule_added  
    when: (semodule_te)
  
  - name: try to start named 
    service:
      name: named
      state: restarted    
    when: (semodule_added) 
```
Но в этом случае, если злодей поломает named (такая вероятность существует, т.к. named смотрит наружу), то он сможет писать в /etc и стало быть сможет получить контроль над всем хостом ns01. Такое безобразие инженер допустить не может, поэтому ему надо придумать какое-то другое решение.

- второе, что пришло в голову инженеру - добавить в файловый контекст named директорию, в которой named пытается создать файл журнала ddns (/etc/named/dynamic). Тогда он решил проанализировать файловые контексты named на ns01:
```bash
[vagrant@ns01 etc]$ sudo semanage fcontext -l | grep named_t

[vagrant@ns01 etc]$ sudo semanage fcontext -l | grep named_conf_t
/etc/rndc.*                                        regular file       system_u:object_r:named_conf_t:s0 
/etc/unbound(/.*)?                                 all files          system_u:object_r:named_conf_t:s0 
/var/named/chroot(/.*)?                            all files          system_u:object_r:named_conf_t:s0 
/etc/named\.rfc1912.zones                          regular file       system_u:object_r:named_conf_t:s0 
/var/named/chroot/etc/named\.rfc1912.zones         regular file       system_u:object_r:named_conf_t:s0 
/etc/named\.conf                                   regular file       system_u:object_r:named_conf_t:s0 
/var/named/named\.ca                               regular file       system_u:object_r:named_conf_t:s0 
/etc/named\.root\.hints                            regular file       system_u:object_r:named_conf_t:s0 
/var/named/chroot/etc/named\.conf                  regular file       system_u:object_r:named_conf_t:s0 
/etc/named\.caching-nameserver\.conf               regular file       system_u:object_r:named_conf_t:s0 
/var/named/chroot/var/named/named\.ca              regular file       system_u:object_r:named_conf_t:s0 
/var/named/chroot/etc/named\.root\.hints           regular file       system_u:object_r:named_conf_t:s0 
/var/named/chroot/etc/named\.caching-nameserver\.conf regular file       system_u:object_r:named_conf_t:s0 

[vagrant@ns01 etc]$ sudo semanage fcontext -l | grep named_zone_t
/var/named(/.*)?                                   all files          system_u:object_r:named_zone_t:s0 
/var/named/chroot/var/named(/.*)?                  all files          system_u:object_r:named_zone_t:s0 
```

и в процессе анализа, инженеру приходит гениальная по своей простоте идея (да, он скромен) - а что, если в конфигурации named для ddns содержится очепятка, и необходимо просто

- в named.conf в дазделах для ddns поменять директорию, где размещается файл зоны с /etc/named/dynamic на /var/named/dynamic (см поправленный файл /part_ii/selinux_dns_problems/provisioning/files/ns01/named.conf )

### Эпилог

Инженер правит конфиг named, делает sudo vagrant destroy ns01 --force && sudo vagrant up ns01, с машины client выполняет тестовый кейс и наслаждается плодами своих трудов:
```bash
[vagrant@client ~]$ sudo nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> [vagrant@client ~]$ ping ya.ru
PING ya.ru (87.250.250.242) 56(84) bytes of data.
64 bytes from ya.ru (87.250.250.242): icmp_seq=1 ttl=63 time=16.5 ms
64 bytes from ya.ru (87.250.250.242): icmp_seq=2 ttl=63 time=16.6 ms
64 bytes from ya.ru (87.250.250.242): icmp_seq=3 ttl=63 time=14.7 ms
64 bytes from ya.ru (87.250.250.242): icmp_seq=4 ttl=63 time=14.3 ms
64 bytes from ya.ru (87.250.250.242): icmp_seq=5 ttl=63 time=14.1 ms
^C
--- ya.ru ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 7285ms
rtt min/avg/max/mdev = 14.131/15.279/16.604/1.071 ms

```




   


