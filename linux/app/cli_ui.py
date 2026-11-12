"""Shared Linux CLI presentation. Copyright Igor Krauch (github.com/igareck)."""
from __future__ import annotations
import json
from pathlib import Path
import os
import platform
import shutil
import subprocess
import sys
import textwrap
import unicodedata
import time
from app_paths import resource_path

VERSION = 'CLI Version 1.8'
SEPARATOR = '----------------------'
ARTWORK_BASE = 0x104000
ARTWORK_FAMILY = 'AntiDPI Artwork 16'


def color(text, code='93'):
    return '\033['+code+'m'+text+'\033[0m' if sys.stdout.isatty() and 'NO_COLOR' not in os.environ else text


def columns():
    try:return max(40,os.get_terminal_size(sys.stdout.fileno()).columns)
    except (OSError,AttributeError):return max(40,shutil.get_terminal_size((100,24)).columns)


def cell_width(text):
    return sum(0 if unicodedata.combining(c) else 2 if unicodedata.east_asian_width(c) in ('W','F') else 1 for c in str(text))


def wrap(text,width):
    parts=[]
    for line in str(text).splitlines() or ['']:
        parts.extend(textwrap.wrap(line,width=max(1,width),break_long_words=True,break_on_hyphens=False) or [''])
    return parts


def table(headers, rows, widths):
    border='+'+'+'.join('-'*(w+2) for w in widths)+'+'
    print(border)
    def emit(values, heading=False):
        cells=[wrap(value,w) for value,w in zip(values,widths)]
        for i in range(max(map(len,cells))):
            line='|'
            for parts,w in zip(cells,widths):
                item=parts[i] if i<len(parts) else ''
                line+=' '+item+' '*(w-cell_width(item)+1)+'|'
            print(color(line,'96') if heading else line)
    emit(headers,True);print(border)
    for row in rows:
        emit(row);print(border)


def paragraphs(lines, code=None):
    # A newline here is a paragraph boundary, not a screen-width boundary.
    # Let the terminal create soft wraps that it can reflow on window resize.
    for line in lines:
        print(color(str(line),code) if code else str(line))


def tile_artwork_lines(root):
    # All 400x145 original shade cells are packed into these color-font tiles.
    # No terminal font change, image resizing or low-resolution substitution.
    data=json.loads(resource_path(root, 'artwork.json').read_text(encoding='utf-8'))
    rows=data['tiles']
    if len(rows)!=29 or any(len(row)!=100 for row in rows):
        raise ValueError('Некорректные размеры исходного рисунка.')
    return rows


def tile_font_available():
    if os.environ.get('TERM')=='linux' or os.environ.get('SSH_CONNECTION'):
        return False
    # A fresh root-side fc-match cannot describe an already-running terminal's
    # Pango font map. Print PUA tiles only inside the prepared native renderer.
    return os.environ.get('AntiDPI_ARTWORK_RENDERER') == 'fresh-gnome-fontconfig-v1'


def show_artwork(root):
    # The supplied image occupies 100 cells by 29 lines. Do not substitute
    # Braille/dither or resample the original source when the window is narrow.
    if not tile_font_available():
        if os.environ.get('TERM') != 'linux' and not os.environ.get('SSH_CONNECTION'):
            print('Для исходного логотипа запустите INSTALL.sh, START.sh или DELETE.sh в графической сессии GNOME Terminal.')
        return
    if columns()<100 and sys.stdin.isatty():
        size=shutil.get_terminal_size((80,24))
        print('\033[8;'+str(max(size.lines,40))+';110t',end='',flush=True)
        for _ in range(8):
            if columns()>=100:break
            time.sleep(.05)
        if columns()<100:
            input('Для исходного рисунка увеличьте ширину окна минимум до 100 символов и нажмите Enter.\n')
    if columns()<100:
        print('Исходный рисунок требует ширину окна не менее 100 символов.')
        return
    print()
    for line in tile_artwork_lines(root):print(color(line,'38;2;255;255;255;48;2;12;12;12'))
    print()


