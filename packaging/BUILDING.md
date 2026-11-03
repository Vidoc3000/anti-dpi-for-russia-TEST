# Сборка выпусков Igareck AntiDPI CLI

Эта папка содержит скрипты создания Windows ZIP/EXE и Linux tar.gz из файлов репозитория.

Пользователям, которые хотят установить программу, достаточно готовых файлов из Releases. Следующие инструкции предназначены для разработчиков и сопровождающего проекта.

## Состав репозитория

| Путь | Содержимое |
| --- | --- |
| `windows/` | Содержимое корневой папки из финального Windows ZIP: `Igareck_Manager.ps1`, `УСТАНОВКА.cmd`, `payload/` и остальные файлы сборки |
| `linux/` | Содержимое корневой папки из финального Linux tar.gz: `INSTALL.sh`, `START.sh`, `DELETE.sh`, `app/`, `assets/`, `data/` и остальные файлы сборки |
| `LICENSE` | Основная лицензия проекта |
| `THIRD_PARTY_NOTICES.md` | Сведения о сторонних лицензиях |
| `licenses/` | Копии лицензий сторонних компонентов |
| `packaging/` | Содержимое этой папки |
| `dist/` | Результаты сборки; создаётся автоматически |

## Windows ZIP и EXE

### Что требуется

- Windows 10/11 x64.
- Windows PowerShell 5.1 или PowerShell 7.
- .NET Framework 4.8 со штатным компилятором `csc.exe` из `%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\`. В Windows 11 этот Framework уже является частью системы; в старых установках Windows 10 проверьте его наличие.
- Полный комплект исходников, описанный выше.

Сама сборка не требует прав администратора. Запуск готового установочного EXE запрашивает повышение прав, необходимое программе для установки и работы с WinDivert.

Откройте PowerShell в корне репозитория:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\packaging\windows\build.ps1
```

Либо из уже открытого PowerShell:

```powershell
& .\packaging\windows\build.ps1
```

Результаты:

- `dist/Igareck_AntiDPI_CLI_v1.0_Windows_x64.zip`
- `dist/Igareck_AntiDPI_CLI_v1.0_Windows_x64.exe`
- `dist/SHA256SUMS_Windows_v1.0.txt`

ZIP содержит одну корневую папку программы. EXE содержит точную копию этого ZIP; сборщик проверяет совпадение SHA-256. Каталог `packaging/` внутрь EXE не добавляется.

Для пересборки существующих результатов:

```powershell
& .\packaging\windows\build.ps1 -Force
```

Для создания только ZIP, без компиляции EXE:

```powershell
& .\packaging\windows\build.ps1 -ZipOnly
```

Этот режим также работает в PowerShell 7 на Linux. Он создаёт отдельный файл `SHA256SUMS_Windows_ZIP_v1.0.txt` и не компилирует EXE. Для публикации пары ZIP/EXE используйте полную сборку на Windows.

### Исходник EXE

- `windows/Setup.cs` — запуск установщика.
- `windows/app.manifest` — манифест Windows с запросом прав администратора.
- `windows/build.ps1` — упаковка ZIP, генерация сведений о версии и компиляция EXE.

EXE проверяет SHA-256 встроенного ZIP, проверяет пути его элементов, распаковывает файлы во временную папку и запускает штатный Windows PowerShell через `conhost.exe`. Запускается тот же `Igareck_Manager.ps1 -Action Install`, который используется комплектом программы. После завершения установщика удаляется только временная папка для запуска.

## Linux tar.gz

### Что требуется

- Bash.
- Python 3.9 или новее со стандартной библиотекой.

Для упаковки не нужны `sudo`, установленный Zapret2, сборочные библиотеки nfqws2 или доступ к сети. Зависимости для установки и работы программы ставятся во время установки.

Из корня репозитория:

```bash
bash packaging/linux/build.sh
```

Результаты:

- `dist/Igareck_AntiDPI_CLI_v1.0_Linux_x64.tar.gz`
- `dist/SHA256SUMS_Linux_v1.0.txt`

Для пересборки:

```bash
bash packaging/linux/build.sh --force
```

В архиве сохраняются исходные файлы программы. Для `INSTALL.sh`, `START.sh` и `DELETE.sh` устанавливаются права `755`. Остальным обычным файлам назначаются права `644` или `755` по исходному признаку.

## Общие правила сборки

1. Основная лицензия репозитория добавляется в корень каждой сборки под именем `LICENSE`; также добавляются `THIRD_PARTY_NOTICES.md` и `licenses/`. При конфликте разных файлов по одному пути сборка останавливается.
2. Каталоги Git, кэши Python, виртуальные окружения, `dist/`, `build/`, `logs/`, `_state/` и установленный движок (`zapret-winws/` или `engine/`) исключаются. Файлы `SHA256SUMS*`, `Verification_*`, `.pyc`, `.pyo`, `.log` и `.tmp` также не включаются в сборку.
3. Вложенная папка `linux/packaging/` сохраняется: это метаданные самой программы.
4. Движок Bol-Van на этапе упаковки не скачивается. Его скачивает установщик программы. Код установки, стратегии и сетевые настройки сборщики не изменяют.
5. По умолчанию существующие результаты не перезаписываются. Разрешение на замену задаётся `-Force` или `--force`. Результаты нельзя направлять в `windows/`, `linux/`, `packaging/` или непосредственно в корень репозитория.
6. Контрольные суммы лежат рядом с готовыми файлами и предназначены для публикации в Releases. Встроенная проверка ZIP в EXE проверяет целостность его содержимого; она не заменяет цифровую подпись или проверку происхождения самого EXE.

Файлы лицензий добавляются в дистрибутивы. Какие из этих файлов сам установщик копирует в конечную папку установленной программы, определяет его код.

### Дополнительные параметры

```powershell
& .\packaging\windows\build.ps1 -RepositoryRoot 'C:\Projects\anti-dpi-for-russia' -OutputDirectory 'C:\Builds\Igareck' -Version '1.0'
```

```bash
bash packaging/linux/build.sh --repo-root "$HOME/Projects/anti-dpi-for-russia" --output-dir "$HOME/Builds/Igareck" --version 1.0
```

`Version`/`--version` задаёт имена выходных файлов и метаданные EXE. Параметр не меняет текст версии внутри самой программы: его необходимо обновлять в исходниках отдельно.

Порядок файлов и время элементов архива фиксированы. По умолчанию используется эпоха `0` (для ZIP — минимальная дата формата, 1980-01-01). Можно задать `SOURCE_DATE_EPOCH` или явный параметр `-SourceDateEpoch` / `--source-date-epoch`, например время коммита выпуска. При одинаковых файлах, параметрах и инструментах архивы получаются повторяемыми. Побайтовая повторяемость EXE со штатным компилятором .NET Framework не гарантируется: на неё влияют данные компилятора, включая идентификатор сборки и время сборки.

### Проверка результатов

Windows:

```powershell
Get-FileHash .\dist\Igareck_AntiDPI_CLI_v1.0_Windows_x64.zip -Algorithm SHA256
Get-FileHash .\dist\Igareck_AntiDPI_CLI_v1.0_Windows_x64.exe -Algorithm SHA256
Get-Content .\dist\SHA256SUMS_Windows_v1.0.txt
```

Linux:

```bash
(cd dist && sha256sum -c SHA256SUMS_Linux_v1.0.txt)
tar -tzf dist/Igareck_AntiDPI_CLI_v1.0_Linux_x64.tar.gz
```

