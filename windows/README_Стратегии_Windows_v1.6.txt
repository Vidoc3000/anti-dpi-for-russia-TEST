============================================================================
AntiDPI Strategies + Bol-Van Zapret2
GUI + CLI Version 1.6 | Windows 10/11 x64 | СПРАВОЧНИК ВСЕХ 492 СТРАТЕГИЙ
============================================================================
ПРОГРАММА ГОТОВЫХ ANTI-DPI СТРАТЕГИЙ НА БАЗЕ ZAPRET2 (BOL-VAN)
В УДОБНОЙ CLI ОБОЛОЧКЕ ДЛЯ РАБОТЫ ЧЕРНЫХ СПИСКОВ VPN/TOR + YOUTUBE
============================================================================
https://github.com/igareck/anti-dpi-for-russia
https://github.com/bol-van/zapret-win-bundle
Telegram: https://t.me/igareq
============================================================================

Здесь используется общая нумерация Golden+Silver из меню программы:
Golden: 1–45 (45); Silver: 46–492 (447). Всего 24 семейства и 492 стратегии.

МАРКЕРЫ И ОБРАБОТЧИКИ
pos: числовые смещения в данных либо позиции, связанные с разобранным TLS.
0 — начало данных; 1 и 2 — числовые смещения; 1220 — фиксированная позиция.
sniext — начало расширения Server Name в TLS; host — начало имени SNI;
endhost — конец имени SNI; midsld — середина домена второго уровня в SNI.
Суффиксы +1, -2 и т. п. сдвигают соответствующий маркер.
Длинный список pos означает несколько точек разделения, а не несколько доменов.
Если маркер для конкретного ClientHello неприменим, действует логика обработчика
загруженной сборки; заявленная точка не означает гарантированное число пакетов.
multisplit — отправка TCP-частей в обычном порядке.
multidisorder — отправка TCP-частей от последних к первым.
fakedsplit — две настоящие части в обычном порядке плюс фейки.
fakeddisorder — две настоящие части с перестановкой плюс фейки.
hostfakesplit — фейковые вставки на месте SNI и настоящие части вокруг них.
tcpseg — дополнительный сегмент выбранного диапазона; это не полный multisplit.
seqovl — перекрытие TCP-последовательности; в этих стратегиях заполнение нулевое.
nodrop — этот шаг оставляет исходные данные следующему обработчику цепочки.
AutoTTL — расчёт TTL по оценке пути со смещением и границами из аргумента.
badsum — неверная транспортная checksum; tcp_md5 — TCP MD5 Signature option.
rnd — обновление случайных полей фейка; dupsid — копирование Session ID
настоящего ClientHello в фейк, если структуры совместимы.
padencap — настройка длин TLS/padding фейка с учётом настоящего ClientHello.

НАВИГАЦИЯ ПО СЕМЕЙСТВАМ
1–13: Golden / fake + multisplit (13 шт.)
14–20: Golden / multisplit + multisplit (7 шт.)
21–21: Golden / fake + multidisorder (1 шт.)
22–32: Golden / Именованный hostfakesplit (11 шт.)
33–45: Golden / Реальный ClientHello + fake + multisplit (13 шт.)
46–80: Silver / fake + multisplit (35 шт.)
81–92: Silver / multisplit + multisplit (12 шт.)
93–93: Silver / fake + multidisorder (1 шт.)
94–142: Silver / Именованный hostfakesplit (49 шт.)
143–172: Silver / Реальный ClientHello + fake + multisplit (30 шт.)
173–176: Silver / fake (4 шт.)
177–201: Silver / fake + fake + fakeddisorder (25 шт.)
202–209: Silver / fake + fake + multidisorder (8 шт.)
210–214: Silver / fake + fake + multisplit (5 шт.)
215–341: Silver / fake + fakeddisorder (127 шт.)
342–408: Silver / fake + fakedsplit (67 шт.)
409–409: Silver / fake + hostfakesplit (1 шт.)
410–410: Silver / fake + tcpseg (1 шт.)
411–428: Silver / fakedsplit (18 шт.)
429–456: Silver / hostfakesplit (28 шт.)
457–478: Silver / multisplit + fakeddisorder (22 шт.)
479–480: Silver / tcpseg (2 шт.)
481–484: Silver / Большой TLS-префикс / multisplit (4 шт.)
485–492: Silver / SYN-data + TCP window-size (8 шт.)

============================================================================
СТРАТЕГИЯ 1 — Golden
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Семейство 1: Golden / fake + multisplit; вариант 1.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 2 — Golden
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld,1220)
Семейство 1: Golden / fake + multisplit; вариант 2.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld,1220. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld,1220

============================================================================
СТРАТЕГИЯ 3 — Golden
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 1: Golden / fake + multisplit; вариант 3.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 4 — Golden
============================================================================
Название: TLS-фейк (SNI=dl.google.com; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Семейство 1: Golden / fake + multisplit; вариант 4.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка: dl.google.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=fake:blob=public_tls_pattern:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 5 — Golden
============================================================================
Название: TLS-фейк (SNI=dl.google.com; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 1: Golden / fake + multisplit; вариант 5.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка: dl.google.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=fake:blob=public_tls_pattern:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 6 — Golden
============================================================================
Название: TLS-фейк (SNI=dl.google.com; SEQ=1000000) + multisplit (ClientHello по частям;
  pos=1,midsld)
Семейство 1: Golden / fake + multisplit; вариант 6.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка: dl.google.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=fake:blob=public_tls_pattern:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 7 — Golden
============================================================================
Название: TLS-фейк (SNI=open.spotify.com; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,midsld)
Семейство 1: Golden / fake + multisplit; вариант 7.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка: open.spotify.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не
   заменяются.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=fake:blob=public_tls_pattern:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 8 — Golden
============================================================================
Название: TLS-фейк (SNI=open.spotify.com; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 1: Golden / fake + multisplit; вариант 8.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка: open.spotify.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не
   заменяются.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=fake:blob=public_tls_pattern:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 9 — Golden
============================================================================
Название: TLS-фейк (SNI=open.spotify.com; SEQ=1000000) + multisplit (ClientHello по частям;
  pos=1,midsld)
Семейство 1: Golden / fake + multisplit; вариант 9.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка: open.spotify.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не
   заменяются.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=fake:blob=public_tls_pattern:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 10 — Golden
============================================================================
Название: TLS-фейк (SNI=open.spotify.com; SEQ=1000000) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 1: Golden / fake + multisplit; вариант 10.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка: open.spotify.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не
   заменяются.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=fake:blob=public_tls_pattern:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 11 — Golden
============================================================================
Название: TLS-фейк (SNI=dl.google.com; SEQ=1000000) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 1: Golden / fake + multisplit; вариант 11.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка: dl.google.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=fake:blob=public_tls_pattern:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 12 — Golden
============================================================================
Название: TLS-фейк (штатный SNI; SEQ=1000000; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,midsld)
Семейство 1: Golden / fake + multisplit; вариант 12.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 13 — Golden
============================================================================
Название: TLS-фейк (штатный SNI; SEQ=1000000; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 1: Golden / fake + multisplit; вариант 13.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 14 — Golden
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 2: Golden / multisplit + multisplit; вариант 1.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:tcp_ts=-1000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 15 — Golden
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по
  частям; pos=1,midsld,1220)
Семейство 2: Golden / multisplit + multisplit; вариант 2.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld,1220. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:tcp_ts=-1000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,midsld,1220

============================================================================
СТРАТЕГИЯ 16 — Golden
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 2: Golden / multisplit + multisplit; вариант 3.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:tcp_ts=-1000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 17 — Golden
============================================================================
Название: Разделённый TLS-фейк (SNI=dl.google.com; TS=-1000; pos=2; nodrop) + multisplit
  (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 2: Golden / multisplit + multisplit; вариант 4.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка: dl.google.com.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=multisplit:blob=public_tls_pattern:tcp_ts=-1000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 18 — Golden
============================================================================
Название: Разделённый TLS-фейк (SNI=open.spotify.com; TS=-1000; pos=2; nodrop) + multisplit
  (ClientHello по частям; pos=1,midsld)
Семейство 2: Golden / multisplit + multisplit; вариант 5.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка: open.spotify.com.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=multisplit:blob=public_tls_pattern:tcp_ts=-1000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 19 — Golden
============================================================================
Название: Разделённый TLS-фейк (SNI=open.spotify.com; TS=-1000; pos=2; nodrop) + multisplit
  (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 2: Golden / multisplit + multisplit; вариант 6.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка: open.spotify.com.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=multisplit:blob=public_tls_pattern:tcp_ts=-1000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 20 — Golden
============================================================================
Название: Разделённый TLS-фейк (SNI=dl.google.com; TS=-1000; pos=2; nodrop) + multisplit
  (ClientHello по частям; pos=1,midsld)
Семейство 2: Golden / multisplit + multisplit; вариант 7.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка: dl.google.com.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=multisplit:blob=public_tls_pattern:tcp_ts=-1000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 21 — Golden
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000) + multidisorder (ClientHello в обратном порядке;
  pos=2,midsld; seqovl=1)
Семейство 3: Golden / fake + multidisorder; вариант 1.
Цепочка обработчиков: fake + multidisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multidisorder
   Настоящий ClientHello разбивается на TCP-части; части отправляются от последних к первым. Сервер
   собирает байтовый поток по TCP SEQ.
   Точки разделения: pos=2,midsld. Расшифровка маркеров приведена в начале справочника.
   seqovl=1: задано перекрытие TCP-последовательности с нулевым заполнением. Применимость зависит от
   разрешённых точек и обработчика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:repeats=1
--lua-desync=multidisorder:pos=2,midsld:seqovl=1

============================================================================
СТРАТЕГИЯ 22 — Golden
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=google.com; TS=-1000)
Семейство 4: Golden / Именованный hostfakesplit; вариант 1.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=google.com: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=google.com:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 23 — Golden
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=google.com; TCP MD5)
Семейство 4: Golden / Именованный hostfakesplit; вариант 2.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=google.com: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=google.com:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 24 — Golden
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=4pda.to; TS=-1000)
Семейство 4: Golden / Именованный hostfakesplit; вариант 3.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=4pda.to: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=4pda.to:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 25 — Golden
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=vk.com; TS=-1000)
Семейство 4: Golden / Именованный hostfakesplit; вариант 4.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=vk.com: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=vk.com:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 26 — Golden
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=vk.com; TCP MD5)
Семейство 4: Golden / Именованный hostfakesplit; вариант 5.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=vk.com: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=vk.com:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 27 — Golden
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=w3.org; TCP MD5)
Семейство 4: Golden / Именованный hostfakesplit; вариант 6.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=w3.org: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=w3.org:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 28 — Golden
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=icloud.com; TS=-1000)
Семейство 4: Golden / Именованный hostfakesplit; вариант 7.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=icloud.com: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=icloud.com:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 29 — Golden
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=yandex.ru; TS=-1000)
Семейство 4: Golden / Именованный hostfakesplit; вариант 8.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=yandex.ru: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=yandex.ru:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 30 — Golden
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=yandex.ru; TCP MD5)
Семейство 4: Golden / Именованный hostfakesplit; вариант 9.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=yandex.ru: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=yandex.ru:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 31 — Golden
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=w3.org; TS=-1000)
Семейство 4: Golden / Именованный hostfakesplit; вариант 10.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=w3.org: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=w3.org:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 32 — Golden
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=icloud.com; TCP MD5)
Семейство 4: Golden / Именованный hostfakesplit; вариант 11.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=icloud.com: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=icloud.com:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 33 — Golden
============================================================================
Название: Фейк из текущего ClientHello (SNI=google.com; TS=-1000) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 5: Golden / Реальный ClientHello + fake + multisplit; вариант 1.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: google.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=google.com: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=google.com: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=google.com:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 34 — Golden
============================================================================
Название: Фейк из текущего ClientHello (SNI=google.com; TS=-1000) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 5: Golden / Реальный ClientHello + fake + multisplit; вариант 2.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: google.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=google.com: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=google.com: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=google.com:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 35 — Golden
============================================================================
Название: Фейк из текущего ClientHello (SNI=4pda.to; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,midsld)
Семейство 5: Golden / Реальный ClientHello + fake + multisplit; вариант 3.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 4pda.to. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=4pda.to: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=4pda.to: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=4pda.to:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 36 — Golden
============================================================================
Название: Фейк из текущего ClientHello (SNI=4pda.to; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 5: Golden / Реальный ClientHello + fake + multisplit; вариант 4.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 4pda.to. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=4pda.to: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=4pda.to: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=4pda.to:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 37 — Golden
============================================================================
Название: Фейк из текущего ClientHello (SNI=vk.com; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,midsld)
Семейство 5: Golden / Реальный ClientHello + fake + multisplit; вариант 5.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: vk.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=vk.com: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=vk.com: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=vk.com:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 38 — Golden
============================================================================
Название: Фейк из текущего ClientHello (SNI=vk.com; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 5: Golden / Реальный ClientHello + fake + multisplit; вариант 6.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: vk.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=vk.com: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=vk.com: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=vk.com:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 39 — Golden
============================================================================
Название: Фейк из текущего ClientHello (SNI=w3.org; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,midsld)
Семейство 5: Golden / Реальный ClientHello + fake + multisplit; вариант 7.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: w3.org. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=w3.org: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=w3.org: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=w3.org:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 40 — Golden
============================================================================
Название: Фейк из текущего ClientHello (SNI=w3.org; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 5: Golden / Реальный ClientHello + fake + multisplit; вариант 8.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: w3.org. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=w3.org: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=w3.org: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=w3.org:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 41 — Golden
============================================================================
Название: Фейк из текущего ClientHello (SNI=yandex.ru; TS=-1000) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 5: Golden / Реальный ClientHello + fake + multisplit; вариант 9.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: yandex.ru. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=yandex.ru: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=yandex.ru: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=yandex.ru:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 42 — Golden
============================================================================
Название: Фейк из текущего ClientHello (SNI=www.microsoft.com; TS=-1000) + multisplit (ClientHello
  по частям; pos=1,midsld)
Семейство 5: Golden / Реальный ClientHello + fake + multisplit; вариант 10.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: www.microsoft.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не
   заменяются.
   tls_mod=sni=www.microsoft.com: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=www.microsoft.com: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=www.microsoft.com:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 43 — Golden
============================================================================
Название: Фейк из текущего ClientHello (SNI=yandex.ru; TS=-1000) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 5: Golden / Реальный ClientHello + fake + multisplit; вариант 11.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: yandex.ru. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=yandex.ru: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=yandex.ru: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=yandex.ru:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 44 — Golden
============================================================================
Название: Фейк из текущего ClientHello (SNI=icloud.com; TS=-1000) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 5: Golden / Реальный ClientHello + fake + multisplit; вариант 12.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: icloud.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=icloud.com: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=icloud.com: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=icloud.com:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 45 — Golden
============================================================================
Название: Фейк из текущего ClientHello (SNI=www.microsoft.com; TS=-1000) + multisplit (ClientHello
  по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 5: Golden / Реальный ClientHello + fake + multisplit; вариант 13.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: www.microsoft.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не
   заменяются.
   tls_mod=sni=www.microsoft.com: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=www.microsoft.com: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=www.microsoft.com:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 46 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=-3000) + multisplit (ClientHello по частям;
  pos=1,midsld,1220)
Семейство 6: Silver / fake + multisplit; вариант 1.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld,1220. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=-3000:repeats=1
--lua-desync=multisplit:pos=1,midsld,1220

============================================================================
СТРАТЕГИЯ 47 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=-3000) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 6: Silver / fake + multisplit; вариант 2.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=-3000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 48 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + multisplit (ClientHello по частям;
  pos=1,midsld,1220)
Семейство 6: Silver / fake + multisplit; вариант 3.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld,1220. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld,1220

============================================================================
СТРАТЕГИЯ 49 — Silver
============================================================================
Название: TLS-фейк (SNI=max.ru; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Семейство 6: Silver / fake + multisplit; вариант 4.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка: max.ru. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=fake:blob=public_tls_pattern:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 50 — Silver
============================================================================
Название: TLS-фейк (SNI=max.ru; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Семейство 6: Silver / fake + multisplit; вариант 5.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка: max.ru. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=fake:blob=public_tls_pattern:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 51 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по
  частям; pos=host+1)
Семейство 6: Silver / fake + multisplit; вариант 6.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=host+1

============================================================================
СТРАТЕГИЯ 52 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по
  частям; pos=midsld)
Семейство 6: Silver / fake + multisplit; вариант 7.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=midsld

============================================================================
СТРАТЕГИЯ 53 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по
  частям; pos=sniext+1)
Семейство 6: Silver / fake + multisplit; вариант 8.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=sniext+1

============================================================================
СТРАТЕГИЯ 54 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по
  частям; pos=1)
