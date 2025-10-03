#!/bin/bash

# Аргументы 
SRC_DIR="$1"
DEST_DIR="$2"

# Каталог бэкапов по умолчанию 
if [ -z "$DEST_DIR" ]; then
    DEST_DIR="$HOME/backups"
fi

# Проверка исходного каталога 
if [ -z "$SRC_DIR" ] || [ ! -d "$SRC_DIR" ]; then
    echo "Ошибка: исходный каталог не существует или не указан."
    exit 1
fi

# Создание каталога для бэкапов, если нет 
if [ ! -d "$DEST_DIR" ]; then
    mkdir -p "$DEST_DIR"
fi

# Имя архива 
DATE=$(date +%Y%m%d_%H%M%S)
BASENAME=$(basename "$SRC_DIR")
ARCHIVE_NAME="backup_${BASENAME}_${DATE}.tar.gz"

# Создание архива
tar -czf "$DEST_DIR/$ARCHIVE_NAME" -C "$(dirname "$SRC_DIR")" "$BASENAME"
STATUS=$?

# Размер архива (только если успешно)
if [ $STATUS -eq 0 ]; then
    SIZE=$(du -h "$DEST_DIR/$ARCHIVE_NAME" | awk '{print $1}')
else
    SIZE=0
fi

# Логирование 
LOG_FILE="$DEST_DIR/backup.log"
echo "$(date +%Y-%m-%dT%H:%M:%S) SRC=$SRC_DIR DST=$DEST_DIR FILE=$ARCHIVE_NAME SIZE=$SIZE STATUS=$STATUS" >> "$LOG_FILE"

# Вывод результата
if [ $STATUS -eq 0 ]; then
    echo "Резервная копия создана: $DEST_DIR/$ARCHIVE_NAME (размер: $SIZE)"
else
    echo "Ошибка при создании резервной копии."
fi

exit $STATUS
