Домашние задания по курсу "Безопасность Linux"
===============================================

ДЗ 10 - Шифрование, LUKS
-----------------------------------------------
0. Поднял виртуалку Ubutu 18.04 - ub2 - virtualbox - (см [Vagrantfile](Vagrantfile)), зашел в терминал
1. Сгенерил ключевой файл [enc.key](enc.key):
```bash
vagrant@ub2:~$ dd if=/dev/urandom of=~/enc.key bs=1 count=4096
4096+0 records in
4096+0 records out
4096 bytes (4.1 kB, 4.0 KiB) copied, 0.0107308 s, 382 kB/s
```
2. Создаем криптоконтейнер на основе ключа:

2.1. Создаем пустой файл fs.img, 10М:
```bash
vagrant@ub2:~$ dd if=/dev/zero of=./fs.img bs=1M count=10
10+0 records in
10+0 records out
10485760 bytes (10 MB, 10 MiB) copied, 0.027672 s, 379 MB/s
```
2.2. Создаем блочное устройство
```bash
vagrant@ub2:~$ sudo losetup --find --show ~/fs.img
/dev/loop0
```
2.3. cryptsetup установлен, создаем криптоконтейнер, используя enc.key в качестве ключа:
```bash
vagrant@ub2:~$ sudo  cryptsetup -s 512 luksFormat /dev/loop0 ~/enc.key

WARNING!
========
This will overwrite data on /dev/loop0 irrevocably.

Are you sure? (Type uppercase yes): YES
```

3. Отрываю криптоконтейнер ключем enc.key

3.1. открываем контейнер
```bash
vagrant@ub2:~$ sudo cryptsetup luksOpen /dev/loop0 dj_crypt -d ~/enc.key
```
3.2. монтируем контейнер в папку /home/vagrant/secret_disk, предварительно создав файловую систему
```bash
vagrant@ub2:~$ sudo mkfs.ext3 /dev/mapper/dj_crypt
mke2fs 1.44.1 (24-Mar-2018)
Creating filesystem with 8192 1k blocks and 2048 inodes

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (1024 blocks): done
Writing superblocks and filesystem accounting information: done

vagrant@ub2:~$ mkdir secret_disk

vagrant@ub2:~$ sudo mount /dev/mapper/dj_crypt /home/vagrant/secret_disk 
```
4. Создаю в папке secret_disk набор произвольных файлов
```bash
vagrant@ub2:~$ cd secret_disk
vagrant@ub2:~/secret_disk$ sudo touch test_{1..5}.txt
vagrant@ub2:~/secret_disk$ ls -lha
total 17K
drwxr-xr-x 3 root    root    1.0K Jun  6 15:35 .
drwxr-xr-x 6 vagrant vagrant 4.0K Jun  6 15:30 ..
drwx------ 2 root    root     12K Jun  6 15:32 lost+found
-rw-r--r-- 1 root    root       0 Jun  6 15:35 test_1.txt
-rw-r--r-- 1 root    root       0 Jun  6 15:35 test_2.txt
-rw-r--r-- 1 root    root       0 Jun  6 15:35 test_3.txt
-rw-r--r-- 1 root    root       0 Jun  6 15:35 test_4.txt
-rw-r--r-- 1 root    root       0 Jun  6 15:35 test_5.txt

```

5. Закрыл контейнер (отмонтировал папку, закрыл контейнер, проверил, что в /dev/mapper нет устройства, соответствующего контейнеру)
```bash
vagrant@ub2:~/secret_disk$ cd ~
vagrant@ub2:~$ sudo umount ~/secret_disk
vagrant@ub2:~$ sudo cryptsetup luksClose dj_crypt
vagrant@ub2:~$ sudo ls -lha /dev/mapper
total 0
drwxr-xr-x  2 root root      60 Jun  6 15:40 .
drwxr-xr-x 16 root root    3.6K Jun  6 15:40 ..
crw-------  1 root root 10, 236 Jun  6 15:07 control
vagrant@ub2:~$ ls -lha ~/secret_disk/
total 8.0K
drwxrwxr-x 2 vagrant vagrant 4.0K Jun  6 15:30 .
drwxr-xr-x 6 vagrant vagrant 4.0K Jun  6 15:30 ..
```
6. открыл контейнер, смонтировал устройство
```bash
vagrant@ub2:~$ sudo cryptsetup luksOpen /dev/loop0 dj_crypt -d ~/enc.key
vagrant@ub2:~$ sudo mount /dev/mapper/dj_crypt ~/secret_disk
```
7. проверил, что созданные файлы остались на месте
```bash
vagrant@ub2:~$ ls -lha ~/secret_disk/
total 17K
drwxr-xr-x 3 root    root    1.0K Jun  6 15:35 .
drwxr-xr-x 6 vagrant vagrant 4.0K Jun  6 15:30 ..
drwx------ 2 root    root     12K Jun  6 15:32 lost+found
-rw-r--r-- 1 root    root       0 Jun  6 15:35 test_1.txt
-rw-r--r-- 1 root    root       0 Jun  6 15:35 test_2.txt
-rw-r--r-- 1 root    root       0 Jun  6 15:35 test_3.txt
-rw-r--r-- 1 root    root       0 Jun  6 15:35 test_4.txt
-rw-r--r-- 1 root    root       0 Jun  6 15:35 test_5.txt
```