Семейство 6: Silver / fake + multisplit; вариант 9.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=1

============================================================================
СТРАТЕГИЯ 55 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,midsld,1220)
Семейство 6: Silver / fake + multisplit; вариант 10.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld,1220. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld,1220

============================================================================
СТРАТЕГИЯ 56 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + multisplit
  (ClientHello по частям; pos=1)
Семейство 6: Silver / fake + multisplit; вариант 11.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=1

============================================================================
СТРАТЕГИЯ 57 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + multisplit
  (ClientHello по частям; pos=midsld)
Семейство 6: Silver / fake + multisplit; вариант 12.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=midsld

============================================================================
СТРАТЕГИЯ 58 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + multisplit
  (ClientHello по частям; pos=2)
Семейство 6: Silver / fake + multisplit; вариант 13.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=2

============================================================================
СТРАТЕГИЯ 59 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + multisplit
  (ClientHello по частям; pos=sniext+1)
Семейство 6: Silver / fake + multisplit; вариант 14.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=sniext+1

============================================================================
СТРАТЕГИЯ 60 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по
  частям; pos=2)
Семейство 6: Silver / fake + multisplit; вариант 15.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=2

============================================================================
СТРАТЕГИЯ 61 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по
  частям; pos=sniext+1)
Семейство 6: Silver / fake + multisplit; вариант 16.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=sniext+1

============================================================================
СТРАТЕГИЯ 62 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по
  частям; pos=sniext+4)
Семейство 6: Silver / fake + multisplit; вариант 17.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=sniext+4

============================================================================
СТРАТЕГИЯ 63 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + multisplit (ClientHello
  по частям; pos=sniext+1)
Семейство 6: Silver / fake + multisplit; вариант 18.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=sniext+1

============================================================================
СТРАТЕГИЯ 64 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + multisplit (ClientHello
  по частям; pos=1)
Семейство 6: Silver / fake + multisplit; вариант 19.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=1

============================================================================
СТРАТЕГИЯ 65 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + multisplit (ClientHello
  по частям; pos=host+1)
Семейство 6: Silver / fake + multisplit; вариант 20.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=host+1

============================================================================
СТРАТЕГИЯ 66 — Silver
============================================================================
Название: TLS-фейк (SNI=max.ru; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 6: Silver / fake + multisplit; вариант 21.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка: max.ru. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=fake:blob=public_tls_pattern:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 67 — Silver
============================================================================
Название: TLS-фейк (SNI=max.ru; SEQ=1000000) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 6: Silver / fake + multisplit; вариант 22.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка: max.ru. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=fake:blob=public_tls_pattern:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 68 — Silver
============================================================================
Название: TLS-фейк (SNI=eh.vk.ru; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 6: Silver / fake + multisplit; вариант 23.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка: eh.vk.ru. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=fake:blob=public_tls_pattern:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 69 — Silver
============================================================================
Название: TLS-фейк (SNI=eh.vk.ru; SEQ=1000000) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 6: Silver / fake + multisplit; вариант 24.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка: eh.vk.ru. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=fake:blob=public_tls_pattern:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 70 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по
  частям; pos=2)
Семейство 6: Silver / fake + multisplit; вариант 25.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=2

============================================================================
СТРАТЕГИЯ 71 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + multisplit
  (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 6: Silver / fake + multisplit; вариант 26.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 72 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + multisplit (ClientHello по
  частям; pos=1,midsld,1220)
Семейство 6: Silver / fake + multisplit; вариант 27.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld,1220. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=multisplit:pos=1,midsld,1220

============================================================================
СТРАТЕГИЯ 73 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по
  частям; pos=1,midsld,1220)
Семейство 6: Silver / fake + multisplit; вариант 28.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld,1220. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=1,midsld,1220

============================================================================
СТРАТЕГИЯ 74 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по
  частям; pos=midsld)
Семейство 6: Silver / fake + multisplit; вариант 29.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=6: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=midsld

============================================================================
СТРАТЕГИЯ 75 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по
  частям; pos=sniext+4)
Семейство 6: Silver / fake + multisplit; вариант 30.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=6: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=sniext+4

============================================================================
СТРАТЕГИЯ 76 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по
  частям; pos=sniext+1)
Семейство 6: Silver / fake + multisplit; вариант 31.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=6: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=sniext+1

============================================================================
СТРАТЕГИЯ 77 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по
  частям; pos=host+1)
Семейство 6: Silver / fake + multisplit; вариант 32.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=6: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=host+1

============================================================================
СТРАТЕГИЯ 78 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по
  частям; pos=1)
Семейство 6: Silver / fake + multisplit; вариант 33.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=6: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multisplit:pos=1

============================================================================
СТРАТЕГИЯ 79 — Silver
============================================================================
Название: TLS-фейк (SNI=eh.vk.ru; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Семейство 6: Silver / fake + multisplit; вариант 34.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка: eh.vk.ru. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=fake:blob=public_tls_pattern:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 80 — Silver
============================================================================
Название: TLS-фейк (SNI=eh.vk.ru; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Семейство 6: Silver / fake + multisplit; вариант 35.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка: eh.vk.ru. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=fake:blob=public_tls_pattern:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 81 — Silver
============================================================================
Название: Разделённый TLS-фейк (SNI=dl.google.com; SEQ=1000000; pos=2; nodrop) + multisplit
  (ClientHello по частям; pos=1,midsld)
Семейство 7: Silver / multisplit + multisplit; вариант 1.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка: dl.google.com.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=multisplit:blob=public_tls_pattern:tcp_seq=1000000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 82 — Silver
============================================================================
Название: Разделённый TLS-фейк (SNI=dl.google.com; SEQ=1000000; pos=2; nodrop) + multisplit
  (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 7: Silver / multisplit + multisplit; вариант 2.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка: dl.google.com.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=multisplit:blob=public_tls_pattern:tcp_seq=1000000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 83 — Silver
============================================================================
Название: Разделённый TLS-фейк (SNI=max.ru; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 7: Silver / multisplit + multisplit; вариант 3.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка: max.ru.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=multisplit:blob=public_tls_pattern:tcp_ts=-1000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 84 — Silver
============================================================================
Название: Разделённый TLS-фейк (SNI=max.ru; SEQ=1000000; pos=2; nodrop) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 7: Silver / multisplit + multisplit; вариант 4.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка: max.ru.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=multisplit:blob=public_tls_pattern:tcp_seq=1000000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 85 — Silver
============================================================================
Название: Разделённый TLS-фейк (SNI=open.spotify.com; SEQ=1000000; pos=2; nodrop) + multisplit
  (ClientHello по частям; pos=1,midsld)
Семейство 7: Silver / multisplit + multisplit; вариант 5.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка: open.spotify.com.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=multisplit:blob=public_tls_pattern:tcp_seq=1000000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 86 — Silver
============================================================================
Название: Разделённый TLS-фейк (SNI=open.spotify.com; SEQ=1000000; pos=2; nodrop) + multisplit
  (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 7: Silver / multisplit + multisplit; вариант 6.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка: open.spotify.com.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=multisplit:blob=public_tls_pattern:tcp_seq=1000000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 87 — Silver
============================================================================
Название: Разделённый TLS-фейк (SNI=max.ru; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 7: Silver / multisplit + multisplit; вариант 7.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка: max.ru.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=multisplit:blob=public_tls_pattern:tcp_ts=-1000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 88 — Silver
============================================================================
Название: Разделённый TLS-фейк (SNI=eh.vk.ru; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 7: Silver / multisplit + multisplit; вариант 8.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка: eh.vk.ru.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=multisplit:blob=public_tls_pattern:tcp_ts=-1000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 89 — Silver
============================================================================
Название: Разделённый TLS-фейк (SNI=max.ru; SEQ=1000000; pos=2; nodrop) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 7: Silver / multisplit + multisplit; вариант 9.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка: max.ru.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=multisplit:blob=public_tls_pattern:tcp_seq=1000000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 90 — Silver
============================================================================
Название: Разделённый TLS-фейк (SNI=eh.vk.ru; SEQ=1000000; pos=2; nodrop) + multisplit (ClientHello
  по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 7: Silver / multisplit + multisplit; вариант 10.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка: eh.vk.ru.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=multisplit:blob=public_tls_pattern:tcp_seq=1000000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 91 — Silver
============================================================================
Название: Разделённый TLS-фейк (SNI=eh.vk.ru; SEQ=1000000; pos=2; nodrop) + multisplit (ClientHello
  по частям; pos=1,midsld)
Семейство 7: Silver / multisplit + multisplit; вариант 11.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка: eh.vk.ru.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=multisplit:blob=public_tls_pattern:tcp_seq=1000000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 92 — Silver
============================================================================
Название: Разделённый TLS-фейк (SNI=eh.vk.ru; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 7: Silver / multisplit + multisplit; вариант 12.
Цепочка обработчиков: multisplit + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка: eh.vk.ru.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
--payload=tls_client_hello
--lua-desync=multisplit:blob=public_tls_pattern:tcp_ts=-1000:pos=2:nodrop:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 93 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + multidisorder (ClientHello в
  обратном порядке; pos=2,midsld; seqovl=1)
Семейство 8: Silver / fake + multidisorder; вариант 1.
Цепочка обработчиков: fake + multidisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multidisorder
   Настоящий ClientHello разбивается на TCP-части; части отправляются от последних к первым. Сервер
   собирает байтовый поток по TCP SEQ.
   Точки разделения: pos=2,midsld. Расшифровка маркеров приведена в начале справочника.
   seqovl=1: задано перекрытие TCP-последовательности с нулевым заполнением. Применимость зависит от
   разрешённых точек и обработчика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=multidisorder:pos=2,midsld:seqovl=1

============================================================================
СТРАТЕГИЯ 94 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=yandex.ru; TCP MD5; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 1.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=yandex.ru: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=yandex.ru:midhost=midsld:disorder_after:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 95 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=2040.test; TCP MD5; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 2.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=2040.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=2040.test:midhost=midsld:disorder_after:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 96 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=9e1ca.test; TS=-1000)
Семейство 9: Silver / Именованный hostfakesplit; вариант 3.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=9e1ca.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=9e1ca.test:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 97 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=google.com; TS=-1000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 4.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=google.com: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=google.com:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 98 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=9e1ca.test; TS=-1000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 5.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=9e1ca.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=9e1ca.test:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 99 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=google.com; SEQ=1000000)
Семейство 9: Silver / Именованный hostfakesplit; вариант 6.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=google.com: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=google.com:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 100 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=9e1ca.test; SEQ=1000000)
Семейство 9: Silver / Именованный hostfakesplit; вариант 7.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=9e1ca.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=9e1ca.test:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 101 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=google.com; SEQ=1000000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 8.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=google.com: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=google.com:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 102 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=9e1ca.test; SEQ=1000000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 9.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=9e1ca.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=9e1ca.test:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 103 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=9e1ca.test; TCP MD5)
Семейство 9: Silver / Именованный hostfakesplit; вариант 10.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=9e1ca.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=9e1ca.test:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 104 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=google.com; TCP MD5; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 11.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=google.com: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=google.com:midhost=midsld:disorder_after:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 105 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=9e1ca.test; TCP MD5; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 12.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=9e1ca.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=9e1ca.test:midhost=midsld:disorder_after:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 106 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=49.test; TS=-1000)
Семейство 9: Silver / Именованный hostfakesplit; вариант 13.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=49.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=49.test:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 107 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=4pda.to; TS=-1000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 14.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=4pda.to: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=4pda.to:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 108 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=49.test; TS=-1000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 15.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=49.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=49.test:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 109 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=4pda.to; SEQ=1000000)
Семейство 9: Silver / Именованный hostfakesplit; вариант 16.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=4pda.to: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=4pda.to:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 110 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=49.test; SEQ=1000000)
Семейство 9: Silver / Именованный hostfakesplit; вариант 17.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=49.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=49.test:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 111 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=4pda.to; SEQ=1000000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 18.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=4pda.to: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=4pda.to:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 112 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=49.test; SEQ=1000000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 19.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=49.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=49.test:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 113 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=3.test; TS=-1000)
Семейство 9: Silver / Именованный hostfakesplit; вариант 20.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=3.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=3.test:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 114 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=3.test; SEQ=1000000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 21.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=3.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=3.test:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 115 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=3.test; TCP MD5)
Семейство 9: Silver / Именованный hostfakesplit; вариант 22.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=3.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=3.test:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 116 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=vk.com; TCP MD5; midhost=midsld; перестановка
  после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 23.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=vk.com: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=vk.com:midhost=midsld:disorder_after:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 117 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=3.test; TCP MD5; midhost=midsld; перестановка
  после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 24.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=3.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=3.test:midhost=midsld:disorder_after:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 118 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=w3.org; TS=-1000; midhost=midsld; перестановка
  после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 25.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=w3.org: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=w3.org:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 119 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=w3.org; SEQ=1000000)
