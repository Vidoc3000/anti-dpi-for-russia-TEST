"""Offline checks for Linux launch, dependency and container regressions."""
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
import json
import os
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch, Mock

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO/'linux/app'))
import app_paths
import dependencies
import desktop_integration as desktop
import diagnostics
import engine_environment as environment
import antidpi
import terminal_bootstrap as terminal
import remove_installation
import target_probe


def state(mapping='0 0 4294967295', groups='allow', caps='ffffffffffffffff'):
    return dict(uid_map=mapping, gid_map=mapping, setgroups=groups, cap_effective=caps)


class ScopeDiagnosticTests(unittest.TestCase):
    def test_all_ports_explains_coverage_and_potential_overhead(self):
        text=' '.join(antidpi.scope_guidance('all'))
        self.assertIn('IPv4 TCP',text)
        self.assertIn('IPv6, UDP и QUIC/HTTP/3',text)
        self.assertIn('нагрузка/задержка',text)
        self.assertIn('динамические порты',text)

    def test_narrow_scope_reports_selected_port_count(self):
        text=' '.join(antidpi.scope_guidance('443,1000-1002'))
        self.assertIn('всего 4 TCP-портов',text)
        self.assertIn('остальных портах не перехватываются',text)
        self.assertNotIn('охват максимальный',text)

    def test_queue_drop_metrics_are_explained_and_flagged(self):
        with redirect_stdout(StringIO()) as output:
            antidpi.show_queue_metrics(12,{'id_sequence':500,'kernel_drops':2,'userspace_drops':1})
        self.assertIn('последний ID пакета 500',output.getvalue())
        self.assertIn('потери ядра 2, userspace 1',output.getvalue())
        self.assertIn('Есть потери в NFQUEUE',output.getvalue())

    def test_nfqueue_progress_uses_packet_sequence_changes_not_monotonic_counts(self):
        self.assertTrue(antidpi.queue_progressed({'id_sequence':0xffffffff},{'id_sequence':0}))
        self.assertFalse(antidpi.queue_progressed({'id_sequence':7},{'id_sequence':7}))
        self.assertFalse(antidpi.queue_progressed({},{}))

    def test_windows_prompt_discloses_protocol_limits_and_all_port_cost(self):
        source=(REPO/'windows/payload/AntiDPI_Launcher_Core_20261023_public_v1.ps1').read_text(encoding='utf-8')
        self.assertIn('IPv6, UDP и QUIC/HTTP/3 не перехватываются',source)
        self.assertIn('увеличить нагрузку',source)
        self.assertIn('могут требовать all',source)


class ContainerTests(unittest.TestCase):
    def test_host_preserves_upstream_identity(self):
        self.assertEqual(environment.engine_identity(state()), (2147483647, 2147483647))

    def test_lxc_uses_mapped_identity(self):
        self.assertEqual(environment.engine_identity(state('0 100000 65536')), (65534, 65534))

    def test_uid_and_gid_maps_can_differ(self):
        s = state('0 100000 65536')
        s['gid_map'] = '0 100000 1000'
        self.assertEqual(environment.engine_identity(s), (65534, 999))

    def test_root_only_mapping_is_rejected(self):
        with self.assertRaisesRegex(RuntimeError, 'ненулевого'):
            environment.engine_identity(state('0 0 1'))

    def test_setgroups_deny_is_not_bypassed(self):
        with self.assertRaisesRegex(RuntimeError, 'запрещает setgroups'):
            environment.engine_identity(state(groups='deny'))

    def test_missing_capabilities_stop_before_nft(self):
        with patch.object(environment, 'snapshot', return_value=state(caps='0')), \
             patch.object(environment.subprocess, 'run') as nft:
            with self.assertRaisesRegex(RuntimeError, 'CAP_NET_ADMIN'):
                environment.check_environment()
            nft.assert_not_called()

    def test_nft_probe_only_checks_without_applying(self):
        with patch.object(environment, 'snapshot', return_value=state()), \
             patch.object(environment.subprocess, 'run', return_value=Mock(returncode=0)) as nft:
            environment.check_environment()
            self.assertEqual(nft.call_args.args[0], ['nft', '--check', '-f', '-'])
            self.assertIn('queue num', nft.call_args.kwargs['input'])

    def test_failed_preflight_keeps_snapshot(self):
        with tempfile.TemporaryDirectory() as temporary, \
             patch.object(environment, 'snapshot', return_value=state(caps='0')):
            with self.assertRaises(RuntimeError):
                environment.check_environment(Path(temporary))
            self.assertEqual(json.loads((Path(temporary)/'engine-environment.json').read_text())['cap_effective'], '0')

    def test_permission_error_is_not_called_strategy_incompatibility(self):
        text = environment.failure_message(1, 1, 'setgroups: Invalid argument')
        self.assertIn('прав/окружения', text)
        self.assertNotIn('несовместима', text)

    def test_engine_identity_is_consistent_for_all_recipes(self):
        with patch.object(antidpi.os, 'geteuid', return_value=0), \
             patch.object(environment, 'snapshot', return_value=state('0 100000 65536')):
            for row in antidpi.load_catalogue()['ProfileRows']:
                args = antidpi.engine_arguments(Path('/opt/antidpi'), row)
                self.assertEqual(args.count('--uid=65534:65534'), 1)
                self.assertEqual(args[-len(row['Args']):], row['Args'])


