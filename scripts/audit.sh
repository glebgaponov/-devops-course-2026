#!/usr/bin/env bash
set -euo pipefail

echo "=== DEVOPS SECURITY AUDIT ==="

ssh -t devops '
sudo -v || exit 1

echo "1. Nginx:"
sudo systemctl is-active nginx

echo "2. Конфигурация:"
sudo nginx -t

echo "3. HTTP:"
curl -s -o /dev/null -w "%{http_code}\n" \
  -H "Host: devops.local" http://127.0.0.1/

echo "4. HTTPS:"
curl -sk -o /dev/null -w "%{http_code}\n" \
  --resolve devops.local:443:127.0.0.1 https://devops.local/

echo "5. Права сертификата:"
sudo stat -c "%a %n" /etc/ssl/private/devops.key

echo "6. Небезопасные файлы:"
find /var/www/devops-site -type f -perm -0002 -print

echo "7. Firewall:"
sudo ufw status
'

echo "=== АУДИТ ЗАВЕРШЁН ==="