Семейство 9: Silver / Именованный hostfakesplit; вариант 26.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=w3.org: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=w3.org:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 120 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=c.test; SEQ=1000000)
Семейство 9: Silver / Именованный hostfakesplit; вариант 27.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=c.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=c.test:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 121 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=w3.org; SEQ=1000000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 28.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=w3.org: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=w3.org:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 122 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=c.test; SEQ=1000000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 29.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=c.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=c.test:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 123 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=c.test; TCP MD5)
Семейство 9: Silver / Именованный hostfakesplit; вариант 30.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=c.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=c.test:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 124 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=w3.org; TCP MD5; midhost=midsld; перестановка
  после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 31.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=w3.org: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=w3.org:midhost=midsld:disorder_after:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 125 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=c.test; TCP MD5; midhost=midsld; перестановка
  после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 32.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=c.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=c.test:midhost=midsld:disorder_after:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 126 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=18dda.test; TS=-1000)
Семейство 9: Silver / Именованный hostfakesplit; вариант 33.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=18dda.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=18dda.test:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 127 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=icloud.com; TS=-1000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 34.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=icloud.com: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=icloud.com:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 128 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=icloud.com; TCP MD5; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 35.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=icloud.com: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=icloud.com:midhost=midsld:disorder_after:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 129 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=18dda.test; TCP MD5; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 36.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=18dda.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=18dda.test:midhost=midsld:disorder_after:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 130 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=2040.test; TS=-1000)
Семейство 9: Silver / Именованный hostfakesplit; вариант 37.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=2040.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=2040.test:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 131 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=yandex.ru; TS=-1000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 38.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=yandex.ru: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=yandex.ru:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 132 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=2040.test; TS=-1000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 39.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=2040.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=2040.test:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 133 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=yandex.ru; SEQ=1000000)
Семейство 9: Silver / Именованный hostfakesplit; вариант 40.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=yandex.ru: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=yandex.ru:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 134 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=2040.test; SEQ=1000000)
Семейство 9: Silver / Именованный hostfakesplit; вариант 41.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=2040.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=2040.test:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 135 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=yandex.ru; SEQ=1000000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 42.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=yandex.ru: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=yandex.ru:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 136 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=2040.test; SEQ=1000000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 43.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=2040.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=2040.test:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 137 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=2040.test; TCP MD5)
Семейство 9: Silver / Именованный hostfakesplit; вариант 44.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=2040.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=2040.test:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 138 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=49.test; TCP MD5; midhost=midsld; перестановка
  после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 45.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=49.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=49.test:midhost=midsld:disorder_after:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 139 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=vk.com; TS=-1000; midhost=midsld; перестановка
  после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 46.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=vk.com: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=vk.com:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 140 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=vk.com; SEQ=1000000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 47.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=vk.com: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=vk.com:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

============================================================================
СТРАТЕГИЯ 141 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=c.test; TS=-1000; midhost=midsld; перестановка
  после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 48.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=c.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=c.test:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 142 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; host=18dda.test; TS=-1000; midhost=midsld;
  перестановка после SNI)
Семейство 9: Silver / Именованный hostfakesplit; вариант 49.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host=18dda.test: шаблон фейкового имени. Это шаблон для генерации имени подходящей длины, а не
   обещание буквального совпадения всего SNI с доменом.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:host=18dda.test:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 143 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=9e1ca.test; TS=-1000) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 1.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 9e1ca.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=9e1ca.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=9e1ca.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=9e1ca.test:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 144 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=9e1ca.test; TS=-1000) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 2.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 9e1ca.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=9e1ca.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=9e1ca.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=9e1ca.test:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 145 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=google.com; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 3.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: google.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=google.com: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=google.com: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=google.com:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 146 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=9e1ca.test; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 4.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 9e1ca.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=9e1ca.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=9e1ca.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=9e1ca.test:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 147 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=google.com; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 5.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: google.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=google.com: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=google.com: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=google.com:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 148 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=9e1ca.test; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 6.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 9e1ca.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=9e1ca.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=9e1ca.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=9e1ca.test:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 149 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=49.test; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 7.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 49.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=49.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=49.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=49.test:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 150 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=3.test; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 8.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 3.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=3.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=3.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=3.test:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 151 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=3.test; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 9.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 3.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=3.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=3.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=3.test:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 152 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=vk.com; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 10.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: vk.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=vk.com: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=vk.com: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=vk.com:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 153 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=3.test; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 11.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 3.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=3.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=3.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=3.test:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 154 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=vk.com; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 12.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: vk.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=vk.com: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=vk.com: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=vk.com:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 155 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=3.test; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 13.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 3.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=3.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=3.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=3.test:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 156 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=c.test; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 14.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: c.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=c.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=c.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=c.test:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 157 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=c.test; TS=-1000) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 15.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: c.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=c.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=c.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=c.test:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 158 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=w3.org; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 16.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: w3.org. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=w3.org: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=w3.org: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=w3.org:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 159 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=18dda.test; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 17.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 18dda.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=18dda.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=18dda.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=18dda.test:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 160 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=icloud.com; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 18.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: icloud.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=icloud.com: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=icloud.com: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=icloud.com:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 161 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=18dda.test; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 19.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 18dda.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=18dda.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=18dda.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=18dda.test:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 162 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=2040.test; TS=-1000) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 20.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 2040.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=2040.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=2040.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=2040.test:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 163 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=yandex.ru; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 21.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: yandex.ru. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=yandex.ru: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=yandex.ru: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=yandex.ru:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 164 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=2040.test; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 22.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 2040.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=2040.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=2040.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=2040.test:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 165 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=yandex.ru; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 23.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: yandex.ru. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=yandex.ru: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=yandex.ru: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=yandex.ru:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 166 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=2040.test; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 24.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 2040.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=2040.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=2040.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=2040.test:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 167 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=e9d9cc906c1c.test; TS=-1000) + multisplit (ClientHello
  по частям; pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 25.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: e9d9cc906c1c.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не
   заменяются.
   tls_mod=sni=e9d9cc906c1c.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=e9d9cc906c1c.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=e9d9cc906c1c.test:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 168 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=c.test; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 26.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: c.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=c.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=c.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=c.test:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 169 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=icloud.com; SEQ=1000000) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 27.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: icloud.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=icloud.com: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=icloud.com: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=icloud.com:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 170 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=2040.test; TS=-1000) + multisplit (ClientHello по
  частям; pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 28.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: 2040.test. Адрес VPN-сервера и настоящий SNI соединения этим шагом не заменяются.
   tls_mod=sni=2040.test: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=2040.test: в фейковой копии устанавливается это имя SNI.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=2040.test:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 171 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=www.microsoft.com; SEQ=1000000) + multisplit
  (ClientHello по частям; pos=1,midsld)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 29.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: www.microsoft.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не
   заменяются.
   tls_mod=sni=www.microsoft.com: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=www.microsoft.com: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=www.microsoft.com:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 172 — Silver
============================================================================
Название: Фейк из текущего ClientHello (SNI=www.microsoft.com; SEQ=1000000) + multisplit
  (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 10: Silver / Реальный ClientHello + fake + multisplit; вариант 30.
Цепочка обработчиков: fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный TLS-фейк строится из копии собранного ClientHello текущего соединения. Меняется
   фейковая копия.
   Совместимый Lua-обработчик проверяет пригодность копии; при непригодном шаблоне использует
   штатный TLS-шаблон с теми же заданными модификаторами.
   SNI фейка: www.microsoft.com. Адрес VPN-сервера и настоящий SNI соединения этим шагом не
   заменяются.
   tls_mod=sni=www.microsoft.com: модификаторы TLS-фейка применяются в контексте этого шага.
   sni=www.microsoft.com: в фейковой копии устанавливается это имя SNI.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=reasm_data:tls_mod=sni=www.microsoft.com:tcp_seq=1000000:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 173 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap)
Семейство 11: Silver / fake; вариант 1.
Цепочка обработчиков: fake.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1

============================================================================
СТРАТЕГИЯ 174 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap)
Семейство 11: Silver / fake; вариант 2.
Цепочка обработчиков: fake.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1

============================================================================
СТРАТЕГИЯ 175 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap)
Семейство 11: Silver / fake; вариант 3.
Цепочка обработчиков: fake.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1

============================================================================
СТРАТЕГИЯ 176 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap)
Семейство 11: Silver / fake; вариант 4.
Цепочка обработчиков: fake.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1

============================================================================
СТРАТЕГИЯ 177 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + TLS-фейк (штатный SNI; SEQ=1000000;
  TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; SEQ=1000000; pos=1)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 1.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=1:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 178 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + TLS-фейк (штатный SNI; SEQ=1000000;
  TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; SEQ=1000000; pos=1,midsld)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 2.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 179 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + TLS-фейк (штатный SNI; SEQ=1000000;
  TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; SEQ=1000000;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 3.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 180 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + TLS-фейк (штатный SNI; SEQ=1000000;
  TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; SEQ=1000000; pos=2)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 4.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=2:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 181 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; неверная checksum) + TLS-фейк (штатный SNI; неверная
  checksum; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=1)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 5.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:badsum:repeats=1
--lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=1:badsum

============================================================================
СТРАТЕГИЯ 182 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; неверная checksum) + TLS-фейк (штатный SNI; неверная
  checksum; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; неверная checksum;
  pos=host+1)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 6.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:badsum:repeats=1
--lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=host+1:badsum

============================================================================
СТРАТЕГИЯ 183 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; неверная checksum) + TLS-фейк (штатный SNI; неверная
  checksum; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; неверная checksum;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 7.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:badsum:repeats=1
--lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:badsum

============================================================================
СТРАТЕГИЯ 184 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + TLS-фейк (штатный SNI; флаги -ACK;
  TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=sniext+1)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 8.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 185 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги +SYN) + TLS-фейк (штатный SNI; флаги +SYN;
  TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=sniext+4)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 9.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_set=SYN:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 186 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + TLS-фейк (штатный SNI;
  ACK=-66000; TS-опция первой; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки;
  ACK=-66000; TS-опция первой; pos=2)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 10.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=2:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 187 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + TLS-фейк (штатный SNI;
  ACK=-66000; TS-опция первой; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки;
  ACK=-66000; TS-опция первой; pos=1)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 11.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 188 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + TLS-фейк (штатный SNI;
  ACK=-66000; TS-опция первой; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки;
  ACK=-66000; TS-опция первой; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 12.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 189 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + TLS-фейк (штатный SNI;
  ACK=-66000; TS-опция первой; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки;
  ACK=-66000; TS-опция первой; pos=1,midsld)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 13.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 190 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TTL=1) + TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid) +
  fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=midsld)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 14.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=midsld:ip_ttl=1

============================================================================
СТРАТЕГИЯ 191 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TTL=1) + TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid) +
  fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=sniext+1)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 15.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:ip_ttl=1

============================================================================
СТРАТЕГИЯ 192 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TTL=1) + TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid) +
  fakeddisorder (перестановка + нулевые фейки; TTL=1;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 16.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_ttl=1

============================================================================
СТРАТЕГИЯ 193 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TTL=1) + TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid) +
  fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=2)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 17.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=2:ip_ttl=1

============================================================================
СТРАТЕГИЯ 194 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TTL=1) + TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid) +
  fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=1,midsld)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 18.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:ip_ttl=1

============================================================================
СТРАТЕГИЯ 195 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги +SYN) + TLS-фейк (штатный SNI; флаги +SYN;
  TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 19.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_set=SYN:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 196 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + TLS-фейк (штатный SNI; флаги -ACK;
  TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=2)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 20.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=2:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 197 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + TLS-фейк (штатный SNI; флаги -ACK;
  TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=sniext+4)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 21.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 198 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + TLS-фейк (штатный SNI; флаги -ACK;
  TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 22.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 199 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TTL=1) + TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid) +
  fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=host+1)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 23.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=host+1:ip_ttl=1

============================================================================
СТРАТЕГИЯ 200 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + TLS-фейк (штатный SNI; флаги -ACK;
  TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=1,midsld)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 24.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 201 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + TLS-фейк (штатный SNI; флаги -ACK;
  TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=1)
Семейство 12: Silver / fake + fake + fakeddisorder; вариант 25.
Цепочка обработчиков: fake + fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid:repeats=1
--lua-desync=fakeddisorder:pos=1:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 202 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + TLS-фейк (штатный SNI;
  ACK=-66000; TS-опция первой; TLS=rnd,dupsid) + multidisorder (ClientHello в обратном порядке;
  pos=1,midsld)
Семейство 13: Silver / fake + fake + multidisorder; вариант 1.
Цепочка обработчиков: fake + fake + multidisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. multidisorder
   Настоящий ClientHello разбивается на TCP-части; части отправляются от последних к первым. Сервер
   собирает байтовый поток по TCP SEQ.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid:repeats=1
