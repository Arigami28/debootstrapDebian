#!/bin/bash

## проверка на то что пользователь запустил скрипт из под root
if [ "$UID" != "0" -a "$UID" != "" ];then
    echo ""
    echo "Вы не суперпользователь."
    echo "Для работы скрипта надо запустить его от пользователя root."
    echo ""
    exit 1
fi


## добавление конфигурационного файла
source ./config.cfg


## скачиваем стабильный дистрибутив с репов яндекса
echo "Cкачивание и наполнение Debian 9"
debootstrap --arch=$ARCH \
            --keyring=keyrings/debian-archive-keyring.gpg \
            --include=$PACKAGE \
            --variant=minbase $DISTR $TARGET http://mirror.yandex.ru/debian


## наполнение fstab
echo "наполнение fstab"
echo "
# /etc/fstab: static file system information.
# <file system> <mount point>   <type>      <options>                                   <dump>  <pass>
proc            /proc           proc        defaults                                     0       0
$DISK           /               ext4        defaults,relatime,discard,barrier=0 0 1      0       1
" > $TARGET/etc/fstab


## наполнение source.list репами yandex.ru
echo
echo "
deb http://mirror.yandex.ru/debian/ stretch main
deb-src http://mirror.yandex.ru/debian/ stretch main
OD
deb http://security.debian.org/debian-security stretch/updates main
deb-src http://security.debian.org/debian-security stretch/updates main

# stretch-updates, previously known as 'volatile'
deb http://mirror.yandex.ru/debian/ stretch-updates main
deb-src http://mirror.yandex.ru/debian/ stretch-updates main
" > $TARGET/etc/apt/sources.list


## наполнение сетевых настроек в hostname,hosts
echo "наполнение сетевых настроек в hostname,hosts"
echo "$HOST" > $TARGET/etc/hostname
echo -e "\n127.0.0.1 localhost $HOST" >> $TARGET/etc/hosts


## добавление пользователя и установка пароля root
echo "Добавление пользователя $USER"
echo "$USER:x:1000:100:$USER:/home/$USER:/bin/bash" >> $TARGET/etc/passwd
echo "guest:$USERPASSWD:17647::::::" >> $TARGET/etc/shadow
mkdir $TARGET/home/$USER
echo "Установка пароля root"
sed -i "/root/ s/*/$ROOTPASSWORD/g" $TARGET/etc/shadow


## установка времени
echo "Установка времени"
cd $TARGET && ln -sf usr/share/zoneinfo/Europe/Moscow etc/localtime && cd ..


## очистка дистрибутива от хлама после установок
echo "Очистка дистрибутива от хлама после установок"
rm -rf $TARGET/usr/share/man/* $TARGET/usr/share/groff/* $TARGET/usr/share/info/* $TARGET/usr/share/lintian/* \
       $TARGET/usr/include/* $TARGET/var/lib/apt/lists/* $TARGET/var/cache/apt/archives/* $TARGET/var/cache/apt/*.bin \
       $TARGET/usr/share/doc/*

echo "Все готово!"
