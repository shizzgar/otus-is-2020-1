Домашние задания по курсу "Безопасность Linux"
===============================================

ДЗ 7 - Volatity
-----------------------------------------------

# Задача 1
0. Попытался работать с Volatility stabdalone (solid elf) - не получилось подсунуть ему профиль.

1. Скачал исходники с github. распаковал в /opt/volatility 
2. Сделал виртуальное окружение

mkdir venv
python -m venv ./venv
source ./venv/bin/activate

3. запустил установку пакета volatility

python setup.py install

4. скопировал профиль в ./volatility/plugins/overlays/linux

5. распаковал дамп памяти в /mnt/data/otus/IS_2019_12/16/task1/memory.vmem

6. запустил volatility с командой linux_pslist

(venv) djabber@xJabber:/opt/volalitily/volatility-master$ python2.7 vol.py -f /mnt/data/otus/IS_2019_12/16/task1/memory.vmem --profile=LinuxUbuntu_4_15_0-72-generic_profilex64 linux_pslist >b01

результат - файл b01 со списком процессов. в списке процессов сразу бросается в глаза meterpreter - PID 1751 - боеголовка от MSF, и, соответственно sh (2964), который порождается этим процессом

Offset             Name                 Pid             PPid            Uid             Gid    DTB                Start Time
------------------ -------------------- --------------- --------------- --------------- ------ ------------------ ----------
0xffff8a9db6dc0000 bash                 1733            1724            1000            1000   0x0000000014662000 2020-01-16 14:00:57 UTC+0000
0xffff8a9dcf5ec5c0 sudo                 1750            1733            0               0      0x000000005388a000 2020-01-16 14:01:22 UTC+0000
0xffff8a9dcf5edd00 meterpreter          1751            1750            0               0      0x0000000014540000 2020-01-16 14:01:22 UTC+0000
0xffff8a9dc3c40000 sh                   2964            1751            0               0      0x0000000076aec000 2020-01-16 14:02:57 UTC+0000

7. запустил volatility с параметром linux_netscan 

(venv) djabber@xJabber:/opt/volalitily/volatility-master$ python2.7 vol.py -f /mnt/data/otus/IS_2019_12/16/task1/memory.vmem --profile=LinuxUbuntu_4_15_0-72-generic_profilex64 linux_netscan >b02

результат - файл b02 - в котором видно установленное соединение на  192.168.180.131:1337 (созвучно с 31337 - eleet :)) ) - что тоже наводит на мысли...

8a9df81f6000 TCP      192.168.180.132 :51934 192.168.180.131 : 1337 ESTABLISHED    

8. выполнил volatility - с параметром linux_netstat

все сходится...

TCP      192.168.180.132 :51934 192.168.180.131 : 1337 ESTABLISHED           meterpreter/1751 
TCP      192.168.180.132 :51934 192.168.180.131 : 1337 ESTABLISHED                    sh/2964 

meterpreter патчит sh и запускает реверс-шелл..., что подтверждается, если запустить volatility с параметром linux_malfind - 

Process: meterpreter Pid: 1751 Address: 0x400000 File: /
Protection: VM_READ|VM_WRITE|VM_EXEC
Flags: VM_READ|VM_WRITE|VM_EXEC|VM_MAYREAD|VM_MAYWRITE|VM_MAYEXEC|VM_DENYWRITE|VM_ACCOUNT|VM_CAN_NONLINEAR

0x00000000400000  7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00   .ELF............
0x00000000400010  02 00 3e 00 01 00 00 00 78 00 40 00 00 00 00 00   ..>.....x.@.....
0x00000000400020  40 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00   @...............
0x00000000400030  00 00 00 00 40 00 38 00 01 00 00 00 00 00 00 00   ....@.8.........

тут мы видим, что процесс 1751 (meterpreter) - лезет в область памяти, которая принадлежит исполняемому файлу (ELF)

# Задача 2
Задача разбиралась на занятии, но все же...

1. скопировал профиль ubuntu 16.04 в ./volatility/plugins/overlays/linux

2. распаковал дамп памяти в /mnt/data/otus/IS_2019_12/16/task2/image

3. запустил volatility с командой linux_bash

интерес вызвало вот это: устанавливаются права на странные файлы, стирается история, запускается процесс в фоне.
Pid      Name                 Command Time                   Command
-------- -------------------- ------------------------------ -------
    1166 bash                 2018-04-15 15:24:47 UTC+0000   chown panda:panda ht0p 
    1166 bash                 2018-04-15 15:24:47 UTC+0000   chown panda:panda suleanu
    1166 bash                 2018-04-15 15:24:47 UTC+0000   mv suleanu ht0p
    1166 bash                 2018-04-15 15:24:55 UTC+0000   shred -u .bash_history 
    1166 bash                 2018-04-15 15:25:30 UTC+0000   ./ht0p \  &
    1166 bash                 2018-04-15 15:25:32 UTC+0000   htop

надо сдампить и посмотреть:

(venv) djabber@xJabber:/opt/volalitily/volatility-master$ python2.7 vol.py -f /mnt/data/otus/IS_2019_12/16/task2/image --profile=Linuxubuntu16_04x64 linux_find_file -F "/home/panda/ht0p"

получаем

Inode Number                  Inode File Path
---------------- ------------------ ---------
          390593 0xffff88007bd8e698 /home/panda/ht0p

узнали inode, далее, дампим

(venv) djabber@xJabber:/opt/volalitily/volatility-master$ python2.7 vol.py -f /mnt/data/otus/IS_2019_12/16/task2/image --profile=Linuxubuntu16_04x64 linux_find_file -i 0xffff88007bd8e698 -O ht0p

chmod +x ./ht0p
./ht0p

не запускается. смотрим внутрь - файл забит нулями... а должен запускаться и выводить ключик... :( 

дальше уж и не знаю, куда смотреть...