--lua-desync=multidisorder:pos=1,midsld

============================================================================
СТРАТЕГИЯ 203 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + TLS-фейк (штатный SNI;
  ACK=-66000; TS-опция первой; TLS=rnd,dupsid) + multidisorder (ClientHello в обратном порядке;
  pos=1)
Семейство 13: Silver / fake + fake + multidisorder; вариант 2.
Цепочка обработчиков: fake + fake + multidisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. multidisorder
   Настоящий ClientHello разбивается на TCP-части; части отправляются от последних к первым. Сервер
   собирает байтовый поток по TCP SEQ.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid:repeats=1
--lua-desync=multidisorder:pos=1

============================================================================
СТРАТЕГИЯ 204 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=-3000) + TLS-фейк (штатный SNI; SEQ=-3000;
  TLS=rnd,dupsid) + multidisorder (ClientHello в обратном порядке; pos=1,midsld,1220)
Семейство 13: Silver / fake + fake + multidisorder; вариант 3.
Цепочка обработчиков: fake + fake + multidisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. multidisorder
   Настоящий ClientHello разбивается на TCP-части; части отправляются от последних к первым. Сервер
   собирает байтовый поток по TCP SEQ.
   Точки разделения: pos=1,midsld,1220. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=-3000:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_seq=-3000:tls_mod=rnd,dupsid:repeats=1
--lua-desync=multidisorder:pos=1,midsld,1220

============================================================================
СТРАТЕГИЯ 205 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=-3000) + TLS-фейк (штатный SNI; SEQ=-3000;
  TLS=rnd,dupsid) + multidisorder (ClientHello в обратном порядке; pos=1,midsld)
Семейство 13: Silver / fake + fake + multidisorder; вариант 4.
Цепочка обработчиков: fake + fake + multidisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. multidisorder
   Настоящий ClientHello разбивается на TCP-части; части отправляются от последних к первым. Сервер
   собирает байтовый поток по TCP SEQ.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=-3000:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_seq=-3000:tls_mod=rnd,dupsid:repeats=1
--lua-desync=multidisorder:pos=1,midsld

============================================================================
СТРАТЕГИЯ 206 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + TLS-фейк (штатный SNI; SEQ=1000000;
  TLS=rnd,dupsid) + multidisorder (ClientHello в обратном порядке; pos=2)
Семейство 13: Silver / fake + fake + multidisorder; вариант 5.
Цепочка обработчиков: fake + fake + multidisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. multidisorder
   Настоящий ClientHello разбивается на TCP-части; части отправляются от последних к первым. Сервер
   собирает байтовый поток по TCP SEQ.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid:repeats=1
--lua-desync=multidisorder:pos=2

============================================================================
СТРАТЕГИЯ 207 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + TLS-фейк (штатный SNI; SEQ=1000000;
  TLS=rnd,dupsid) + multidisorder (ClientHello в обратном порядке; pos=1,midsld,1220)
Семейство 13: Silver / fake + fake + multidisorder; вариант 6.
Цепочка обработчиков: fake + fake + multidisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. multidisorder
   Настоящий ClientHello разбивается на TCP-части; части отправляются от последних к первым. Сервер
   собирает байтовый поток по TCP SEQ.
   Точки разделения: pos=1,midsld,1220. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid:repeats=1
--lua-desync=multidisorder:pos=1,midsld,1220

============================================================================
СТРАТЕГИЯ 208 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + TLS-фейк (штатный SNI; SEQ=1000000;
  TLS=rnd,dupsid) + multidisorder (ClientHello в обратном порядке; pos=1,midsld)
Семейство 13: Silver / fake + fake + multidisorder; вариант 7.
Цепочка обработчиков: fake + fake + multidisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. multidisorder
   Настоящий ClientHello разбивается на TCP-части; части отправляются от последних к первым. Сервер
   собирает байтовый поток по TCP SEQ.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid:repeats=1
--lua-desync=multidisorder:pos=1,midsld

============================================================================
СТРАТЕГИЯ 209 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + TLS-фейк (штатный SNI; SEQ=1000000;
  TLS=rnd,dupsid) + multidisorder (ClientHello в обратном порядке; pos=1)
Семейство 13: Silver / fake + fake + multidisorder; вариант 8.
Цепочка обработчиков: fake + fake + multidisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. multidisorder
   Настоящий ClientHello разбивается на TCP-части; части отправляются от последних к первым. Сервер
   собирает байтовый поток по TCP SEQ.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid:repeats=1
--lua-desync=multidisorder:pos=1

============================================================================
СТРАТЕГИЯ 210 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + TLS-фейк (штатный SNI; TS=-1000;
  TLS=rnd,dupsid) + multisplit (ClientHello по частям; pos=1,midsld,1220)
Семейство 14: Silver / fake + fake + multisplit; вариант 1.
Цепочка обработчиков: fake + fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld,1220. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid:repeats=1
--lua-desync=multisplit:pos=1,midsld,1220

============================================================================
СТРАТЕГИЯ 211 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + TLS-фейк (штатный SNI; TS=-1000;
  TLS=rnd,dupsid) + multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 14: Silver / fake + fake + multisplit; вариант 2.
Цепочка обработчиков: fake + fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid:repeats=1
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

============================================================================
СТРАТЕГИЯ 212 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + TLS-фейк (штатный SNI; TS=-1000;
  TLS=rnd,dupsid) + multisplit (ClientHello по частям; pos=2)
Семейство 14: Silver / fake + fake + multisplit; вариант 3.
Цепочка обработчиков: fake + fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid:repeats=1
--lua-desync=multisplit:pos=2

============================================================================
СТРАТЕГИЯ 213 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + TLS-фейк (штатный SNI;
  ACK=-66000; TS-опция первой; TLS=rnd,dupsid) + multisplit (ClientHello по частям; pos=1,midsld)
Семейство 14: Silver / fake + fake + multisplit; вариант 4.
Цепочка обработчиков: fake + fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 214 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + TLS-фейк (штатный SNI; TS=-1000) + multisplit
  (ClientHello по частям; pos=1,midsld)
Семейство 14: Silver / fake + fake + multisplit; вариант 5.
Цепочка обработчиков: fake + fake + multisplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
3. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:repeats=1
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 215 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TS=-1000; pos=1)
Семейство 15: Silver / fake + fakeddisorder; вариант 1.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 216 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TS=-1000; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 2.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 217 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TS=-1000; pos=1,midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 3.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 218 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TS=-1000; pos=2)
Семейство 15: Silver / fake + fakeddisorder; вариант 4.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=2:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 219 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TS=-1000; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 5.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 220 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TS=-1000; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 6.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=host+1:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 221 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) +
  fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=1)
Семейство 15: Silver / fake + fakeddisorder; вариант 7.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 222 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; неверная checksum; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; неверная checksum; pos=1)
Семейство 15: Silver / fake + fakeddisorder; вариант 8.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1:badsum

============================================================================
СТРАТЕГИЯ 223 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; неверная checksum) + fakeddisorder (перестановка + нулевые фейки;
  неверная checksum; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 9.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:badsum:repeats=1
--lua-desync=fakeddisorder:pos=host+1:badsum

============================================================================
СТРАТЕГИЯ 224 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; неверная checksum) + fakeddisorder (перестановка + нулевые
  фейки; неверная checksum; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 10.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:badsum:repeats=1
--lua-desync=fakeddisorder:pos=host+1:badsum

============================================================================
СТРАТЕГИЯ 225 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; неверная checksum) + fakeddisorder (перестановка + нулевые
  фейки; неверная checksum; pos=midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 11.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:badsum:repeats=1
--lua-desync=fakeddisorder:pos=midsld:badsum

============================================================================
СТРАТЕГИЯ 226 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; неверная checksum; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; неверная checksum; pos=midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 12.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=midsld:badsum

============================================================================
СТРАТЕГИЯ 227 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; неверная checksum) + fakeddisorder (перестановка + нулевые фейки;
  неверная checksum; pos=midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 13.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:badsum:repeats=1
--lua-desync=fakeddisorder:pos=midsld:badsum

============================================================================
СТРАТЕГИЯ 228 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; неверная checksum; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; неверная checksum; pos=1,midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 14.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:badsum

============================================================================
СТРАТЕГИЯ 229 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; неверная checksum) + fakeddisorder (перестановка + нулевые
  фейки; неверная checksum; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 15.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:badsum:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:badsum

============================================================================
СТРАТЕГИЯ 230 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; неверная checksum) + fakeddisorder (перестановка + нулевые фейки;
  неверная checksum; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 16.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:badsum:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:badsum

============================================================================
СТРАТЕГИЯ 231 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; неверная checksum) + fakeddisorder (перестановка + нулевые
  фейки; неверная checksum; pos=1,midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 17.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:badsum:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:badsum

============================================================================
СТРАТЕГИЯ 232 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги +SYN; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка
  + нулевые фейки; флаги +SYN; pos=midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 18.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=midsld:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 233 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги
  +SYN; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 19.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 234 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки;
  флаги +SYN; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 20.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_set=SYN:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 235 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги +SYN; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка
  + нулевые фейки; флаги +SYN; pos=1,midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 21.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 236 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги +SYN; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка
  + нулевые фейки; флаги +SYN; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 22.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 237 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги
  +SYN; pos=1,midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 23.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 238 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги +SYN; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка
  + нулевые фейки; флаги +SYN; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 24.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 239 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки;
  флаги +SYN; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 25.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_set=SYN:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 240 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки;
  флаги +SYN; pos=2)
Семейство 15: Silver / fake + fakeddisorder; вариант 26.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_set=SYN:repeats=1
--lua-desync=fakeddisorder:pos=2:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 241 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги -ACK) + fakeddisorder (перестановка + нулевые фейки; флаги
  -ACK; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 27.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 242 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + fakeddisorder (перестановка + нулевые фейки;
  флаги -ACK; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 28.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
--lua-desync=fakeddisorder:pos=host+1:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 243 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + fakeddisorder (перестановка + нулевые фейки;
  флаги -ACK; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 29.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 244 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги -ACK) + fakeddisorder (перестановка + нулевые фейки; флаги
  -ACK; pos=sniext+4)
Семейство 15: Silver / fake + fakeddisorder; вариант 30.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 245 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги -ACK) + fakeddisorder (перестановка + нулевые фейки; флаги
  -ACK; pos=2)
Семейство 15: Silver / fake + fakeddisorder; вариант 31.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:repeats=1
--lua-desync=fakeddisorder:pos=2:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 246 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги -ACK; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка
  + нулевые фейки; флаги -ACK; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 32.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 247 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + fakeddisorder (перестановка + нулевые фейки;
  флаги -ACK; pos=2)
Семейство 15: Silver / fake + fakeddisorder; вариант 33.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
--lua-desync=fakeddisorder:pos=2:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 248 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги -ACK; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка
  + нулевые фейки; флаги -ACK; pos=1)
Семейство 15: Silver / fake + fakeddisorder; вариант 34.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 249 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + fakeddisorder (перестановка + нулевые фейки;
  флаги -ACK; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 35.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 250 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakeddisorder (перестановка + нулевые фейки;
  TS=-1000; pos=1)
Семейство 15: Silver / fake + fakeddisorder; вариант 36.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
--lua-desync=fakeddisorder:pos=1:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 251 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) +
  fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 37.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 252 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) +
  fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 38.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=host+1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 253 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) +
  fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=1,midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 39.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 254 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) +
  fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=2)
Семейство 15: Silver / fake + fakeddisorder; вариант 40.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=2:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 255 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) +
  fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 41.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 256 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; неверная checksum) + fakeddisorder (перестановка + нулевые фейки;
  неверная checksum; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 42.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:badsum:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:badsum

============================================================================
СТРАТЕГИЯ 257 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; неверная checksum) + fakeddisorder (перестановка + нулевые
  фейки; неверная checksum; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 43.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:badsum:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:badsum

============================================================================
СТРАТЕГИЯ 258 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; неверная checksum; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; неверная checksum; pos=sniext+4)
Семейство 15: Silver / fake + fakeddisorder; вариант 44.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:badsum

============================================================================
СТРАТЕГИЯ 259 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; неверная checksum; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; неверная checksum;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 45.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:badsum

============================================================================
СТРАТЕГИЯ 260 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; неверная checksum) + fakeddisorder (перестановка + нулевые фейки;
  неверная checksum; pos=1,midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 46.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:badsum:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:badsum

============================================================================
СТРАТЕГИЯ 261 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги
  +SYN; pos=2)
Семейство 15: Silver / fake + fakeddisorder; вариант 47.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:repeats=1
--lua-desync=fakeddisorder:pos=2:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 262 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки;
  флаги +SYN; pos=sniext+4)
Семейство 15: Silver / fake + fakeddisorder; вариант 48.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_set=SYN:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 263 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги
  +SYN; pos=sniext+4)
Семейство 15: Silver / fake + fakeddisorder; вариант 49.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 264 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги -ACK; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка
  + нулевые фейки; флаги -ACK; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 50.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=host+1:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 265 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги -ACK) + fakeddisorder (перестановка + нулевые фейки; флаги
  -ACK; pos=midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 51.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:repeats=1
--lua-desync=fakeddisorder:pos=midsld:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 266 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги -ACK; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка
  + нулевые фейки; флаги -ACK; pos=midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 52.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=midsld:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 267 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TS=-1000; pos=sniext+4)
Семейство 15: Silver / fake + fakeddisorder; вариант 53.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 268 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) +
  fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+4)
Семейство 15: Silver / fake + fakeddisorder; вариант 54.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 269 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) +
  fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 55.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=midsld:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 270 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakeddisorder (перестановка
  + нулевые фейки; ACK=-66000; TS-опция первой; pos=2)
Семейство 15: Silver / fake + fakeddisorder; вариант 56.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fakeddisorder:pos=2:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 271 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakeddisorder (перестановка
  + нулевые фейки; ACK=-66000; TS-опция первой; pos=1)
