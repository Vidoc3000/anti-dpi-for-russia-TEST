# Сторонние компоненты и лицензии — AntiDPI

Этот документ относится к AntiDPI CLI v1.0 для Windows 10/11 x64
и Linux Ubuntu/Debian x64. Сведения подготовлены 31 октября 2026 года
по составу этих выпусков и официальных компонентов, используемых установщиками.

Авторский код программы, установщиков и каталога стратегий AntiDPI:
**Igor Krauch (github.com/igareck)**.
Основные условия лицензирования собственного кода устанавливаются файлом
[`LICENSE`](LICENSE) в корне репозитория. Этот документ не заменяет основной
файл лицензии и не меняет лицензии сторонних компонентов.

Авторские права на сторонние компоненты принадлежат их соответствующим
правообладателям. При использовании и распространении каждого компонента
продолжают действовать его собственные условия, включая требования о
сохранении уведомлений об авторстве и предоставлении исходного кода,
когда такие требования предусмотрены лицензией.

## 1. Какие компоненты включены в программу AntiDPI

В собственных Windows ZIP/EXE и Linux tar.gz находятся сама программа AntiDPI,
каталог стратегий, документация и материалы оформления. Шрифты входят в эти
сборки и сопровождаются отдельными лицензиями OFL.

Официальный движок Zapret2 скачивается установщиком отдельно:

- **Windows:** официальный архив `bol-van/zapret-win-bundle`, содержащий
  `winws2.exe`, WinDivert, Cygwin и другие файлы официальной Windows-сборки.
- **Linux:** исходники `bol-van/zapret2`; `nfqws2` собирается на компьютере
  пользователя с использованием зависимостей его дистрибутива.

Выбор «последняя версия» может изменить состав и версии загружаемых компонентов.
В этом случае следует учитывать уведомления, поставляемые именно с выбранной
версией. Сохранённые здесь копии лицензий не заменяют такие уведомления.

## 2. Zapret2 — Bol-Van

- Проект: <https://github.com/bol-van/zapret2>
- Официальная Windows-сборка: <https://github.com/bol-van/zapret-win-bundle>
- Уведомление об авторстве в проверенной версии:
  `Copyright (c) 2016-2026 bol-van`.
- Лицензия авторского кода Zapret2: **MIT License**.
- Копия: [`licenses/Zapret2-MIT.txt`](licenses/Zapret2-MIT.txt).

Движок, штатные Lua-библиотеки скачиваются из проекта Bol-Van. 
MIT-уведомление Bol-Van сохраняется вместе с кодом и его частями.
Наличие MIT-лицензии у Zapret2 не отменяет лицензий его зависимостей.

Совместимые версии, закреплённые в AntiDPI CLI v1.0:

| Платформа | Репозиторий | Коммит |
|---|---|---|
| Windows | `bol-van/zapret-win-bundle` | `6eb463a6758fb48cd101bc55dfd057e6e9d98af1` |
| Linux | `bol-van/zapret2` | `4a33055448ce5f4e7acc704e1fbe0d8a8a6aa08d` |

Копия MIT-лицензии взята из `docs/LICENSE.txt` закреплённой Linux-версии Zapret2.

## 3. WinDivert — Windows

- Авторы: **Basil (basil00) и участники WinDivert**.
- Проект и исходный код: <https://github.com/basil00/WinDivert>
- Официальная документация: <https://reqrypt.org/windivert-doc.html>
- Используемые файлы: `WinDivert.dll`, `WinDivert64.sys`
- Лицензирование: на выбор **GNU LGPL версии 3 или более поздней** либо
  **GNU GPL версии 2 или более поздней**, согласно уведомлениям WinDivert.
- Полный upstream-файл с текстами лицензий:
  [`licenses/WinDivert-LICENSE.txt`](licenses/WinDivert-LICENSE.txt).

Приложенная копия лицензий получена из официального тега WinDivert `v2.2.2`.
Она содержит исходное уведомление о двойном лицензировании и полные тексты
LGPL v3, GPL v3 и GPL v2. Это указание источника текста лицензий, а не
утверждение, что любая выбранная пользователем Windows-сборка содержит
именно эту версию бинарных файлов.

WinDivert скачивается как часть официального bundle, а не включается в
собственный EXE-установщик AntiDPI. При отдельном распространении
DLL/драйвера необходимо соблюдать применимую лицензию, включая условия
доступности соответствующих исходников.

## 4. Cygwin — Windows

- Правообладатели: **Cygwin Authors и соответствующие участники проекта**.
- Проект: <https://cygwin.com/>
- Условия: <https://cygwin.com/licensing.html>
- Исходный код: <https://cygwin.com/git.html>
- Компонент: библиотека `cygwin1.dll`, загружаемая в составе официального
  Windows-bundle. В проверенном закреплённом bundle её метаданные указывают
  версию **3.4.10** и `Copyright © Cygwin Authors 1996-2023`.
- Лицензия библиотеки Cygwin API: **LGPL-3.0-or-later** с дополнительным
  разрешением **Cygwin Linking Exception**. Для отдельных инструментов
  и фрагментов исходников Cygwin могут действовать другие условия.
- Уведомление и дополнительное разрешение:
  [`licenses/Cygwin-CYGWIN_LICENSE.txt`](licenses/Cygwin-CYGWIN_LICENSE.txt).
- Полные тексты GNU:
  [`licenses/GNU-LGPL-3.0.txt`](licenses/GNU-LGPL-3.0.txt) и
  [`licenses/GNU-GPL-3.0.txt`](licenses/GNU-GPL-3.0.txt).

