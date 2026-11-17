AntiDPI Strategies + Bol-Van Zapret2
СПРАВОЧНИК СТРАТЕГИЙ WINDOWS - ИСТОЧНИК КАТАЛОГА 20261023_public_v1
GUI + CLI 1.28 | 492 стратегии | 24 семейства | 45 Golden + 447 Silver
==============================================================================

1. КАК ПОЛЬЗОВАТЬСЯ СПРАВОЧНИКОМ

Номер и аргументы ниже соответствуют встроенному каталогу Windows и Linux. Стратегии 1–45 помечены Golden, 46–492 - Silver. Семейство объединяет рецепты с общей цепочкой обработки; варианты внутри семейства могут различаться точками разделения, параметрами TCP, фейком, TLS-паттерном или дополнительной инициализацией. Название - краткое описание рецепта, а не обещание результата.

В GUI выберите профиль и сначала используйте «Проверить, не запускать». Затем при необходимости испытайте один профиль на выбранной сети, контролируя базовую доступность и штатно остановите запуск. Тестирование одной сети не гарантирует результат в другой. Не запускайте одновременно несколько перехватчиков.

2. ТЕРМИНЫ И ОГРАНИЧЕНИЯ

• fake - дополнительная поддельная последовательность/пакет; её байты и TCP-параметры задаются аргументом. Фейк не заменяет настоящий ClientHello.
• multisplit - разбиение потока на части в указанных позициях; порядок обычный.
• multidisorder - разбиение/переупорядочивание частей согласно опциям профиля.
• hostfakesplit - семейство рецептов с фейком и разделением около указанных частей имени узла.
• disorder - изменение порядка отправки частей; это не шифрование и не изменение приложения.
• TLS ClientHello и SNI описывают начальное TLS-сообщение; конкретное имя/паттерн берётся из точных аргументов ниже.
• tcp_ts, tcp_seq, repeats, split-pos и другие параметры - буквальные значения движка; не подменяйте их догадками.

Аргументы в каталоге - только специфичные для рецепта. Общие параметры интерфейса, семейства IP, протокола, портов, lua-библиотек и исключений добавляет оболочка. Для семейства IPv4 используется ips-exclude.txt, для IPv6 - ips6-exclude.txt. Точный фактический набор можно посмотреть в GUI через «Аргументы».

Не следует считать надпись Golden доказательством, что профиль лучше в любой сети. Результаты зависят от сетевого фильтра, маршрута, сервера и других программ; серия из нескольких тестов остаётся предварительной. Проверка YouTube не является VPN/Tor тестом и не доказывает обход DPI.

3. КАТАЛОГ ПО СЕМЕЙСТВАМ