Семейство 15: Silver / fake + fakeddisorder; вариант 57.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fakeddisorder:pos=1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 272 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakeddisorder (перестановка
  + нулевые фейки; ACK=-66000; TS-опция первой; pos=midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 58.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fakeddisorder:pos=midsld:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 273 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakeddisorder (перестановка
  + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 59.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 274 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakeddisorder (перестановка
  + нулевые фейки; ACK=-66000; TS-опция первой; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 60.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fakeddisorder:pos=host+1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 275 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakeddisorder (перестановка
  + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+4)
Семейство 15: Silver / fake + fakeddisorder; вариант 61.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 276 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakeddisorder (перестановка
  + нулевые фейки; ACK=-66000; TS-опция первой;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 62.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 277 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TCP MD5; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 63.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:tcp_md5

============================================================================
СТРАТЕГИЯ 278 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TCP MD5; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 64.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_md5

============================================================================
СТРАТЕГИЯ 279 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TCP MD5; pos=2)
Семейство 15: Silver / fake + fakeddisorder; вариант 65.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=2:tcp_md5

============================================================================
СТРАТЕГИЯ 280 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TCP MD5; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 66.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=host+1:tcp_md5

============================================================================
СТРАТЕГИЯ 281 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-2,3-20;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 67.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_autottl=-2,3-20

============================================================================
СТРАТЕГИЯ 282 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-3,3-20; pos=midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 68.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=midsld:ip_autottl=-3,3-20

============================================================================
СТРАТЕГИЯ 283 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-1,3-20;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 69.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_autottl=-1,3-20

============================================================================
СТРАТЕГИЯ 284 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-1,3-20; pos=1)
Семейство 15: Silver / fake + fakeddisorder; вариант 70.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1:ip_autottl=-1,3-20

============================================================================
СТРАТЕГИЯ 285 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-2,3-20; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 71.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:ip_autottl=-2,3-20

============================================================================
СТРАТЕГИЯ 286 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-1,3-20; pos=midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 72.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=midsld:ip_autottl=-1,3-20

============================================================================
СТРАТЕГИЯ 287 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-2,3-20; pos=midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 73.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=midsld:ip_autottl=-2,3-20

============================================================================
СТРАТЕГИЯ 288 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-2,3-20; pos=2)
Семейство 15: Silver / fake + fakeddisorder; вариант 74.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=2:ip_autottl=-2,3-20

============================================================================
СТРАТЕГИЯ 289 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-1,3-20; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 75.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=host+1:ip_autottl=-1,3-20

============================================================================
СТРАТЕГИЯ 290 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-2,3-20; pos=1)
Семейство 15: Silver / fake + fakeddisorder; вариант 76.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1:ip_autottl=-2,3-20

============================================================================
СТРАТЕГИЯ 291 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-2,3-20; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 77.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=host+1:ip_autottl=-2,3-20

============================================================================
СТРАТЕГИЯ 292 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-1,3-20; pos=1,midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 78.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:ip_autottl=-1,3-20

============================================================================
СТРАТЕГИЯ 293 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-1,3-20; pos=2)
Семейство 15: Silver / fake + fakeddisorder; вариант 79.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=2:ip_autottl=-1,3-20

============================================================================
СТРАТЕГИЯ 294 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-3,3-20; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 80.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=host+1:ip_autottl=-3,3-20

============================================================================
СТРАТЕГИЯ 295 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-3,3-20; pos=sniext+4)
Семейство 15: Silver / fake + fakeddisorder; вариант 81.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:ip_autottl=-3,3-20

============================================================================
СТРАТЕГИЯ 296 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-4,3-20; pos=2)
Семейство 15: Silver / fake + fakeddisorder; вариант 82.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=2:ip_autottl=-4,3-20

============================================================================
СТРАТЕГИЯ 297 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-2,3-20; pos=sniext+4)
Семейство 15: Silver / fake + fakeddisorder; вариант 83.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:ip_autottl=-2,3-20

============================================================================
СТРАТЕГИЯ 298 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-3,3-20; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 84.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:ip_autottl=-3,3-20

============================================================================
СТРАТЕГИЯ 299 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-3,3-20; pos=2)
Семейство 15: Silver / fake + fakeddisorder; вариант 85.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=2:ip_autottl=-3,3-20

============================================================================
СТРАТЕГИЯ 300 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-4,3-20; pos=1)
Семейство 15: Silver / fake + fakeddisorder; вариант 86.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1:ip_autottl=-4,3-20

============================================================================
СТРАТЕГИЯ 301 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-4,3-20;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 87.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_autottl=-4,3-20

============================================================================
СТРАТЕГИЯ 302 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-3,3-20; pos=1)
Семейство 15: Silver / fake + fakeddisorder; вариант 88.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1:ip_autottl=-3,3-20

============================================================================
СТРАТЕГИЯ 303 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-4,3-20; pos=1,midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 89.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:ip_autottl=-4,3-20

============================================================================
СТРАТЕГИЯ 304 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-5,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-5,3-20; pos=2)
Семейство 15: Silver / fake + fakeddisorder; вариант 90.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-5,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-5,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-5,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=2:ip_autottl=-5,3-20

============================================================================
СТРАТЕГИЯ 305 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-5,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-5,3-20; pos=sniext+4)
Семейство 15: Silver / fake + fakeddisorder; вариант 91.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-5,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-5,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-5,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:ip_autottl=-5,3-20

============================================================================
СТРАТЕГИЯ 306 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-5,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-5,3-20;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 92.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-5,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   ip_autottl=-5,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-5,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_autottl=-5,3-20

============================================================================
СТРАТЕГИЯ 307 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TTL=1; pos=midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 93.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=midsld:ip_ttl=1

============================================================================
СТРАТЕГИЯ 308 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TTL=1) + fakeddisorder (перестановка + нулевые фейки;
  TTL=1; pos=midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 94.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
--lua-desync=fakeddisorder:pos=midsld:ip_ttl=1

============================================================================
СТРАТЕГИЯ 309 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TTL=1) + fakeddisorder (перестановка + нулевые фейки;
  TTL=1; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 95.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:ip_ttl=1

============================================================================
СТРАТЕГИЯ 310 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TTL=1; pos=sniext+4)
Семейство 15: Silver / fake + fakeddisorder; вариант 96.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:ip_ttl=1

============================================================================
СТРАТЕГИЯ 311 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TTL=1; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 97.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:ip_ttl=1

============================================================================
СТРАТЕГИЯ 312 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=1) + fakeddisorder (перестановка + нулевые фейки; TTL=1;
  pos=midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 98.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:repeats=1
--lua-desync=fakeddisorder:pos=midsld:ip_ttl=1

============================================================================
СТРАТЕГИЯ 313 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=1) + fakeddisorder (перестановка + нулевые фейки; TTL=1;
  pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 99.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:ip_ttl=1

============================================================================
СТРАТЕГИЯ 314 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TTL=1; pos=1)
Семейство 15: Silver / fake + fakeddisorder; вариант 100.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1:ip_ttl=1

============================================================================
СТРАТЕГИЯ 315 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TTL=1; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 101.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=host+1:ip_ttl=1

============================================================================
СТРАТЕГИЯ 316 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=1) + fakeddisorder (перестановка + нулевые фейки; TTL=1;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 102.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_ttl=1

============================================================================
СТРАТЕГИЯ 317 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TTL=1; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 103.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_ttl=1

============================================================================
СТРАТЕГИЯ 318 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TTL=1) + fakeddisorder (перестановка + нулевые фейки;
  TTL=1; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 104.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
--lua-desync=fakeddisorder:pos=host+1:ip_ttl=1

============================================================================
СТРАТЕГИЯ 319 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TTL=1) + fakeddisorder (перестановка + нулевые фейки;
  TTL=1; pos=1,midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 105.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:ip_ttl=1

============================================================================
СТРАТЕГИЯ 320 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=1) + fakeddisorder (перестановка + нулевые фейки; TTL=1;
  pos=1,midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 106.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:ip_ttl=1

============================================================================
СТРАТЕГИЯ 321 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TTL=1; pos=1,midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 107.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:ip_ttl=1

============================================================================
СТРАТЕГИЯ 322 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakeddisorder (перестановка + нулевые фейки;
  SEQ=1000000; pos=1,midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 108.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 323 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakeddisorder (перестановка + нулевые фейки;
  SEQ=1000000; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 109.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 324 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakeddisorder (перестановка + нулевые фейки;
  SEQ=1000000; pos=1)
Семейство 15: Silver / fake + fakeddisorder; вариант 110.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fakeddisorder:pos=1:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 325 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakeddisorder (перестановка + нулевые фейки;
  SEQ=1000000; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 111.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fakeddisorder:pos=host+1:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 326 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakeddisorder (перестановка + нулевые фейки;
  SEQ=1000000; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 112.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 327 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; неверная checksum; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; неверная checksum; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 113.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=host+1:badsum

============================================================================
СТРАТЕГИЯ 328 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки;
  флаги +SYN; pos=1,midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 114.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_flags_set=SYN:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 329 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги
  +SYN; pos=1)
Семейство 15: Silver / fake + fakeddisorder; вариант 115.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:repeats=1
--lua-desync=fakeddisorder:pos=1:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 330 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги +SYN; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка
  + нулевые фейки; флаги +SYN; pos=1)
Семейство 15: Silver / fake + fakeddisorder; вариант 116.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 331 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги -ACK; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка
  + нулевые фейки; флаги -ACK; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 117.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 332 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги
  +SYN; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 118.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 333 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TS=-1000; pos=midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 119.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=midsld:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 334 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakeddisorder (перестановка + нулевые фейки;
  TS=-1000; pos=2)
Семейство 15: Silver / fake + fakeddisorder; вариант 120.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
--lua-desync=fakeddisorder:pos=2:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 335 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakeddisorder (перестановка + нулевые фейки;
  TS=-1000; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 121.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
--lua-desync=fakeddisorder:pos=host+1:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 336 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakeddisorder (перестановка + нулевые фейки;
  TS=-1000; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 15: Silver / fake + fakeddisorder; вариант 122.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 337 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TCP MD5; pos=1)
Семейство 15: Silver / fake + fakeddisorder; вариант 123.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=1:tcp_md5

============================================================================
СТРАТЕГИЯ 338 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка +
  нулевые фейки; TCP MD5; pos=sniext+4)
Семейство 15: Silver / fake + fakeddisorder; вариант 124.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:tcp_md5

============================================================================
СТРАТЕГИЯ 339 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-4,3-20; pos=midsld)
Семейство 15: Silver / fake + fakeddisorder; вариант 125.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=midsld:ip_autottl=-4,3-20

============================================================================
СТРАТЕГИЯ 340 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-5,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder
  (перестановка + нулевые фейки; AutoTTL=-5,3-20; pos=host+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 126.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-5,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-5,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-5,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakeddisorder:pos=host+1:ip_autottl=-5,3-20

============================================================================
СТРАТЕГИЯ 341 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=-3000) + fakeddisorder (перестановка + нулевые фейки;
  SEQ=-3000; pos=sniext+1)
Семейство 15: Silver / fake + fakeddisorder; вариант 127.
Цепочка обработчиков: fake + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=-3000:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:tcp_seq=-3000

============================================================================
СТРАТЕГИЯ 342 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakedsplit (разделение +
  нулевые фейки; TCP MD5; pos=sniext+4)
Семейство 16: Silver / fake + fakedsplit; вариант 1.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=sniext+4:tcp_md5

============================================================================
СТРАТЕГИЯ 343 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakedsplit (разделение +
  нулевые фейки; TCP MD5; pos=host+1)
Семейство 16: Silver / fake + fakedsplit; вариант 2.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=host+1:tcp_md5

============================================================================
СТРАТЕГИЯ 344 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakedsplit (разделение +
  нулевые фейки; TCP MD5; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 16: Silver / fake + fakedsplit; вариант 3.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_md5

============================================================================
СТРАТЕГИЯ 345 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakedsplit (разделение +
  нулевые фейки; TCP MD5; pos=1,midsld)
Семейство 16: Silver / fake + fakedsplit; вариант 4.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1,midsld:tcp_md5

============================================================================
СТРАТЕГИЯ 346 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakedsplit (разделение +
  нулевые фейки; TCP MD5; pos=sniext+1)
Семейство 16: Silver / fake + fakedsplit; вариант 5.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=sniext+1:tcp_md5

============================================================================
СТРАТЕГИЯ 347 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-1,3-20; pos=sniext+4)
Семейство 16: Silver / fake + fakedsplit; вариант 6.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=sniext+4:ip_autottl=-1,3-20

============================================================================
СТРАТЕГИЯ 348 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-1,3-20; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 16: Silver / fake + fakedsplit; вариант 7.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_autottl=-1,3-20

============================================================================
СТРАТЕГИЯ 349 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-1,3-20; pos=1,midsld)
Семейство 16: Silver / fake + fakedsplit; вариант 8.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1,midsld:ip_autottl=-1,3-20

============================================================================
СТРАТЕГИЯ 350 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=-3000) + fakedsplit (разделение + нулевые фейки;
  SEQ=-3000; pos=2)
Семейство 16: Silver / fake + fakedsplit; вариант 9.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=-3000:repeats=1
--lua-desync=fakedsplit:pos=2:tcp_seq=-3000

============================================================================
СТРАТЕГИЯ 351 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakedsplit (разделение + нулевые фейки;
  SEQ=1000000; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 16: Silver / fake + fakedsplit; вариант 10.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 352 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; SEQ=1000000; TLS=rnd,dupsid,padencap) + fakedsplit (разделение +
  нулевые фейки; SEQ=1000000; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 16: Silver / fake + fakedsplit; вариант 11.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 353 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakedsplit (разделение + нулевые фейки;
  SEQ=1000000; pos=sniext+1)
Семейство 16: Silver / fake + fakedsplit; вариант 12.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fakedsplit:pos=sniext+1:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 354 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakedsplit (разделение +
  нулевые фейки; TCP MD5; pos=midsld)
Семейство 16: Silver / fake + fakedsplit; вариант 13.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=midsld:tcp_md5

============================================================================
СТРАТЕГИЯ 355 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-1,3-20; pos=sniext+1)
Семейство 16: Silver / fake + fakedsplit; вариант 14.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=sniext+1:ip_autottl=-1,3-20