Условия лицензирования Cygwin проверены на [официальном сайте проекта](https://cygwin.com/licensing.html). 
Копии текстов лицензий взяты из [зеркала исходников Cygwin на GitHub](https://github.com/mirror/newlib-cygwin).

## 5. LuaJIT и Lua

- LuaJIT: <https://luajit.org/>
- Исходный код: <https://github.com/LuaJIT/LuaJIT>
- Основной автор LuaJIT: **Mike Pall**; авторство Lua и других включённых
  материалов приведено в upstream-файле `COPYRIGHT`.
- Лицензия: **MIT License**, с сохранением соответствующих уведомлений.
- Копия полного уведомления:
  [`licenses/LuaJIT-COPYRIGHT.txt`](licenses/LuaJIT-COPYRIGHT.txt).

В проверенном `winws2.exe` из закреплённого Windows-bundle присутствует
идентификатор `LuaJIT 2.1.1756211046`. В Linux установщик использует
дистрибутивный пакет LuaJIT; его версия зависит от Ubuntu/Debian.
Приложенный текст `COPYRIGHT` получен из официальной ветки LuaJIT `v2.1`.

## 6. zlib

- Авторы: **Jean-loup Gailly и Mark Adler**.
- Проект: <https://zlib.net/>
- Исходный код: <https://github.com/madler/zlib>
- Лицензия: **zlib License**.
- Копия: [`licenses/zlib-LICENSE.txt`](licenses/zlib-LICENSE.txt).

zlib используется при сборке движка Zapret2. В Linux соответствующая
библиотека устанавливается через пакетный менеджер дистрибутива.
Приложен исходный файл `LICENSE` официального проекта zlib.

## 7. Уведомления внутри исходников Zapret2

Кроме общей MIT-лицензии Bol-Van, исходники `nfq2` содержат
компоненты с собственными уведомлениями. Эти уведомления сохраняются
в соответствующих upstream-файлах; дополнительные копии приведены ниже.

| Компонент | Авторство и условия | Копия уведомления |
|---|---|---|
| `nfq2/kavl.h` | Attractive Chaos, 2018; MIT | [`licenses/kavl-MIT.txt`](licenses/kavl-MIT.txt) |
| `nfq2/uthash.h` | Troy D. Hanson, 2003–2025; BSD-подобные условия из заголовка | [`licenses/uthash-LICENSE.txt`](licenses/uthash-LICENSE.txt) |
| SHA/HMAC/HKDF, код RFC 6234 | IETF Trust и указанные авторы кода, 2011; условия из `nfq2/crypto/sha.h` | [`licenses/RFC6234-LICENSE.txt`](licenses/RFC6234-LICENSE.txt) |
| AES и AES-GCM | Steven M. Gibson / GRC; заявление public domain и отказ от гарантий из исходников | [`licenses/GRC-AES-GCM-NOTICES.txt`](licenses/GRC-AES-GCM-NOTICES.txt) |

Эти копии извлечены из закреплённого коммита Zapret2
`4a33055448ce5f4e7acc704e1fbe0d8a8a6aa08d`.
Они не являются перелицензированием соответствующего кода от имени автора проекта.

## 8. Шрифт Windows: AntiDPIArtCLI

- Файл в Windows-поставке: `payload/AntiDPIArtCLI.ttf`.
- Исходное уведомление: `Copyright (c) 2019 - Present, Microsoft Corporation,
  with Reserved Font Name Cascadia Code.`
- Исходный проект Cascadia Code: <https://github.com/microsoft/cascadia-code>.
- Лицензия: **SIL Open Font License 1.1**.
- Копия исходного сопровождающего файла:
  [`licenses/AntiDPIArtCLI_OFL.txt`](licenses/AntiDPIArtCLI_OFL.txt).

Модифицированный шрифт распространяется в файле `AntiDPIArtCLI.ttf`.
Уведомления Microsoft, условия OFL и сведения о Reserved Font Name
сохраняются. Лицензия собственного программного кода AntiDPI
не заменяет OFL для этого шрифтового файла.

## 9. Шрифт Linux: AntiDPI Artwork 16

- Файл в Linux-поставке: `assets/fonts/AntiDPIArtLinux16.ttf`.
- Уведомление: `Copyright Igor Krauch (github.com/igareck).`
- Шрифт цветовых элементов создан для отображения предоставленного
  ASCII-изображения в терминале.
- Лицензия: **SIL Open Font License 1.1**, уже указанная в поставке.
- Копия сопровождающего файла:
  [`licenses/AntiDPIArt_OFL.txt`](licenses/AntiDPIArt_OFL.txt).

Это авторский шрифт Igor Krauch (github.com/igareck), распространяемый отдельно
на условиях самостоятельной лицензии OFL.

## 10. Системные зависимости Linux и Windows

Linux-установщик получает системные зависимости из репозиториев
Ubuntu/Debian через `apt`: Python, curl, nftables, iproute2, kmod,
Fontconfig, инструменты компиляции и библиотеки для сборки `nfqws2`.
В частности, используются пакеты `libnetfilter-queue-dev`,
`libnfnetlink-dev`, `libmnl-dev`, `zlib1g-dev`, `libcap-dev`
и `libluajit-5.1-dev`.

Эти пакеты не включены в архив Linux tar.gz AntiDPI.

Windows-компоненты операционной системы и среды выполнения .NET
используются на условиях их соответствующих правообладателей.
Их дистрибутивы не включены в установщик AntiDPI.

## 11. Сохранение исходных условий

Копии лицензий следует хранить в репозитории и соответствующей сборке/версии
вместе с необходимыми уведомлениями компонентов. Наличие файлов в
`licenses/` не заменяет исходники, сценарии сборки и другие материалы,
которые необходимо предоставлять при распространении определённых
бинарных компонентов на условиях GPL/LGPL.

Сведения об авторах и проекты перечислены для указания происхождения
и соблюдения лицензий.