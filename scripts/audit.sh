#!/usr/bin/env bash
set -euo pipefail

echo "=== DEVOPS SECURITY AUDIT ==="

set -uo pipefail

sudo -v || exit 1

errors=0

check() {
    local name="$1"
    shift

    if "$@"; then
        echo "[OK] $name"
    else
        echo "[FAIL] $name"
        errors=$((errors + 1))
    fi
}

echo
echo "=== [1] NGINX ==="

check "Nginx запущен" \
    sudo systemctl is-active --quiet nginx

check "Конфигурация Nginx корректна" \
    sudo nginx -t

echo
echo "=== [2] HTTP И HTTPS ==="

check "HTTP перенаправляет на HTTPS" \
    bash -c 'test "$(curl -s -o /dev/null -w "%{http_code}" -H "Host: devops.local" http://127.0.0.1/)" = "301"'

check "HTTPS работает" \
    bash -c 'test "$(curl -sk -o /dev/null -w "%{http_code}" --resolve devops.local:443:127.0.0.1 https://devops.local/)" = "200"'

check "Docker-приложение доступно через HTTPS" \
    bash -c 'test "$(curl -sk -o /dev/null -w "%{http_code}" --resolve devops.local:443:127.0.0.1 https://devops.local/app/health)" = "200"'

echo
echo "=== [3] ПРАВА ДОСТУПА ==="

check "Закрытый ключ SSL защищён" \
    bash -c 'mode=$(sudo stat -c "%a" /etc/ssl/private/devops.key); test "$mode" = "600" || test "$mode" = "640"'

check "Нет файлов с правом записи для всех" \
    bash -c 'test -z "$(find /var/www/devops-site -type f -perm -0002 -print)"'

echo
echo "=== [4] FIREWALL ==="

check "UFW активен" \
    bash -c 'sudo ufw status | grep -q "Status: active"'

echo
echo "=== [5] КОНТЕЙНЕРИЗАЦИЯ ==="

check "Служба Docker запущена" \
    sudo systemctl is-active --quiet docker

check "PostgreSQL имеет статус healthy" \
    bash -c 'cd ~/app && test "$(docker inspect --format "{{.State.Health.Status}}" "$(docker compose ps -q db)")" = "healthy"'

check "Flask доступен только на 127.0.0.1:5000" \
    bash -c 'sudo ss -tlnp | grep -q "127.0.0.1:5000" && ! sudo ss -tlnp | grep -Eq "(0.0.0.0|\[::\]|\*):5000\b"'

check "PostgreSQL не опубликован на хосте" \
    bash -c '! sudo ss -tlnp | grep -Eq ":(5432)\b"'

check "Файл .env имеет права 600" \
    bash -c 'test "$(stat -c "%a" ~/app/.env)" = "600"'

echo
echo "=== РЕЗУЛЬТАТ ==="

if [ "$errors" -eq 0 ]; then
    echo "АУДИТ ПРОЙДЕН: ошибок нет"
    exit 0
else
    echo "АУДИТ НЕ ПРОЙДЕН: ошибок $errors"
    exit 1
fi

echo "=== АУДИТ ЗАВЕРШЁН ==="