============================================================================
СТРАТЕГИЯ 356 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-1,3-20; pos=midsld)
Семейство 16: Silver / fake + fakedsplit; вариант 15.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=midsld:ip_autottl=-1,3-20

============================================================================
СТРАТЕГИЯ 357 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-1,3-20; pos=1)
Семейство 16: Silver / fake + fakedsplit; вариант 16.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1:ip_autottl=-1,3-20

============================================================================
СТРАТЕГИЯ 358 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-1,3-20; pos=2)
Семейство 16: Silver / fake + fakedsplit; вариант 17.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=2:ip_autottl=-1,3-20

============================================================================
СТРАТЕГИЯ 359 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=-3000) + fakedsplit (разделение + нулевые фейки;
  SEQ=-3000; pos=sniext+1)
Семейство 16: Silver / fake + fakedsplit; вариант 18.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=-3000:repeats=1
--lua-desync=fakedsplit:pos=sniext+1:tcp_seq=-3000

============================================================================
СТРАТЕГИЯ 360 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=-3000) + fakedsplit (разделение + нулевые фейки;
  SEQ=-3000; pos=host+1)
Семейство 16: Silver / fake + fakedsplit; вариант 19.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=-3000:repeats=1
--lua-desync=fakedsplit:pos=host+1:tcp_seq=-3000

============================================================================
СТРАТЕГИЯ 361 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakedsplit (разделение + нулевые фейки;
  SEQ=1000000; pos=2)
Семейство 16: Silver / fake + fakedsplit; вариант 20.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fakedsplit:pos=2:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 362 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; SEQ=1000000; TLS=rnd,dupsid,padencap) + fakedsplit (разделение +
  нулевые фейки; SEQ=1000000; pos=2)
Семейство 16: Silver / fake + fakedsplit; вариант 21.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=2:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 363 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakedsplit (разделение +
  нулевые фейки; TS=-1000; pos=sniext+1)
Семейство 16: Silver / fake + fakedsplit; вариант 22.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=sniext+1:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 364 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakedsplit (разделение +
  нулевые фейки; TS=-1000; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 16: Silver / fake + fakedsplit; вариант 23.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 365 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakedsplit (разделение +
  нулевые фейки; TS=-1000; pos=host+1)
Семейство 16: Silver / fake + fakedsplit; вариант 24.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=host+1:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 366 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakedsplit (разделение + нулевые фейки;
  TS=-1000; pos=midsld)
Семейство 16: Silver / fake + fakedsplit; вариант 25.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
--lua-desync=fakedsplit:pos=midsld:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 367 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakedsplit (разделение + нулевые фейки;
  TS=-1000; pos=1,midsld)
Семейство 16: Silver / fake + fakedsplit; вариант 26.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
--lua-desync=fakedsplit:pos=1,midsld:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 368 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakedsplit (разделение + нулевые фейки;
  TS=-1000; pos=1)
Семейство 16: Silver / fake + fakedsplit; вариант 27.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
--lua-desync=fakedsplit:pos=1:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 369 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakedsplit (разделение + нулевые фейки;
  TS=-1000; pos=2)
Семейство 16: Silver / fake + fakedsplit; вариант 28.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
--lua-desync=fakedsplit:pos=2:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 370 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakedsplit (разделение + нулевые фейки;
  TS=-1000; pos=host+1)
Семейство 16: Silver / fake + fakedsplit; вариант 29.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
--lua-desync=fakedsplit:pos=host+1:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 371 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakedsplit
  (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=1,midsld)
Семейство 16: Silver / fake + fakedsplit; вариант 30.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1,midsld:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 372 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakedsplit
  (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=1)
Семейство 16: Silver / fake + fakedsplit; вариант 31.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 373 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakedsplit
  (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=midsld)
Семейство 16: Silver / fake + fakedsplit; вариант 32.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=midsld:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 374 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakedsplit
  (разделение + нулевые фейки; ACK=-66000; TS-опция первой;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 16: Silver / fake + fakedsplit; вариант 33.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 375 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakedsplit
  (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=host+1)
Семейство 16: Silver / fake + fakedsplit; вариант 34.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=host+1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 376 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakedsplit
  (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+4)
Семейство 16: Silver / fake + fakedsplit; вариант 35.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=sniext+4:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 377 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakedsplit
  (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+1)
Семейство 16: Silver / fake + fakedsplit; вариант 36.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=sniext+1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 378 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakedsplit (разделение +
  нулевые фейки; ACK=-66000; TS-опция первой; pos=midsld)
Семейство 16: Silver / fake + fakedsplit; вариант 37.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fakedsplit:pos=midsld:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 379 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakedsplit (разделение +
  нулевые фейки; ACK=-66000; TS-опция первой;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 16: Silver / fake + fakedsplit; вариант 38.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 380 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakedsplit (разделение +
  нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+4)
Семейство 16: Silver / fake + fakedsplit; вариант 39.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fakedsplit:pos=sniext+4:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 381 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakedsplit (разделение +
  нулевые фейки; TCP MD5; pos=2)
Семейство 16: Silver / fake + fakedsplit; вариант 40.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=2:tcp_md5

============================================================================
СТРАТЕГИЯ 382 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakedsplit (разделение + нулевые фейки;
  SEQ=1000000; pos=1)
Семейство 16: Silver / fake + fakedsplit; вариант 41.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fakedsplit:pos=1:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 383 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakedsplit (разделение + нулевые фейки;
  SEQ=1000000; pos=sniext+4)
Семейство 16: Silver / fake + fakedsplit; вариант 42.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
--lua-desync=fakedsplit:pos=sniext+4:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 384 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakedsplit (разделение +
  нулевые фейки; TS=-1000; pos=2)
Семейство 16: Silver / fake + fakedsplit; вариант 43.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=2:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 385 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakedsplit (разделение +
  нулевые фейки; TS=-1000; pos=1)
Семейство 16: Silver / fake + fakedsplit; вариант 44.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 386 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakedsplit
  (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=2)
Семейство 16: Silver / fake + fakedsplit; вариант 45.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=2:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 387 — Silver
============================================================================
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakedsplit (разделение +
  нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+1)
Семейство 16: Silver / fake + fakedsplit; вариант 46.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Отдельный фейк из четырёх нулевых байтов. Это не TLS ClientHello и собственного SNI у него нет.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
--lua-desync=fakedsplit:pos=sniext+1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 388 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-2,3-20; pos=sniext+4)
Семейство 16: Silver / fake + fakedsplit; вариант 47.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=sniext+4:ip_autottl=-2,3-20

============================================================================
СТРАТЕГИЯ 389 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-2,3-20; pos=1)
Семейство 16: Silver / fake + fakedsplit; вариант 48.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1:ip_autottl=-2,3-20

============================================================================
СТРАТЕГИЯ 390 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-4,3-20; pos=host+1)
Семейство 16: Silver / fake + fakedsplit; вариант 49.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=host+1:ip_autottl=-4,3-20

============================================================================
СТРАТЕГИЯ 391 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-4,3-20; pos=sniext+4)
Семейство 16: Silver / fake + fakedsplit; вариант 50.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=sniext+4:ip_autottl=-4,3-20

============================================================================
СТРАТЕГИЯ 392 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-3,3-20; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 16: Silver / fake + fakedsplit; вариант 51.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_autottl=-3,3-20

============================================================================
СТРАТЕГИЯ 393 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-4,3-20; pos=sniext+1)
Семейство 16: Silver / fake + fakedsplit; вариант 52.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=sniext+1:ip_autottl=-4,3-20

============================================================================
СТРАТЕГИЯ 394 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-4,3-20; pos=1,midsld)
Семейство 16: Silver / fake + fakedsplit; вариант 53.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1,midsld:ip_autottl=-4,3-20

============================================================================
СТРАТЕГИЯ 395 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-4,3-20; pos=1)
Семейство 16: Silver / fake + fakedsplit; вариант 54.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1:ip_autottl=-4,3-20

============================================================================
СТРАТЕГИЯ 396 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-3,3-20; pos=midsld)
Семейство 16: Silver / fake + fakedsplit; вариант 55.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=midsld:ip_autottl=-3,3-20

============================================================================
СТРАТЕГИЯ 397 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-3,3-20; pos=host+1)
Семейство 16: Silver / fake + fakedsplit; вариант 56.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=host+1:ip_autottl=-3,3-20

============================================================================
СТРАТЕГИЯ 398 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-3,3-20; pos=sniext+1)
Семейство 16: Silver / fake + fakedsplit; вариант 57.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=sniext+1:ip_autottl=-3,3-20

============================================================================
СТРАТЕГИЯ 399 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-3,3-20; pos=1)
Семейство 16: Silver / fake + fakedsplit; вариант 58.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-3,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1:ip_autottl=-3,3-20

============================================================================
СТРАТЕГИЯ 400 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-4,3-20; pos=midsld)
Семейство 16: Silver / fake + fakedsplit; вариант 59.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=midsld:ip_autottl=-4,3-20

============================================================================
СТРАТЕГИЯ 401 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые
  фейки; TTL=6; pos=sniext+1)
Семейство 16: Silver / fake + fakedsplit; вариант 60.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=6: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=6: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=sniext+1:ip_ttl=6

============================================================================
СТРАТЕГИЯ 402 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые
  фейки; TTL=6; pos=2)
Семейство 16: Silver / fake + fakedsplit; вариант 61.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=6: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=6: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=2:ip_ttl=6

============================================================================
СТРАТЕГИЯ 403 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые
  фейки; TTL=6; pos=midsld)
Семейство 16: Silver / fake + fakedsplit; вариант 62.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=6: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=6: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=midsld:ip_ttl=6

============================================================================
СТРАТЕГИЯ 404 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые
  фейки; TTL=6; pos=1,midsld)
Семейство 16: Silver / fake + fakedsplit; вариант 63.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=6: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=6: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1,midsld:ip_ttl=6

============================================================================
СТРАТЕГИЯ 405 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые
  фейки; TTL=6; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 16: Silver / fake + fakedsplit; вариант 64.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_ttl=6: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   ip_ttl=6: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_ttl=6

============================================================================
СТРАТЕГИЯ 406 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-2,3-20; pos=2)
Семейство 16: Silver / fake + fakedsplit; вариант 65.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=2:ip_autottl=-2,3-20

============================================================================
СТРАТЕГИЯ 407 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-4,3-20; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 16: Silver / fake + fakedsplit; вариант 66.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   ip_autottl=-4,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_autottl=-4,3-20

============================================================================
СТРАТЕГИЯ 408 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение
  + нулевые фейки; AutoTTL=-2,3-20; pos=sniext+1)
Семейство 16: Silver / fake + fakedsplit; вариант 67.
Цепочка обработчиков: fake + fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   ip_autottl=-2,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=fakedsplit:pos=sniext+1:ip_autottl=-2,3-20

============================================================================
СТРАТЕГИЯ 409 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + hostfakesplit (фейковые
  вставки в SNI; случайный host; TS=-1000; перестановка после SNI; без второго фейка)
Семейство 17: Silver / fake + hostfakesplit; вариант 1.
Цепочка обработчиков: fake + hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   nofake2: вторая фейковая вставка hostfakesplit отключена.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=hostfakesplit:disorder_after:nofake2:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 410 — Silver
============================================================================
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + tcpseg (добавочный TCP-
  сегмент; IP ID=rnd; pos=0,1)
Семейство 18: Silver / fake + tcpseg; вариант 1.
Цепочка обработчиков: fake + tcpseg.

ПОШАГОВЫЙ СОСТАВ
1. fake
   Перед настоящим ClientHello отправляется отдельный TLS-фейк из штатного шаблона Zapret2.
   SNI фейка берётся из fake_default_tls. В закреплённой совместимой сборке это www.microsoft.com;
   при выборе последней версии используется шаблон загруженной сборки.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   tls_mod=rnd,dupsid,padencap: модификаторы TLS-фейка применяются в контексте этого шага.
   rnd: обновляются случайные поля TLS-фейка (Random и Session ID).
   dupsid: Session ID настоящего ClientHello копируется в фейк, когда структуры это позволяют.
   padencap: длины TLS/padding в заголовках фейка увеличиваются с учётом размера настоящего
   ClientHello; это не команда скачать или дописать столько данных.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. tcpseg
   Отправляется дополнительный TCP-сегмент с выбранным диапазоном настоящего ClientHello. Сам tcpseg
   не заменяет исходный ClientHello целиком.
   Диапазон дополнительного сегмента: pos=0,1. Расшифровка маркеров приведена в начале справочника.
   ip_id=rnd: IPv4 Identification формируется случайным образом.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
--lua-desync=tcpseg:pos=0,1:ip_id=rnd:repeats=1

============================================================================
СТРАТЕГИЯ 411 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; TS=-1000; pos=host+1)
Семейство 19: Silver / fakedsplit; вариант 1.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=host+1:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 412 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; TS=-1000; pos=sniext+4)
Семейство 19: Silver / fakedsplit; вариант 2.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=sniext+4:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 413 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; TS=-1000; pos=sniext+1)
Семейство 19: Silver / fakedsplit; вариант 3.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=sniext+1:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 414 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; TS=-1000; pos=1)
Семейство 19: Silver / fakedsplit; вариант 4.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=1:tcp_ts=-1000

============================================================================
СТРАТЕГИЯ 415 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=midsld)
Семейство 19: Silver / fakedsplit; вариант 5.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=midsld:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 416 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+4)
Семейство 19: Silver / fakedsplit; вариант 6.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=sniext+4:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 417 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=host+1)
Семейство 19: Silver / fakedsplit; вариант 7.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=host+1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 418 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+1)
Семейство 19: Silver / fakedsplit; вариант 8.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=sniext+1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 419 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=1)
Семейство 19: Silver / fakedsplit; вариант 9.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 420 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=1,midsld)
Семейство 19: Silver / fakedsplit; вариант 10.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=1,midsld:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 421 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 19: Silver / fakedsplit; вариант 11.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 422 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=2)
Семейство 19: Silver / fakedsplit; вариант 12.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=2:tcp_ack=-66000:tcp_ts_up

============================================================================
СТРАТЕГИЯ 423 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; SEQ=-3000; pos=host+1)
Семейство 19: Silver / fakedsplit; вариант 13.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=host+1:tcp_seq=-3000