class TerminalTests(unittest.TestCase):
    def launch(self, graphical, paths, result=0):
        user = dict(home='/home/example', username='example', uid=1000, gid=1000) if graphical else None
        with patch.object(desktop, 'graphical_user', return_value=user), \
             patch.object(terminal, 'find_terminal', return_value=paths), \
             patch.object(terminal.sys.stdin, 'isatty', return_value=True), \
             patch.object(terminal.sys.stdout, 'isatty', return_value=True), \
             patch.object(terminal.os, 'geteuid', return_value=1000), \
             patch.object(terminal, 'current_terminal') as current, \
             patch.object(terminal.subprocess, 'Popen', return_value=Mock(wait=Mock(return_value=result))) as graphical_process:
            terminal.launch('run', ['--strategy', '25'])
            return current.call_count, graphical_process.call_count

    def test_kde_without_gnome_uses_existing_terminal(self):
        self.assertEqual(self.launch(True, (None, None)), (1, 0))

    def test_ssh_and_headless_do_not_open_windows(self):
        self.assertEqual(self.launch(False, ('gnome', 'server')), (1, 0))
        self.assertIsNone(desktop.graphical_user({'SSH_CONNECTION': 'fixture'}))

    def test_gnome_still_uses_artwork_window(self):
        self.assertEqual(self.launch(True, ('gnome', 'server')), (0, 1))

    def test_precommand_window_failure_falls_back_once(self):
        self.assertEqual(self.launch(True, ('gnome', 'server'), terminal.TERMINAL_UNAVAILABLE), (1, 1))

    def test_application_failure_is_never_retried(self):
        self.assertEqual(self.launch(True, ('gnome', 'server'), 1), (0, 1))

    def test_desktop_without_gnome_opens_terminal_before_sudo(self):
        with patch.object(terminal.sys.stdin, 'isatty', return_value=False), \
             patch.object(terminal.os, 'geteuid', return_value=1000), \
             patch.object(terminal, 'find_terminal', return_value=(None, None)), \
             patch.object(terminal, 'text_terminals', return_value=iter([['/usr/bin/konsole', '--nofork', '-e']])), \
             patch.object(terminal.subprocess, 'Popen', return_value=Mock(wait=Mock(return_value=0))) as process:
            terminal.launch_desktop('uninstall', [])
            argv = process.call_args.args[0]
            self.assertEqual(argv[:4], ['/usr/bin/konsole', '--nofork', '-e', 'sudo'])
            self.assertIn('--inside-plain', argv)
            self.assertEqual(argv[-1], 'uninstall')

    def test_desktop_application_error_does_not_launch_another_terminal(self):
        with patch.object(terminal.sys.stdin, 'isatty', return_value=False), \
             patch.object(terminal.os, 'geteuid', return_value=1000), \
             patch.object(terminal, 'find_terminal', return_value=('gnome', 'server')), \
             patch.object(terminal, 'session', return_value=1), \
             patch.object(terminal, 'text_terminals') as fallback:
            self.assertEqual(terminal.launch_desktop('run', []), 1)
            fallback.assert_not_called()

    def test_actual_desktop_entry_uses_new_launcher_for_both_actions(self):
        for action, role in (('start', 'run'), ('delete', 'uninstall')):
            with patch.object(sys, 'argv', ['desktop_integration.py', '--launch', action]), \
                 patch.object(terminal, 'launch_desktop', return_value=0) as launch:
                with self.assertRaises(SystemExit) as stopped:
                    runpy.run_path(str(REPO/'linux/app/desktop_integration.py'), run_name='__main__')
                self.assertEqual(stopped.exception.code, 0)
                launch.assert_called_once_with(role, [])

    def test_plain_window_removes_artwork_marker(self):
        with patch.object(terminal.sys, 'argv', ['bootstrap', '--inside-plain', 'run']), \
             patch.object(terminal.os, 'geteuid', return_value=0), \
             patch.dict(terminal.os.environ, {terminal.READY: terminal.RENDERER}), \
             patch.object(terminal.os, 'execve', side_effect=SystemExit(0)) as execute:
            with self.assertRaises(SystemExit):
                terminal.main()
            env = execute.call_args.args[2]
            self.assertNotIn(terminal.READY, env)
            self.assertEqual(env['AntiDPI_TERMINAL_WINDOW'], '1')

    def test_font_setup_failure_happens_before_starting_application(self):
        with patch.object(terminal, 'find_terminal', return_value=('gnome', 'server')), \
             patch.object(terminal, 'fontconfig_file', side_effect=RuntimeError('font fixture')), \
             patch.object(terminal.subprocess, 'Popen') as process:
            with self.assertRaises(terminal.TerminalUnavailable):
                terminal.artwork_session('install', [])
            process.assert_not_called()

    def test_dbus_failure_happens_before_starting_application(self):
        server = Mock(poll=Mock(return_value=None))
        with patch.object(terminal, 'find_terminal', return_value=('gnome', 'server')), \
             patch.object(terminal, 'fontconfig_file', return_value=Path('/fixture/fonts.conf')), \
             patch.object(terminal, 'verify_font'), \
             patch.object(terminal, 'bus_name_owned', side_effect=OSError('D-Bus fixture')), \
             patch.object(terminal.subprocess, 'Popen', return_value=server) as process:
            with self.assertRaises(terminal.TerminalUnavailable):
                terminal.artwork_session('install', [])
            self.assertEqual(process.call_count, 1)  # Only the server; never the client/application.
            server.terminate.assert_called_once()