def show_header(root, artwork=True):
    machine=platform.machine().lower()
    architecture='x64' if machine in ('x86_64','amd64') else 'ARM64' if machine in ('aarch64','arm64') else machine
    rule='='*min(79,columns())
    lines=[rule,'  AntiDPI Strategies + Bol-Van Zapret2',
           '  '+VERSION+' | Linux Ubuntu/Debian '+architecture,rule,
           '  ПРОГРАММА ГОТОВЫХ ANTI-DPI СТРАТЕГИЙ ОТ AntiDPI НА БАЗЕ ZAPRET2 (BOL-VAN)',
           '  В УДОБНОЙ CLI ОБОЛОЧКЕ ДЛЯ РАБОТЫ ЧЕРНЫХ СПИСКОВ VPN/TOR + YOUTUBE',rule,
           '  AntiDPI из репозитория:',
           '  https://github.com/igareck/anti-dpi-for-russia',
           '  VPN/Tor Черные Списки:',
           '  https://github.com/igareck/vpn-configs-for-russia',
           '  Telegram: https://t.me/igareq',rule,
           '  Zapret2 от Bol-Van, сборка для Linux из репозитория:',
           '  https://github.com/bol-van/zapret2',
           '  Скачивается напрямую или через прокси из оригинального репозитория',rule]
    paragraphs(lines,'96')
    if artwork and sys.stdout.isatty():
        show_artwork(root)


def pause(message):
    if sys.stdin.isatty() and sys.stdout.isatty():
        input('\n'+SEPARATOR+'\n\n'+message+'\n')


def show_intro(root, prefix=None, installing=False):
    show_header(root)
    destination='папка, которую вы выберете далее' if installing else str(prefix or root)
    engine_path='<выбранная папка>/engine/nfqws2' if installing else str((prefix or root)/'engine/nfqws2')
    paragraphs(['','ВНИМАНИЕ!',
      '1. Если используется антивирус, добавьте папку установленной программы, файл nfqws2 и процесс nfqws2 в его исключения.',
      '   Папка программы: '+destination,
      '   Движок: '+engine_path,
      '2. Добавьте в исключения антивируса процессы используемых VPN/Tor-клиентов и их ядер.',
      '3. Если антивирус продолжает мешать соединениям, временно отключите его для проверки.',
      '   Эти инструкции относятся к установленному антивирусу; UFW и системный брандмауэр программа не отключает.'],'93')
    pause('Нажмите Enter, чтобы продолжить и прочитать ЗАМЕТКИ')
    paragraphs(['','ЗАМЕТКИ:',
      '1. Программа с готовыми AntiDPI стратегиями разработана специально для восстановления работоспособности VPN-конфигураций Черных Списков, Tor и YouTube.',
      '2. Для работы с VPN Черных Списков или Tor включайте каждую стратегию поочередно, затем пингуйте подписки/мосты в вашем клиенте!',
      '   На одних стратегиях будет больше живых VPN-конфигураций, на других меньше.',
      '3. Для работы с YouTube следуйте инструкциям ниже и запустите автоматическую проверку стратегий на доступ к YouTube.',
      '   VPN для доступа к YouTube не требуется. YouTube работает напрямую из вашей сети вместе с AntiDPI стратегиями.',
      '4. Успешный тест на доступ к YouTube не всегда означает, что стратегия идеально работает с VPN-конфигурациями.',
      '   В свою очередь — отрицательный тест на YouTube абсолютно не значит, что стратегия не работает с VPN, часто наоборот.',
      '   Бывает, что стратегия не дает прямой доступ на YouTube, но при этом пингует самое максимальное число VPN-конфигураций.',
      '5. Стратегии Golden для VPN/Tor/YouTube могут работать лучше, чем Silver.',
      '6. Набор стратегий протестирован на российских кабельных/мобильных сетях.'],'93')
    pause('Нажмите Enter, чтобы продолжить установку' if installing else 'Нажмите Enter, чтобы продолжить работу')


def catalogue(data):
    print('\n######################\n')
    info=data['CatalogueInfo']; total=int(info['ProfileCount']); golden=45; silver=total-golden
    paragraphs([f'КАТАЛОГ (Октябрь 2026): Golden+Silver; {total} стратегии AntiDPI.',
                f'Golden: 1–{golden} ({golden}). Silver: {golden+1}–{total} ({silver}).'],'96')
    print('\n'+SEPARATOR+'\n\nВводите номер стратегии из колонки «Номера».')
    family_width=max(10,min(65,columns()-40))
    rows=[]
    for f in data['FamilyRows']:
        group,name=f['Name'].split(' / ',1)
        numbers=str(f['First']) if f['First']==f['Last'] else f'{f["First"]}–{f["Last"]}'
        rows.append([f['Number'],group,name,f['Count'],numbers])
    table(['#','Набор','Семейство','Кол.','Номера'],rows,[2,6,family_width,4,7])


def selection_prompt():
    print('\n'+color('Выберите один из двух вариантов.','96'))
    paragraphs(['1. Либо введите номер AntiDPI-стратегии из таблицы (0 — выход из программы)',
      '2. Либо, чтобы проверить диапазон стратегий на доступ к YouTube, наберите слово "Youtube" (без учета регистра) и далее следуйте указаниям'])
    print(SEPARATOR)
    return input('Ваш выбор: ').strip()