============================================================================
СТРАТЕГИЯ 424 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; SEQ=1000000; pos=sniext+4)
Семейство 19: Silver / fakedsplit; вариант 14.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=sniext+4:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 425 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; SEQ=1000000; pos=1)
Семейство 19: Silver / fakedsplit; вариант 15.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=1:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 426 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; SEQ=1000000; pos=2)
Семейство 19: Silver / fakedsplit; вариант 16.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: 1000000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=2:tcp_seq=1000000

============================================================================
СТРАТЕГИЯ 427 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; SEQ=-3000;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 19: Silver / fakedsplit; вариант 17.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_seq=-3000

============================================================================
СТРАТЕГИЯ 428 — Silver
============================================================================
Название: fakedsplit (разделение + нулевые фейки; SEQ=-3000; pos=1,midsld)
Семейство 19: Silver / fakedsplit; вариант 18.
Цепочка обработчиков: fakedsplit.

ПОШАГОВЫЙ СОСТАВ
1. fakedsplit
   Настоящий ClientHello делится на две части; рядом с настоящими частями отправляются нулевые
   фейковые данные. Порядок настоящих частей сохраняется.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   Смещение TCP SEQ: -3000; меняется номер последовательности отправляемого пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=fakedsplit:pos=1,midsld:tcp_seq=-3000

============================================================================
СТРАТЕГИЯ 429 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TS=-1000; перестановка после SNI;
  без второго фейка)
Семейство 20: Silver / hostfakesplit; вариант 1.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   nofake2: вторая фейковая вставка hostfakesplit отключена.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:disorder_after:nofake2:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 430 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TS=-1000; без второго фейка)
Семейство 20: Silver / hostfakesplit; вариант 2.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   nofake2: вторая фейковая вставка hostfakesplit отключена.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:nofake2:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 431 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TS=-1000)
Семейство 20: Silver / hostfakesplit; вариант 3.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 432 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TS=-1000; midhost=midsld; без
  второго фейка)
Семейство 20: Silver / hostfakesplit; вариант 4.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   nofake2: вторая фейковая вставка hostfakesplit отключена.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:nofake2:midhost=midsld:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 433 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TS=-1000; midhost=midsld;
  перестановка после SNI; без второго фейка)
Семейство 20: Silver / hostfakesplit; вариант 5.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   nofake2: вторая фейковая вставка hostfakesplit отключена.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:disorder_after:nofake2:midhost=midsld:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 434 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; ACK=-66000; TS-опция первой;
  перестановка после SNI)
Семейство 20: Silver / hostfakesplit; вариант 6.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:disorder_after:tcp_ack=-66000:tcp_ts_up:repeats=1

============================================================================
СТРАТЕГИЯ 435 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; ACK=-66000; TS-опция первой)
Семейство 20: Silver / hostfakesplit; вариант 7.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:tcp_ack=-66000:tcp_ts_up:repeats=1

============================================================================
СТРАТЕГИЯ 436 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TCP MD5; перестановка после SNI)
Семейство 20: Silver / hostfakesplit; вариант 8.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:disorder_after:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 437 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TCP MD5)
Семейство 20: Silver / hostfakesplit; вариант 9.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 438 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TS=-1000; midhost=midsld;
  перестановка после SNI)
Семейство 20: Silver / hostfakesplit; вариант 10.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:disorder_after:midhost=midsld:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 439 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; ACK=-66000; TS-опция первой;
  midhost=midsld)
Семейство 20: Silver / hostfakesplit; вариант 11.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:midhost=midsld:tcp_ack=-66000:tcp_ts_up:repeats=1

============================================================================
СТРАТЕГИЯ 440 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; ACK=-66000; TS-опция первой;
  midhost=midsld; перестановка после SNI)
Семейство 20: Silver / hostfakesplit; вариант 12.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:disorder_after:midhost=midsld:tcp_ack=-66000:tcp_ts_up:repeats=1

============================================================================
СТРАТЕГИЯ 441 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TCP MD5; без второго фейка)
Семейство 20: Silver / hostfakesplit; вариант 13.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   nofake2: вторая фейковая вставка hostfakesplit отключена.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:nofake2:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 442 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TS=-1000; перестановка после SNI)
Семейство 20: Silver / hostfakesplit; вариант 14.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   Смещение TCP Timestamp: -1000; применяется, когда Timestamp присутствует в TCP-заголовке.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:disorder_after:tcp_ts=-1000:repeats=1

============================================================================
СТРАТЕГИЯ 443 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TCP MD5; midhost=midsld)
Семейство 20: Silver / hostfakesplit; вариант 15.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:midhost=midsld:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 444 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TCP MD5; midhost=midsld;
  перестановка после SNI)
Семейство 20: Silver / hostfakesplit; вариант 16.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:disorder_after:midhost=midsld:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 445 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TCP MD5; midhost=midsld; без
  второго фейка)
Семейство 20: Silver / hostfakesplit; вариант 17.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   nofake2: вторая фейковая вставка hostfakesplit отключена.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:nofake2:midhost=midsld:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 446 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; AutoTTL=-1,3-20; перестановка после
  SNI)
Семейство 20: Silver / hostfakesplit; вариант 18.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:disorder_after:ip_autottl=-1,3-20:repeats=1

============================================================================
СТРАТЕГИЯ 447 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; AutoTTL=-1,3-20; перестановка после
  SNI; без второго фейка)
Семейство 20: Silver / hostfakesplit; вариант 19.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   nofake2: вторая фейковая вставка hostfakesplit отключена.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:disorder_after:nofake2:ip_autottl=-1,3-20:repeats=1

============================================================================
СТРАТЕГИЯ 448 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; AutoTTL=-1,3-20; без второго фейка)
Семейство 20: Silver / hostfakesplit; вариант 20.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   nofake2: вторая фейковая вставка hostfakesplit отключена.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:nofake2:ip_autottl=-1,3-20:repeats=1

============================================================================
СТРАТЕГИЯ 449 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; AutoTTL=-1,3-20)
Семейство 20: Silver / hostfakesplit; вариант 21.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:ip_autottl=-1,3-20:repeats=1

============================================================================
СТРАТЕГИЯ 450 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; AutoTTL=-1,3-20; midhost=midsld;
  перестановка после SNI; без второго фейка)
Семейство 20: Silver / hostfakesplit; вариант 22.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   nofake2: вторая фейковая вставка hostfakesplit отключена.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:disorder_after:nofake2:midhost=midsld:ip_autottl=-1,3-20:repeats=1

============================================================================
СТРАТЕГИЯ 451 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; ACK=-66000; TS-опция первой;
  перестановка после SNI; без второго фейка)
Семейство 20: Silver / hostfakesplit; вариант 23.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   nofake2: вторая фейковая вставка hostfakesplit отключена.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:disorder_after:nofake2:tcp_ack=-66000:tcp_ts_up:repeats=1

============================================================================
СТРАТЕГИЯ 452 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TCP MD5; перестановка после SNI;
  без второго фейка)
Семейство 20: Silver / hostfakesplit; вариант 24.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   nofake2: вторая фейковая вставка hostfakesplit отключена.
   tcp_md5: добавляется TCP MD5 Signature option. Это TCP-опция, а не шифрование трафика.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:disorder_after:nofake2:tcp_md5:repeats=1

============================================================================
СТРАТЕГИЯ 453 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; AutoTTL=-1,3-20; midhost=midsld;
  перестановка после SNI)
Семейство 20: Silver / hostfakesplit; вариант 25.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   ip_autottl=-1,3-20: TTL рассчитывается по оценке пути с указанным смещением и пределами.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:disorder_after:midhost=midsld:ip_autottl=-1,3-20:repeats=1

============================================================================
СТРАТЕГИЯ 454 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; ACK=-66000; TS-опция первой; без
  второго фейка)
Семейство 20: Silver / hostfakesplit; вариант 26.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   nofake2: вторая фейковая вставка hostfakesplit отключена.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:nofake2:tcp_ack=-66000:tcp_ts_up:repeats=1

============================================================================
СТРАТЕГИЯ 455 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; ACK=-66000; TS-опция первой;
  midhost=midsld; перестановка после SNI; без второго фейка)
Семейство 20: Silver / hostfakesplit; вариант 27.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   disorder_after: участок после SNI отправляется с дополнительной перестановкой частей;
   используется штатный маркер -1.
   nofake2: вторая фейковая вставка hostfakesplit отключена.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:disorder_after:nofake2:midhost=midsld:tcp_ack=-66000:tcp_ts_up:repeats=1

============================================================================
СТРАТЕГИЯ 456 — Silver
============================================================================
Название: hostfakesplit (фейковые вставки в SNI; случайный host; ACK=-66000; TS-опция первой;
  midhost=midsld; без второго фейка)
Семейство 20: Silver / hostfakesplit; вариант 28.
Цепочка обработчиков: hostfakesplit.

ПОШАГОВЫЙ СОСТАВ
1. hostfakesplit
   Выделяется участок настоящего ClientHello с SNI. Отправляются части настоящего ClientHello и
   фейковые вставки на месте имени.
   host явно не задан: используется автоматически сгенерированное фейковое имя. SNI Microsoft этому
   обработчику не приписывается.
   Отклонение и repeats относятся к фейковым вставкам; настоящий SNI соединения восстанавливается из
   настоящих частей.
   nofake2: вторая фейковая вставка hostfakesplit отключена.
   midhost=midsld: сам настоящий участок SNI дополнительно делится по этому маркеру.
   Смещение TCP ACK: -66000; меняется номер подтверждения отправляемого пакета.
   tcp_ts_up: уже имеющаяся Timestamp-опция перемещается в начало TCP-опций. Это не увеличение
   Timestamp.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=hostfakesplit:nofake2:midhost=midsld:tcp_ack=-66000:tcp_ts_up:repeats=1

============================================================================
СТРАТЕГИЯ 457 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; TTL=1; pos=2; nodrop) + fakeddisorder (перестановка +
  нулевые фейки; TTL=1; pos=sniext+4)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 1.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:ip_ttl=1:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:ip_ttl=1

============================================================================
СТРАТЕГИЯ 458 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; TTL=1; pos=2; nodrop) + fakeddisorder (перестановка +
  нулевые фейки; TTL=1; pos=sniext+1)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 2.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:ip_ttl=1:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:ip_ttl=1

============================================================================
СТРАТЕГИЯ 459 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; TTL=1; pos=2; nodrop) + fakeddisorder (перестановка +
  нулевые фейки; TTL=1; pos=2)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 3.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:ip_ttl=1:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=2:ip_ttl=1

============================================================================
СТРАТЕГИЯ 460 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; TTL=1; pos=2; nodrop) + fakeddisorder (перестановка +
  нулевые фейки; TTL=1; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 4.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:ip_ttl=1:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_ttl=1

============================================================================
СТРАТЕГИЯ 461 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; TTL=1; pos=2; nodrop) + fakeddisorder (перестановка +
  нулевые фейки; TTL=1; pos=1,midsld)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 5.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:ip_ttl=1:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:ip_ttl=1

============================================================================
СТРАТЕГИЯ 462 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; TTL=1; pos=2; nodrop) + fakeddisorder (перестановка +
  нулевые фейки; TTL=1; pos=host+1)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 6.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:ip_ttl=1:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=host+1:ip_ttl=1

============================================================================
СТРАТЕГИЯ 463 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; неверная checksum; pos=2; nodrop) + fakeddisorder
  (перестановка + нулевые фейки; неверная checksum; pos=1)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 7.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:badsum:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=1:badsum

============================================================================
СТРАТЕГИЯ 464 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; TTL=1; pos=2; nodrop) + fakeddisorder (перестановка +
  нулевые фейки; TTL=1; pos=1)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 8.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:ip_ttl=1:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=1:ip_ttl=1

============================================================================
СТРАТЕГИЯ 465 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; неверная checksum; pos=2; nodrop) + fakeddisorder
  (перестановка + нулевые фейки; неверная checksum; pos=midsld)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 9.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:badsum:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=midsld:badsum

============================================================================
СТРАТЕГИЯ 466 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; неверная checksum; pos=2; nodrop) + fakeddisorder
  (перестановка + нулевые фейки; неверная checksum; pos=host+1)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 10.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=host+1. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:badsum:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=host+1:badsum

============================================================================
СТРАТЕГИЯ 467 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; неверная checksum; pos=2; nodrop) + fakeddisorder
  (перестановка + нулевые фейки; неверная checksum;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 11.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:badsum:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:badsum

============================================================================
СТРАТЕГИЯ 468 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; неверная checksum; pos=2; nodrop) + fakeddisorder
  (перестановка + нулевые фейки; неверная checksum; pos=1,midsld)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 12.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   badsum: формируется неверная контрольная сумма транспортного пакета.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   badsum: формируется неверная контрольная сумма транспортного пакета.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:badsum:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:badsum

============================================================================
СТРАТЕГИЯ 469 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; флаги +SYN; pos=2; nodrop) + fakeddisorder
  (перестановка + нулевые фейки; флаги +SYN; pos=midsld)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 13.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:tcp_flags_set=SYN:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=midsld:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 470 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; флаги +SYN; pos=2; nodrop) + fakeddisorder
  (перестановка + нулевые фейки; флаги +SYN;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 14.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:tcp_flags_set=SYN:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 471 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; флаги +SYN; pos=2; nodrop) + fakeddisorder
  (перестановка + нулевые фейки; флаги +SYN; pos=1,midsld)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 15.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:tcp_flags_set=SYN:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=1,midsld:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 472 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; флаги +SYN; pos=2; nodrop) + fakeddisorder
  (перестановка + нулевые фейки; флаги +SYN; pos=sniext+1)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 16.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:tcp_flags_set=SYN:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 473 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; флаги +SYN; pos=2; nodrop) + fakeddisorder
  (перестановка + нулевые фейки; флаги +SYN; pos=sniext+4)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 17.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:tcp_flags_set=SYN:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 474 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; флаги +SYN; pos=2; nodrop) + fakeddisorder
  (перестановка + нулевые фейки; флаги +SYN; pos=2)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 18.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_set=SYN: указанные TCP-флаги устанавливаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:tcp_flags_set=SYN:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=2:tcp_flags_set=SYN

