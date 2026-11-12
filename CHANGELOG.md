# Changelog / История изменений

## 1.10 — Windows GUI/installer update and clearer diagnostics

| English | Русский |
| --- | --- |
| Add installed-version and About information, meaningful strategy-check and YouTube-analysis diagnostics with per-attempt evidence, configurable error-detail dialogs, and faster live analysis updates. Allow safe in-place Windows updates while preserving settings, logs, and the Zapret2 bundle; protect locally modified files. Fix Cyrillic installer output and settings layout. | Добавлены версия и вкладка «О программе», осмысленные результаты проверки стратегий и YouTube-анализа с данными по каждой попытке, настройка показа ошибок и более быстрая обработка обновлений анализа. Установщик поддерживает безопасное обновление на месте с сохранением настроек, логов и Zapret2, защищая изменённые пользователем файлы. Исправлены вывод кириллицы и размещение настроек. |
| Combined release: Linux package advances to 1.10; Windows GUI + CLI advances to 1.9. | Общий релиз: версия Linux-пакета повышена до 1.10; Windows GUI + CLI — до 1.9. |

## 1.9 — Windows strategy analysis and controls

| English | Русский |
| --- | --- |
| Replace the Windows strategy selector with a searchable, family-filtered list. Compare YouTube checks with a direct baseline on the selected adapter; report BASELINE_PASS / INCONCLUSIVE when access is already available or the control is unstable. Add configurable attempts, HTTPS timeout, and response threshold. Linux carries the current source and strategy catalogue. | Селектор стратегий Windows заменён списком с поиском и фильтром семейств. Проверка YouTube сравнивается с контрольным запросом на выбранном адаптере; при уже доступном доступе или нестабильном контроле показываются BASELINE_PASS / INCONCLUSIVE. Добавлены настройки числа попыток, HTTPS-таймаута и порога ответа. Linux содержит актуальные исходники и каталог стратегий. |
| Combined release: Linux package advances to 1.9; Windows GUI + CLI advances to 1.8. | Общий релиз: версия Linux-пакета повышена до 1.9; Windows GUI + CLI — до 1.8. |

## 1.7 — Windows icons and system-font console

| English | Русский |
| --- | --- |
| Refresh the launch/uninstall icons, use the system console font instead of bundling a custom Windows font, and remove unused font/artwork source files. Show PowerShell during installation rather than hiding it. Linux behavior is unchanged. | Обновлены иконки запуска/удаления, для консоли Windows используется системный шрифт вместо отдельного TTF, удалены неиспользуемые файлы шрифта и исходника рисунка. PowerShell во время установки теперь виден пользователю. Работа Linux-пакета не менялась. |
| Windows GUI + CLI package advances to 1.6; Linux package version advances to 1.7 for the combined release. | Версия Windows GUI + CLI повышена до 1.6; версия Linux-пакета — до 1.7 для общего выпуска. |

## 1.6 — Windows installer and live YouTube analysis

| English | Русский |
| --- | --- |
| Add a graphical Windows installer with explicit setup choices, progress, and logs. Run YouTube strategy checks sequentially and display each result as soon as it completes; use JSON snapshots instead of parsing optional diagnostic Event fields. Improve GUI scrolling/settings and remove the unused root artwork asset. | Добавлены графический мастер установки Windows с выбором параметров, прогрессом и логами, последовательная проверка стратегий YouTube с немедленным показом результатов и JSON-снимки вместо разбора необязательных полей Event. Улучшены прокрутка и настройки GUI; удалён неиспользуемый корневой ресурс оформления. |
| Linux package version advances to 1.6 for the combined release; Windows GUI + CLI advances to 1.5. | Версия Linux-пакета повышена до 1.6 для общего выпуска; Windows GUI + CLI — до 1.5. |

## 1.5 — Windows GUI: анализ YouTube и настройки

| English | Русский |
| --- | --- |
| Add a Windows GUI tab to compare strategies by YouTube HTTPS availability, persist network settings, and show physical adapter names. Analysis results are limited to IPv4/TCP/TLS YouTube checks and do not validate VPN/Tor clients or tunnels. | Добавлены вкладки Windows GUI для сравнения стратегий по доступности YouTube, сохранения сетевых настроек и отображения имён физических адаптеров. Анализ ограничен YouTube-проверкой по IPv4/TCP/TLS и не проверяет VPN/Tor-клиенты или туннели. |
| Linux package version advances to 1.5; Windows GUI + CLI advances to 1.4. | Версия Linux-пакета повышена до 1.5; Windows GUI + CLI — до 1.4. |

## 1.4 — IPv6 and UDP/QUIC

| English | Русский |
| --- | --- |
| Add IPv4/IPv6 selection and separate UDP/QUIC Initial profiles to the Windows GUI and Linux CLI. QUIC presets use fake_default_quic and only target QUIC Initial on selected UDP ports. | Добавлены выбор IPv4/IPv6 и отдельные UDP/QUIC Initial-профили в Windows GUI и Linux CLI. QUIC-профили используют fake_default_quic и применяются только к QUIC Initial на выбранных UDP-портах. |
| TLS benchmark and YouTube checks remain TCP/TLS-specific; neither proves a VPN/Tor tunnel or third-party client authorization. | TLS benchmark и проверка YouTube остаются отдельными TCP/TLS-проверками; они не подтверждают работу VPN/Tor-туннеля или авторизацию стороннего клиента. |
| Linux package version advances to 1.4; Windows GUI + CLI package advances to 1.3. | Версия Linux-пакета повышена до 1.4; Windows GUI + CLI — до 1.3. |

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
