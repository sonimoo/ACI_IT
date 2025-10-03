#!/bin/bash

tries=0

while [ $tries -lt 3 ]; do
    echo "Введите ваше имя: "
    read name

    if [ -z "$name" ]; then
        echo "Имя не может быть пустым."
        tries=$((tries+1))
    else
        break
    fi
done

if [ -z "$name" ]; then
    echo "3 неправильные попытки. Выход."
    exit 1
fi

echo "Введите отдел (необязательно): "
read dep
if [ -z "$dep" ]; then
    dep="не указан"
fi

echo "Дата: $(date)"
echo "Имя хоста: $(hostname)"
echo "Аптайм: $(uptime -p)"
echo "Свободное место на /: $(df -h / | awk 'NR==2 {print $4}')"
echo "Пользователей вошло: $(who | wc -l)"

echo "Здравствуйте, $name (отдел $dep)!"
