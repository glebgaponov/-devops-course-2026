# Настройка сервера DevOps

## 9. Контейнеризация

### Установка Docker
На Ubuntu установлен Docker Engine из официального репозитория и Docker Compose.
Пользователь student добавлен в группу docker.

### Структура проекта
Приложение расположено в /home/student/app.

- app.py — Flask-приложение.
- requirements.txt — зависимости Python.
- Dockerfile — сборка образа.
- docker-compose.yml — запуск Flask и PostgreSQL.
- .dockerignore — исключения при сборке.
- .env — переменные окружения.

Файл .env хранится только на сервере с правами 600.

### Docker Compose
Используются два сервиса:
- app — Flask и Gunicorn.
- db — PostgreSQL 16 Alpine.

PostgreSQL имеет healthcheck. Приложение запускается после готовности базы.

Команды запуска:

    cd ~/app
    docker compose up -d --build
    docker compose ps

### Сеть и порты
Приложение опубликовано только на 127.0.0.1:5000.
Порт PostgreSQL 5432 не опубликован.
Контейнеры взаимодействуют через сеть app_backend.

### Хранение данных
Для PostgreSQL используется именованный том app_db_data.
Команда docker compose down сохраняет данные.
Команда docker compose down -v удаляет том и данные тестовой базы.

### Nginx Reverse Proxy
Nginx принимает HTTPS-запросы и передаёт /app/ приложению Flask.

- https://devops.local/ — статический сайт.
- https://devops.local/app/ — Flask-приложение.
- https://devops.local/app/health — проверка состояния.

При остановке Flask Nginx возвращает 502 Bad Gateway.

### Безопасность Docker
Docker создаёт собственные правила NAT.
Публикация портов Docker может обходить ограничения UFW.

Поэтому приложение привязано к 127.0.0.1, а PostgreSQL не публикует порт.

Скрипт scripts/audit.sh проверяет Docker, PostgreSQL, порты и права .env.