------------------------------------------------------------------------------
СЕМЕЙСТВО 1 - Golden / fake + multisplit (профили 1–13; 13 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 1 - Golden | вариант 1
Название: TLS-фейк (штатный SNI; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 2 - Golden | вариант 2
Название: TLS-фейк (штатный SNI; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld,1220)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld,1220

ПРОФИЛЬ 3 - Golden | вариант 3
Название: TLS-фейк (штатный SNI; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 4 - Golden | вариант 4
Название: TLS-фейк (SNI=dl.google.com; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=public_tls_pattern:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')

ПРОФИЛЬ 5 - Golden | вариант 5
Название: TLS-фейк (SNI=dl.google.com; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=public_tls_pattern:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')

ПРОФИЛЬ 6 - Golden | вариант 6
Название: TLS-фейк (SNI=dl.google.com; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: SEQ
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=public_tls_pattern:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')

ПРОФИЛЬ 7 - Golden | вариант 7
Название: TLS-фейк (SNI=open.spotify.com; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=public_tls_pattern:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')

ПРОФИЛЬ 8 - Golden | вариант 8
Название: TLS-фейк (SNI=open.spotify.com; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=public_tls_pattern:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')

ПРОФИЛЬ 9 - Golden | вариант 9
Название: TLS-фейк (SNI=open.spotify.com; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: SEQ
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=public_tls_pattern:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')

ПРОФИЛЬ 10 - Golden | вариант 10
Название: TLS-фейк (SNI=open.spotify.com; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: SEQ
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=public_tls_pattern:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')

ПРОФИЛЬ 11 - Golden | вариант 11
Название: TLS-фейк (SNI=dl.google.com; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: SEQ
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=public_tls_pattern:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')

ПРОФИЛЬ 12 - Golden | вариант 12
Название: TLS-фейк (штатный SNI; SEQ=1000000; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS+SEQ
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 13 - Golden | вариант 13
Название: TLS-фейк (штатный SNI; SEQ=1000000; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS+SEQ
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
------------------------------------------------------------------------------
СЕМЕЙСТВО 2 - Golden / multisplit + multisplit (профили 14–20; 7 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 14 - Golden | вариант 1
Название: Разделённый TLS-фейк (штатный SNI; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: multisplit + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:tcp_ts=-1000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 15 - Golden | вариант 2
Название: Разделённый TLS-фейк (штатный SNI; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,midsld,1220)
Цепочка: multisplit + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:tcp_ts=-1000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,midsld,1220

ПРОФИЛЬ 16 - Golden | вариант 3
Название: Разделённый TLS-фейк (штатный SNI; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: multisplit + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:tcp_ts=-1000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 17 - Golden | вариант 4
Название: Разделённый TLS-фейк (SNI=dl.google.com; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: multisplit + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=public_tls_pattern:tcp_ts=-1000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')

ПРОФИЛЬ 18 - Golden | вариант 5
Название: Разделённый TLS-фейк (SNI=open.spotify.com; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: multisplit + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=public_tls_pattern:tcp_ts=-1000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,midsld
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')

ПРОФИЛЬ 19 - Golden | вариант 6
Название: Разделённый TLS-фейк (SNI=open.spotify.com; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: multisplit + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=public_tls_pattern:tcp_ts=-1000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')

ПРОФИЛЬ 20 - Golden | вариант 7
Название: Разделённый TLS-фейк (SNI=dl.google.com; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: multisplit + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=public_tls_pattern:tcp_ts=-1000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,midsld
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
------------------------------------------------------------------------------
СЕМЕЙСТВО 3 - Golden / fake + multidisorder (профили 21–21; 1 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 21 - Golden | вариант 1
Название: TLS-фейк (штатный SNI; TS=-1000) + multidisorder (ClientHello в обратном порядке; pos=2,midsld; seqovl=1)
Цепочка: fake + multidisorder | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:repeats=1
  --lua-desync=multidisorder:pos=2,midsld:seqovl=1
------------------------------------------------------------------------------
СЕМЕЙСТВО 4 - Golden / Именованный hostfakesplit (профили 22–32; 11 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 22 - Golden | вариант 1
Название: hostfakesplit (фейковые вставки в SNI; host=google.com; TS=-1000)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=google.com:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 23 - Golden | вариант 2
Название: hostfakesplit (фейковые вставки в SNI; host=google.com; TCP MD5)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=google.com:tcp_md5:repeats=1

ПРОФИЛЬ 24 - Golden | вариант 3
Название: hostfakesplit (фейковые вставки в SNI; host=4pda.to; TS=-1000)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=4pda.to:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 25 - Golden | вариант 4
Название: hostfakesplit (фейковые вставки в SNI; host=vk.com; TS=-1000)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=vk.com:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 26 - Golden | вариант 5
Название: hostfakesplit (фейковые вставки в SNI; host=vk.com; TCP MD5)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=vk.com:tcp_md5:repeats=1

ПРОФИЛЬ 27 - Golden | вариант 6
Название: hostfakesplit (фейковые вставки в SNI; host=w3.org; TCP MD5)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=w3.org:tcp_md5:repeats=1

ПРОФИЛЬ 28 - Golden | вариант 7
Название: hostfakesplit (фейковые вставки в SNI; host=icloud.com; TS=-1000)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=icloud.com:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 29 - Golden | вариант 8
Название: hostfakesplit (фейковые вставки в SNI; host=yandex.ru; TS=-1000)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=yandex.ru:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 30 - Golden | вариант 9
Название: hostfakesplit (фейковые вставки в SNI; host=yandex.ru; TCP MD5)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=yandex.ru:tcp_md5:repeats=1

ПРОФИЛЬ 31 - Golden | вариант 10
Название: hostfakesplit (фейковые вставки в SNI; host=w3.org; TS=-1000)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=w3.org:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 32 - Golden | вариант 11
Название: hostfakesplit (фейковые вставки в SNI; host=icloud.com; TCP MD5)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=icloud.com:tcp_md5:repeats=1
------------------------------------------------------------------------------
СЕМЕЙСТВО 5 - Golden / Реальный ClientHello + fake + multisplit (профили 33–45; 13 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 33 - Golden | вариант 1
Название: Фейк из текущего ClientHello (SNI=google.com; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=google.com:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 34 - Golden | вариант 2
Название: Фейк из текущего ClientHello (SNI=google.com; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=google.com:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 35 - Golden | вариант 3
Название: Фейк из текущего ClientHello (SNI=4pda.to; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=4pda.to:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 36 - Golden | вариант 4
Название: Фейк из текущего ClientHello (SNI=4pda.to; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=4pda.to:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 37 - Golden | вариант 5
Название: Фейк из текущего ClientHello (SNI=vk.com; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=vk.com:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 38 - Golden | вариант 6
Название: Фейк из текущего ClientHello (SNI=vk.com; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=vk.com:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 39 - Golden | вариант 7
Название: Фейк из текущего ClientHello (SNI=w3.org; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=w3.org:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 40 - Golden | вариант 8
Название: Фейк из текущего ClientHello (SNI=w3.org; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=w3.org:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 41 - Golden | вариант 9
Название: Фейк из текущего ClientHello (SNI=yandex.ru; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=yandex.ru:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 42 - Golden | вариант 10
Название: Фейк из текущего ClientHello (SNI=www.microsoft.com; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=www.microsoft.com:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 43 - Golden | вариант 11
Название: Фейк из текущего ClientHello (SNI=yandex.ru; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=yandex.ru:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 44 - Golden | вариант 12
Название: Фейк из текущего ClientHello (SNI=icloud.com; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=icloud.com:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 45 - Golden | вариант 13
Название: Фейк из текущего ClientHello (SNI=www.microsoft.com; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=www.microsoft.com:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
------------------------------------------------------------------------------
СЕМЕЙСТВО 6 - Silver / fake + multisplit (профили 46–80; 35 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 46 - Silver | вариант 1
Название: Нулевой фейк (4 нулевых байта; SEQ=-3000) + multisplit (ClientHello по частям; pos=1,midsld,1220)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=-3000:repeats=1
  --lua-desync=multisplit:pos=1,midsld,1220

ПРОФИЛЬ 47 - Silver | вариант 2
Название: Нулевой фейк (4 нулевых байта; SEQ=-3000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=-3000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 48 - Silver | вариант 3
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld,1220)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld,1220

ПРОФИЛЬ 49 - Silver | вариант 4
Название: TLS-фейк (SNI=max.ru; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=public_tls_pattern:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')

ПРОФИЛЬ 50 - Silver | вариант 5
Название: TLS-фейк (SNI=max.ru; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: SEQ
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=public_tls_pattern:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')

ПРОФИЛЬ 51 - Silver | вариант 6
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=host+1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=host+1

ПРОФИЛЬ 52 - Silver | вариант 7
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=midsld

ПРОФИЛЬ 53 - Silver | вариант 8
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=sniext+1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=sniext+1

ПРОФИЛЬ 54 - Silver | вариант 9
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=1

ПРОФИЛЬ 55 - Silver | вариант 10
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld,1220)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld,1220

ПРОФИЛЬ 56 - Silver | вариант 11
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=1)
Цепочка: fake + multisplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=1

ПРОФИЛЬ 57 - Silver | вариант 12
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=midsld)
Цепочка: fake + multisplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=midsld

ПРОФИЛЬ 58 - Silver | вариант 13
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=2)
Цепочка: fake + multisplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=2

ПРОФИЛЬ 59 - Silver | вариант 14
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=sniext+1)
Цепочка: fake + multisplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=sniext+1

ПРОФИЛЬ 60 - Silver | вариант 15
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=2)
Цепочка: fake + multisplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=2

ПРОФИЛЬ 61 - Silver | вариант 16
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=sniext+1)
Цепочка: fake + multisplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=sniext+1

ПРОФИЛЬ 62 - Silver | вариант 17
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=sniext+4)
Цепочка: fake + multisplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=sniext+4

ПРОФИЛЬ 63 - Silver | вариант 18
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=sniext+1)
Цепочка: fake + multisplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=sniext+1

ПРОФИЛЬ 64 - Silver | вариант 19
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=1)
Цепочка: fake + multisplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=1

ПРОФИЛЬ 65 - Silver | вариант 20
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=host+1)
Цепочка: fake + multisplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=host+1

ПРОФИЛЬ 66 - Silver | вариант 21
Название: TLS-фейк (SNI=max.ru; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=public_tls_pattern:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')

ПРОФИЛЬ 67 - Silver | вариант 22
Название: TLS-фейк (SNI=max.ru; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: SEQ
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=public_tls_pattern:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')

ПРОФИЛЬ 68 - Silver | вариант 23
Название: TLS-фейк (SNI=eh.vk.ru; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=public_tls_pattern:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')

ПРОФИЛЬ 69 - Silver | вариант 24
Название: TLS-фейк (SNI=eh.vk.ru; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: SEQ
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=public_tls_pattern:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')

ПРОФИЛЬ 70 - Silver | вариант 25
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=2)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=2

ПРОФИЛЬ 71 - Silver | вариант 26
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 72 - Silver | вариант 27
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + multisplit (ClientHello по частям; pos=1,midsld,1220)
Цепочка: fake + multisplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=multisplit:pos=1,midsld,1220

ПРОФИЛЬ 73 - Silver | вариант 28
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=1,midsld,1220)
Цепочка: fake + multisplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=1,midsld,1220

ПРОФИЛЬ 74 - Silver | вариант 29
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=midsld)
Цепочка: fake + multisplit | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=midsld

ПРОФИЛЬ 75 - Silver | вариант 30
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=sniext+4)
Цепочка: fake + multisplit | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=sniext+4

ПРОФИЛЬ 76 - Silver | вариант 31
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=sniext+1)
Цепочка: fake + multisplit | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=sniext+1

ПРОФИЛЬ 77 - Silver | вариант 32
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=host+1)
Цепочка: fake + multisplit | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=host+1

ПРОФИЛЬ 78 - Silver | вариант 33
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + multisplit (ClientHello по частям; pos=1)
Цепочка: fake + multisplit | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multisplit:pos=1

ПРОФИЛЬ 79 - Silver | вариант 34
Название: TLS-фейк (SNI=eh.vk.ru; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=public_tls_pattern:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')

ПРОФИЛЬ 80 - Silver | вариант 35
Название: TLS-фейк (SNI=eh.vk.ru; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: SEQ
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=public_tls_pattern:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
------------------------------------------------------------------------------
СЕМЕЙСТВО 7 - Silver / multisplit + multisplit (профили 81–92; 12 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 81 - Silver | вариант 1
Название: Разделённый TLS-фейк (SNI=dl.google.com; SEQ=1000000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: multisplit + multisplit | Processing: SEQ
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=public_tls_pattern:tcp_seq=1000000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,midsld
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')

ПРОФИЛЬ 82 - Silver | вариант 2
Название: Разделённый TLS-фейк (SNI=dl.google.com; SEQ=1000000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: multisplit + multisplit | Processing: SEQ
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=public_tls_pattern:tcp_seq=1000000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=dl.google.com'),'experimental TLS SNI failed')

ПРОФИЛЬ 83 - Silver | вариант 3
Название: Разделённый TLS-фейк (SNI=max.ru; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: multisplit + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=public_tls_pattern:tcp_ts=-1000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,midsld
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')

ПРОФИЛЬ 84 - Silver | вариант 4
Название: Разделённый TLS-фейк (SNI=max.ru; SEQ=1000000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: multisplit + multisplit | Processing: SEQ
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=public_tls_pattern:tcp_seq=1000000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,midsld
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')

ПРОФИЛЬ 85 - Silver | вариант 5
Название: Разделённый TLS-фейк (SNI=open.spotify.com; SEQ=1000000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: multisplit + multisplit | Processing: SEQ
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=public_tls_pattern:tcp_seq=1000000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,midsld
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')

ПРОФИЛЬ 86 - Silver | вариант 6
Название: Разделённый TLS-фейк (SNI=open.spotify.com; SEQ=1000000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: multisplit + multisplit | Processing: SEQ
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=public_tls_pattern:tcp_seq=1000000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=open.spotify.com'),'experimental TLS SNI failed')

ПРОФИЛЬ 87 - Silver | вариант 7
Название: Разделённый TLS-фейк (SNI=max.ru; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: multisplit + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=public_tls_pattern:tcp_ts=-1000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')

ПРОФИЛЬ 88 - Silver | вариант 8
Название: Разделённый TLS-фейк (SNI=eh.vk.ru; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: multisplit + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=public_tls_pattern:tcp_ts=-1000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')

ПРОФИЛЬ 89 - Silver | вариант 9
Название: Разделённый TLS-фейк (SNI=max.ru; SEQ=1000000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: multisplit + multisplit | Processing: SEQ
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=public_tls_pattern:tcp_seq=1000000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=max.ru'),'experimental TLS SNI failed')

ПРОФИЛЬ 90 - Silver | вариант 10
Название: Разделённый TLS-фейк (SNI=eh.vk.ru; SEQ=1000000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: multisplit + multisplit | Processing: SEQ
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=public_tls_pattern:tcp_seq=1000000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')

ПРОФИЛЬ 91 - Silver | вариант 11
Название: Разделённый TLS-фейк (SNI=eh.vk.ru; SEQ=1000000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: multisplit + multisplit | Processing: SEQ
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=public_tls_pattern:tcp_seq=1000000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,midsld
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')

ПРОФИЛЬ 92 - Silver | вариант 12
Название: Разделённый TLS-фейк (SNI=eh.vk.ru; TS=-1000; pos=2; nodrop) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: multisplit + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Инициализация: public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=public_tls_pattern:tcp_ts=-1000:pos=2:nodrop:repeats=1
  --lua-desync=multisplit:pos=1,midsld
  --lua-init=public_tls_pattern=assert(tls_mod(fake_default_tls,'sni=eh.vk.ru'),'experimental TLS SNI failed')
------------------------------------------------------------------------------
СЕМЕЙСТВО 8 - Silver / fake + multidisorder (профили 93–93; 1 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 93 - Silver | вариант 1
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + multidisorder (ClientHello в обратном порядке; pos=2,midsld; seqovl=1)
Цепочка: fake + multidisorder | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=multidisorder:pos=2,midsld:seqovl=1
------------------------------------------------------------------------------
СЕМЕЙСТВО 9 - Silver / Именованный hostfakesplit (профили 94–142; 49 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 94 - Silver | вариант 1
Название: hostfakesplit (фейковые вставки в SNI; host=yandex.ru; TCP MD5; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=yandex.ru:midhost=midsld:disorder_after:tcp_md5:repeats=1

ПРОФИЛЬ 95 - Silver | вариант 2
Название: hostfakesplit (фейковые вставки в SNI; host=2040.test; TCP MD5; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=2040.test:midhost=midsld:disorder_after:tcp_md5:repeats=1

ПРОФИЛЬ 96 - Silver | вариант 3
Название: hostfakesplit (фейковые вставки в SNI; host=9e1ca.test; TS=-1000)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=9e1ca.test:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 97 - Silver | вариант 4
Название: hostfakesplit (фейковые вставки в SNI; host=google.com; TS=-1000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=google.com:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 98 - Silver | вариант 5
Название: hostfakesplit (фейковые вставки в SNI; host=9e1ca.test; TS=-1000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=9e1ca.test:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 99 - Silver | вариант 6
Название: hostfakesplit (фейковые вставки в SNI; host=google.com; SEQ=1000000)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=google.com:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 100 - Silver | вариант 7
Название: hostfakesplit (фейковые вставки в SNI; host=9e1ca.test; SEQ=1000000)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=9e1ca.test:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 101 - Silver | вариант 8
Название: hostfakesplit (фейковые вставки в SNI; host=google.com; SEQ=1000000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=google.com:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 102 - Silver | вариант 9
Название: hostfakesplit (фейковые вставки в SNI; host=9e1ca.test; SEQ=1000000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=9e1ca.test:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 103 - Silver | вариант 10
Название: hostfakesplit (фейковые вставки в SNI; host=9e1ca.test; TCP MD5)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=9e1ca.test:tcp_md5:repeats=1

ПРОФИЛЬ 104 - Silver | вариант 11
Название: hostfakesplit (фейковые вставки в SNI; host=google.com; TCP MD5; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=google.com:midhost=midsld:disorder_after:tcp_md5:repeats=1

ПРОФИЛЬ 105 - Silver | вариант 12
Название: hostfakesplit (фейковые вставки в SNI; host=9e1ca.test; TCP MD5; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=9e1ca.test:midhost=midsld:disorder_after:tcp_md5:repeats=1

ПРОФИЛЬ 106 - Silver | вариант 13
Название: hostfakesplit (фейковые вставки в SNI; host=49.test; TS=-1000)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=49.test:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 107 - Silver | вариант 14
Название: hostfakesplit (фейковые вставки в SNI; host=4pda.to; TS=-1000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=4pda.to:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 108 - Silver | вариант 15
Название: hostfakesplit (фейковые вставки в SNI; host=49.test; TS=-1000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=49.test:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 109 - Silver | вариант 16
Название: hostfakesplit (фейковые вставки в SNI; host=4pda.to; SEQ=1000000)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=4pda.to:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 110 - Silver | вариант 17
Название: hostfakesplit (фейковые вставки в SNI; host=49.test; SEQ=1000000)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=49.test:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 111 - Silver | вариант 18
Название: hostfakesplit (фейковые вставки в SNI; host=4pda.to; SEQ=1000000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=4pda.to:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 112 - Silver | вариант 19
Название: hostfakesplit (фейковые вставки в SNI; host=49.test; SEQ=1000000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=49.test:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 113 - Silver | вариант 20
Название: hostfakesplit (фейковые вставки в SNI; host=3.test; TS=-1000)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=3.test:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 114 - Silver | вариант 21
Название: hostfakesplit (фейковые вставки в SNI; host=3.test; SEQ=1000000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=3.test:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 115 - Silver | вариант 22
Название: hostfakesplit (фейковые вставки в SNI; host=3.test; TCP MD5)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=3.test:tcp_md5:repeats=1

ПРОФИЛЬ 116 - Silver | вариант 23
Название: hostfakesplit (фейковые вставки в SNI; host=vk.com; TCP MD5; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=vk.com:midhost=midsld:disorder_after:tcp_md5:repeats=1

ПРОФИЛЬ 117 - Silver | вариант 24
Название: hostfakesplit (фейковые вставки в SNI; host=3.test; TCP MD5; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=3.test:midhost=midsld:disorder_after:tcp_md5:repeats=1

ПРОФИЛЬ 118 - Silver | вариант 25
Название: hostfakesplit (фейковые вставки в SNI; host=w3.org; TS=-1000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=w3.org:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 119 - Silver | вариант 26
Название: hostfakesplit (фейковые вставки в SNI; host=w3.org; SEQ=1000000)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=w3.org:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 120 - Silver | вариант 27
Название: hostfakesplit (фейковые вставки в SNI; host=c.test; SEQ=1000000)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=c.test:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 121 - Silver | вариант 28
Название: hostfakesplit (фейковые вставки в SNI; host=w3.org; SEQ=1000000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=w3.org:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 122 - Silver | вариант 29
Название: hostfakesplit (фейковые вставки в SNI; host=c.test; SEQ=1000000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=c.test:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 123 - Silver | вариант 30
Название: hostfakesplit (фейковые вставки в SNI; host=c.test; TCP MD5)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=c.test:tcp_md5:repeats=1

ПРОФИЛЬ 124 - Silver | вариант 31
Название: hostfakesplit (фейковые вставки в SNI; host=w3.org; TCP MD5; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=w3.org:midhost=midsld:disorder_after:tcp_md5:repeats=1

ПРОФИЛЬ 125 - Silver | вариант 32
Название: hostfakesplit (фейковые вставки в SNI; host=c.test; TCP MD5; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=c.test:midhost=midsld:disorder_after:tcp_md5:repeats=1

ПРОФИЛЬ 126 - Silver | вариант 33
Название: hostfakesplit (фейковые вставки в SNI; host=18dda.test; TS=-1000)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=18dda.test:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 127 - Silver | вариант 34
Название: hostfakesplit (фейковые вставки в SNI; host=icloud.com; TS=-1000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=icloud.com:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 128 - Silver | вариант 35
Название: hostfakesplit (фейковые вставки в SNI; host=icloud.com; TCP MD5; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=icloud.com:midhost=midsld:disorder_after:tcp_md5:repeats=1

ПРОФИЛЬ 129 - Silver | вариант 36
Название: hostfakesplit (фейковые вставки в SNI; host=18dda.test; TCP MD5; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=18dda.test:midhost=midsld:disorder_after:tcp_md5:repeats=1

ПРОФИЛЬ 130 - Silver | вариант 37
Название: hostfakesplit (фейковые вставки в SNI; host=2040.test; TS=-1000)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=2040.test:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 131 - Silver | вариант 38
Название: hostfakesplit (фейковые вставки в SNI; host=yandex.ru; TS=-1000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=yandex.ru:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 132 - Silver | вариант 39
Название: hostfakesplit (фейковые вставки в SNI; host=2040.test; TS=-1000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=2040.test:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 133 - Silver | вариант 40
Название: hostfakesplit (фейковые вставки в SNI; host=yandex.ru; SEQ=1000000)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=yandex.ru:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 134 - Silver | вариант 41
Название: hostfakesplit (фейковые вставки в SNI; host=2040.test; SEQ=1000000)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=2040.test:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 135 - Silver | вариант 42
Название: hostfakesplit (фейковые вставки в SNI; host=yandex.ru; SEQ=1000000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=yandex.ru:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 136 - Silver | вариант 43
Название: hostfakesplit (фейковые вставки в SNI; host=2040.test; SEQ=1000000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=2040.test:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 137 - Silver | вариант 44
Название: hostfakesplit (фейковые вставки в SNI; host=2040.test; TCP MD5)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=2040.test:tcp_md5:repeats=1

ПРОФИЛЬ 138 - Silver | вариант 45
Название: hostfakesplit (фейковые вставки в SNI; host=49.test; TCP MD5; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=49.test:midhost=midsld:disorder_after:tcp_md5:repeats=1

ПРОФИЛЬ 139 - Silver | вариант 46
Название: hostfakesplit (фейковые вставки в SNI; host=vk.com; TS=-1000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=vk.com:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 140 - Silver | вариант 47
Название: hostfakesplit (фейковые вставки в SNI; host=vk.com; SEQ=1000000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=vk.com:midhost=midsld:disorder_after:tcp_seq=1000000:repeats=1

ПРОФИЛЬ 141 - Silver | вариант 48
Название: hostfakesplit (фейковые вставки в SNI; host=c.test; TS=-1000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=c.test:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 142 - Silver | вариант 49
Название: hostfakesplit (фейковые вставки в SNI; host=18dda.test; TS=-1000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:host=18dda.test:midhost=midsld:disorder_after:tcp_ts=-1000:repeats=1
------------------------------------------------------------------------------
СЕМЕЙСТВО 10 - Silver / Реальный ClientHello + fake + multisplit (профили 143–172; 30 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 143 - Silver | вариант 1
Название: Фейк из текущего ClientHello (SNI=9e1ca.test; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=9e1ca.test:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 144 - Silver | вариант 2
Название: Фейк из текущего ClientHello (SNI=9e1ca.test; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=9e1ca.test:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 145 - Silver | вариант 3
Название: Фейк из текущего ClientHello (SNI=google.com; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=google.com:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 146 - Silver | вариант 4
Название: Фейк из текущего ClientHello (SNI=9e1ca.test; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=9e1ca.test:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 147 - Silver | вариант 5
Название: Фейк из текущего ClientHello (SNI=google.com; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=google.com:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 148 - Silver | вариант 6
Название: Фейк из текущего ClientHello (SNI=9e1ca.test; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=9e1ca.test:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 149 - Silver | вариант 7
Название: Фейк из текущего ClientHello (SNI=49.test; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=49.test:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 150 - Silver | вариант 8
Название: Фейк из текущего ClientHello (SNI=3.test; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=3.test:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 151 - Silver | вариант 9
Название: Фейк из текущего ClientHello (SNI=3.test; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=3.test:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 152 - Silver | вариант 10
Название: Фейк из текущего ClientHello (SNI=vk.com; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=vk.com:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 153 - Silver | вариант 11
Название: Фейк из текущего ClientHello (SNI=3.test; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=3.test:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 154 - Silver | вариант 12
Название: Фейк из текущего ClientHello (SNI=vk.com; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=vk.com:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 155 - Silver | вариант 13
Название: Фейк из текущего ClientHello (SNI=3.test; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=3.test:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 156 - Silver | вариант 14
Название: Фейк из текущего ClientHello (SNI=c.test; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=c.test:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 157 - Silver | вариант 15
Название: Фейк из текущего ClientHello (SNI=c.test; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=c.test:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 158 - Silver | вариант 16
Название: Фейк из текущего ClientHello (SNI=w3.org; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=w3.org:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 159 - Silver | вариант 17
Название: Фейк из текущего ClientHello (SNI=18dda.test; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=18dda.test:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 160 - Silver | вариант 18
Название: Фейк из текущего ClientHello (SNI=icloud.com; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=icloud.com:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 161 - Silver | вариант 19
Название: Фейк из текущего ClientHello (SNI=18dda.test; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=18dda.test:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 162 - Silver | вариант 20
Название: Фейк из текущего ClientHello (SNI=2040.test; TS=-1000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=2040.test:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 163 - Silver | вариант 21
Название: Фейк из текущего ClientHello (SNI=yandex.ru; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=yandex.ru:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 164 - Silver | вариант 22
Название: Фейк из текущего ClientHello (SNI=2040.test; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=2040.test:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 165 - Silver | вариант 23
Название: Фейк из текущего ClientHello (SNI=yandex.ru; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=yandex.ru:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 166 - Silver | вариант 24
Название: Фейк из текущего ClientHello (SNI=2040.test; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=2040.test:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 167 - Silver | вариант 25
Название: Фейк из текущего ClientHello (SNI=e9d9cc906c1c.test; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=e9d9cc906c1c.test:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 168 - Silver | вариант 26
Название: Фейк из текущего ClientHello (SNI=c.test; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=c.test:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 169 - Silver | вариант 27
Название: Фейк из текущего ClientHello (SNI=icloud.com; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=icloud.com:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 170 - Silver | вариант 28
Название: Фейк из текущего ClientHello (SNI=2040.test; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=2040.test:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 171 - Silver | вариант 29
Название: Фейк из текущего ClientHello (SNI=www.microsoft.com; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=www.microsoft.com:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 172 - Silver | вариант 30
Название: Фейк из текущего ClientHello (SNI=www.microsoft.com; SEQ=1000000) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + multisplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=reasm_data:tls_mod=sni=www.microsoft.com:tcp_seq=1000000:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1
------------------------------------------------------------------------------
СЕМЕЙСТВО 11 - Silver / fake (профили 173–176; 4 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 173 - Silver | вариант 1
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap)
Цепочка: fake | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1

ПРОФИЛЬ 174 - Silver | вариант 2
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap)
Цепочка: fake | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1

ПРОФИЛЬ 175 - Silver | вариант 3
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap)
Цепочка: fake | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1

ПРОФИЛЬ 176 - Silver | вариант 4
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap)
Цепочка: fake | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
------------------------------------------------------------------------------
СЕМЕЙСТВО 12 - Silver / fake + fake + fakeddisorder (профили 177–201; 25 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 177 - Silver | вариант 1
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + TLS-фейк (штатный SNI; SEQ=1000000; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; SEQ=1000000; pos=1)
Цепочка: fake + fake + fakeddisorder | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=1:tcp_seq=1000000

ПРОФИЛЬ 178 - Silver | вариант 2
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + TLS-фейк (штатный SNI; SEQ=1000000; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; SEQ=1000000; pos=1,midsld)
Цепочка: fake + fake + fakeddisorder | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:tcp_seq=1000000

ПРОФИЛЬ 179 - Silver | вариант 3
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + TLS-фейк (штатный SNI; SEQ=1000000; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; SEQ=1000000; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fake + fakeddisorder | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_seq=1000000

ПРОФИЛЬ 180 - Silver | вариант 4
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + TLS-фейк (штатный SNI; SEQ=1000000; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; SEQ=1000000; pos=2)
Цепочка: fake + fake + fakeddisorder | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=2:tcp_seq=1000000

ПРОФИЛЬ 181 - Silver | вариант 5
Название: Нулевой фейк (4 нулевых байта; неверная checksum) + TLS-фейк (штатный SNI; неверная checksum; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=1)
Цепочка: fake + fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:badsum:repeats=1
  --lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=1:badsum

ПРОФИЛЬ 182 - Silver | вариант 6
Название: Нулевой фейк (4 нулевых байта; неверная checksum) + TLS-фейк (штатный SNI; неверная checksum; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=host+1)
Цепочка: fake + fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:badsum:repeats=1
  --lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:badsum

ПРОФИЛЬ 183 - Silver | вариант 7
Название: Нулевой фейк (4 нулевых байта; неверная checksum) + TLS-фейк (штатный SNI; неверная checksum; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:badsum:repeats=1
  --lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:badsum

ПРОФИЛЬ 184 - Silver | вариант 8
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + TLS-фейк (штатный SNI; флаги -ACK; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=sniext+1)
Цепочка: fake + fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_unset=ACK

ПРОФИЛЬ 185 - Silver | вариант 9
Название: Нулевой фейк (4 нулевых байта; флаги +SYN) + TLS-фейк (штатный SNI; флаги +SYN; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=sniext+4)
Цепочка: fake + fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_set=SYN:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:tcp_flags_set=SYN

ПРОФИЛЬ 186 - Silver | вариант 10
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=2)
Цепочка: fake + fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=2:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 187 - Silver | вариант 11
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=1)
Цепочка: fake + fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 188 - Silver | вариант 12
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 189 - Silver | вариант 13
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=1,midsld)
Цепочка: fake + fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 190 - Silver | вариант 14
Название: Нулевой фейк (4 нулевых байта; TTL=1) + TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=midsld)
Цепочка: fake + fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:ip_ttl=1

ПРОФИЛЬ 191 - Silver | вариант 15
Название: Нулевой фейк (4 нулевых байта; TTL=1) + TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=sniext+1)
Цепочка: fake + fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:ip_ttl=1

ПРОФИЛЬ 192 - Silver | вариант 16
Название: Нулевой фейк (4 нулевых байта; TTL=1) + TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_ttl=1

ПРОФИЛЬ 193 - Silver | вариант 17
Название: Нулевой фейк (4 нулевых байта; TTL=1) + TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=2)
Цепочка: fake + fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=2:ip_ttl=1

ПРОФИЛЬ 194 - Silver | вариант 18
Название: Нулевой фейк (4 нулевых байта; TTL=1) + TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=1,midsld)
Цепочка: fake + fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:ip_ttl=1

ПРОФИЛЬ 195 - Silver | вариант 19
Название: Нулевой фейк (4 нулевых байта; флаги +SYN) + TLS-фейк (штатный SNI; флаги +SYN; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_set=SYN:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_flags_set=SYN

ПРОФИЛЬ 196 - Silver | вариант 20
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + TLS-фейк (штатный SNI; флаги -ACK; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=2)
Цепочка: fake + fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=2:tcp_flags_unset=ACK

ПРОФИЛЬ 197 - Silver | вариант 21
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + TLS-фейк (штатный SNI; флаги -ACK; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=sniext+4)
Цепочка: fake + fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:tcp_flags_unset=ACK

ПРОФИЛЬ 198 - Silver | вариант 22
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + TLS-фейк (штатный SNI; флаги -ACK; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_flags_unset=ACK

ПРОФИЛЬ 199 - Silver | вариант 23
Название: Нулевой фейк (4 нулевых байта; TTL=1) + TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=host+1)
Цепочка: fake + fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:ip_ttl=1

ПРОФИЛЬ 200 - Silver | вариант 24
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + TLS-фейк (штатный SNI; флаги -ACK; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=1,midsld)
Цепочка: fake + fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:tcp_flags_unset=ACK

ПРОФИЛЬ 201 - Silver | вариант 25
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + TLS-фейк (штатный SNI; флаги -ACK; TLS=rnd,dupsid) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=1)
Цепочка: fake + fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=fakeddisorder:pos=1:tcp_flags_unset=ACK
------------------------------------------------------------------------------
СЕМЕЙСТВО 13 - Silver / fake + fake + multidisorder (профили 202–209; 8 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 202 - Silver | вариант 1
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid) + multidisorder (ClientHello в обратном порядке; pos=1,midsld)
Цепочка: fake + fake + multidisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=multidisorder:pos=1,midsld

ПРОФИЛЬ 203 - Silver | вариант 2
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid) + multidisorder (ClientHello в обратном порядке; pos=1)
Цепочка: fake + fake + multidisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=multidisorder:pos=1

ПРОФИЛЬ 204 - Silver | вариант 3
Название: Нулевой фейк (4 нулевых байта; SEQ=-3000) + TLS-фейк (штатный SNI; SEQ=-3000; TLS=rnd,dupsid) + multidisorder (ClientHello в обратном порядке; pos=1,midsld,1220)
Цепочка: fake + fake + multidisorder | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=-3000:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_seq=-3000:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=multidisorder:pos=1,midsld,1220

ПРОФИЛЬ 205 - Silver | вариант 4
Название: Нулевой фейк (4 нулевых байта; SEQ=-3000) + TLS-фейк (штатный SNI; SEQ=-3000; TLS=rnd,dupsid) + multidisorder (ClientHello в обратном порядке; pos=1,midsld)
Цепочка: fake + fake + multidisorder | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=-3000:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_seq=-3000:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=multidisorder:pos=1,midsld

ПРОФИЛЬ 206 - Silver | вариант 5
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + TLS-фейк (штатный SNI; SEQ=1000000; TLS=rnd,dupsid) + multidisorder (ClientHello в обратном порядке; pos=2)
Цепочка: fake + fake + multidisorder | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=multidisorder:pos=2

ПРОФИЛЬ 207 - Silver | вариант 6
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + TLS-фейк (штатный SNI; SEQ=1000000; TLS=rnd,dupsid) + multidisorder (ClientHello в обратном порядке; pos=1,midsld,1220)
Цепочка: fake + fake + multidisorder | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=multidisorder:pos=1,midsld,1220

ПРОФИЛЬ 208 - Silver | вариант 7
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + TLS-фейк (штатный SNI; SEQ=1000000; TLS=rnd,dupsid) + multidisorder (ClientHello в обратном порядке; pos=1,midsld)
Цепочка: fake + fake + multidisorder | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=multidisorder:pos=1,midsld

ПРОФИЛЬ 209 - Silver | вариант 8
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + TLS-фейк (штатный SNI; SEQ=1000000; TLS=rnd,dupsid) + multidisorder (ClientHello в обратном порядке; pos=1)
Цепочка: fake + fake + multidisorder | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=multidisorder:pos=1
------------------------------------------------------------------------------
СЕМЕЙСТВО 14 - Silver / fake + fake + multisplit (профили 210–214; 5 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 210 - Silver | вариант 1
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid) + multisplit (ClientHello по частям; pos=1,midsld,1220)
Цепочка: fake + fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=multisplit:pos=1,midsld,1220

ПРОФИЛЬ 211 - Silver | вариант 2
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid) + multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1

ПРОФИЛЬ 212 - Silver | вариант 3
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid) + multisplit (ClientHello по частям; pos=2)
Цепочка: fake + fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=multisplit:pos=2

ПРОФИЛЬ 213 - Silver | вариант 4
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + fake + multisplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid:repeats=1
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 214 - Silver | вариант 5
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + TLS-фейк (штатный SNI; TS=-1000) + multisplit (ClientHello по частям; pos=1,midsld)
Цепочка: fake + fake + multisplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:repeats=1
  --lua-desync=multisplit:pos=1,midsld
------------------------------------------------------------------------------
СЕМЕЙСТВО 15 - Silver / fake + fakeddisorder (профили 215–341; 127 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 215 - Silver | вариант 1
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TS=-1000; pos=1)
Цепочка: fake + fakeddisorder | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1:tcp_ts=-1000

ПРОФИЛЬ 216 - Silver | вариант 2
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TS=-1000; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:tcp_ts=-1000

ПРОФИЛЬ 217 - Silver | вариант 3
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TS=-1000; pos=1,midsld)
Цепочка: fake + fakeddisorder | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:tcp_ts=-1000

ПРОФИЛЬ 218 - Silver | вариант 4
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TS=-1000; pos=2)
Цепочка: fake + fakeddisorder | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=2:tcp_ts=-1000

ПРОФИЛЬ 219 - Silver | вариант 5
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TS=-1000; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ts=-1000

ПРОФИЛЬ 220 - Silver | вариант 6
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TS=-1000; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:tcp_ts=-1000

ПРОФИЛЬ 221 - Silver | вариант 7
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=1)
Цепочка: fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 222 - Silver | вариант 8
Название: TLS-фейк (штатный SNI; неверная checksum; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=1)
Цепочка: fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1:badsum

ПРОФИЛЬ 223 - Silver | вариант 9
Название: TLS-фейк (штатный SNI; неверная checksum) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:badsum:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:badsum

ПРОФИЛЬ 224 - Silver | вариант 10
Название: Нулевой фейк (4 нулевых байта; неверная checksum) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:badsum:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:badsum

ПРОФИЛЬ 225 - Silver | вариант 11
Название: Нулевой фейк (4 нулевых байта; неверная checksum) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=midsld)
Цепочка: fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:badsum:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:badsum

ПРОФИЛЬ 226 - Silver | вариант 12
Название: TLS-фейк (штатный SNI; неверная checksum; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=midsld)
Цепочка: fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:badsum

ПРОФИЛЬ 227 - Silver | вариант 13
Название: TLS-фейк (штатный SNI; неверная checksum) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=midsld)
Цепочка: fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:badsum:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:badsum

ПРОФИЛЬ 228 - Silver | вариант 14
Название: TLS-фейк (штатный SNI; неверная checksum; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=1,midsld)
Цепочка: fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:badsum

ПРОФИЛЬ 229 - Silver | вариант 15
Название: Нулевой фейк (4 нулевых байта; неверная checksum) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:badsum:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:badsum

ПРОФИЛЬ 230 - Silver | вариант 16
Название: TLS-фейк (штатный SNI; неверная checksum) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:badsum:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:badsum

ПРОФИЛЬ 231 - Silver | вариант 17
Название: Нулевой фейк (4 нулевых байта; неверная checksum) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=1,midsld)
Цепочка: fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:badsum:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:badsum

ПРОФИЛЬ 232 - Silver | вариант 18
Название: TLS-фейк (штатный SNI; флаги +SYN; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=midsld)
Цепочка: fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:tcp_flags_set=SYN

ПРОФИЛЬ 233 - Silver | вариант 19
Название: TLS-фейк (штатный SNI; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_flags_set=SYN

ПРОФИЛЬ 234 - Silver | вариант 20
Название: Нулевой фейк (4 нулевых байта; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_set=SYN:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_flags_set=SYN

ПРОФИЛЬ 235 - Silver | вариант 21
Название: TLS-фейк (штатный SNI; флаги +SYN; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=1,midsld)
Цепочка: fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:tcp_flags_set=SYN

ПРОФИЛЬ 236 - Silver | вариант 22
Название: TLS-фейк (штатный SNI; флаги +SYN; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_flags_set=SYN

ПРОФИЛЬ 237 - Silver | вариант 23
Название: TLS-фейк (штатный SNI; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=1,midsld)
Цепочка: fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:tcp_flags_set=SYN

ПРОФИЛЬ 238 - Silver | вариант 24
Название: TLS-фейк (штатный SNI; флаги +SYN; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_set=SYN

ПРОФИЛЬ 239 - Silver | вариант 25
Название: Нулевой фейк (4 нулевых байта; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_set=SYN:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_set=SYN

ПРОФИЛЬ 240 - Silver | вариант 26
Название: Нулевой фейк (4 нулевых байта; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=2)
Цепочка: fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_set=SYN:repeats=1
  --lua-desync=fakeddisorder:pos=2:tcp_flags_set=SYN

ПРОФИЛЬ 241 - Silver | вариант 27
Название: TLS-фейк (штатный SNI; флаги -ACK) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_unset=ACK

ПРОФИЛЬ 242 - Silver | вариант 28
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:tcp_flags_unset=ACK

ПРОФИЛЬ 243 - Silver | вариант 29
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_unset=ACK

ПРОФИЛЬ 244 - Silver | вариант 30
Название: TLS-фейк (штатный SNI; флаги -ACK) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=sniext+4)
Цепочка: fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:tcp_flags_unset=ACK

ПРОФИЛЬ 245 - Silver | вариант 31
Название: TLS-фейк (штатный SNI; флаги -ACK) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=2)
Цепочка: fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:repeats=1
  --lua-desync=fakeddisorder:pos=2:tcp_flags_unset=ACK

ПРОФИЛЬ 246 - Silver | вариант 32
Название: TLS-фейк (штатный SNI; флаги -ACK; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_unset=ACK

ПРОФИЛЬ 247 - Silver | вариант 33
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=2)
Цепочка: fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
  --lua-desync=fakeddisorder:pos=2:tcp_flags_unset=ACK

ПРОФИЛЬ 248 - Silver | вариант 34
Название: TLS-фейк (штатный SNI; флаги -ACK; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=1)
Цепочка: fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1:tcp_flags_unset=ACK

ПРОФИЛЬ 249 - Silver | вариант 35
Название: Нулевой фейк (4 нулевых байта; флаги -ACK) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_unset=ACK:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_flags_unset=ACK

ПРОФИЛЬ 250 - Silver | вариант 36
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakeddisorder (перестановка + нулевые фейки; TS=-1000; pos=1)
Цепочка: fake + fakeddisorder | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
  --lua-desync=fakeddisorder:pos=1:tcp_ts=-1000

ПРОФИЛЬ 251 - Silver | вариант 37
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 252 - Silver | вариант 38
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 253 - Silver | вариант 39
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=1,midsld)
Цепочка: fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 254 - Silver | вариант 40
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=2)
Цепочка: fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=2:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 255 - Silver | вариант 41
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 256 - Silver | вариант 42
Название: TLS-фейк (штатный SNI; неверная checksum) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:badsum:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:badsum

ПРОФИЛЬ 257 - Silver | вариант 43
Название: Нулевой фейк (4 нулевых байта; неверная checksum) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:badsum:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:badsum

ПРОФИЛЬ 258 - Silver | вариант 44
Название: TLS-фейк (штатный SNI; неверная checksum; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=sniext+4)
Цепочка: fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:badsum

ПРОФИЛЬ 259 - Silver | вариант 45
Название: TLS-фейк (штатный SNI; неверная checksum; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:badsum

ПРОФИЛЬ 260 - Silver | вариант 46
Название: TLS-фейк (штатный SNI; неверная checksum) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=1,midsld)
Цепочка: fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:badsum:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:badsum

ПРОФИЛЬ 261 - Silver | вариант 47
Название: TLS-фейк (штатный SNI; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=2)
Цепочка: fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:repeats=1
  --lua-desync=fakeddisorder:pos=2:tcp_flags_set=SYN

ПРОФИЛЬ 262 - Silver | вариант 48
Название: Нулевой фейк (4 нулевых байта; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=sniext+4)
Цепочка: fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_set=SYN:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:tcp_flags_set=SYN

ПРОФИЛЬ 263 - Silver | вариант 49
Название: TLS-фейк (штатный SNI; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=sniext+4)
Цепочка: fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:tcp_flags_set=SYN

ПРОФИЛЬ 264 - Silver | вариант 50
Название: TLS-фейк (штатный SNI; флаги -ACK; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:tcp_flags_unset=ACK

ПРОФИЛЬ 265 - Silver | вариант 51
Название: TLS-фейк (штатный SNI; флаги -ACK) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=midsld)
Цепочка: fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:tcp_flags_unset=ACK

ПРОФИЛЬ 266 - Silver | вариант 52
Название: TLS-фейк (штатный SNI; флаги -ACK; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=midsld)
Цепочка: fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:tcp_flags_unset=ACK

ПРОФИЛЬ 267 - Silver | вариант 53
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TS=-1000; pos=sniext+4)
Цепочка: fake + fakeddisorder | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:tcp_ts=-1000

ПРОФИЛЬ 268 - Silver | вариант 54
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+4)
Цепочка: fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 269 - Silver | вариант 55
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=midsld)
Цепочка: fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 270 - Silver | вариант 56
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=2)
Цепочка: fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fakeddisorder:pos=2:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 271 - Silver | вариант 57
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=1)
Цепочка: fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fakeddisorder:pos=1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 272 - Silver | вариант 58
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=midsld)
Цепочка: fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 273 - Silver | вариант 59
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 274 - Silver | вариант 60
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 275 - Silver | вариант 61
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+4)
Цепочка: fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 276 - Silver | вариант 62
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakeddisorder (перестановка + нулевые фейки; ACK=-66000; TS-опция первой; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 277 - Silver | вариант 63
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TCP MD5; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:tcp_md5

ПРОФИЛЬ 278 - Silver | вариант 64
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TCP MD5; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_md5

ПРОФИЛЬ 279 - Silver | вариант 65
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TCP MD5; pos=2)
Цепочка: fake + fakeddisorder | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=2:tcp_md5

ПРОФИЛЬ 280 - Silver | вариант 66
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TCP MD5; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:tcp_md5

ПРОФИЛЬ 281 - Silver | вариант 67
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-2,3-20; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_autottl=-2,3-20

ПРОФИЛЬ 282 - Silver | вариант 68
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-3,3-20; pos=midsld)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:ip_autottl=-3,3-20

ПРОФИЛЬ 283 - Silver | вариант 69
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-1,3-20; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_autottl=-1,3-20

ПРОФИЛЬ 284 - Silver | вариант 70
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-1,3-20; pos=1)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1:ip_autottl=-1,3-20

ПРОФИЛЬ 285 - Silver | вариант 71
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-2,3-20; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:ip_autottl=-2,3-20

ПРОФИЛЬ 286 - Silver | вариант 72
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-1,3-20; pos=midsld)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:ip_autottl=-1,3-20

ПРОФИЛЬ 287 - Silver | вариант 73
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-2,3-20; pos=midsld)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:ip_autottl=-2,3-20

ПРОФИЛЬ 288 - Silver | вариант 74
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-2,3-20; pos=2)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=2:ip_autottl=-2,3-20

ПРОФИЛЬ 289 - Silver | вариант 75
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-1,3-20; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:ip_autottl=-1,3-20

ПРОФИЛЬ 290 - Silver | вариант 76
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-2,3-20; pos=1)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1:ip_autottl=-2,3-20

ПРОФИЛЬ 291 - Silver | вариант 77
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-2,3-20; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:ip_autottl=-2,3-20

ПРОФИЛЬ 292 - Silver | вариант 78
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-1,3-20; pos=1,midsld)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:ip_autottl=-1,3-20

ПРОФИЛЬ 293 - Silver | вариант 79
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-1,3-20; pos=2)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=2:ip_autottl=-1,3-20

ПРОФИЛЬ 294 - Silver | вариант 80
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-3,3-20; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:ip_autottl=-3,3-20

ПРОФИЛЬ 295 - Silver | вариант 81
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-3,3-20; pos=sniext+4)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:ip_autottl=-3,3-20

ПРОФИЛЬ 296 - Silver | вариант 82
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-4,3-20; pos=2)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=2:ip_autottl=-4,3-20

ПРОФИЛЬ 297 - Silver | вариант 83
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-2,3-20; pos=sniext+4)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:ip_autottl=-2,3-20

ПРОФИЛЬ 298 - Silver | вариант 84
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-3,3-20; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:ip_autottl=-3,3-20

ПРОФИЛЬ 299 - Silver | вариант 85
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-3,3-20; pos=2)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=2:ip_autottl=-3,3-20

ПРОФИЛЬ 300 - Silver | вариант 86
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-4,3-20; pos=1)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1:ip_autottl=-4,3-20

ПРОФИЛЬ 301 - Silver | вариант 87
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-4,3-20; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_autottl=-4,3-20

ПРОФИЛЬ 302 - Silver | вариант 88
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-3,3-20; pos=1)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1:ip_autottl=-3,3-20

ПРОФИЛЬ 303 - Silver | вариант 89
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-4,3-20; pos=1,midsld)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:ip_autottl=-4,3-20

ПРОФИЛЬ 304 - Silver | вариант 90
Название: TLS-фейк (штатный SNI; AutoTTL=-5,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-5,3-20; pos=2)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-5,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=2:ip_autottl=-5,3-20

ПРОФИЛЬ 305 - Silver | вариант 91
Название: TLS-фейк (штатный SNI; AutoTTL=-5,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-5,3-20; pos=sniext+4)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-5,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:ip_autottl=-5,3-20

ПРОФИЛЬ 306 - Silver | вариант 92
Название: TLS-фейк (штатный SNI; AutoTTL=-5,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-5,3-20; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-5,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_autottl=-5,3-20

ПРОФИЛЬ 307 - Silver | вариант 93
Название: TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=midsld)
Цепочка: fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:ip_ttl=1

ПРОФИЛЬ 308 - Silver | вариант 94
Название: Нулевой фейк (4 нулевых байта; TTL=1) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=midsld)
Цепочка: fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:ip_ttl=1

ПРОФИЛЬ 309 - Silver | вариант 95
Название: Нулевой фейк (4 нулевых байта; TTL=1) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:ip_ttl=1

ПРОФИЛЬ 310 - Silver | вариант 96
Название: TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=sniext+4)
Цепочка: fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:ip_ttl=1

ПРОФИЛЬ 311 - Silver | вариант 97
Название: TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:ip_ttl=1

ПРОФИЛЬ 312 - Silver | вариант 98
Название: TLS-фейк (штатный SNI; TTL=1) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=midsld)
Цепочка: fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:ip_ttl=1

ПРОФИЛЬ 313 - Silver | вариант 99
Название: TLS-фейк (штатный SNI; TTL=1) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:ip_ttl=1

ПРОФИЛЬ 314 - Silver | вариант 100
Название: TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=1)
Цепочка: fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1:ip_ttl=1

ПРОФИЛЬ 315 - Silver | вариант 101
Название: TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:ip_ttl=1

ПРОФИЛЬ 316 - Silver | вариант 102
Название: TLS-фейк (штатный SNI; TTL=1) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_ttl=1

ПРОФИЛЬ 317 - Silver | вариант 103
Название: TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_ttl=1

ПРОФИЛЬ 318 - Silver | вариант 104
Название: Нулевой фейк (4 нулевых байта; TTL=1) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:ip_ttl=1

ПРОФИЛЬ 319 - Silver | вариант 105
Название: Нулевой фейк (4 нулевых байта; TTL=1) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=1,midsld)
Цепочка: fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:ip_ttl=1:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:ip_ttl=1

ПРОФИЛЬ 320 - Silver | вариант 106
Название: TLS-фейк (штатный SNI; TTL=1) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=1,midsld)
Цепочка: fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:ip_ttl=1

ПРОФИЛЬ 321 - Silver | вариант 107
Название: TLS-фейк (штатный SNI; TTL=1; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=1,midsld)
Цепочка: fake + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=1:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:ip_ttl=1

ПРОФИЛЬ 322 - Silver | вариант 108
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakeddisorder (перестановка + нулевые фейки; SEQ=1000000; pos=1,midsld)
Цепочка: fake + fakeddisorder | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:tcp_seq=1000000

ПРОФИЛЬ 323 - Silver | вариант 109
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakeddisorder (перестановка + нулевые фейки; SEQ=1000000; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:tcp_seq=1000000

ПРОФИЛЬ 324 - Silver | вариант 110
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakeddisorder (перестановка + нулевые фейки; SEQ=1000000; pos=1)
Цепочка: fake + fakeddisorder | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fakeddisorder:pos=1:tcp_seq=1000000

ПРОФИЛЬ 325 - Silver | вариант 111
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakeddisorder (перестановка + нулевые фейки; SEQ=1000000; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:tcp_seq=1000000

ПРОФИЛЬ 326 - Silver | вариант 112
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakeddisorder (перестановка + нулевые фейки; SEQ=1000000; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_seq=1000000

ПРОФИЛЬ 327 - Silver | вариант 113
Название: TLS-фейк (штатный SNI; неверная checksum; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:badsum:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:badsum

ПРОФИЛЬ 328 - Silver | вариант 114
Название: Нулевой фейк (4 нулевых байта; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=1,midsld)
Цепочка: fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_flags_set=SYN:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:tcp_flags_set=SYN

ПРОФИЛЬ 329 - Silver | вариант 115
Название: TLS-фейк (штатный SNI; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=1)
Цепочка: fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:repeats=1
  --lua-desync=fakeddisorder:pos=1:tcp_flags_set=SYN

ПРОФИЛЬ 330 - Silver | вариант 116
Название: TLS-фейк (штатный SNI; флаги +SYN; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=1)
Цепочка: fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1:tcp_flags_set=SYN

ПРОФИЛЬ 331 - Silver | вариант 117
Название: TLS-фейк (штатный SNI; флаги -ACK; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_unset=ACK:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_flags_unset=ACK

ПРОФИЛЬ 332 - Silver | вариант 118
Название: TLS-фейк (штатный SNI; флаги +SYN) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_flags_set=SYN:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_set=SYN

ПРОФИЛЬ 333 - Silver | вариант 119
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TS=-1000; pos=midsld)
Цепочка: fake + fakeddisorder | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:tcp_ts=-1000

ПРОФИЛЬ 334 - Silver | вариант 120
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakeddisorder (перестановка + нулевые фейки; TS=-1000; pos=2)
Цепочка: fake + fakeddisorder | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
  --lua-desync=fakeddisorder:pos=2:tcp_ts=-1000

ПРОФИЛЬ 335 - Silver | вариант 121
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakeddisorder (перестановка + нулевые фейки; TS=-1000; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:tcp_ts=-1000

ПРОФИЛЬ 336 - Silver | вариант 122
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakeddisorder (перестановка + нулевые фейки; TS=-1000; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakeddisorder | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ts=-1000

ПРОФИЛЬ 337 - Silver | вариант 123
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TCP MD5; pos=1)
Цепочка: fake + fakeddisorder | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=1:tcp_md5

ПРОФИЛЬ 338 - Silver | вариант 124
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; TCP MD5; pos=sniext+4)
Цепочка: fake + fakeddisorder | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:tcp_md5

ПРОФИЛЬ 339 - Silver | вариант 125
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-4,3-20; pos=midsld)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:ip_autottl=-4,3-20

ПРОФИЛЬ 340 - Silver | вариант 126
Название: TLS-фейк (штатный SNI; AutoTTL=-5,3-20; TLS=rnd,dupsid,padencap) + fakeddisorder (перестановка + нулевые фейки; AutoTTL=-5,3-20; pos=host+1)
Цепочка: fake + fakeddisorder | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-5,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:ip_autottl=-5,3-20

ПРОФИЛЬ 341 - Silver | вариант 127
Название: Нулевой фейк (4 нулевых байта; SEQ=-3000) + fakeddisorder (перестановка + нулевые фейки; SEQ=-3000; pos=sniext+1)
Цепочка: fake + fakeddisorder | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=-3000:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:tcp_seq=-3000
------------------------------------------------------------------------------
СЕМЕЙСТВО 16 - Silver / fake + fakedsplit (профили 342–408; 67 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 342 - Silver | вариант 1
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TCP MD5; pos=sniext+4)
Цепочка: fake + fakedsplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=sniext+4:tcp_md5

ПРОФИЛЬ 343 - Silver | вариант 2
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TCP MD5; pos=host+1)
Цепочка: fake + fakedsplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=host+1:tcp_md5

ПРОФИЛЬ 344 - Silver | вариант 3
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TCP MD5; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakedsplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_md5

ПРОФИЛЬ 345 - Silver | вариант 4
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TCP MD5; pos=1,midsld)
Цепочка: fake + fakedsplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1,midsld:tcp_md5

ПРОФИЛЬ 346 - Silver | вариант 5
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TCP MD5; pos=sniext+1)
Цепочка: fake + fakedsplit | Processing: MD5
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=sniext+1:tcp_md5

ПРОФИЛЬ 347 - Silver | вариант 6
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-1,3-20; pos=sniext+4)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=sniext+4:ip_autottl=-1,3-20

ПРОФИЛЬ 348 - Silver | вариант 7
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-1,3-20; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_autottl=-1,3-20

ПРОФИЛЬ 349 - Silver | вариант 8
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-1,3-20; pos=1,midsld)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1,midsld:ip_autottl=-1,3-20

ПРОФИЛЬ 350 - Silver | вариант 9
Название: Нулевой фейк (4 нулевых байта; SEQ=-3000) + fakedsplit (разделение + нулевые фейки; SEQ=-3000; pos=2)
Цепочка: fake + fakedsplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=-3000:repeats=1
  --lua-desync=fakedsplit:pos=2:tcp_seq=-3000

ПРОФИЛЬ 351 - Silver | вариант 10
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakedsplit (разделение + нулевые фейки; SEQ=1000000; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakedsplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_seq=1000000

ПРОФИЛЬ 352 - Silver | вариант 11
Название: TLS-фейк (штатный SNI; SEQ=1000000; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; SEQ=1000000; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakedsplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_seq=1000000

ПРОФИЛЬ 353 - Silver | вариант 12
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakedsplit (разделение + нулевые фейки; SEQ=1000000; pos=sniext+1)
Цепочка: fake + fakedsplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fakedsplit:pos=sniext+1:tcp_seq=1000000

ПРОФИЛЬ 354 - Silver | вариант 13
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TCP MD5; pos=midsld)
Цепочка: fake + fakedsplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=midsld:tcp_md5

ПРОФИЛЬ 355 - Silver | вариант 14
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-1,3-20; pos=sniext+1)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=sniext+1:ip_autottl=-1,3-20

ПРОФИЛЬ 356 - Silver | вариант 15
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-1,3-20; pos=midsld)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=midsld:ip_autottl=-1,3-20

ПРОФИЛЬ 357 - Silver | вариант 16
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-1,3-20; pos=1)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1:ip_autottl=-1,3-20

ПРОФИЛЬ 358 - Silver | вариант 17
Название: TLS-фейк (штатный SNI; AutoTTL=-1,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-1,3-20; pos=2)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-1,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=2:ip_autottl=-1,3-20

ПРОФИЛЬ 359 - Silver | вариант 18
Название: Нулевой фейк (4 нулевых байта; SEQ=-3000) + fakedsplit (разделение + нулевые фейки; SEQ=-3000; pos=sniext+1)
Цепочка: fake + fakedsplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=-3000:repeats=1
  --lua-desync=fakedsplit:pos=sniext+1:tcp_seq=-3000

ПРОФИЛЬ 360 - Silver | вариант 19
Название: Нулевой фейк (4 нулевых байта; SEQ=-3000) + fakedsplit (разделение + нулевые фейки; SEQ=-3000; pos=host+1)
Цепочка: fake + fakedsplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=-3000:repeats=1
  --lua-desync=fakedsplit:pos=host+1:tcp_seq=-3000

ПРОФИЛЬ 361 - Silver | вариант 20
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakedsplit (разделение + нулевые фейки; SEQ=1000000; pos=2)
Цепочка: fake + fakedsplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fakedsplit:pos=2:tcp_seq=1000000

ПРОФИЛЬ 362 - Silver | вариант 21
Название: TLS-фейк (штатный SNI; SEQ=1000000; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; SEQ=1000000; pos=2)
Цепочка: fake + fakedsplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_seq=1000000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=2:tcp_seq=1000000

ПРОФИЛЬ 363 - Silver | вариант 22
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TS=-1000; pos=sniext+1)
Цепочка: fake + fakedsplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=sniext+1:tcp_ts=-1000

ПРОФИЛЬ 364 - Silver | вариант 23
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TS=-1000; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakedsplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ts=-1000

ПРОФИЛЬ 365 - Silver | вариант 24
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TS=-1000; pos=host+1)
Цепочка: fake + fakedsplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=host+1:tcp_ts=-1000

ПРОФИЛЬ 366 - Silver | вариант 25
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakedsplit (разделение + нулевые фейки; TS=-1000; pos=midsld)
Цепочка: fake + fakedsplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
  --lua-desync=fakedsplit:pos=midsld:tcp_ts=-1000

ПРОФИЛЬ 367 - Silver | вариант 26
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakedsplit (разделение + нулевые фейки; TS=-1000; pos=1,midsld)
Цепочка: fake + fakedsplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
  --lua-desync=fakedsplit:pos=1,midsld:tcp_ts=-1000

ПРОФИЛЬ 368 - Silver | вариант 27
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakedsplit (разделение + нулевые фейки; TS=-1000; pos=1)
Цепочка: fake + fakedsplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
  --lua-desync=fakedsplit:pos=1:tcp_ts=-1000

ПРОФИЛЬ 369 - Silver | вариант 28
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakedsplit (разделение + нулевые фейки; TS=-1000; pos=2)
Цепочка: fake + fakedsplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
  --lua-desync=fakedsplit:pos=2:tcp_ts=-1000

ПРОФИЛЬ 370 - Silver | вариант 29
Название: Нулевой фейк (4 нулевых байта; TS=-1000) + fakedsplit (разделение + нулевые фейки; TS=-1000; pos=host+1)
Цепочка: fake + fakedsplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ts=-1000:repeats=1
  --lua-desync=fakedsplit:pos=host+1:tcp_ts=-1000

ПРОФИЛЬ 371 - Silver | вариант 30
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=1,midsld)
Цепочка: fake + fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1,midsld:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 372 - Silver | вариант 31
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=1)
Цепочка: fake + fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 373 - Silver | вариант 32
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=midsld)
Цепочка: fake + fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=midsld:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 374 - Silver | вариант 33
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 375 - Silver | вариант 34
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=host+1)
Цепочка: fake + fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=host+1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 376 - Silver | вариант 35
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+4)
Цепочка: fake + fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=sniext+4:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 377 - Silver | вариант 36
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+1)
Цепочка: fake + fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=sniext+1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 378 - Silver | вариант 37
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=midsld)
Цепочка: fake + fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fakedsplit:pos=midsld:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 379 - Silver | вариант 38
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 380 - Silver | вариант 39
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+4)
Цепочка: fake + fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fakedsplit:pos=sniext+4:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 381 - Silver | вариант 40
Название: TLS-фейк (штатный SNI; TCP MD5; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TCP MD5; pos=2)
Цепочка: fake + fakedsplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=2:tcp_md5

ПРОФИЛЬ 382 - Silver | вариант 41
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakedsplit (разделение + нулевые фейки; SEQ=1000000; pos=1)
Цепочка: fake + fakedsplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fakedsplit:pos=1:tcp_seq=1000000

ПРОФИЛЬ 383 - Silver | вариант 42
Название: Нулевой фейк (4 нулевых байта; SEQ=1000000) + fakedsplit (разделение + нулевые фейки; SEQ=1000000; pos=sniext+4)
Цепочка: fake + fakedsplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_seq=1000000:repeats=1
  --lua-desync=fakedsplit:pos=sniext+4:tcp_seq=1000000

ПРОФИЛЬ 384 - Silver | вариант 43
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TS=-1000; pos=2)
Цепочка: fake + fakedsplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=2:tcp_ts=-1000

ПРОФИЛЬ 385 - Silver | вариант 44
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TS=-1000; pos=1)
Цепочка: fake + fakedsplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1:tcp_ts=-1000

ПРОФИЛЬ 386 - Silver | вариант 45
Название: TLS-фейк (штатный SNI; ACK=-66000; TS-опция первой; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=2)
Цепочка: fake + fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ack=-66000:tcp_ts_up:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=2:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 387 - Silver | вариант 46
Название: Нулевой фейк (4 нулевых байта; ACK=-66000; TS-опция первой) + fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+1)
Цепочка: fake + fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=0x00000000:tcp_ack=-66000:tcp_ts_up:repeats=1
  --lua-desync=fakedsplit:pos=sniext+1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 388 - Silver | вариант 47
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-2,3-20; pos=sniext+4)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=sniext+4:ip_autottl=-2,3-20

ПРОФИЛЬ 389 - Silver | вариант 48
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-2,3-20; pos=1)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1:ip_autottl=-2,3-20

ПРОФИЛЬ 390 - Silver | вариант 49
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-4,3-20; pos=host+1)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=host+1:ip_autottl=-4,3-20

ПРОФИЛЬ 391 - Silver | вариант 50
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-4,3-20; pos=sniext+4)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=sniext+4:ip_autottl=-4,3-20

ПРОФИЛЬ 392 - Silver | вариант 51
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-3,3-20; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_autottl=-3,3-20

ПРОФИЛЬ 393 - Silver | вариант 52
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-4,3-20; pos=sniext+1)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=sniext+1:ip_autottl=-4,3-20

ПРОФИЛЬ 394 - Silver | вариант 53
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-4,3-20; pos=1,midsld)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1,midsld:ip_autottl=-4,3-20

ПРОФИЛЬ 395 - Silver | вариант 54
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-4,3-20; pos=1)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1:ip_autottl=-4,3-20

ПРОФИЛЬ 396 - Silver | вариант 55
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-3,3-20; pos=midsld)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=midsld:ip_autottl=-3,3-20

ПРОФИЛЬ 397 - Silver | вариант 56
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-3,3-20; pos=host+1)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=host+1:ip_autottl=-3,3-20

ПРОФИЛЬ 398 - Silver | вариант 57
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-3,3-20; pos=sniext+1)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=sniext+1:ip_autottl=-3,3-20

ПРОФИЛЬ 399 - Silver | вариант 58
Название: TLS-фейк (штатный SNI; AutoTTL=-3,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-3,3-20; pos=1)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-3,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1:ip_autottl=-3,3-20

ПРОФИЛЬ 400 - Silver | вариант 59
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-4,3-20; pos=midsld)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=midsld:ip_autottl=-4,3-20

ПРОФИЛЬ 401 - Silver | вариант 60
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TTL=6; pos=sniext+1)
Цепочка: fake + fakedsplit | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=sniext+1:ip_ttl=6

ПРОФИЛЬ 402 - Silver | вариант 61
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TTL=6; pos=2)
Цепочка: fake + fakedsplit | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=2:ip_ttl=6

ПРОФИЛЬ 403 - Silver | вариант 62
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TTL=6; pos=midsld)
Цепочка: fake + fakedsplit | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=midsld:ip_ttl=6

ПРОФИЛЬ 404 - Silver | вариант 63
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TTL=6; pos=1,midsld)
Цепочка: fake + fakedsplit | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1,midsld:ip_ttl=6

ПРОФИЛЬ 405 - Silver | вариант 64
Название: TLS-фейк (штатный SNI; TTL=6; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; TTL=6; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakedsplit | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_ttl=6:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_ttl=6

ПРОФИЛЬ 406 - Silver | вариант 65
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-2,3-20; pos=2)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=2:ip_autottl=-2,3-20

ПРОФИЛЬ 407 - Silver | вариант 66
Название: TLS-фейк (штатный SNI; AutoTTL=-4,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-4,3-20; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-4,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_autottl=-4,3-20

ПРОФИЛЬ 408 - Silver | вариант 67
Название: TLS-фейк (штатный SNI; AutoTTL=-2,3-20; TLS=rnd,dupsid,padencap) + fakedsplit (разделение + нулевые фейки; AutoTTL=-2,3-20; pos=sniext+1)
Цепочка: fake + fakedsplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:ip_autottl=-2,3-20:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=fakedsplit:pos=sniext+1:ip_autottl=-2,3-20
------------------------------------------------------------------------------
СЕМЕЙСТВО 17 - Silver / fake + hostfakesplit (профили 409–409; 1 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 409 - Silver | вариант 1
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + hostfakesplit (фейковые вставки в SNI; случайный host; TS=-1000; перестановка после SNI; без второго фейка)
Цепочка: fake + hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=hostfakesplit:disorder_after:nofake2:tcp_ts=-1000:repeats=1
------------------------------------------------------------------------------
СЕМЕЙСТВО 18 - Silver / fake + tcpseg (профили 410–410; 1 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 410 - Silver | вариант 1
Название: TLS-фейк (штатный SNI; TS=-1000; TLS=rnd,dupsid,padencap) + tcpseg (добавочный TCP-сегмент; IP ID=rnd; pos=0,1)
Цепочка: fake + tcpseg | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000:tls_mod=rnd,dupsid,padencap:repeats=1
  --lua-desync=tcpseg:pos=0,1:ip_id=rnd:repeats=1
------------------------------------------------------------------------------
СЕМЕЙСТВО 19 - Silver / fakedsplit (профили 411–428; 18 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 411 - Silver | вариант 1
Название: fakedsplit (разделение + нулевые фейки; TS=-1000; pos=host+1)
Цепочка: fakedsplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=host+1:tcp_ts=-1000

ПРОФИЛЬ 412 - Silver | вариант 2
Название: fakedsplit (разделение + нулевые фейки; TS=-1000; pos=sniext+4)
Цепочка: fakedsplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=sniext+4:tcp_ts=-1000

ПРОФИЛЬ 413 - Silver | вариант 3
Название: fakedsplit (разделение + нулевые фейки; TS=-1000; pos=sniext+1)
Цепочка: fakedsplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=sniext+1:tcp_ts=-1000

ПРОФИЛЬ 414 - Silver | вариант 4
Название: fakedsplit (разделение + нулевые фейки; TS=-1000; pos=1)
Цепочка: fakedsplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=1:tcp_ts=-1000

ПРОФИЛЬ 415 - Silver | вариант 5
Название: fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=midsld)
Цепочка: fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=midsld:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 416 - Silver | вариант 6
Название: fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+4)
Цепочка: fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=sniext+4:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 417 - Silver | вариант 7
Название: fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=host+1)
Цепочка: fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=host+1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 418 - Silver | вариант 8
Название: fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=sniext+1)
Цепочка: fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=sniext+1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 419 - Silver | вариант 9
Название: fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=1)
Цепочка: fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 420 - Silver | вариант 10
Название: fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=1,midsld)
Цепочка: fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=1,midsld:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 421 - Silver | вариант 11
Название: fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 422 - Silver | вариант 12
Название: fakedsplit (разделение + нулевые фейки; ACK=-66000; TS-опция первой; pos=2)
Цепочка: fakedsplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=2:tcp_ack=-66000:tcp_ts_up

ПРОФИЛЬ 423 - Silver | вариант 13
Название: fakedsplit (разделение + нулевые фейки; SEQ=-3000; pos=host+1)
Цепочка: fakedsplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=host+1:tcp_seq=-3000

ПРОФИЛЬ 424 - Silver | вариант 14
Название: fakedsplit (разделение + нулевые фейки; SEQ=1000000; pos=sniext+4)
Цепочка: fakedsplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=sniext+4:tcp_seq=1000000

ПРОФИЛЬ 425 - Silver | вариант 15
Название: fakedsplit (разделение + нулевые фейки; SEQ=1000000; pos=1)
Цепочка: fakedsplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=1:tcp_seq=1000000

ПРОФИЛЬ 426 - Silver | вариант 16
Название: fakedsplit (разделение + нулевые фейки; SEQ=1000000; pos=2)
Цепочка: fakedsplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=2:tcp_seq=1000000

ПРОФИЛЬ 427 - Silver | вариант 17
Название: fakedsplit (разделение + нулевые фейки; SEQ=-3000; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: fakedsplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_seq=-3000

ПРОФИЛЬ 428 - Silver | вариант 18
Название: fakedsplit (разделение + нулевые фейки; SEQ=-3000; pos=1,midsld)
Цепочка: fakedsplit | Processing: SEQ
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=fakedsplit:pos=1,midsld:tcp_seq=-3000
------------------------------------------------------------------------------
СЕМЕЙСТВО 20 - Silver / hostfakesplit (профили 429–456; 28 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 429 - Silver | вариант 1
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TS=-1000; перестановка после SNI; без второго фейка)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:disorder_after:nofake2:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 430 - Silver | вариант 2
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TS=-1000; без второго фейка)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:nofake2:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 431 - Silver | вариант 3
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TS=-1000)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 432 - Silver | вариант 4
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TS=-1000; midhost=midsld; без второго фейка)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:nofake2:midhost=midsld:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 433 - Silver | вариант 5
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TS=-1000; midhost=midsld; перестановка после SNI; без второго фейка)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:disorder_after:nofake2:midhost=midsld:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 434 - Silver | вариант 6
Название: hostfakesplit (фейковые вставки в SNI; случайный host; ACK=-66000; TS-опция первой; перестановка после SNI)
Цепочка: hostfakesplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:disorder_after:tcp_ack=-66000:tcp_ts_up:repeats=1

ПРОФИЛЬ 435 - Silver | вариант 7
Название: hostfakesplit (фейковые вставки в SNI; случайный host; ACK=-66000; TS-опция первой)
Цепочка: hostfakesplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:tcp_ack=-66000:tcp_ts_up:repeats=1

ПРОФИЛЬ 436 - Silver | вариант 8
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TCP MD5; перестановка после SNI)
Цепочка: hostfakesplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:disorder_after:tcp_md5:repeats=1

ПРОФИЛЬ 437 - Silver | вариант 9
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TCP MD5)
Цепочка: hostfakesplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:tcp_md5:repeats=1

ПРОФИЛЬ 438 - Silver | вариант 10
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TS=-1000; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:disorder_after:midhost=midsld:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 439 - Silver | вариант 11
Название: hostfakesplit (фейковые вставки в SNI; случайный host; ACK=-66000; TS-опция первой; midhost=midsld)
Цепочка: hostfakesplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:midhost=midsld:tcp_ack=-66000:tcp_ts_up:repeats=1

ПРОФИЛЬ 440 - Silver | вариант 12
Название: hostfakesplit (фейковые вставки в SNI; случайный host; ACK=-66000; TS-опция первой; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:disorder_after:midhost=midsld:tcp_ack=-66000:tcp_ts_up:repeats=1

ПРОФИЛЬ 441 - Silver | вариант 13
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TCP MD5; без второго фейка)
Цепочка: hostfakesplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:nofake2:tcp_md5:repeats=1

ПРОФИЛЬ 442 - Silver | вариант 14
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TS=-1000; перестановка после SNI)
Цепочка: hostfakesplit | Processing: TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:disorder_after:tcp_ts=-1000:repeats=1

ПРОФИЛЬ 443 - Silver | вариант 15
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TCP MD5; midhost=midsld)
Цепочка: hostfakesplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:midhost=midsld:tcp_md5:repeats=1

ПРОФИЛЬ 444 - Silver | вариант 16
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TCP MD5; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:disorder_after:midhost=midsld:tcp_md5:repeats=1

ПРОФИЛЬ 445 - Silver | вариант 17
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TCP MD5; midhost=midsld; без второго фейка)
Цепочка: hostfakesplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:nofake2:midhost=midsld:tcp_md5:repeats=1

ПРОФИЛЬ 446 - Silver | вариант 18
Название: hostfakesplit (фейковые вставки в SNI; случайный host; AutoTTL=-1,3-20; перестановка после SNI)
Цепочка: hostfakesplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:disorder_after:ip_autottl=-1,3-20:repeats=1

ПРОФИЛЬ 447 - Silver | вариант 19
Название: hostfakesplit (фейковые вставки в SNI; случайный host; AutoTTL=-1,3-20; перестановка после SNI; без второго фейка)
Цепочка: hostfakesplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:disorder_after:nofake2:ip_autottl=-1,3-20:repeats=1

ПРОФИЛЬ 448 - Silver | вариант 20
Название: hostfakesplit (фейковые вставки в SNI; случайный host; AutoTTL=-1,3-20; без второго фейка)
Цепочка: hostfakesplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:nofake2:ip_autottl=-1,3-20:repeats=1

ПРОФИЛЬ 449 - Silver | вариант 21
Название: hostfakesplit (фейковые вставки в SNI; случайный host; AutoTTL=-1,3-20)
Цепочка: hostfakesplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:ip_autottl=-1,3-20:repeats=1

ПРОФИЛЬ 450 - Silver | вариант 22
Название: hostfakesplit (фейковые вставки в SNI; случайный host; AutoTTL=-1,3-20; midhost=midsld; перестановка после SNI; без второго фейка)
Цепочка: hostfakesplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:disorder_after:nofake2:midhost=midsld:ip_autottl=-1,3-20:repeats=1

ПРОФИЛЬ 451 - Silver | вариант 23
Название: hostfakesplit (фейковые вставки в SNI; случайный host; ACK=-66000; TS-опция первой; перестановка после SNI; без второго фейка)
Цепочка: hostfakesplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:disorder_after:nofake2:tcp_ack=-66000:tcp_ts_up:repeats=1

ПРОФИЛЬ 452 - Silver | вариант 24
Название: hostfakesplit (фейковые вставки в SNI; случайный host; TCP MD5; перестановка после SNI; без второго фейка)
Цепочка: hostfakesplit | Processing: MD5
Профиль ограничен префиксом ClientHello - это свойство рецепта, не гарантия совместимости с каждым TLS-сеансом.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:disorder_after:nofake2:tcp_md5:repeats=1

ПРОФИЛЬ 453 - Silver | вариант 25
Название: hostfakesplit (фейковые вставки в SNI; случайный host; AutoTTL=-1,3-20; midhost=midsld; перестановка после SNI)
Цепочка: hostfakesplit | Processing: AutoTTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:disorder_after:midhost=midsld:ip_autottl=-1,3-20:repeats=1

ПРОФИЛЬ 454 - Silver | вариант 26
Название: hostfakesplit (фейковые вставки в SNI; случайный host; ACK=-66000; TS-опция первой; без второго фейка)
Цепочка: hostfakesplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:nofake2:tcp_ack=-66000:tcp_ts_up:repeats=1

ПРОФИЛЬ 455 - Silver | вариант 27
Название: hostfakesplit (фейковые вставки в SNI; случайный host; ACK=-66000; TS-опция первой; midhost=midsld; перестановка после SNI; без второго фейка)
Цепочка: hostfakesplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:disorder_after:nofake2:midhost=midsld:tcp_ack=-66000:tcp_ts_up:repeats=1

ПРОФИЛЬ 456 - Silver | вариант 28
Название: hostfakesplit (фейковые вставки в SNI; случайный host; ACK=-66000; TS-опция первой; midhost=midsld; без второго фейка)
Цепочка: hostfakesplit | Processing: ACK_TS
Требуется поддержка TCP timestamps; если её нет, запуск может не пройти настройку или профиль будет недоступен.
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=hostfakesplit:nofake2:midhost=midsld:tcp_ack=-66000:tcp_ts_up:repeats=1
------------------------------------------------------------------------------
СЕМЕЙСТВО 21 - Silver / multisplit + fakeddisorder (профили 457–478; 22 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 457 - Silver | вариант 1
Название: Разделённый TLS-фейк (штатный SNI; TTL=1; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=sniext+4)
Цепочка: multisplit + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:ip_ttl=1:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:ip_ttl=1

ПРОФИЛЬ 458 - Silver | вариант 2
Название: Разделённый TLS-фейк (штатный SNI; TTL=1; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=sniext+1)
Цепочка: multisplit + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:ip_ttl=1:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:ip_ttl=1

ПРОФИЛЬ 459 - Silver | вариант 3
Название: Разделённый TLS-фейк (штатный SNI; TTL=1; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=2)
Цепочка: multisplit + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:ip_ttl=1:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=2:ip_ttl=1

ПРОФИЛЬ 460 - Silver | вариант 4
Название: Разделённый TLS-фейк (штатный SNI; TTL=1; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: multisplit + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:ip_ttl=1:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:ip_ttl=1

ПРОФИЛЬ 461 - Silver | вариант 5
Название: Разделённый TLS-фейк (штатный SNI; TTL=1; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=1,midsld)
Цепочка: multisplit + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:ip_ttl=1:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:ip_ttl=1

ПРОФИЛЬ 462 - Silver | вариант 6
Название: Разделённый TLS-фейк (штатный SNI; TTL=1; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=host+1)
Цепочка: multisplit + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:ip_ttl=1:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:ip_ttl=1

ПРОФИЛЬ 463 - Silver | вариант 7
Название: Разделённый TLS-фейк (штатный SNI; неверная checksum; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=1)
Цепочка: multisplit + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:badsum:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=1:badsum

ПРОФИЛЬ 464 - Silver | вариант 8
Название: Разделённый TLS-фейк (штатный SNI; TTL=1; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=1)
Цепочка: multisplit + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:ip_ttl=1:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=1:ip_ttl=1

ПРОФИЛЬ 465 - Silver | вариант 9
Название: Разделённый TLS-фейк (штатный SNI; неверная checksum; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=midsld)
Цепочка: multisplit + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:badsum:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:badsum

ПРОФИЛЬ 466 - Silver | вариант 10
Название: Разделённый TLS-фейк (штатный SNI; неверная checksum; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=host+1)
Цепочка: multisplit + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:badsum:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=host+1:badsum

ПРОФИЛЬ 467 - Silver | вариант 11
Название: Разделённый TLS-фейк (штатный SNI; неверная checksum; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: multisplit + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:badsum:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:badsum

ПРОФИЛЬ 468 - Silver | вариант 12
Название: Разделённый TLS-фейк (штатный SNI; неверная checksum; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; неверная checksum; pos=1,midsld)
Цепочка: multisplit + fakeddisorder | Processing: BadSum
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:badsum:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:badsum

ПРОФИЛЬ 469 - Silver | вариант 13
Название: Разделённый TLS-фейк (штатный SNI; флаги +SYN; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=midsld)
Цепочка: multisplit + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:tcp_flags_set=SYN:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:tcp_flags_set=SYN

ПРОФИЛЬ 470 - Silver | вариант 14
Название: Разделённый TLS-фейк (штатный SNI; флаги +SYN; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1)
Цепочка: multisplit + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:tcp_flags_set=SYN:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:tcp_flags_set=SYN

ПРОФИЛЬ 471 - Silver | вариант 15
Название: Разделённый TLS-фейк (штатный SNI; флаги +SYN; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=1,midsld)
Цепочка: multisplit + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:tcp_flags_set=SYN:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=1,midsld:tcp_flags_set=SYN

ПРОФИЛЬ 472 - Silver | вариант 16
Название: Разделённый TLS-фейк (штатный SNI; флаги +SYN; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=sniext+1)
Цепочка: multisplit + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:tcp_flags_set=SYN:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_set=SYN

ПРОФИЛЬ 473 - Silver | вариант 17
Название: Разделённый TLS-фейк (штатный SNI; флаги +SYN; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=sniext+4)
Цепочка: multisplit + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:tcp_flags_set=SYN:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:tcp_flags_set=SYN

ПРОФИЛЬ 474 - Silver | вариант 18
Название: Разделённый TLS-фейк (штатный SNI; флаги +SYN; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; флаги +SYN; pos=2)
Цепочка: multisplit + fakeddisorder | Processing: SYN
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:tcp_flags_set=SYN:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=2:tcp_flags_set=SYN

ПРОФИЛЬ 475 - Silver | вариант 19
Название: Разделённый TLS-фейк (штатный SNI; флаги -ACK; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=midsld)
Цепочка: multisplit + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:tcp_flags_unset=ACK:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:tcp_flags_unset=ACK

ПРОФИЛЬ 476 - Silver | вариант 20
Название: Разделённый TLS-фейк (штатный SNI; флаги -ACK; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=sniext+1)
Цепочка: multisplit + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:tcp_flags_unset=ACK:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+1:tcp_flags_unset=ACK

ПРОФИЛЬ 477 - Silver | вариант 21
Название: Разделённый TLS-фейк (штатный SNI; флаги -ACK; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; флаги -ACK; pos=sniext+4)
Цепочка: multisplit + fakeddisorder | Processing: NoACK
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:tcp_flags_unset=ACK:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=sniext+4:tcp_flags_unset=ACK

ПРОФИЛЬ 478 - Silver | вариант 22
Название: Разделённый TLS-фейк (штатный SNI; TTL=1; pos=2; nodrop) + fakeddisorder (перестановка + нулевые фейки; TTL=1; pos=midsld)
Цепочка: multisplit + fakeddisorder | Processing: TTL
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:blob=fake_default_tls:ip_ttl=1:pos=2:nodrop:repeats=1
  --lua-desync=fakeddisorder:pos=midsld:ip_ttl=1
------------------------------------------------------------------------------
СЕМЕЙСТВО 22 - Silver / tcpseg (профили 479–480; 2 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 479 - Silver | вариант 1
Название: tcpseg (добавочный TCP-сегмент; IP ID=rnd; pos=0,1)
Цепочка: tcpseg | Processing: Tcpseg
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=tcpseg:pos=0,1:ip_id=rnd:repeats=1

ПРОФИЛЬ 480 - Silver | вариант 2
Название: tcpseg (добавочный TCP-сегмент; IP ID=rnd; pos=0,midsld)
Цепочка: tcpseg | Processing: Tcpseg
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=tcpseg:pos=0,midsld:ip_id=rnd:repeats=1
------------------------------------------------------------------------------
СЕМЕЙСТВО 23 - Silver / Большой TLS-префикс / multisplit (профили 481–484; 4 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 481 - Silver | вариант 1
Название: multisplit (ClientHello по частям; pos=1,midsld; seqovl=2048)
Цепочка: multisplit | Processing: OVERLAP
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:pos=1,midsld:seqovl=2048

ПРОФИЛЬ 482 - Silver | вариант 2
Название: multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1; seqovl=1024)
Цепочка: multisplit | Processing: OVERLAP
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:seqovl=1024

ПРОФИЛЬ 483 - Silver | вариант 3
Название: multisplit (ClientHello по частям; pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1; seqovl=2048)
Цепочка: multisplit | Processing: OVERLAP
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:pos=1,sniext+1,host+1,midsld-2,midsld,midsld+2,endhost-1:seqovl=2048

ПРОФИЛЬ 484 - Silver | вариант 4
Название: multisplit (ClientHello по частям; pos=1,midsld; seqovl=1024)
Цепочка: multisplit | Processing: OVERLAP
Аргументы профиля:
  --payload=tls_client_hello
  --lua-desync=multisplit:pos=1,midsld:seqovl=1024
------------------------------------------------------------------------------
СЕМЕЙСТВО 24 - Silver / SYN-data + TCP window-size (профили 485–492; 8 шт.)
------------------------------------------------------------------------------

ПРОФИЛЬ 485 - Silver | вариант 1
Название: SYN-data (16 нулевых байт в SYN)
Цепочка: SYN-data | Processing: SYN
Аргументы профиля:
  --lua-desync=syndata

ПРОФИЛЬ 486 - Silver | вариант 2
Название: SYN-data (TLS-фейк с rnd, dupsid и случайным SNI) + multisplit (pos=1,midsld)
Цепочка: syndata + multisplit | Processing: SYN
Аргументы профиля:
  --lua-desync=syndata:blob=fake_default_tls:tls_mod=rnd,dupsid,rndsni
  --payload=tls_client_hello
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 487 - Silver | вариант 3
Название: SYN-data (короткий TLS-префикс 0x1603) + multisplit (pos=2)
Цепочка: syndata + multisplit | Processing: SYN
Аргументы профиля:
  --lua-desync=syndata:blob=0x1603
  --payload=tls_client_hello
  --lua-desync=multisplit:pos=2

ПРОФИЛЬ 488 - Silver | вариант 4
Название: SYN-data (TLS-фейк с SNI=google.com) + multidisorder (pos=1,midsld)
Цепочка: syndata + multidisorder | Processing: SYN
Аргументы профиля:
  --lua-desync=syndata:blob=fake_default_tls:tls_mod=rnd,dupsid,sni=google.com
  --payload=tls_client_hello
  --lua-desync=multidisorder:pos=1,midsld

ПРОФИЛЬ 489 - Silver | вариант 5
Название: TCP window-size (wsize=1, scale=6) + multisplit (pos=1,midsld)
Цепочка: wssize + multisplit | Processing: SYN
Аргументы профиля:
  --lua-desync=wssize:wsize=1:scale=6
  --payload=tls_client_hello
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 490 - Silver | вариант 6
Название: TCP window-size + SYN-data (16 нулевых байт) + multisplit (pos=1,midsld)
Цепочка: wssize + syndata + multisplit | Processing: SYN
Аргументы профиля:
  --lua-desync=wssize:wsize=1:scale=6
  --lua-desync=syndata
  --payload=tls_client_hello
  --lua-desync=multisplit:pos=1,midsld

ПРОФИЛЬ 491 - Silver | вариант 7
Название: TCP window-size + SYN-data (TLS-фейк с rnd, dupsid и случайным SNI) + multidisorder
Цепочка: wssize + syndata + multidisorder | Processing: SYN
Аргументы профиля:
  --lua-desync=wssize:wsize=1:scale=6
  --lua-desync=syndata:blob=fake_default_tls:tls_mod=rnd,dupsid,rndsni
  --payload=tls_client_hello
  --lua-desync=multidisorder:pos=1,midsld

ПРОФИЛЬ 492 - Silver | вариант 8
Название: TCP window-size + SYN-data (короткий TLS-префикс 0x1603) + multisplit (pos=2)
Цепочка: wssize + syndata + multisplit | Processing: SYN
Аргументы профиля:
  --lua-desync=wssize:wsize=1:scale=6
  --lua-desync=syndata:blob=0x1603
  --payload=tls_client_hello
  --lua-desync=multisplit:pos=2

==============================================================================
КОНЕЦ КАТАЛОГА
Проверяйте фактические аргументы в приложении; не изменяйте рецепт без понимания Zapret2.
