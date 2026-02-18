# Сборка Kimai Desktop в DMG

## Быстрый старт

```bash
./scripts/build_dmg.sh
```

Скрипт автоматически:
1. Найдёт `xcodebuild` (приоритет — Xcode.app)
2. Создаст Release архив
3. Извлечёт `.app` из архива
4. Добавит symlink на `/Applications`
5. Упакует всё в DMG (UDZO сжатие)
6. Подчистит временные файлы

DMG появится в `build/Kimai_Desktop_v{version}_{build}.dmg`

## Предварительные требования

- macOS с установленным **Xcode** (не только CommandLineTools)
- Если `xcodebuild` не работает из терминала:
  ```bash
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  ```

## Ручная сборка через Xcode GUI

1. Открой проект в Xcode
2. **Product → Archive**
3. В Organizer: **Distribute App → Direct Distribution** (или Copy App)
4. Создай DMG:
   ```bash
   hdiutil create -volname "Kimai Desktop" \
     -srcfolder /path/to/kimai_desktop_macos.app \
     -ov -format UDZO \
     KimaiDesktop.dmg
   ```
