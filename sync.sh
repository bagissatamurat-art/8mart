#!/bin/bash
# Обновление из Claude: скачали архив из чата → ./sync.sh
# Берёт самый свежий .zip из ~/Downloads с проектом внутри, раскладывает поверх этой папки, коммитит и отправляет в GitHub.
set -e
cd "$(dirname "$0")"
ZIP=$(ls -t ~/Downloads/*.zip 2>/dev/null | while read -r z; do unzip -l "$z" 2>/dev/null | grep -q 'pubspec.yaml' && { echo "$z"; break; }; done)
[ -z "$ZIP" ] && { echo "Не нашёл архив с проектом в Загрузках. Скачайте его из чата."; exit 1; }
echo "Архив: $ZIP"
TMP=$(mktemp -d)
ditto -x -k "$ZIP" "$TMP"
SRC=$(dirname "$(find "$TMP" -name pubspec.yaml -not -path '*/widgetbook/*' | head -1)")
rsync -a --delete --exclude .git --exclude env.json --exclude build --exclude .dart_tool --exclude sync.sh --exclude web --exclude ios --exclude android --exclude macos --exclude linux --exclude windows "$SRC"/ ./
rm -rf "$TMP"
git add -A
git commit -qm "обновление $(date '+%d.%m %H:%M')" && echo "Сохранено" || echo "Изменений нет"
git push -q origin main && echo "Отправлено в GitHub. Через 5 минут напишите в чат «проверь»."
