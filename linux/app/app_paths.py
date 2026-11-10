"""Paths shared by the source tree and the installed application.

Copyright Igor Krauch (github.com/igareck).
"""
from pathlib import Path

FILE_LAYOUT = {'antidpi.py': 'app/antidpi.py',
 'diagnostics.py': 'app/diagnostics.py',
 'dependencies.py': 'app/dependencies.py',
 'engine_environment.py': 'app/engine_environment.py',
 'install.py': 'app/install.py',
 'remove_installation.py': 'app/remove_installation.py',
 'cli_ui.py': 'app/cli_ui.py',
 'desktop_integration.py': 'app/desktop_integration.py',
 'global_command.py': 'app/global_command.py',
 'terminal_bootstrap.py': 'app/terminal_bootstrap.py',
 'engine_guard.py': 'app/engine_guard.py',
 'source_download.py': 'app/source_download.py',
 'youtube_probe.py': 'app/youtube_probe.py',
 'target_probe.py': 'app/target_probe.py',
 'app_paths.py': 'app/app_paths.py',
 'desktop_launcher.c': 'app/desktop_launcher.c',
 'INSTALL.sh': 'INSTALL.sh',
 'START.sh': 'START.sh',
 'DELETE.sh': 'DELETE.sh',
 'LICENSE.txt': 'LICENSE.txt',
 'README_Установка_Linux_v1.4.txt': 'README_Установка_Linux_v1.4.txt',
 'README_Стратегии_Linux_v1.4.txt': 'README_Стратегии_Linux_v1.4.txt',
 'catalogue.json': 'data/catalogue.json',
 'release.json': 'data/release.json',
 'upstream.json': 'data/upstream.json',
 'actual_tls_guard.lua': 'data/actual_tls_guard.lua',
 'lists/ips-exclude.txt': 'data/lists/ips-exclude.txt',
 'lists/ips6-exclude.txt': 'data/lists/ips6-exclude.txt',
 'AntiDPIArtLinux16.ttf': 'assets/fonts/AntiDPIArtLinux16.ttf',
 'AntiDPIArt_OFL.txt': 'assets/fonts/AntiDPIArt_OFL.txt',
 'artwork.json': 'assets/logo/artwork.json',
 'ascii-art-new-1147-25102026.txt': 'assets/logo/ascii-art-new-1147-25102026.txt',
 'antidpi-zapret2.png': 'assets/icons/antidpi-zapret2.png',
 'AntiDPI_Zapret2_start.jpg': 'assets/icons/AntiDPI_Zapret2_start.jpg',
 'AntiDPI_Zapret2_delete.jpg': 'assets/icons/AntiDPI_Zapret2_delete.jpg',
 'io.github.antidpi.Zapret2.metainfo.xml': 'packaging/io.github.antidpi.Zapret2.metainfo.xml'}


def resource_path(root, name):
    """Locate a packaged file without depending on the working directory."""
    root = Path(root).resolve()
    if name not in FILE_LAYOUT:
        raise ValueError("Unknown application resource: " + name)
    direct = root / name
    if direct.is_file():
        return direct
    if root.name == "app" and (root.parent / "INSTALL.sh").is_file():
        root = root.parent
    return root / FILE_LAYOUT[name]
