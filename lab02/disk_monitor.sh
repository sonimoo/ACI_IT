#!/bin/bash

# Аргументы
FS_PATH="$1"
THRESHOLD="$2"

# Если порог не указан - используем 80
if [ -z "$THRESHOLD" ]; then
    THRESHOLD=80
fi

# Проверка: путь вообще существует?
if [ ! -d "$FS_PATH" ]; then
    echo "Ошибка: путь '$FS_PATH' не найден."
    exit 2
fi

# Получаем процент использования через df
USAGE=$(df "$FS_PATH" | awk 'NR==2 {print $5}' | tr -d '%')

# Текущая дата/время
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Вывод отчёта
echo "$DATE"
echo "Путь: $FS_PATH"
echo "Использовано: ${USAGE}%"

# Сравнение с порогом
if [ "$USAGE" -lt "$THRESHOLD" ]; then
    echo "Статус: OK"
    exit 0
else
    echo "Статус: WARNING: диск почти заполнен!"
    exit 1
fi
