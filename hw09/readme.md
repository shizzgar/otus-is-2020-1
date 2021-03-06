Домашние задания по курсу "Безопасность Linux"
===============================================

ДЗ 8 - Snort etc
-----------------------------------------------

# Развертывание стенда

0. Поднял виртуалку ub2 - virtualbox - (см [Vagrantfile](Vagrantfile))
1. Собрал Snort3 из исходников, используя [подробное руководство](Snort_3_on_Ubuntu.pdf) 

# Написание правила
0. Скачал запись трафика [pcaps](https://www.malware-traffic-analysis.net/2020/03/14/2020-03-14-traffic-analysis-exercise.pcap.zip)
1. Посмотрел в hex-вьюере (из пакета midnight commander). Подозрительным показалась загрузка файла */images/imgpaper.png* с хоста 64.44.133.131, т.к. расширение файла .png, а в реальных данных - сигнатура заголовка исполняемого файла Win32 ('MZ'...'PE').
2. Сделал правило для Snort3 (см. [local.rules](local.rules)), вставил правило в разде ips [snort.lua](snort.lua)
3. Запустил snort3 в режиме анализа записи трафика pcaps:
```bash
root@ub2:~/pcaps# snort -c /usr/local/etc/snort/snort.lua -r ~/pcaps/2020-03-14-traffic-analysis-exercise.pcap -A alert_fast -s 65535 -k none
```
4. результаты анализа трафика - выложил в [файле](result.txt)
