# Changelog / История изменений

## Next — Windows network profiles and connection monitoring

| English | Русский |
| --- | --- |
| Extend saved Windows connection profiles with a validated HTTPS monitor target and interval. Add opt-in periodic, interface-bound HTTPS checks with local history and tray notifications on availability changes; stable network changes trigger an extra check. Monitoring never changes system network settings or automatically selects or applies a strategy. | Дополнить профили подключения Windows проверяемой целью HTTPS-мониторинга и интервалом. Добавить включаемые пользователем периодические HTTPS-проверки через выбранный адаптер, локальную историю и уведомления в системном трее при смене доступности; после стабильного изменения сети выполнять дополнительную проверку. Мониторинг не меняет системные сетевые настройки и не выбирает и не применяет стратегию автоматически. |

## Next — Move Android preview workflow actions to Node 24

| English | Русский |
| --- | --- |
| Update the Android preview workflow's pinned checkout, Go, Java, artifact upload, and artifact download actions to Node 24-compatible releases to avoid the GitHub Actions Node 20 deprecation warning. | Обновить зафиксированные версии checkout, Go, Java, загрузки и скачивания artifacts в Android preview workflow до совместимых с Node 24, чтобы убрать предупреждения о выводе Node 20 из эксплуатации. |

## Next — Verify Linux update provenance before installation

| English | Русский |
| --- | --- |
| Verify release package attestations with the official GitHub CLI before extraction, enforcing the expected repository, release workflow, and `main` source ref. Fail closed when the CLI is missing, untrusted, outdated, or the attestation is invalid. | Проверять attestation релизного пакета официальным GitHub CLI до распаковки, требуя ожидаемые репозиторий, release workflow и исходную ветку `main`. Отказ от обновления при отсутствии CLI, небезопасном пути к нему, неподдерживаемой версии или недействительной attestation. |

## Next — GitHub artifact attestations for release packages

| English | Русский |
| --- | --- |
| Generate GitHub artifact provenance attestations for published ZIP/EXE/TAR.GZ packages, verify them in the release workflow, and document local verification with `gh attestation verify`. | Добавить GitHub artifact attestations для ZIP/EXE/TAR.GZ, проверять их в workflow публикации и описать локальную проверку командой `gh attestation verify`. |

## Next — Previewable, redacted Linux diagnostic archive

| English | Русский |
| --- | --- |
| Add an explicit Linux CLI support-archive command with a content preview, per-file exclusions, common secret/network-identifier redaction, noninteractive confirmation safeguards, and owner-only output permissions. | Добавить явную CLI-команду Linux для диагностического архива: предварительный просмотр содержимого, исключение отдельных файлов, маскировка распространённых секретов и сетевых идентификаторов, подтверждение в неинтерактивном режиме и права доступа только владельцу. |

## Next — Linux in-place updater

| English | Русский |
| --- | --- |
| Add a Linux CLI updater that fetches the latest stable GitHub release, verifies the archive SHA-256, rejects unsafe archive entries, and stages a fresh build before replacing the installed tree. Settings and logs are carried forward; the previous installation remains available for rollback. Also resolve the packaged catalogue through the shared resource map in the Linux installer. | Добавить обновление Linux из CLI: загрузка последнего стабильного релиза GitHub, проверка SHA-256, безопасная распаковка и предварительная сборка до замены установленной программы. Настройки и журналы переносятся, предыдущая установка остаётся для отката. Также исправить получение каталога стратегий установщиком через общую карту ресурсов. |

## 1.25 — Coordinated Windows and Linux release

| English | Русский |
| --- | --- |
| Publish a coordinated Windows GUI + CLI 1.25 and Linux CLI 1.25 release. Integrate Zapret2 Blockcheck strategy testing into the Windows client GUI: export strategy lists for blockcheck, launch blockcheck2.cmd from the analysis tab, and document blockcheck usage in the Windows manual. Bump all platform versions, regression tests, workflow defaults, and documentation to 1.25. | Выпустить согласованные Windows GUI + CLI 1.25 и Linux CLI 1.25. Интегрировать тестирование стратегий Zapret2 Blockcheck в клиент Windows: экспорт списков стратегий для blockcheck, запуск blockcheck2.cmd со вкладки анализа и документирование использования blockcheck в руководстве Windows. Повысить версии платформ, регрессионные тесты, значения по умолчанию workflow и документацию до 1.25. |

## 1.20 — Combined Windows matrix fix and Linux package refresh

| English | Русский |
| --- | --- |
| Publish a coordinated Windows GUI + CLI 1.20 and Linux CLI 1.20 release. Fix the Windows baseline connectivity matrix so the selected target name/host/path are passed to the worker as evaluated values, and detach completed jobs before modal results to avoid duplicate timer cleanup. The Linux package is republished with the current catalogue and release metadata. | Выпустить согласованные Windows GUI + CLI 1.20 и Linux CLI 1.20. Исправить базовую матрицу доступности Windows: передавать в рабочий процесс вычисленные имя/хост/путь цели и отвязывать завершённую задачу до показа модального результата, чтобы исключить повторную очистку таймером. Linux-пакет перевыпущен с текущим каталогом и метаданными версии. |