8. Создал доп. ключ

8.1. Создал еще один ключевой файл
```bash
vagrant@ub2:~$ dd if=/dev/urandom of=~/another.key bs=1 count=4096
4096+0 records in
4096+0 records out
4096 bytes (4.1 kB, 4.0 KiB) copied, 0.033995 s, 120 kB/s
```
8.2. Создал доп. ключ для контейнера
```bash
vagrant@ub2:~$ sudo cryptsetup luksAddKey /dev/loop0 -d ~/enc.key another.key
```

9. Удалил старый ключ, проверил, что слот 0 - пустой
```bash
vagrant@ub2:~$ sudo cryptsetup luksRemoveKey /dev/loop0 -d ~/enc.key 
vagrant@ub2:~$ sudo cryptsetup luksDump /dev/loop0 
LUKS header information for /dev/loop0

Version:       	1
Cipher name:   	aes
Cipher mode:   	xts-plain64
Hash spec:     	sha256
Payload offset:	4096
MK bits:       	512
MK digest:     	d0 99 e9 ab 99 7c 46 e1 15 40 19 e9 08 56 e8 35 ea 7c 65 b5 
MK salt:       	51 0b 16 20 55 44 f1 02 a9 b9 e6 24 e9 90 a8 28 
               	e4 d7 e4 ef ad 9e d8 45 14 6c 73 f3 56 f9 92 db 
MK iterations: 	77283
UUID:          	a62d86f9-1d5d-4359-8ac8-1ecdf52fd1f3

Key Slot 0: DISABLED
Key Slot 1: ENABLED
	Iterations:         	1464490
	Salt:               	cf 60 b2 e7 24 cb ce 5d 5a 17 0b ea 90 79 22 12 
	                      	6e a1 2f 65 18 3d 5b 0a dd 0b 05 7d 9f 3b 79 e2 
	Key material offset:	512
	AF stripes:            	4000
Key Slot 2: DISABLED

```

10. Попытался очистить слот 0, но т.к. текущая версия cryptsetup чистит слот после удаления ключа - получил уведомление - слот не активен:
```bash
vagrant@ub2:~$ sudo cryptsetup luksKillSlot /dev/loop0 0 -d ~/another.key
Keyslot 0 is not active.
```

11. Проделаем пункты 5-7 с новым ключем: размонтируем устройство, закрываем контейнер, открываем контейнер с новым ключем, проверяем, что файлы на месте:
```bash
vagrant@ub2:~$ sudo umount ./secret_disk
vagrant@ub2:~$ sudo cryptsetup luksClose dj_crypt
vagrant@ub2:~$ sudo cryptsetup luksOpen /dev/loop0 dj_crypt -d ~/another.key
vagrant@ub2:~$ sudo mount /dev/mapper/dj_crypt ./secret_disk/
vagrant@ub2:~$ ls -lhs ./secret_disk/
total 12K
12K drwx------ 2 root root 12K Jun  6 15:32 lost+found
  0 -rw-r--r-- 1 root root   0 Jun  6 15:35 test_1.txt
  0 -rw-r--r-- 1 root root   0 Jun  6 15:35 test_2.txt
  0 -rw-r--r-- 1 root root   0 Jun  6 15:35 test_3.txt
  0 -rw-r--r-- 1 root root   0 Jun  6 15:35 test_4.txt
  0 -rw-r--r-- 1 root root   0 Jun  6 15:35 test_5.txt
```
12. размонтируем устройство, закрываем контейнер, проверяем, что папка пустая
```bash
vagrant@ub2:~$ sudo umount ./secret_disk
vagrant@ub2:~$ sudo cryptsetup luksClose dj_crypt
vagrant@ub2:~$ ls -lhs ./secret_disk/
total 0
```