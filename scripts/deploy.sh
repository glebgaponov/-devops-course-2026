#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="$HOME/devops.crt"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
elif [[ $# -ne 0 ]]; then
    echo "Ошибка: неизвестный аргумент" >&2
    exit 1
fi

if [[ ! -f site/index.html ]]; then
    echo "Ошибка: отсутствует site/index.html" >&2
    exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo "Ошибка: есть незакоммиченные изменения" >&2
    exit 1
fi

RSYNC_ARGS=(-avz --delete --chmod=D755,F644)
if [[ "$DRY_RUN" -eq 1 ]]; then
    RSYNC_ARGS+=(--dry-run)
fi

/opt/homebrew/bin//opt/homebrew/bin/rsync "${RSYNC_ARGS[@]}" \
    -e "ssh -o BatchMode=yes -o ConnectTimeout=5" \
    site/ "${REMOTE}:${REMOTE_DIR}/"

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "Пробный деплой завершён"
    exit 0
fi

curl --noproxy '*' -fsS --cacert "$CA_CERT" \
    --resolve devops.local:443:192.168.56.2 \
    "$SITE_URL" >/dev/null || {
    echo "Ошибка: сайт недоступен" >&2
    exit 1
}

echo "Деплой успешен: $(git rev-parse --short HEAD)"
