# Changelog / История изменений

## 1.3 — Windows GUI reliability / Linux

| English | Русский |
| --- | --- |
| Fix the post-install Windows GUI launch: keep the form visible while hiding only the PowerShell console. Add startup diagnostics for GUI initialization. | Исправлен запуск Windows GUI после установки: окно программы остаётся видимым, скрывается только консоль PowerShell. Добавлена диагностика этапов запуска GUI. |
| Windows package version advances to 1.2; Linux package version advances to 1.3 for the combined release. | Версия Windows-пакета повышена до 1.2; версия Linux-пакета — до 1.3 для общего выпуска. |

## 1.2 — Windows GUI / Linux

| English | Русский |
| --- | --- |
| Add a Windows GUI for strategy selection, adapter and TCP port configuration, managed stop, and logs. | Добавлено графическое управление Windows: выбор стратегии, адаптера и TCP-портов, штатная остановка и логи. |
| Linux package version advances to 1.2; Windows GUI package version is 1.1. | Версия Linux-пакета повышена до 1.2; версия Windows-пакета с GUI — 1.1. |

## 1.1 — Linux

| English | Русский |
| --- | --- |
| Linux is updated to v1.1. Windows remains at v1.0. | Linux обновлён до v1.1. Windows остаётся на v1.0. |
| Run from an existing terminal without requiring GNOME Terminal, including KDE and SSH sessions. | Запуск из текущего терминала без обязательного GNOME Terminal, в том числе в KDE и через SSH. |
| Desktop launchers can use Konsole, Xfce Terminal, MATE Terminal, XTerm, or the system terminal alternative. | Ярлыки могут использовать Konsole, Xfce Terminal, MATE Terminal, XTerm или системную альтернативу терминала. |
| Fall back to the current terminal if the GNOME artwork window cannot be prepared. Application failures never trigger a second launch. | При ошибке подготовки окна GNOME используется текущий терминал. Ошибки самой программы не вызывают повторный запуск. |
| Detect ready dependencies automatically on other distributions; retain the --skip-deps option. | Автоматическое определение готовых зависимостей в других дистрибутивах; параметр --skip-deps сохранён. |
| Select a mapped non-root UID/GID in containers and report missing privileges before strategy validation. | Выбор доступного непривилегированного UID/GID в контейнерах и диагностика недостающих прав до проверки стратегий. |
| Print tracebacks and save private error logs. | Вывод traceback и сохранение подробных журналов ошибок с ограниченными правами доступа. |
| Keep all 484 strategies and the pinned compatible Zapret2 commit unchanged. | Все 484 стратегии и закреплённый совместимый коммит Zapret2 сохранены. |
| Include the changes contributed by @egorguslyan in PR #2. | Включены изменения @egorguslyan из PR #2. |

## 1.0

| English | Русский |
| --- | --- |
| First public release of AntiDPI CLI. | Первый публичный выпуск AntiDPI CLI. |
| Support for Windows 10/11 x64 and Ubuntu/Debian Linux x64. | Поддержка Windows 10/11 x64 и Linux Ubuntu/Debian x64. |
| 484 strategies: 45 Golden and 439 Silver. | 484 стратегии: 45 Golden и 439 Silver. |
| Switch and restart strategies, and change the network adapter. | Переключение и перезапуск стратегий, смена сетевого адаптера. |
| Built-in YouTube availability check. | Встроенная проверка доступности YouTube. |
| Program installation and uninstallation. | Установка и удаление программы. |