class DependencyTests(unittest.TestCase):
    def test_ready_dependencies_need_neither_apt_nor_manual_flag(self):
        with patch.object(dependencies, 'missing_dependencies', return_value=[]), \
             patch.object(dependencies.subprocess, 'run') as apt:
            dependencies.ensure_dependencies(['fixture'])
            apt.assert_not_called()

    def test_skip_deps_still_checks_missing_dependencies(self):
        with patch.object(dependencies, 'missing_dependencies', return_value=['nft']), \
             patch.object(dependencies.subprocess, 'run') as apt:
            with self.assertRaisesRegex(RuntimeError, 'nft'):
                dependencies.ensure_dependencies(['fixture'], skip=True)
            apt.assert_not_called()

    def test_non_debian_missing_dependencies_does_not_invoke_apt(self):
        with patch.object(dependencies, 'missing_dependencies', return_value=['nft']), \
             patch.object(dependencies.Path, 'is_file', return_value=False), \
             patch.object(dependencies.subprocess, 'run') as apt:
            with self.assertRaisesRegex(RuntimeError, 'дистрибутива'):
                dependencies.ensure_dependencies(['fixture'])
            apt.assert_not_called()


class EndpointProbeTests(unittest.TestCase):
    def test_target_validation_normalizes_idn_and_defaults_sni(self):
        target = target_probe.validate_target({'host':'пример.рф','port':'443'})
        self.assertEqual(target['host'],'xn--e1afmkfd.xn--p1ai')
        self.assertEqual(target['sni'],target['host'])
        self.assertTrue(target['verify_certificate'])

    def test_target_validation_rejects_bad_ports_and_names(self):
        for value in (
            {'host':'vpn.example.org','port':0},
            {'host':'vpn.example.org/path','port':443},
            {'host':'vpn.example.org','port':443,'sni':'192.0.2.1'},
            {'host':'2001:db8::1','port':443,'sni':'vpn.example.org'},
        ):
            with self.subTest(value=value), self.assertRaises(ValueError):
                target_probe.validate_target(value)

    def test_tls_probe_binds_interface_and_source_port_and_sends_no_application_data(self):
        raw=Mock()
        raw.getsockname.return_value=('0.0.0.0',20001)
        secure=Mock()
        secure.version.return_value='TLSv1.3'
        context=Mock()
        context.wrap_socket.return_value=secure
        info=(target_probe.socket.AF_INET,target_probe.socket.SOCK_STREAM,6,'',('203.0.113.9',443))
        with patch.object(target_probe.socket,'socket',return_value=raw):
            result=target_probe.probe('eth0',(20000,20063),
                {'host':'vpn.example.org','port':443,'sni':'front.example.org'},
                resolver=Mock(return_value=[info]),context_factory=Mock(return_value=context))
        self.assertTrue(result['pass'],result)
        self.assertEqual(result['tls'],'TLSv1.3')
        raw.bind.assert_called_once_with(('0.0.0.0',20000))
        raw.connect.assert_called_once_with(info[4])
        context.wrap_socket.assert_called_once_with(raw,server_hostname='front.example.org')
        secure.sendall.assert_not_called()

    def test_cli_target_argument_requires_explicit_tcp_port(self):
        with self.assertRaises(ValueError):
            antidpi.parse_target_argument('vpn.example.org')
        target=antidpi.parse_target_argument('vpn.example.org:2053','front.example.org')
        self.assertEqual((target['host'],target['port'],target['sni']),
                         ('vpn.example.org',2053,'front.example.org'))

    def test_ranking_prefers_reliability_then_handshake_latency(self):
        scores=[
            {'number':3,'successes':1,'success_rate':.5,'median_seconds':.1},
            {'number':2,'successes':2,'success_rate':1.0,'median_seconds':.5},
            {'number':1,'successes':2,'success_rate':1.0,'median_seconds':.2},
        ]
        self.assertEqual([row['number'] for row in antidpi.rank_endpoint_scores(scores)],[1,2,3])

    def test_new_syn_data_and_window_size_profiles_are_catalogued(self):
        data=antidpi.load_catalogue()
        self.assertEqual(data['CatalogueInfo']['ProfileCount'],492)
        self.assertEqual(data['CatalogueInfo']['FamilyCount'],24)
        rows={row['Number']:row for row in data['ProfileRows']}
        self.assertEqual(set(range(485,493)),set(rows) - set(range(1,485)))
        self.assertEqual(antidpi.recipe_range('485-492'),list(range(485,493)))
        with self.assertRaises(ValueError): antidpi.recipe_range('493')
        self.assertEqual(rows[485]['Args'],['--lua-desync=syndata'])
        self.assertIn('--lua-desync=syndata:blob=fake_default_tls:tls_mod=rnd,dupsid,rndsni',rows[486]['Args'])
        self.assertIn('--lua-desync=wssize:wsize=1:scale=6',rows[489]['Args'])
        self.assertTrue(all(row['NeedsTimestamps'] is False for row in rows.values() if row['Number'] >= 485))
        self.assertTrue(all(any(arg.startswith('--lua-desync=syndata') for arg in row['Args']) or
                            any(arg.startswith('--lua-desync=wssize') for arg in row['Args'])
                            for row in rows.values() if row['Number'] >= 485))

    def test_adaptive_search_chooses_one_middle_profile_per_family_then_expands(self):
        data=antidpi.load_catalogue()
        rows={row['Number']:row for row in data['ProfileRows']}
        selected=list(rows)
        representatives=antidpi.adaptive_representatives(rows,selected)
        self.assertEqual(len(representatives),len(data['FamilyRows']))
        self.assertEqual(len({rows[number]['Family'] for number in representatives}),len(data['FamilyRows']))
        family=rows[representatives[0]]['Family']
        remaining=antidpi.adaptive_family_candidates(rows,selected,family,set(representatives))
        self.assertEqual(len(remaining),data['FamilyRows'][family-1]['Count']-1)
        self.assertTrue(all(rows[number]['Family']==family for number in remaining))


