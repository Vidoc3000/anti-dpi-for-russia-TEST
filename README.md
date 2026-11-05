# `IGARECK ANTI-DPI`
## `ПРОГРАММА ГОТОВЫХ ANTI-DPI СТРАТЕГИЙ НА БАЗЕ ZAPRET2 BOL-VAN`
## `В УДОБНОЙ CLI ОБОЛОЧКЕ ДЛЯ РАБОТЫ ЧЕРНЫХ СПИСКОВ VPN + TOR`

### Разработана специально для восстановления работоспособности VPN-конфигураций Черных Списков и Tor-мостов (+ YouTube) в России. Адаптирована под массового пользователя.
### Для обхода фильтров ТСПУ Роскомнадзора.

<div align="center">

[![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=data:image/svg%2Bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNiAxNiI%2BPHBhdGggZmlsbD0id2hpdGUiIGQ9Ik0wIDBoN3Y3SDB6TTkgMGg3djdIOXpNMCA5aDd2N0gwek05IDloN3Y3SDl6Ii8%2BPC9zdmc%2B)](https://github.com/igareck/anti-dpi-for-russia/releases)
[![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://github.com/igareck/anti-dpi-for-russia/releases)

[![Telegram](https://img.shields.io/badge/Join_me_on-Telegram-26A5E4?style=flat-square&logo=telegram&logoColor=white)](https://t.me/igareq)
[![Support me on Patreon](https://img.shields.io/badge/Support-Patreon-f96854?style=flat-square&logo=patreon&logoColor=white)](https://www.patreon.com/igareck/shop)

**🌐 Язык: [Русский](README.md) | 🌐 Language: [English](README-EN-US.md)**

</div>

<div align="center">

<img src="assets/Igareck_AntiDPI_CLI_v1_UI.jpg" width="860"/>

</div>

```diff
+ Программа изначально разработана с целью восстановления работы публичных подписок VPN/Tor!
- Работоспособность Youtube, Discord, Facebook, Linkedin, X (Twitter) с Igareck AntiDPI,
- на некоторых Golden-стратегиях без VPN - это приятный бонус, но не текущая цель проекта.
```

### **`Программа восстанавливает работоспособность VPN Черных списков и даже Tor мостов в России?`**

**Может буквально оживлять подписки.**

**Если у вас не пингуется вообще ничего или всего 1-2 конфигурации из большого списка - попробуйте данное ПО.** 

Для работы с VPN Черных Списков или Tor-мостов, сначала запустите **Igareck AntiDPI** и включайте каждую стратегию поочередно, затем пингуйте подписки/мосты в вашем клиенте!
На одних стратегиях может быть больше живых VPN-конфигураций, на других меньше. Выяснить, какие работают лучше, может только сам пользователь методом подбора. Начинайте с Golden-стратегий.

Tor-мосты после запуска **Igareck AntiDPI**, например, подключаются быстрее, а Obfs4-мосты, в частности, работают там, где не работали раньше.

### **`Как понять, что Igareck AntiDPI работает?`**

1. Сначала пингуйте подписки ЧС **[BLACK_VLESS_RUS_mobile.txt](https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/BLACK_VLESS_RUS_mobile.txt)** или **[BLACK_SS+All_RUS.txt](https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/BLACK_SS%2BAll_RUS.txt)** или **[BLACK_VLESS_RUS.txt](https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/BLACK_VLESS_RUS.txt)** без **Igareck AntiDPI** из открытой сети.
2. Затем включите **Igareck AntiDPI** и одну из стратегий, начиная с **Golden**.
3. Включите проверку задержки в VPN-клиенте еще раз.
4. Сравните прирост числа живых конфигураций.
5. **Профит!**

### **`С какими VPN/Tor-клиентами совместим Igareck AntiDPI?`**

**С любыми:** **[Karing](https://github.com/KaringX/karing/releases), [v2rayN](https://github.com/2dust/v2rayN/releases), [Throne](https://github.com/throneproj/Throne/releases), [Clash Verge Rev](https://github.com/clash-verge-rev/clash-verge-rev/releases), [OnionHop V3](https://github.com/center2055/OnionHop/releases), [OnionFruit](https://github.com/dragonfruitnetwork/onionfruit/releases/latest)** и прочими. 

Не требует специальных настроек, просто работает в фоне.

### **`Какие есть стратегии? Что за Golden и Silver разделения в таблице?`**

**484 стратегии:** 45 Golden + 439 Silver; 23 семейства.

Подробный справочник всех стратегий: **[README_Стратегии_Windows_v1.0.txt](windows/README_Стратегии_Windows_v1.0.txt)**

Стратегии Golden могут лучше обходить фильтры ТСПУ и для VPN/Tor/YouTube потенциально сильнее, чем Silver.

### **`Через Igareck AntiDPI программу можно смотреть YouTube на ПК без использования VPN?`**

Да, для работы с YouTube запустите автоматическую проверку стратегий на доступ к YouTube в меню, где будет выбор между вводом `номера стратегии` и вводом слова `YouTube`. Стратегии, давшие ответ `PASS`, должны открыть YouTube в браузере без VPN.

**Первоочередная цель `Igareck AntiDPI` - это восстановление работы VPN/Tor, а прямой доступ YouTube - это приятный бонусный эффект.** На некоторых Golden-стратегиях могут также открываться Discord/Linkedin/Facebook/Threads/X.com и частично сайт Tor Project.

### **`Означает ли успешность проверки Youtube, что стратегия пингует/заводит больше VPN-конфигураций в подписках?`**
   
Успешный тест на доступ к YouTube не всегда означает, что стратегия лучше остальных работает с VPN-конфигурациями.

Бывает, что стратегия не дает прямой доступ на YouTube, но при этом пингует самое максимальное число VPN-конфигураций.

### **`На базе чего разработана программа и в чем ее преимущество?`**

Программа разработана на базе движка [Zapret2](https://github.com/bol-van/zapret2) разработчика [Bol-Van](https://github.com/bol-van).

**Igareck AntiDPI** уже содержит готовые стратегии обхода фильтрации ТСПУ, где от пользователя требуется лишь подобрать лучшую из рабочих, а не искать с нуля.

Программа со стратегиями протестирована в российских мобильных/кабельных сетях и подойдет пользователям публичных подписок VPN/Tor + Youtube в России.

Адаптирована под массового пользователя и завернута в удобную CLI-оболочку, с интуитивно понятным меню, возможностью настройки/выбора/теста/перезагрузки стратегий в процессе работы. Для пользования программой специальных знаний командной строки (команд для терминала) не требуется. Все, что потребуется от пользователя - вводить `цифры`, `да`/`нет` или `youtube`. Система всегда подскажет, что нажать.

### `Какие платформы поддерживает?`

**[Windows 10/11 x64](https://github.com/igareck/anti-dpi-for-russia/releases)** ★ **[Linux Ubuntu/Debian x64](https://github.com/igareck/anti-dpi-for-russia/releases)**

Планируется разработка Android-версии.

---

## Инструкции по установке и запуску

## `Windows 10/11 x64`

<details>
<summary><code> Нажмите чтобы открыть </code></summary>

㋡
  
### **1. Запуск инсталлятора.**

**[УСТАНОВКА ЧЕРЕЗ EXE](https://github.com/igareck/anti-dpi-for-russia/releases/download/v1.0/Igareck_AntiDPI_CLI_v1.0_Windows_x64.exe)**

Двойным кликом запустите файл **Igareck_AntiDPI_CLI_v1.0_Windows_x64.exe**.
Подтвердите запуск от имени Администратора.

**[УСТАНОВКА ЧЕРЕЗ АРХИВ ZIP](https://github.com/igareck/anti-dpi-for-russia/releases/download/v1.0/Igareck_AntiDPI_CLI_v1.0_Windows_x64.zip)**

Извлеките архив **Igareck_AntiDPI_CLI_v1.0_Windows_x64.zip**, откройте папку **Igareck_AntiDPI_CLI_v1.0_Windows_x64** и запустите **УСТАНОВКА.cmd**.
Подтвердите запуск от имени Администратора.

### **2. Ознакомьтесь с абзацами `ВНИМАНИЕ` и `ЗАМЕТКИ`, нажмите для продолжения клавишу Enter.**

### **3. Выберите путь установки.**

Просто нажмите **Enter** для установки программы в **`C:\Igareck_AntiDPI`** по умолчанию.

Либо введите другой адрес для установки.

### **4. Выберите версию движка (введите цифру).**

1 — максимально совместимая версия Zapret2 с закреплённым коммитом, на базе которой проводилось тестирование последней версии **Igareck AntiDPI**.

2 — последняя версия Zapret2 официальной ветки master.

### **5. Введите `да/yes`, чтобы создать папку с ярлыками, инструкцией и описанием на Рабочем Столе.**

### **6. Дождаться окончания установки.**

---
---

*РАБОТА ПРОГРАММЫ НАЧИНАЕТСЯ СРАЗУ ПОСЛЕ ЗАВЕРШЕНИЯ УСТАНОВКИ.*

*ЗАПУСК УСТАНОВЛЕННОЙ ПРОГРАММЫ ВОЗМОЖЕН ЧЕРЕЗ ЯРЛЫК `START_Igareck_AntiDPI` НА РАБОЧЕМ СТОЛЕ (ПАПКА `Igareck_AntiDPI`) ИЛИ ЧЕРЕЗ `ЗАПУСК_Igareck_AntiDPI_Zapret2.cmd` В КОРНЕВОЙ ПАПКЕ.*

---
---

### **7. Введите номер активного Интернет-адаптера для работы AntiDPI Стратегий.**

Программа сама предложит существующий физический адаптер, который подключен к сети интернет.

Обычный пользователь может просто нажать **Enter**, чтобы выбрать дефолтный, так как в стандартной системе стоит один физический адаптер, который программа захватит автоматически.

Продвинутый пользователь, если адаптеров несколько штук, если не уверен в выборе, то может проверить свои адаптеры через `Панель управления` - `Сеть и интернет` - `Центр управления сетями и общим доступом` - `Изменение параметров адаптера`

### **8. Выберите порты назначения TCP, трафик которых будет перехватываться Zapret2.**

`Для работы VPN-подписок` потребуется перехват всех портов, потому что публичные подписки/конфигурации VPN всегда содержат постоянно меняющиеся разные порты. Для конкретного узла достаточно его известного TCP-порта.

`Для работы Tor-моста` можно либо включить перехват всех портов, либо ввести только порт, указанный в Tor-мосте.

`Для работы Youtube без VPN` в браузере нужен только порт 443, именно он отвечает за трафик в браузере.

Поддерживаются номер, диапазон, комбинации через запятую, либо `all/все`.

**Enter** в пустое поле портов = `все`. Пример ввода: `80,443,1000-2000`.

### **9. Появится таблица со стратегиями.**

| | | | | |
|:---:|:---:|:---|:---:|:---:|
|**#**|**Набор**|**Семейство**|**Кол.**|**Номера**|
|1|Golden|fake + multisplit|13|1-13|
|2|Golden|multisplit + multisplit|7|14-20|
|3|Golden|fake + multidisorder|1|21|
|4|Golden|Именованный hostfakesplit|11|22-32|
|5|Golden|Реальный ClientHello + fake + multisplit|13|33-45|
|6|Silver|fake + multisplit|35|46-80|
|7|Silver|multisplit + multisplit|12|81-92|
|8|Silver|fake + multidisorder|1|93|
|9|Silver|Именованный hostfakesplit|49|94-142|
|10|Silver|Реальный ClientHello + fake + multisplit|30|143-172|
|11|Silver|fake|4|173-176|
|12|Silver|fake + fake + fakeddisorder|25|177-201|
|13|Silver|fake + fake + multidisorder|8|202-209|
|14|Silver|fake + fake + multisplit|5|210-214|
|15|Silver|fake + fakeddisorder|127|215-341|
|16|Silver|fake + fakedsplit|67|342-408|
|17|Silver|fake + hostfakesplit|1|409|
|18|Silver|fake + tcpseg|1|410|
|19|Silver|fakedsplit|18|411-428|
|20|Silver|hostfakesplit|28|429-456|
|21|Silver|multisplit + fakeddisorder|22|457-478|
|22|Silver|tcpseg|2|479-480|
|23|Silver|Большой TLS-префикс / multisplit|4|481-484|
| | | | | |


### **10. Введите `номер стратегии` из таблицы или слово `YouTube`.**

```diff
Перед вами появится таблица, в которой стратегии разделены на группы/семейства. 
Номера семейств - в первом столбце. 
Категория семейств (наборы Golden/Silver) - во втором столбце.
Golden для VPN/Tor/YouTube могут работать лучше, чем Silver.
Названия семейств - в третьем столбце.
Номера стратегий поочередно - в последнем столбце.
```

**а. Чтобы сразу включить в работу любую из AntiDPI-стратегий**, введите `номер` из последнего правого столбца.

**б. Чтобы проверить AntiDPI-стратегии на доступ к YouTube**, введите вместо номера слово `youtube`. После этого введите диапазон проверяемых стратегий (например `1-50`), либо одиночную стратегию для одиночной проверки. Затем введите число стратегий для параллельной проверки, чтобы ускориться (можно ввести любое число от `1` до `5`).

Далее успешные стратегии появятся списком: `3 (PASS), 5 (PASS), 4 (PASS), 2 (PASS), 1 (PASS), 6 (PASS), 7 (PASS), 8 (PASS), 9 (PASS), 10 (PASS), 11 (UNSTABLE), 12 (PASS), 13 (PASS), 15 (PASS), 14 (PASS)`

Далее снова появится меню **Введите `номер стратегии` из таблицы или слово `YouTube`**: теперь введите номер стратегии, прошедшей проверку, нажмите **Enter**, и она у вас начнет работать. Затем открывайте Youtube в браузере.

```diff
а. Успешный тест на доступ к YouTube не всегда означает, что стратегия идеально работает с VPN-конфигурациями.
б. В свою очередь — отрицательный тест на YouTube абсолютно не значит, что стратегия не работает с VPN, часто наоборот.
в. Бывает, что стратегия не дает прямой доступ на YouTube, но при этом пингует самое максимальное число VPN-конфигураций.
```

### **11. Далее, после запуска стратегии, проверьте количество успешно работающих конфигураций в VPN-клиенте, пропинговав их и запустив (базовая рекомендация - Karing), либо проверьте загрузку Youtube в браузере без использования VPN.**

Конфигурации VPN, которые работают только с программой **Igareck AntiDPI**, а без нее даже не пингуются, могут дать трафик не моментально, а в течение 5-20 секунд после подключения, так что после включения конфигурации с успешным пингом, запаситесь терпением и подождите 5-20 секунд перед тем, как трафик пойдет.

Вместе с программой **Igareck AntiDPI** используйте **подписки Черных Списков** **[BLACK_VLESS_RUS_mobile.txt](https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/BLACK_VLESS_RUS_mobile.txt)** или **[BLACK_SS+All_RUS.txt](https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/BLACK_SS%2BAll_RUS.txt)** или **[BLACK_VLESS_RUS.txt](https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/BLACK_VLESS_RUS.txt)**.

### **12. Опции выбора во время работы программы.**

`ЧТОБЫ СМЕНИТЬ СТРАТЕГИЮ И ВЫБРАТЬ НОВУЮ - нажмите F1`

Вызывает меню выбора стратегий или проверки доступности Youtube.

`ЧТОБЫ ПЕРЕЗАГРУЗИТЬ ТЕКУЩУЮ СТРАТЕГИЮ - нажмите F2`

Перезагружает стратегию. Завершает текущий *winws2.exe* и запускает новый процесс с той же стратегией и тем же адаптером.

`ЧТОБЫ СМЕНИТЬ СЕТЕВОЙ АДАПТЕР/ПОРТ - нажмите F3`

Завершает текущий *winws2.exe*. Запускает выбор активных физических IPv4-адаптеров из таблицы с рекомендацией и выбором.

Далее предлагается выбор TCP-портов, трафик которых будет перехватываться Zapret2.

Новый процесс начнется с той же стратегией.

`ЧТОБЫ ПОЛНОСТЬЮ ОСТАНОВИТЬ РАБОТУ AntiDPI/ZAPRET2 - нажмите CTRL+C`

Остановка текущего *winws2.exe* и выход из программы.

### **13. Запуск и удаление установленной программы.**

**Запуск:**

1. Ярлык **START_Igareck_AntiDPI** в папке **Igareck_AntiDPI** на Рабочем Столе.
2. **ЗАПУСК_Igareck_AntiDPI_Zapret2.cmd** в корневой папке.

**Удаление:**

1. Ярлык **DELETE_Igareck_AntiDPI** в папке **Igareck_AntiDPI** на Рабочем столе.
2. **УДАЛИТЬ_Igareck_AntiDPI_Zapret2.cmd** в корневой папке.

---
---

</details>

## `Linux Ubuntu/Debian x64`

<details>
<summary><code> Нажмите чтобы открыть </code></summary>

㋡

### **1. Запуск инсталлятора.**

**[УСТАНОВКА ЧЕРЕЗ АРХИВ TAR.GZ](https://github.com/igareck/anti-dpi-for-russia/releases/download/v1.1/Igareck_AntiDPI_CLI_v1.1_Linux_x64.tar.gz)**

Откройте терминал в папке со скачанным архивом и выполните:

```bash
tar -xzf Igareck_AntiDPI_CLI_v1.1_Linux_x64.tar.gz
cd Igareck_AntiDPI_CLI_v1.1_Linux_x64
bash INSTALL.sh
```

### **2. Ознакомьтесь с абзацами `ВНИМАНИЕ` и `ЗАМЕТКИ`, нажмите для продолжения клавишу Enter.**

### **3. Выберите путь установки.**

Просто нажмите **Enter** для установки программы в **`/opt/igareck-antidpi`** по умолчанию.

Либо введите другой адрес для установки.

### **4. Выберите версию движка (введите цифру).**

1 — максимально совместимая версия Zapret2 с закреплённым коммитом, на базе которой проводилось тестирование последней версии **Igareck AntiDPI**;

2 — последняя версия Zapret2 официальной ветки master.

### **5. Введите `да/yes`, чтобы создать папку с ярлыками, инструкцией и описанием на Рабочем Столе.**

### **6. Дождаться окончания установки.**

---
---

*РАБОТА ПРОГРАММЫ НАЧИНАЕТСЯ СРАЗУ ПОСЛЕ ЗАВЕРШЕНИЯ УСТАНОВКИ.*

*ЗАПУСК УСТАНОВЛЕННОЙ ПРОГРАММЫ ВОЗМОЖЕН ЧЕРЕЗ ЯРЛЫК `START_Igareck_AntiDPI` НА РАБОЧЕМ СТОЛЕ (ПАПКА `Igareck_AntiDPI`), ЧЕРЕЗ МЕНЮ УСТАНОВЛЕННЫХ ПРОГРАММ, ЧЕРЕЗ `START.sh` В КОРНЕВОЙ ПАПКЕ ИЛИ ЧЕРЕЗ ГЛОБАЛЬНУЮ КОМАНДУ ТЕРМИНАЛА `igareck-antidpi`.*

---
---

### **7. Введите номер активного Интернет-адаптера для работы AntiDPI Стратегий.**

Программа сама предложит существующий физический адаптер, который подключен к сети интернет.

Обычный пользователь может просто нажать **Enter**, чтобы выбрать дефолтный, так как в стандартной системе стоит один физический адаптер, который программа захватит автоматически.

Продвинутый пользователь, если адаптеров несколько штук, если не уверен в выборе, то может проверить свои адаптеры через команды в другом терминале:

```bash
nmcli device status
```
или
```bash
netstat -i
```
или
```bash
ifconfig
```
или
```bash
ip -br address
```

### **8. Выберите порты назначения TCP, трафик которых будет перехватываться Zapret2.**

`Для работы VPN-подписок` потребуется перехват всех портов, потому что публичные подписки/конфигурации VPN всегда содержат постоянно меняющиеся разные порты. Для конкретного узла достаточно его известного TCP-порта.

`Для работы Tor-моста` можно либо включить перехват всех портов, либо ввести только порт, указанный в Tor-мосте.

`Для работы Youtube без VPN` в браузере нужен только порт 443, именно он отвечает за трафик в браузере.

Поддерживаются номер, диапазон, комбинации через запятую, либо `all/все`.

**Enter** в пустое поле портов = `все`. Пример ввода: `80,443,1000-2000`.

### **9. Появится таблица со стратегиями.**

| | | | | |
|:---:|:---:|:---|:---:|:---:|
|**#**|**Набор**|**Семейство**|**Кол.**|**Номера**|
|1|Golden|fake + multisplit|13|1-13|
|2|Golden|multisplit + multisplit|7|14-20|
|3|Golden|fake + multidisorder|1|21|
|4|Golden|Именованный hostfakesplit|11|22-32|
|5|Golden|Реальный ClientHello + fake + multisplit|13|33-45|
|6|Silver|fake + multisplit|35|46-80|
|7|Silver|multisplit + multisplit|12|81-92|
|8|Silver|fake + multidisorder|1|93|
|9|Silver|Именованный hostfakesplit|49|94-142|
|10|Silver|Реальный ClientHello + fake + multisplit|30|143-172|
|11|Silver|fake|4|173-176|
|12|Silver|fake + fake + fakeddisorder|25|177-201|
|13|Silver|fake + fake + multidisorder|8|202-209|
|14|Silver|fake + fake + multisplit|5|210-214|
|15|Silver|fake + fakeddisorder|127|215-341|
|16|Silver|fake + fakedsplit|67|342-408|
|17|Silver|fake + hostfakesplit|1|409|
|18|Silver|fake + tcpseg|1|410|
|19|Silver|fakedsplit|18|411-428|
|20|Silver|hostfakesplit|28|429-456|
|21|Silver|multisplit + fakeddisorder|22|457-478|
|22|Silver|tcpseg|2|479-480|
|23|Silver|Большой TLS-префикс / multisplit|4|481-484|
| | | | | |

### **10. Введите `номер стратегии` из таблицы или слово `YouTube`.**

```diff
Перед вами появится таблица, в которой стратегии разделены на группы/семейства. 
Номера семейств - в первом столбце. 
Категория семейств (наборы Golden/Silver) - во втором столбце.
Golden для VPN/Tor/YouTube могут работать лучше, чем Silver.
Названия семейств - в третьем столбце.
Номера стратегий поочередно - в последнем столбце.
```

**а. Чтобы сразу включить в работу любую из AntiDPI-стратегий**, введите `номер` из последнего правого столбца.

**б. Чтобы проверить AntiDPI-стратегии на доступ к YouTube**, введите вместо номера слово `youtube`. После этого введите диапазон проверяемых стратегий (например `1-50`), либо одиночную стратегию для одиночной проверки. Затем введите число стратегий для параллельной проверки, чтобы ускориться (можно ввести любое число от `1` до `5`).

Далее успешные стратегии появятся списком: `3 (PASS), 5 (PASS), 4 (PASS), 2 (PASS), 1 (PASS), 6 (PASS), 7 (PASS), 8 (PASS), 9 (PASS), 10 (PASS), 11 (UNSTABLE), 12 (PASS), 13 (PASS), 15 (PASS), 14 (PASS)`

Далее снова появится меню **Введите `номер стратегии` из таблицы или слово `YouTube`**: теперь введите номер стратегии, прошедшей проверку, нажмите **Enter**, и она у вас начнет работать. Затем открывайте Youtube в браузере.

```diff
а. Успешный тест на доступ к YouTube не всегда означает, что стратегия идеально работает с VPN-конфигурациями.
б. В свою очередь — отрицательный тест на YouTube абсолютно не значит, что стратегия не работает с VPN, часто наоборот.
в. Бывает, что стратегия не дает прямой доступ на YouTube, но при этом пингует самое максимальное число VPN-конфигураций.
```

### **11. Далее, после запуска стратегии, проверьте количество успешно работающих конфигураций в VPN-клиенте, пропинговав их и запустив (базовая рекомендация - Karing), либо проверьте загрузку Youtube в браузере без использования VPN.**

Конфигурации VPN, которые работают только с программой **Igareck AntiDPI**, а без нее даже не пингуются, могут дать трафик не моментально, а в течение 5-20 секунд после подключения, так что после включения конфигурации с успешным пингом, запаситесь терпением и подождите 5-20 секунд перед тем, как трафик пойдет.

Вместе с программой **Igareck AntiDPI** используйте **подписки Черных Списков** **[BLACK_VLESS_RUS_mobile.txt](https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/BLACK_VLESS_RUS_mobile.txt)** или **[BLACK_SS+All_RUS.txt](https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/BLACK_SS%2BAll_RUS.txt)** или **[BLACK_VLESS_RUS.txt](https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/BLACK_VLESS_RUS.txt)**.

### **12. Опции выбора во время работы программы.**

`ЧТОБЫ СМЕНИТЬ СТРАТЕГИЮ И ВЫБРАТЬ НОВУЮ - нажмите F1 (или s)`

Вызывает меню выбора стратегий или проверки доступности Youtube.

`ЧТОБЫ ПЕРЕЗАГРУЗИТЬ ТЕКУЩУЮ СТРАТЕГИЮ - нажмите F2 (или r)`

Перезагружает стратегию. Запускает новый процесс с той же стратегией и тем же адаптером.

`ЧТОБЫ СМЕНИТЬ СЕТЕВОЙ АДАПТЕР/ПОРТ - нажмите F3 (или i)`

Запускает выбор активных физических IPv4-адаптеров из таблицы с рекомендацией и выбором.

Далее предлагается выбор TCP-портов, трафик которых будет перехватываться Zapret2.

Новый процесс начнется с той же стратегией.

`ЧТОБЫ ПОЛНОСТЬЮ ОСТАНОВИТЬ РАБОТУ AntiDPI/ZAPRET2 - нажмите CTRL+C (или q)`

Выход из программы.

### **13. Запуск и удаление установленной программы.**

**Запуск:**

1. Ярлык **START_Igareck_AntiDPI** в папке **Igareck_AntiDPI** на Рабочем Столе.
2. Ярлык **Igareck_AntiDPI** в главном меню программ.
3. Запуск файла **START.sh** в корневой папке.
4. Глобальная команда в терминале **`igareck-antidpi`**.

**Удаление:**

1. **Стандартное удаление с сохранением логов и изменённых файлов.**

Либо команда в терминале:

```bash
sudo bash /opt/igareck-antidpi/DELETE.sh
```
Либо через Ярлык **DELETE_Igareck_AntiDPI** в папке **Igareck_AntiDPI** на Рабочем столе.

2. **Полное удаление вместе с папкой установки.**

```bash
sudo bash /opt/igareck-antidpi/DELETE.sh --purge
```

Если установили в другую папку, замените `/opt/igareck-antidpi` своим путём.

</details>

---

## Сборка из исходников

Инструкции по сборке **Windows ZIP/EXE** и **Linux TAR.GZ** из исходников находятся в **[packaging/BUILDING.md](packaging/BUILDING.md)**.

Готовые версии для установки доступны в **[Releases](https://github.com/igareck/anti-dpi-for-russia/releases)**.

---

## <img src="https://cdn.jsdelivr.net/gh/igareck/GoldCaviar@refs/heads/main/Files/NYC_Statue_of_Liberty_2.gif" width="100" align="absmiddle"> Пользуйтесь интернетом свободно и ответственно!

## 🔖 Лицензия

Лицензия GPL-3.0. С лицензией можно ознакомиться в файле **[`LICENSE`](LICENSE)**

## <img src="https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExM2wwMmJ3bDZvMWV2b2JraXZ4ZWk2Y2I5ODYyZ2M2aG5mMHc5ZW81ZyZlcD12MV9zdGlja2Vyc19zZWFyY2gmY3Q9cw/ME8P6ce7Mn3gnRbird/giphy.gif" width="30"> `Поддержать автора`

**Проект некоммерческий и основан на личном энтузиазме автора.**

**Если есть желание поддержать - можно сделать это 3-мя способами: через `донат на Patreon.com` или `Telegram Stars` или `криптовалютный перевод`.**

Средства пойдут на продолжение деятельности и ее развитие.

Всем неравнодушным заранее благодарен!

### 1. Донат на `Patreon.com/igareck`

[![Support me on Patreon](https://img.shields.io/badge/Support_me_on-Patreon-f96854?style=for-the-badge&logo=patreon&logoColor=white)](https://www.patreon.com/igareck/shop)

Patreon в России работает только через VPN.

Из России оплатить можно через:

**`Международные банковские карты`**

**`Виртуальные карты иностранных эмитентов`**

**`App Store и Google Play: Оплата Patreon через встроенные покупки в приложении на телефоне`**

**`Платежные сервисы-посредники (список ниже)`**

Список посредников для оплаты любой подписки Patreon, пополнения баланса App Store / Google Play, либо же предлагающие услуги оформления международных банковских карт Visa/Mastercard:

<details>
<summary><code><em> Нажмите на стрелку, чтобы раскрыть список посредников для оплаты/перевода </em></code></summary>

⇩

```diff

Оплата подписки Patreon:
https://pyyplbot.com/kak-oplatit/patreon/
https://oplata.guru/patreon
https://oplatym.ru/patreon
https://sanpay.ru/instrustions/kak-oplatit-podpisku-na-patreon.html
https://getpayall.com/services/patreon

Оформление/пополнение международных банковских карт Visa/Mastercard:
https://platipomiru.com/
https://wanttopay.net/
https://pyyplbot.com/bank-cards/
https://oplata.guru/zarubezhnaya-bankovskaya-karta
https://getpayall.com/individual

Пополнение баланса Apple-ID / Google Play:
https://wanttopay.net/
https://oplata.guru/googleplay
https://oplatym.ru/googleplay

```

</details>

### 2. Telegram Stars каналу `t.me/igareq`

[![Telegram](https://img.shields.io/badge/Join_me_on-Telegram-26A5E4?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/igareq)

### 3. Криптовалютный перевод

<details>
<summary><code><em> Нажмите на стрелку, чтобы раскрыть список криптокошельков  </em></code></summary>

⇩

Выберите любую удобную для вас криптовалюту и скопируйте ее адрес. Отправлять следует только на тот кошелек, который соответствует монете, в противном случае средства будут утеряны.

| № | Монета | Адрес |
|--|--|--|
| 1 | `Bitcoin (BTC)` | `18vVz4UzFdxCGnCnAzJtXv6ECsh32ff9VT` |
| 2 | `Монеты_на_базе_Ethereum(ETH): Ethereum (ETH), USDC (ETH), USDT (Ethereum ERC-20), Shiba Inu (SHIB)` | `0xfc668016a823f3EE53d2F3009547666A2BdaBd32` |
| 3 | `Монеты_на_базе_Tron_(TRX): Tron (TRX), USDC (TRX), USDT (TRX)` | `TLnzF6NYgyqBHJMM2qByMXEHLBWNhBWcJ1` |
| 4 | `Монеты_на_базе_Toncoin_(TON): Toncoin (TON), Notcoin (NOT), Hamster Combat (HMSTR), USDT (USDT-TON)` | `EQAGbSuckE93yiACSENJGo8WuRq474Wba1J4yCF1Q59xsL0k` |
| 5 | `Litecoin (LTC)` | `LcHbh84V5PgWk1gTzjGWeef6NQT4MwE9RK` |
| 6 | `Ripple (XRP)` | `rNaKXrfLGsAVvA8JMr9dApMgCNzFmPbvTR` |
| 7 | `Monero (XMR)` | `47uvnonFqbyHMRrZadCAAvL2q9ed476PKdGtbLxXeUj1fs7gtPZ6mx3BeRBd2JM6Wmc16tN7K3ZcDMfds3cE8NaMCgAbD5Q` |
| 8 | `ZCash (ZEC)` | `t1cjEDjtLxatccB6o1pUPxb3pMByCz1L5Ct` |
| 9 | `Dogecoin (DOGE)` | `DRNBruzYDv5vWEz1ndGDjywqugVhd2Zmbm` |
| 10 | `Solana (SOL)` | `Hxm9MjxfD1LNKaWuiFFLzBDTR5CnJSty7gRnkTfubiWj` |
| 11 | `Stellar (XLM)` | `GDRN4K4VDDGNFIWJ3BAN7KL7576764RN44TBHTXYJIXMLK7RNP4UTSJ6` |
| 12 | `Cardano (ADA)` | `addr1qxpw4m02auvmrfee3suz98tvj82cm4mpfllvyda8fz004j40dpemdcuzntj5ykxwv2x6azyp982stfxegm9zvl9kf74s309qhu` |
| 13 | `NEAR Coin (NEAR)` | `d9cba0ec6233589267f43b91d8c156efb7fcd0a0177d7e8a34f7b791a61e7e35` |

</details>

<details>
<summary><code><em> Где покупают криптовалюту? </em></code></summary>

⇩

```diff

BestChange:
https://www.bestchange.com
https://www.bestchange.net
https://www.bestchange.ru
Новая версия сайта BestChange:
https://bestchange.biz/ru

```

</details>


##  <img src="https://media.giphy.com/media/v1.Y2lkPWVjZjA1ZTQ3ZmJ4anB6YjR3aWJpaTRvYzUzejY1dmwzN2c2M3c2NnV0MXUwM3RrcyZlcD12MV9zdGlja2Vyc19zZWFyY2gmY3Q9cw/acN91ftm1tJX23OOBx/giphy.gif" width="60"> Почта для связи: igareck@proton.me

## 👀 Количество посетителей
<img src="https://komarev.com/ghpvc/?username=igareck&label=Visitors&color=0e75b6&style=flat" alt="Visitor Count" /> <img src="https://visitor-badge.laobi.icu/badge?page_id=igareck.visitor-badge&left_color=black&right_color=green&left_text=Cyber+Hits" alt="Cyber Hits"/>  


## <img src="https://media.giphy.com/media/v1.Y2lkPWVjZjA1ZTQ3Z25rOXRoeW1xODR1dWh2b3UycTd6YnB0Y2hlMTZtaDluZW1uNnl4ZyZlcD12MV9zdGlja2Vyc19zZWFyY2gmY3Q9cw/CeYEKonyFQyzWhxmvd/giphy.gif" width="40"> ДИСКЛЕЙМЕР

> *Данный пост не является рекламой VPN. Весь материал предназначен исключительно в информационных целях, и только для граждан тех стран, где эта информация легальна, как минимум - в научных целях. Если вам такое читать нельзя - закройте эту страницу немедленно!* 
>
> *Автор не имеет никаких намерений, не побуждает, не поощряет и не оправдывает использование VPN и любых других программ ни при каких обстоятельствах.*
>
> *Ответственность за любое применение VPN или AntiDPI — на их пользователе.*
>
> *Отказ от ответственности: автор не несёт ответственность за действия третьих лиц и не поощряет противоправное использование VPN или AntiDPI.*
>
> *Автор не несет ответственности за точность, полноту и достоверность опубликованных данных. Все совпадения случайны. Вся информация предоставлена «как есть» и может не соответствовать действительности.*
>
> *Используйте в соответствии с местным законодательством.* 
>
> *Используйте VPN или AntiDPI только в законных и научно-исследовательских целях: в частности - для обеспечения вашей безопасности в сети, защищённого удалённого доступа и тестирования скорости интернет-соединения, и ни в коем случае не применяйте данные технологии для обхода блокировок.*
>
> *Проект некоммерческий, бесплатный, вся представленная "платежная" информация найдена случайным образом где-то в интернет-пространстве, скопирована "как есть" для демонстрации возможного примера и автору не принадлежит.*
>
> *Совет - закройте эту страницу, удалите все VPN и AntiDPI с вашего компьютера, поставьте MAX и Yandex на все устройства, чтобы "ловило" даже на парковке, и пользуйтесь только интернет-ресурсами, которые разрешены вашим интернет-провайдером, ну вы поняли.*