============================================================================
СТРАТЕГИЯ 475 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; флаги -ACK; pos=2; nodrop) + fakeddisorder
  (перестановка + нулевые фейки; флаги -ACK; pos=midsld)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 19.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:tcp_flags_unset=ACK:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=midsld:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 476 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; флаги -ACK; pos=2; nodrop) + fakeddisorder
  (перестановка + нулевые фейки; флаги -ACK; pos=sniext+1)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 20.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+1. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:tcp_flags_unset=ACK:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 477 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; флаги -ACK; pos=2; nodrop) + fakeddisorder
  (перестановка + нулевые фейки; флаги -ACK; pos=sniext+4)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 21.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=sniext+4. Расшифровка маркеров приведена в начале справочника.
   tcp_flags_unset=ACK: указанные TCP-флаги снимаются.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:tcp_flags_unset=ACK:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=sniext+4:tcp_flags_unset=ACK

============================================================================
СТРАТЕГИЯ 478 — Silver
============================================================================
Название: Разделённый TLS-фейк (штатный SNI; TTL=1; pos=2; nodrop) + fakeddisorder (перестановка +
  нулевые фейки; TTL=1; pos=midsld)
Семейство 21: Silver / multisplit + fakeddisorder; вариант 22.
Цепочка обработчиков: multisplit + fakeddisorder.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Штатный TLS-фейк отправляется несколькими TCP-частями. Это подготовительная отправка фейка;
   следующий шаг цепочки обрабатывает настоящий ClientHello.
   SNI фейка берётся из fake_default_tls; в закреплённой совместимой сборке это www.microsoft.com.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.
   Точки разделения: pos=2. Расшифровка маркеров приведена в начале справочника.
   nodrop: этот шаг не отбрасывает исходные данные; следующий обработчик цепочки может обработать
   настоящий ClientHello.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.
2. fakeddisorder
   Настоящий ClientHello делится на две части; вторая отправляется раньше первой. Дополнительно
   отправляются нулевые фейки.
   Параметры отклонения этого обработчика относятся к его фейкам; tcp_ts_up и IP ID также
   учитываются обработчиком для настоящих частей.
   Точки разделения: pos=midsld. Расшифровка маркеров приведена в начале справочника.
   ip_ttl=1: фиксированное значение IPv4 TTL; при AutoTTL служит исходной настройкой.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:blob=fake_default_tls:ip_ttl=1:pos=2:nodrop:repeats=1
--lua-desync=fakeddisorder:pos=midsld:ip_ttl=1

============================================================================
СТРАТЕГИЯ 479 — Silver
============================================================================
Название: tcpseg (добавочный TCP-сегмент; IP ID=rnd; pos=0,1)
Семейство 22: Silver / tcpseg; вариант 1.
Цепочка обработчиков: tcpseg.

ПОШАГОВЫЙ СОСТАВ
1. tcpseg
   Отправляется дополнительный TCP-сегмент с выбранным диапазоном настоящего ClientHello. Сам tcpseg
   не заменяет исходный ClientHello целиком.
   Диапазон дополнительного сегмента: pos=0,1. Расшифровка маркеров приведена в начале справочника.
   ip_id=rnd: IPv4 Identification формируется случайным образом.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=tcpseg:pos=0,1:ip_id=rnd:repeats=1

============================================================================
СТРАТЕГИЯ 480 — Silver
============================================================================
Название: tcpseg (добавочный TCP-сегмент; IP ID=rnd; pos=0,midsld)
Семейство 22: Silver / tcpseg; вариант 2.
Цепочка обработчиков: tcpseg.

ПОШАГОВЫЙ СОСТАВ
1. tcpseg
   Отправляется дополнительный TCP-сегмент с выбранным диапазоном настоящего ClientHello. Сам tcpseg
   не заменяет исходный ClientHello целиком.
   Диапазон дополнительного сегмента: pos=0,midsld. Расшифровка маркеров приведена в начале
   справочника.
   ip_id=rnd: IPv4 Identification формируется случайным образом.
   repeats=1: для этого шага явно задана одна отправка каждой создаваемой части/фейка.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=tcpseg:pos=0,midsld:ip_id=rnd:repeats=1

============================================================================
СТРАТЕГИЯ 481 — Silver
============================================================================
Название: multisplit (ClientHello по частям; pos=1,midsld; seqovl=2048)
Семейство 23: Silver / Большой TLS-префикс / multisplit; вариант 1.
Цепочка обработчиков: multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   seqovl=2048: задано перекрытие TCP-последовательности с нулевым заполнением. Применимость зависит
   от разрешённых точек и обработчика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:pos=1,midsld:seqovl=2048

============================================================================
СТРАТЕГИЯ 482 — Silver
============================================================================
Название: multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1; seqovl=1024)
Семейство 23: Silver / Большой TLS-префикс / multisplit; вариант 2.
Цепочка обработчиков: multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   seqovl=1024: задано перекрытие TCP-последовательности с нулевым заполнением. Применимость зависит
   от разрешённых точек и обработчика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:seqovl=1024

============================================================================
СТРАТЕГИЯ 483 — Silver
============================================================================
Название: multisplit (ClientHello по частям;
  pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1; seqovl=2048)
Семейство 23: Silver / Большой TLS-префикс / multisplit; вариант 3.
Цепочка обработчиков: multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1. Расшифровка маркеров
   приведена в начале справочника.
   seqovl=2048: задано перекрытие TCP-последовательности с нулевым заполнением. Применимость зависит
   от разрешённых точек и обработчика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:seqovl=2048

============================================================================
СТРАТЕГИЯ 484 — Silver
============================================================================
Название: multisplit (ClientHello по частям; pos=1,midsld; seqovl=1024)
Семейство 23: Silver / Большой TLS-префикс / multisplit; вариант 4.
Цепочка обработчиков: multisplit.

ПОШАГОВЫЙ СОСТАВ
1. multisplit
   Настоящий ClientHello разбивается на TCP-части и отправляется в обычном порядке. Это сегментация
   TCP, а не замена настоящего SNI.
   Точки разделения: pos=1,midsld. Расшифровка маркеров приведена в начале справочника.
   seqovl=1024: задано перекрытие TCP-последовательности с нулевым заполнением. Применимость зависит
   от разрешённых точек и обработчика.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--payload=tls_client_hello
--lua-desync=multisplit:pos=1,midsld:seqovl=1024


====================================================================================================
ИСТОЧНИКИ И ЛИЦЕНЗИИ
Программа AntiDPI со стратегиями [Linux/Windows]: https://github.com/igareck/anti-dpi-for-russia
VPN/Tor Черные Списки: https://github.com/igareck/vpn-configs-for-russia
Официальный Zapret2 Bol-Van [Windows]: https://github.com/bol-van/zapret-win-bundle
Telegram: https://t.me/igareq
Contact person: Igor Krauch 
Email: igareck@proton.me
====================================================================================================

============================================================================
SYN-DATA И TCP WINDOW-SIZE — НОВЫЕ ЭКСПЕРИМЕНТАЛЬНЫЕ СТРАТЕГИИ
============================================================================
Семейство 24 добавляет две техники из закреплённой версии Zapret2:
syndata отправляет отдельные данные в начальном TCP SYN; это не подмена и не
замена настоящего TLS ClientHello/SNI. В профилях с tls_client_hello этот
фильтр относится к следующему обработчику, а SYN-data остаётся отдельным шагом.
wssize меняет объявленное TCP-окно (wsize=1, scale=6); совместимость зависит
от сетевого пути. Эти профили экспериментальные, обрабатывают TCP/TLS в выбранном
IP-семействе и не проверяют VPN/Tor-туннель, авторизацию или работу клиентского приложения.
UDP/QUIC-профили отдельные и в нумерованный каталог TLS-стратегий не входят.

============================================================================
СТРАТЕГИЯ 485 — Silver
============================================================================
Название: SYN-data (16 нулевых байт в SYN)
Семейство 24: Silver / SYN-data + TCP window-size; вариант 1.
Цепочка обработчиков: SYN-data.

СОСТАВ И ПОВЕДЕНИЕ
syndata: отдельный 16-байтовый нулевой payload отправляется в начальном TCP SYN.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-desync=syndata

============================================================================
СТРАТЕГИЯ 486 — Silver
============================================================================
Название: SYN-data (TLS-фейк с rnd, dupsid и случайным SNI) + multisplit (pos=1,midsld)
Семейство 24: Silver / SYN-data + TCP window-size; вариант 2.
Цепочка обработчиков: syndata + multisplit.

СОСТАВ И ПОВЕДЕНИЕ
syndata: в SYN отправляется TLS-фейк из штатного шаблона с rnd, dupsid и случайным SNI; настоящий ClientHello не заменяется.
Фильтр tls_client_hello ограничивает последующий split/disorder обработчик распознанным TLS ClientHello.
multisplit: TLS ClientHello обрабатывается частями в обычном порядке; точки разделения указаны в аргументе.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-desync=syndata:blob=fake_default_tls:tls_mod=rnd,dupsid,rndsni
--payload=tls_client_hello
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 487 — Silver
============================================================================
Название: SYN-data (короткий TLS-префикс 0x1603) + multisplit (pos=2)
Семейство 24: Silver / SYN-data + TCP window-size; вариант 3.
Цепочка обработчиков: syndata + multisplit.

СОСТАВ И ПОВЕДЕНИЕ
syndata: в начальном TCP SYN отправляется короткий payload 0x1603.
Фильтр tls_client_hello ограничивает последующий split/disorder обработчик распознанным TLS ClientHello.
multisplit: TLS ClientHello обрабатывается частями в обычном порядке; точки разделения указаны в аргументе.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-desync=syndata:blob=0x1603
--payload=tls_client_hello
--lua-desync=multisplit:pos=2

============================================================================
СТРАТЕГИЯ 488 — Silver
============================================================================
Название: SYN-data (TLS-фейк с SNI=google.com) + multidisorder (pos=1,midsld)
Семейство 24: Silver / SYN-data + TCP window-size; вариант 4.
Цепочка обработчиков: syndata + multidisorder.

СОСТАВ И ПОВЕДЕНИЕ
syndata: для SYN отправляется отдельный TLS-фейк с изменённым SNI google.com; он не меняет настоящий SNI соединения.
Фильтр tls_client_hello ограничивает последующий split/disorder обработчик распознанным TLS ClientHello.
multidisorder: части TLS ClientHello отправляются в изменённом порядке; позиции указаны в аргументе.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-desync=syndata:blob=fake_default_tls:tls_mod=rnd,dupsid,sni=google.com
--payload=tls_client_hello
--lua-desync=multidisorder:pos=1,midsld

============================================================================
СТРАТЕГИЯ 489 — Silver
============================================================================
Название: TCP window-size (wsize=1, scale=6) + multisplit (pos=1,midsld)
Семейство 24: Silver / SYN-data + TCP window-size; вариант 5.
Цепочка обработчиков: wssize + multisplit.

СОСТАВ И ПОВЕДЕНИЕ
wssize: объявленный TCP window size задаётся равным 1 при scale=6.
Фильтр tls_client_hello ограничивает последующий split/disorder обработчик распознанным TLS ClientHello.
multisplit: TLS ClientHello обрабатывается частями в обычном порядке; точки разделения указаны в аргументе.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-desync=wssize:wsize=1:scale=6
--payload=tls_client_hello
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 490 — Silver
============================================================================
Название: TCP window-size + SYN-data (16 нулевых байт) + multisplit (pos=1,midsld)
Семейство 24: Silver / SYN-data + TCP window-size; вариант 6.
Цепочка обработчиков: wssize + syndata + multisplit.

СОСТАВ И ПОВЕДЕНИЕ
wssize: объявленный TCP window size задаётся равным 1 при scale=6.
syndata: отдельный 16-байтовый нулевой payload отправляется в начальном TCP SYN.
Фильтр tls_client_hello ограничивает последующий split/disorder обработчик распознанным TLS ClientHello.
multisplit: TLS ClientHello обрабатывается частями в обычном порядке; точки разделения указаны в аргументе.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-desync=wssize:wsize=1:scale=6
--lua-desync=syndata
--payload=tls_client_hello
--lua-desync=multisplit:pos=1,midsld

============================================================================
СТРАТЕГИЯ 491 — Silver
============================================================================
Название: TCP window-size + SYN-data (TLS-фейк с rnd, dupsid и случайным SNI) + multidisorder
Семейство 24: Silver / SYN-data + TCP window-size; вариант 7.
Цепочка обработчиков: wssize + syndata + multidisorder.

СОСТАВ И ПОВЕДЕНИЕ
wssize: объявленный TCP window size задаётся равным 1 при scale=6.
syndata: в SYN отправляется TLS-фейк из штатного шаблона с rnd, dupsid и случайным SNI; настоящий ClientHello не заменяется.
Фильтр tls_client_hello ограничивает последующий split/disorder обработчик распознанным TLS ClientHello.
multidisorder: части TLS ClientHello отправляются в изменённом порядке; позиции указаны в аргументе.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-desync=wssize:wsize=1:scale=6
--lua-desync=syndata:blob=fake_default_tls:tls_mod=rnd,dupsid,rndsni
--payload=tls_client_hello
--lua-desync=multidisorder:pos=1,midsld

============================================================================
СТРАТЕГИЯ 492 — Silver
============================================================================
Название: TCP window-size + SYN-data (короткий TLS-префикс 0x1603) + multisplit (pos=2)
Семейство 24: Silver / SYN-data + TCP window-size; вариант 8.
Цепочка обработчиков: wssize + syndata + multisplit.

СОСТАВ И ПОВЕДЕНИЕ
wssize: объявленный TCP window size задаётся равным 1 при scale=6.
syndata: в начальном TCP SYN отправляется короткий payload 0x1603.
Фильтр tls_client_hello ограничивает последующий split/disorder обработчик распознанным TLS ClientHello.
multisplit: TLS ClientHello обрабатывается частями в обычном порядке; точки разделения указаны в аргументе.

ТОЧНЫЕ АРГУМЕНТЫ СТРАТЕГИИ
--lua-desync=wssize:wsize=1:scale=6
--lua-desync=syndata:blob=0x1603
--payload=tls_client_hello
--lua-desync=multisplit:pos=2