class ResourceTests(unittest.TestCase):
    def test_standard_uninstall_retains_error_reporter_for_later_purge(self):
        self.assertIn('diagnostics.py', remove_installation.RETAIN)

    def test_every_installed_resource_exists(self):
        for name in app_paths.FILE_LAYOUT:
            self.assertTrue(app_paths.resource_path(REPO/'linux/app', name).is_file(), name)

    def test_help_and_catalogue_work_without_display(self):
        env = dict(os.environ, DISPLAY='', WAYLAND_DISPLAY='', PYTHONDONTWRITEBYTECODE='1')
        for arguments in (['--help'], ['show', '--strategy', '25'], ['show', '--strategy', '492'], ['benchmark', '--help']):
            result = subprocess.run(['bash', str(REPO/'linux/START.sh')]+arguments,
                                    env=env, capture_output=True, text=True, timeout=20)
            self.assertEqual(result.returncode, 0, result.stderr)
            if arguments == ['benchmark', '--help']:
                self.assertIn('--target', result.stdout)
                self.assertIn('TLS-узел', result.stdout)

    def test_traceback_is_visible_and_private_log_is_created(self):
        with tempfile.TemporaryDirectory() as temporary, redirect_stderr(StringIO()) as output:
            try:
                raise RuntimeError('fixture failure')
            except RuntimeError as error:
                path = diagnostics.report_exception(Path(temporary), error, 'unit test')
            self.assertIn('Traceback', output.getvalue())
            self.assertIn('fixture failure', path.read_text())
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)


if __name__ == '__main__':
    unittest.main()