## Windows 1.19 — Updater diagnostics, tray lifecycle, and refreshed manuals

| English | Русский |
| --- | --- |
| Add a persistent update log with progress, failures, and rollback results; identify a foreign WinDivert service without changing it. Defer minimize-to-tray hiding and provide explicit restore actions. Rewrite installation/troubleshooting instructions and regenerate the strategy reference for all 492 profiles. Refresh the pinned official Zapret2 bundle and validate the IPv4 exclusions. Publish as a standalone Windows release; keep the combined Linux release as Latest. | Добавить постоянный журнал обновления с этапами, ошибками и результатом отката; распознавать чужую службу WinDivert, не изменяя её. Отложить скрытие окна при сворачивании в трей и добавить явные команды восстановления окна. Переписать инструкции установки и диагностики и обновить справочник всех 492 профилей. Обновить закреплённый официальный архив Zapret2 и проверить IPv4-исключения. Выпустить Windows отдельно, оставив общий Linux-релиз Latest. |

## Windows 1.18 — Statistical strategy analysis (standalone release)

| English | Русский |
| --- | --- |
| Run five comparative trials per strategy in shuffled order and retain before/after controls. Report median and range of successful response time, observed success rate, 95% Wilson intervals, and change against the control. Label small samples as indicative and keep strategy choice manual. Publish as a standalone Windows release so the existing combined latest release remains the Linux updater target. | В сравнительном режиме выполнять пять проб на стратегию в перемешанном порядке и сохранять контроль до и после серии. Показывать медиану и разброс времени успешных ответов, долю успехов, 95% интервалы Уилсона и изменение относительно контроля. Помечать малую выборку как ориентировочную и оставлять выбор стратегии пользователю. Выпустить Windows отдельно, не меняя Latest-релиз для Linux-обновлятора. |

## 1.18 — Guided Windows update and stop controls

| English | Русский |
| --- | --- |
| Show the complete file replacement preview in the Windows installer and require explicit approval before the noninteractive update proceeds. Keep console-only Ctrl+C guidance out of the GUI worker; the Stop button continues to request managed shutdown and the worker promptly cleans up its owned engine. Linux package is republished with the current CLI and strategy catalogue. | Мастер обновления Windows показывает полный список заменяемых файлов и продолжает только после явного подтверждения. Подсказка Ctrl+C для консоли больше не выводится в GUI; кнопка «Остановить» отправляет запрос штатной остановки, а рабочий процесс завершает принадлежащий программе движок. Пакет Linux перевыпущен с текущим CLI и каталогом стратегий. |
| Combined release: Linux package advances to 1.18; Windows GUI + CLI advances to 1.17. | Общий релиз: версия Linux-пакета повышена до 1.18; Windows GUI + CLI — до 1.17. |

## 1.17 — Windows icon consistency and quiet stop

| English | Русский |
| --- | --- |
| Use the launch shortcut icon for both the Windows GUI window and notification-area icon. Suppress the modal strategy-error dialog after managed stop, including nonzero worker exits; retain details in status/history/log. Linux package is republished with the current CLI and strategy catalogue. | Для окна GUI и значка в трее используется иконка ярлыка запуска. После штатной остановки модальное окно «Ошибка стратегии» не появляется, даже если процесс завершился с ненулевым кодом; подробности остаются в статусе, истории и журнале. Пакет Linux перевыпущен с текущим CLI и каталогом стратегий. |
| Combined release: Linux package advances to 1.17; Windows GUI + CLI advances to 1.16. | Общий релиз: версия Linux-пакета повышена до 1.17; Windows GUI + CLI — до 1.16. |

## 1.16 — Windows managed-stop reliability

| English | Русский |
| --- | --- |
| Keep Windows system-tray text within the 63-character limit to prevent an exception during managed stop. Report stop-request failures in status/history/log without an unnecessary modal pop-up. Linux package is republished with the current CLI and strategy catalogue. | Длина текста в системном трее Windows ограничена 63 символами, чтобы при штатной остановке не возникало исключение. Ошибки запроса остановки отображаются в статусе и истории и записываются в журнал без лишнего модального окна. Пакет Linux перевыпущен с текущим CLI и каталогом стратегий. |
| Combined release: Linux package advances to 1.16; Windows GUI + CLI advances to 1.15. | Общий релиз: версия Linux-пакета повышена до 1.16; Windows GUI + CLI — до 1.15. |

## 1.11 — UTF-8 Windows strategy logs

| English | Русский |
| --- | --- |
| Write redirected Windows strategy-catalogue output as UTF-8 so Cyrillic diagnostics remain readable in GUI logs. | Вывод каталога стратегий Windows перенаправляется в UTF-8, поэтому кириллические сообщения остаются читаемыми в логах GUI. |
| Combined release: Linux package advances to 1.11; Windows GUI + CLI advances to 1.10. | Общий релиз: версия пакета Linux повышена до 1.11; Windows GUI + CLI — до 1.10. |

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
