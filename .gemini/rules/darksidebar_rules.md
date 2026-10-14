# Правила проекта Darksidebar-11

## Обязательный релизный регламент
1. **Семантическое версионирование (SemVer):** При любых исправлениях багов или доработках обязательно поднимать версию (PATCH: `1.0.x`, MINOR: `1.x.0`, MAJOR: `x.0.0`).
2. **Сборка пакета:** Запускать `./build-package.ps1 -Version "<ВЕРСИЯ>"`, формирующий `dist/Darksidebar-11-v<ВЕРСИЯ>.rmskin`.
3. **Хеш Scoop:** Вычислять точный SHA256 хеш файла `.rmskin` и обновлять `bucket/darksidebar-11.json` (`version`, `url`, `hash`). После сборки на GitHub Actions сверять и при необходимости обновлять хеш артефакта релиза.
4. **Git & GitHub:** Коммитить изменения, ставить тег `v<ВЕРСИЯ>`, пушить ветку `main` и тег на GitHub (`git push origin main; git push origin v<ВЕРСИЯ>`).
5. **Кодировка:** Все файлы `.ini` и `.inc` скина сохранять СТРОГО в **UTF-8 с BOM** (`[System.Text.UTF8Encoding]::new($true)` / `utf-8-sig`). Запрещено использовать CP-1251 или UTF-8 без BOM.
6. **Город по умолчанию:** Тюмень (`WeatherCity=Тюмень`, `WeatherCountryName=Россия`). Не затирать автоопределением по IP без согласия (`FirstRunDone=1`).
7. **Синхронизация:** Синхронизировать файлы скина в `%USERPROFILE%\Documents\Rainmeter\Skins\Darksidebar-11\` и вызывать `!RefreshApp`.
