"""Offline checks for Linux launch, dependency and container regressions."""
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
import io
import json
import os
from pathlib import Path
import runpy
import subprocess
import sys
import tarfile
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
import install as linux_installer
import updater


def state(mapping='0 0 4294967295', groups='allow', caps='ffffffffffffffff'):
    return dict(uid_map=mapping, gid_map=mapping, setgroups=groups, cap_effective=caps)


class ScopeDiagnosticTests(unittest.TestCase):
    def test_all_ports_explains_coverage_and_potential_overhead(self):
        text=' '.join(antidpi.scope_guidance('all'))
        self.assertIn('IPv4 TCP',text)
        self.assertIn('IPv4 TCP/TLS',text)
        self.assertIn('VPN/Tor-туннель, авторизация',text)
        quic=' '.join(antidpi.scope_guidance('443','ipv6','udp-quic'))
        self.assertIn('IPv6 UDP/QUIC',quic)
        self.assertIn('QUIC Initial',quic)
        self.assertIn('нагрузка/задержка',text)
        self.assertIn('Динамические порты',text)

    def test_narrow_scope_reports_selected_port_count(self):
        text=' '.join(antidpi.scope_guidance('443,1000-1002'))
        self.assertIn('всего 4 TCP-портов',text)
        self.assertIn('остальные порты не перехватываются',text)
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
        self.assertIn("--wf-l3=$AddressFamily",source)
        self.assertIn("--filter-$transport=$ports",source)
        self.assertIn('нагрузку',source)
        self.assertIn('могут требовать all',source)


class NetworkModeTests(unittest.TestCase):
    def test_ipv6_quic_engine_args_use_correct_family_transport_and_recipe(self):
        row=antidpi.QUIC_PROFILES['fake2']
        args=antidpi.engine_arguments(Path('/opt/antidpi'),row,queue=20001,scope='443',
                                      address_family='ipv6',protocol='udp-quic')
        self.assertIn('--bind-fix6',args)
        self.assertIn('--filter-udp=443',args)
        self.assertIn('--filter-l7=quic',args)
        self.assertIn('--ipset-exclude=/opt/antidpi/lists/ips6-exclude.txt',args)
        self.assertIn('--payload=quic_initial',args)
        self.assertIn('--lua-desync=fake:blob=fake_default_quic:repeats=2',args)
        self.assertNotIn('--bind-fix4',args)
        self.assertNotIn('--filter-tcp=443',args)

    def test_ipv6_quic_nft_rules_match_udp_and_ipv6_only(self):
        rules=antidpi.nft_rules('antidpi_z2_012345abcdef','eth0',
            [{'queue':24000,'ports':None}],['::1/128','fc00::/7','fe80::/10','ff00::/8'],
            '443',False,'ipv6','udp-quic')
        self.assertIn('table ip6 antidpi_z2_012345abcdef',rules)
        self.assertIn('type ipv6_addr',rules)
        self.assertIn('ip6 daddr @excluded',rules)
        self.assertIn('udp dport { 443 }',rules)
        self.assertIn('udp sport { 443 }',rules)
        self.assertIn('queue num 24000 bypass',rules)
        self.assertNotIn('table ip ',rules)
        self.assertNotIn('tcp dport',rules)

    def test_ipv4_tls_keeps_tcp_specific_filters(self):
        row=antidpi.load_catalogue()['ProfileRows'][0]
        args=antidpi.engine_arguments(Path('/opt/antidpi'),row,scope='443')
        self.assertIn('--bind-fix4',args)
        self.assertIn('--filter-tcp=443',args)
        self.assertIn('--filter-l7=tls',args)


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

    def test_diagnostics_command_runs_unprivileged_to_keep_archive_user_readable(self):
        with patch.object(terminal.os,'execv',side_effect=SystemExit(0)) as execute, \
             patch.object(terminal,'find_terminal') as find_terminal:
            with self.assertRaises(SystemExit):
                terminal.launch('run',['diagnostics','--output','/tmp/report.zip'])
        execute.assert_called_once()
        self.assertNotIn('sudo',execute.call_args.args[1])
        find_terminal.assert_not_called()

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

    def test_ipv6_tls_endpoint_is_accepted_with_dns_sni(self):
        target=target_probe.validate_target({'host':'2001:db8::1','port':443,'sni':'vpn.example.org'})
        self.assertEqual(target['host'],'2001:db8::1')
        self.assertEqual(target['sni'],'vpn.example.org')
        self.assertEqual(antidpi.parse_target_argument('[2001:db8::1]:443','vpn.example.org')['host'],'2001:db8::1')

    def test_target_validation_rejects_bad_ports_and_names(self):
        for value in (
            {'host':'vpn.example.org','port':0},
            {'host':'vpn.example.org/path','port':443},
            {'host':'vpn.example.org','port':443,'sni':'192.0.2.1'},
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


class UpdaterTests(unittest.TestCase):
    def release(self, version='1.19', archive_size=123):
        archive_name=f'AntiDPI_CLI_v{version}_Linux_x64.tar.gz'
        sums_name=f'SHA256SUMS_Linux_v{version}.txt'
        base=f'https://github.com/Vidoc3000/anti-dpi-for-russia-TEST/releases/download/v{version}/'
        return {
            'draft':False, 'prerelease':False, 'tag_name':'v'+version,
            'assets':[
                {'name':archive_name,'size':archive_size,'browser_download_url':base+archive_name},
                {'name':sums_name,'size':100,'browser_download_url':base+sums_name},
            ],
        }

    def test_latest_linux_asset_selection_requires_matching_repo_tag_and_checksum(self):
        version,name,archive,sums,size=updater.latest_linux_assets(self.release())
        self.assertEqual((version,name,size),('1.19','AntiDPI_CLI_v1.19_Linux_x64.tar.gz',123))
        self.assertTrue(archive.endswith('/v1.19/'+name))
        self.assertTrue(sums.endswith('/v1.19/SHA256SUMS_Linux_v1.19.txt'))
        invalid=self.release();invalid['assets'][0]['browser_download_url']='https://example.com/file'
        with self.assertRaisesRegex(RuntimeError,'(?i)ссылки'):
            updater.latest_linux_assets(invalid)
        invalid=self.release();invalid['tag_name']='v1.18'
        with self.assertRaisesRegex(RuntimeError,'Тег'):
            updater.latest_linux_assets(invalid)

    def test_checksum_requires_one_exact_sha256_record(self):
        filename='AntiDPI_CLI_v1.19_Linux_x64.tar.gz'
        value='a'*64
        self.assertEqual(updater.checksum_for(value+'  '+filename+'\n',filename),value)
        with self.assertRaisesRegex(RuntimeError,'SHA256SUMS'):
            updater.checksum_for(value+'  other.tar.gz\n',filename)
        with self.assertRaisesRegex(RuntimeError,'SHA256SUMS'):
            updater.checksum_for(value+'  '+filename+'\n'+value+'  '+filename+'\n',filename)

    def test_release_attestation_uses_bundle_and_pins_repository_workflow_and_main_ref(self):
        with tempfile.TemporaryDirectory() as temporary:
            package=Path(temporary)/'release.tar.gz';package.write_bytes(b'fixture')
            bundle={'mediaType':'application/vnd.dev.sigstore.bundle.v0.3+json','dsseEnvelope':{'fixture':True}}
            api_result=json.dumps({'attestations':[{'bundle':bundle}]}).encode()
            def verify_command(command,**_kwargs):
                bundle_path=Path(command[command.index('--bundle')+1])
                self.assertEqual(json.loads(bundle_path.read_text()),bundle)
                self.assertEqual(command[1:3],['attestation','verify'])
                self.assertEqual(command[3],str(package.resolve()))
                self.assertEqual(command[command.index('--repo')+1],updater.ATTESTATION_REPOSITORY)
                self.assertEqual(command[command.index('--signer-workflow')+1],updater.ATTESTATION_WORKFLOW)
                self.assertEqual(command[command.index('--source-ref')+1],'refs/heads/main')
                self.assertIn('--deny-self-hosted-runners',command)
                return Mock(returncode=0)
            with patch.object(updater,'_trusted_gh',return_value='/usr/bin/gh'), \
                 patch.object(updater,'read_url',return_value=api_result) as read, \
                 patch.object(updater.subprocess,'run',side_effect=verify_command):
                updater.verify_release_attestation(package)
            read.assert_called_once_with(
                updater.ATTESTATION_API+'sha256:'+__import__('hashlib').sha256(b'fixture').hexdigest()+'?per_page=100',
                updater.MAX_ATTESTATION_RESPONSE_BYTES,'application/vnd.github+json',updater.ATTESTATION_API_VERSION)

    def test_attestation_redirects_are_checked_before_following(self):
        host=updater.ATTESTATION_BUNDLE_HOST
        handler=updater._SafeRedirectHandler({host})
        request=updater.urllib.request.Request('https://'+host+'/attestations/item')
        for target in ('http://127.0.0.1/metadata',
                       'https://evil.example/attestations/item',
                       'https://'+host+':444/attestations/item'):
            with self.assertRaises(updater.urllib.error.URLError):
                handler.redirect_request(request,None,302,'Found',{},target)
        allowed=handler.redirect_request(request,None,302,'Found',{},'https://'+host+'/attestations/next')
        self.assertEqual(allowed.full_url,'https://'+host+'/attestations/next')

    def test_attestation_bundle_url_is_restricted_to_official_https_storage(self):
        good='https://'+updater.ATTESTATION_BUNDLE_HOST+'/attestations/1/2.json.sn?sig=fixture'
        self.assertEqual(updater._validated_bundle_url(good),good)
        for bad in ('http://'+updater.ATTESTATION_BUNDLE_HOST+'/attestations/x?sig=x',
                    'https://tmaproduction.blob.core.windows.net.evil.test/attestations/x?sig=x',
                    'https://user@'+updater.ATTESTATION_BUNDLE_HOST+'/attestations/x?sig=x',
                    'https://'+updater.ATTESTATION_BUNDLE_HOST+':444/attestations/x?sig=x',
                    'https://'+updater.ATTESTATION_BUNDLE_HOST+'/elsewhere?sig=x'):
            with self.assertRaisesRegex(RuntimeError,'недопустимую ссылку'):
                updater._validated_bundle_url(bad)

    def test_release_attestation_failure_and_missing_cli_fail_closed(self):
        with tempfile.TemporaryDirectory() as temporary:
            package=Path(temporary)/'release.tar.gz';package.write_bytes(b'fixture')
            api_result=json.dumps({'attestations':[{'bundle':{'fixture':True}}]}).encode()
            with patch.object(updater,'_trusted_gh',return_value='/usr/bin/gh'), \
                 patch.object(updater,'read_url',return_value=api_result), \
                 patch.object(updater.subprocess,'run',return_value=Mock(returncode=1)):
                with self.assertRaisesRegex(RuntimeError,'attestation не подтвердила'):
                    updater.verify_release_attestation(package)
            with patch.object(updater,'_trusted_gh',return_value='/usr/bin/gh'), \
                 patch.object(updater,'read_url',return_value=b'{"attestations":[]}'):
                with self.assertRaisesRegex(RuntimeError,'нет доступной Sigstore attestation'):
                    updater.verify_release_attestation(package)
        with patch.object(updater.shutil,'which',return_value=None):
            with self.assertRaisesRegex(RuntimeError,'GitHub CLI'):
                updater._trusted_gh()
        with tempfile.TemporaryDirectory() as temporary:
            untrusted=Path(temporary)/'gh';untrusted.write_text('#!/bin/sh\\nexit 0\\n');untrusted.chmod(0o755)
            with patch.object(updater.shutil,'which',return_value=str(untrusted)):
                with self.assertRaisesRegex(RuntimeError,'принадлежать root'):
                    updater._trusted_gh()

    def test_versions_ignore_trailing_zero_components(self):
        self.assertEqual(updater.version_key('1.18'),updater.version_key('1.18.0'))
        self.assertGreater(updater.version_key('1.19'),updater.version_key('1.18.9'))
        with self.assertRaises(ValueError):updater.version_key('../1.19')

    def test_up_to_date_check_does_not_download_release_assets(self):
        with tempfile.TemporaryDirectory() as temporary:
            root=Path(temporary);(root/'data').mkdir()
            (root/'data/release.json').write_text('{"version":"1.19"}')
            release=json.dumps(self.release()).encode()
            with patch.object(updater.os,'geteuid',return_value=0),patch.object(updater,'read_url',return_value=release) as read:
                self.assertEqual(updater.update(root),0)
            read.assert_called_once_with(updater.API_URL,2*1024*1024,'application/vnd.github+json')

    def test_verified_latest_archive_is_extracted_and_new_installer_is_started(self):
        version='1.19';root_name='AntiDPI_CLI_v1.19_Linux_x64'
        with tempfile.TemporaryDirectory() as temporary:
            temporary=Path(temporary);root=temporary/'installed';(root/'data').mkdir(parents=True)
            (root/'data/release.json').write_text('{"version":"1.18"}')
            archive=temporary/'release.tar.gz'
            self.make_release_archive(archive,[(root_name+'/INSTALL.sh','#!/bin/sh\n','file'),
                (root_name+'/app/install.py','pass\n','file'),
                (root_name+'/data/release.json','{"version":"1.19"}\n','file')])
            package=archive.read_bytes();filename='AntiDPI_CLI_v1.19_Linux_x64.tar.gz'
            metadata=json.dumps(self.release(version,len(package))).encode()
            checksum=(__import__('hashlib').sha256(package).hexdigest()+'  '+filename+'\n').encode()
            bundle_url='https://'+updater.ATTESTATION_BUNDLE_HOST+'/attestations/fixture?sig=redacted'
            attestation=json.dumps({'attestations':[{'bundle_url':bundle_url}]}).encode()
            bundle=json.dumps({'mediaType':'fixture.bundle','dsseEnvelope':{}}).encode()
            with patch.object(updater.os,'geteuid',return_value=0), \
                 patch.object(updater,'read_url',side_effect=[metadata,checksum,package,attestation,bundle]) as read, \
                 patch.object(updater,'_trusted_gh',return_value='/usr/bin/gh'), \
                 patch.object(updater.subprocess,'run',side_effect=[Mock(returncode=0),Mock(returncode=0)]) as run:
                self.assertEqual(updater.update(root,yes=True),0)
            self.assertEqual(read.call_count,5)
            self.assertEqual(read.call_args_list[4].kwargs['allowed_hosts'],{updater.ATTESTATION_BUNDLE_HOST})
            verify_command=run.call_args_list[0].args[0]
            self.assertIn('--bundle',verify_command)
            self.assertIn(updater.ATTESTATION_WORKFLOW,verify_command)
            command=run.call_args_list[1].args[0]
            self.assertEqual(command[2:4],['update','--prefix'])
            self.assertEqual(command[-1],'--yes')
            self.assertTrue(command[1].endswith('/app/install.py'))

    def test_rollback_uses_flat_installed_installer(self):
        with tempfile.TemporaryDirectory() as temporary:
            root=Path(temporary);installer=root/'install.py';installer.write_text('')
            with patch.object(updater.os,'geteuid',return_value=0),patch.object(updater.subprocess,'run',return_value=Mock(returncode=0)) as run:
                self.assertEqual(updater.rollback(root),0)
            self.assertEqual(run.call_args.args[0][1:4],[str(installer),'rollback','--prefix'])

    def make_release_archive(self, path, entries):
        with tarfile.open(path,'w:gz') as archive:
            for name,data,kind in entries:
                info=tarfile.TarInfo(name)
                if kind=='symlink':
                    info.type=tarfile.SYMTYPE;info.linkname='/etc/passwd';archive.addfile(info)
                else:
                    payload=data.encode('utf-8');info.size=len(payload);archive.addfile(info,io.BytesIO(payload))

    def test_safe_extraction_accepts_expected_package_and_rejects_traversal_and_links(self):
        root='AntiDPI_CLI_v1.19_Linux_x64'
        with tempfile.TemporaryDirectory() as temporary:
            temporary=Path(temporary);archive=temporary/'package.tar.gz'
            entries=[(root+'/INSTALL.sh','#!/bin/sh\n','file'),
                     (root+'/app/install.py','pass\n','file'),
                     (root+'/data/release.json','{"version":"1.19"}\n','file')]
            self.make_release_archive(archive,entries)
            extracted=updater.safe_extract(archive,temporary/'ok',root)
            self.assertEqual(json.loads((extracted/'data/release.json').read_text())['version'],'1.19')

            traversal=temporary/'traversal.tar.gz'
            self.make_release_archive(traversal,[(root+'/../escape','x','file')])
            with self.assertRaisesRegex(RuntimeError,'путь'):
                updater.safe_extract(traversal,temporary/'bad',root)

            linked=temporary/'linked.tar.gz'
            self.make_release_archive(linked,[(root+'/INSTALL.sh','x','symlink')])
            with self.assertRaisesRegex(RuntimeError,'(?i)ссылки'):
                updater.safe_extract(linked,temporary/'linked',root)

    def test_installer_resolves_catalogue_from_shared_package_resource_map(self):
        catalogue=app_paths.resource_path(linux_installer.SOURCE,'catalogue.json')
        self.assertEqual(catalogue,REPO/'linux/data/catalogue.json')
        self.assertEqual(linux_installer.installation_catalogue()['CatalogueInfo']['ProfileCount'],492)
        command=terminal.program_command('install',['update','--prefix','/opt/antidpi'])
        self.assertEqual(command[-3:],['update','--prefix','/opt/antidpi'])

    def test_update_directory_swap_restores_previous_install_if_activation_fails(self):
        with tempfile.TemporaryDirectory() as temporary:
            root=Path(temporary);current=root/'antidpi';stage=root/'new';backup=root/'.antidpi.rollback-test'
            current.mkdir();(current/'version').write_text('old')
            stage.mkdir();(stage/'version').write_text('new')
            real_replace=os.replace;calls=[]
            def fail_stage_move(source,destination):
                calls.append((Path(source),Path(destination)))
                if len(calls)==2:raise OSError('simulated stage activation failure')
                return real_replace(source,destination)
            with patch.object(linux_installer.os,'replace',side_effect=fail_stage_move):
                with self.assertRaisesRegex(OSError,'simulated'):
                    linux_installer._activate_update(current,stage,backup)
            self.assertEqual((current/'version').read_text(),'old')
            self.assertFalse(backup.exists())
            self.assertTrue(stage.exists())

    def test_rollback_directory_swap_restores_current_install_if_activation_fails(self):
        with tempfile.TemporaryDirectory() as temporary:
            root=Path(temporary);current=root/'antidpi';backup=root/'.antidpi.rollback-test';failed=root/'.antidpi.failed-test'
            current.mkdir();(current/'version').write_text('new')
            backup.mkdir();(backup/'version').write_text('old')
            real_replace=os.replace;calls=[]
            def fail_backup_move(source,destination):
                calls.append((Path(source),Path(destination)))
                if len(calls)==2:raise OSError('simulated rollback activation failure')
                return real_replace(source,destination)
            with patch.object(linux_installer.os,'replace',side_effect=fail_backup_move):
                with self.assertRaisesRegex(OSError,'simulated'):
                    linux_installer._activate_rollback(current,backup,failed)
            self.assertEqual((current/'version').read_text(),'new')
            self.assertTrue(backup.exists())
            self.assertFalse(failed.exists())

    def test_in_place_update_preserves_settings_logs_and_supports_rollback(self):
        with tempfile.TemporaryDirectory() as temporary:
            prefix=Path(temporary)/'antidpi';prefix.mkdir()
            (prefix/'data').mkdir();(prefix/'data/release.json').write_text('{"version":"1.17"}')
            (prefix/'_state').mkdir();(prefix/'_state/adapter.json').write_text('{"name":"eth0"}')
            (prefix/'logs').mkdir();(prefix/'logs/previous.log').write_text('old log')
            (prefix/'INSTALL.sh').write_text('old installer')
            identity={'schema':'antidpi.zapret2.linux.install.v1','version':'1.9','prefix':str(prefix),
                'id':'1'*32,'upstream_selection':'compatible','shortcuts':None,'global_command':None,'files':{}}
            (prefix/'installation.json').write_text(json.dumps(identity))

            class FakeSession:
                def __init__(self,root):self.root=root
                def recover(self):return None

            def build_stage(command,**_kwargs):
                stage=Path(command[command.index('--prefix')+1])
                stage.mkdir()
                (stage/'data').mkdir();(stage/'data/release.json').write_text((REPO/'linux/data/release.json').read_text())
                (stage/'logs').mkdir();(stage/'logs/build.log').write_text('new build log')
                (stage/'_state').mkdir()
                (stage/'INSTALL.sh').write_text('new installer')
                staged_identity={'schema':'antidpi.zapret2.linux.install.v1','version':'1.9',
                    'prefix':str(stage),'id':'2'*32,'upstream_selection':'compatible','files':{}}
                (stage/'installation.json').write_text(json.dumps(staged_identity))
                return Mock(returncode=0)

            lock=Mock(close=Mock())
            args=type('Args',(),{'prefix':str(prefix),'yes':True})()
            with patch.object(linux_installer.os,'geteuid',return_value=0), \
                 patch.object(linux_installer,'_installation_lock',return_value=lock), \
                 patch.object(linux_installer.subprocess,'run',side_effect=build_stage), \
                 patch.object(antidpi,'Session',FakeSession),redirect_stdout(StringIO()):
                linux_installer.update_install(args)
            updated=json.loads((prefix/'installation.json').read_text())
            backup=Path(updated['rollback_path'])
            self.assertEqual((prefix/'data/release.json').read_text(),(REPO/'linux/data/release.json').read_text())
            self.assertEqual((prefix/'_state/adapter.json').read_text(),'{"name":"eth0"}')
            self.assertEqual((prefix/'logs/previous.log').read_text(),'old log')
            self.assertTrue((prefix/'logs/updates').is_dir())
            self.assertEqual((backup/'data/release.json').read_text(),'{"version":"1.17"}')

            rollback_args=type('Args',(),{'prefix':str(prefix),'yes':True})()
            with patch.object(linux_installer.os,'geteuid',return_value=0), \
                 patch.object(linux_installer,'_installation_lock',return_value=Mock(close=Mock())), \
                 patch.object(antidpi,'Session',FakeSession),redirect_stdout(StringIO()):
                linux_installer.rollback_install(rollback_args)
            self.assertEqual((prefix/'data/release.json').read_text(),'{"version":"1.17"}')
            self.assertEqual((prefix/'_state/adapter.json').read_text(),'{"name":"eth0"}')
            self.assertTrue(Path(json.loads((prefix/'installation.json').read_text())['rollback_path']).is_dir())


class ResourceTests(unittest.TestCase):
    def test_standard_uninstall_retains_error_reporter_for_later_purge(self):
        self.assertIn('diagnostics.py', remove_installation.RETAIN)

    def test_full_purge_removes_only_rollback_copies_owned_by_install_id(self):
        with tempfile.TemporaryDirectory() as temporary:
            root=Path(temporary)/'antidpi';root.mkdir();install_id='a'*32
            owned=Path(temporary)/'.antidpi.rollback-owned';owned.mkdir()
            unrelated=Path(temporary)/'.antidpi.rollback-unrelated';unrelated.mkdir()
            for directory,identifier in ((owned,install_id),(unrelated,'b'*32)):
                (directory/'installation.json').write_text(json.dumps({
                    'schema':remove_installation.SCHEMA,'prefix':str(root),'id':identifier}))
            remove_installation.purge_rollback_backups(root,install_id)
            self.assertFalse(owned.exists())
            self.assertTrue(unrelated.exists())

    def test_every_installed_resource_exists(self):
        for name in app_paths.FILE_LAYOUT:
            self.assertTrue(app_paths.resource_path(REPO/'linux/app', name).is_file(), name)

    def test_help_and_catalogue_work_without_display(self):
        env = dict(os.environ, DISPLAY='', WAYLAND_DISPLAY='', PYTHONDONTWRITEBYTECODE='1')
        commands=[(REPO/'linux/START.sh',['--help']),
                  (REPO/'linux/START.sh',['show','--strategy','25']),
                  (REPO/'linux/START.sh',['show','--strategy','492']),
                  (REPO/'linux/START.sh',['benchmark','--help']),
                  (REPO/'linux/app/antidpi.py',['update','--help']),
                  (REPO/'linux/app/install.py',['update','--help']),
                  (REPO/'linux/app/install.py',['rollback','--help'])]
        commands.append((REPO/'linux/START.sh',['diagnostics','--help']))
        for script,arguments in commands:
            command=['bash',str(script),*arguments] if script.suffix=='.sh' else [sys.executable,str(script),*arguments]
            result = subprocess.run(command,env=env,capture_output=True,text=True,timeout=20)
            self.assertEqual(result.returncode,0,result.stderr)
            if arguments == ['benchmark', '--help']:
                self.assertIn('--target',result.stdout)
                self.assertIn('TLS-узел',result.stdout)
            if arguments == ['update','--help']:
                self.assertTrue('update' in result.stdout or 'Обновление' in result.stdout)
            if arguments == ['diagnostics','--help']:
                self.assertIn('--output',result.stdout)

    def test_traceback_is_visible_and_private_log_is_created(self):
        with tempfile.TemporaryDirectory() as temporary, redirect_stderr(StringIO()) as output:
            try:
                raise RuntimeError('fixture failure')
            except RuntimeError as error:
                path = diagnostics.report_exception(Path(temporary), error, 'unit test')
            self.assertIn('Traceback', output.getvalue())
            self.assertIn('fixture failure', path.read_text())
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_diagnostic_archive_previews_and_redacts_sensitive_values(self):
        with tempfile.TemporaryDirectory() as temporary:
            root=Path(temporary);(root/'logs').mkdir()
            (root/'logs/private.log').write_text(
                'target=vpn.example.org interface=wlan0 password=topsecret '
                'Authorization: Bearer bearersecret email=person@example.com '
                'ghp_abcdefghijklmnopqrstuvwxyz123456 peer=203.0.113.42 ipv6=2001:db8::1%eth9 path=/home/alice/private\n')
            (root/'outside.log').write_text('must never be collected')
            (root/'logs/external.log').symlink_to(root/'outside.log')
            output=root/'support.zip'
            with redirect_stdout(StringIO()) as preview:
                archive=diagnostics.create_diagnostic_archive(root,output,yes=True)
            shown=preview.getvalue()
            self.assertIn('Предварительный просмотр',shown)
            self.assertIn('[REDACTED]',shown)
            self.assertEqual(archive,output)
            self.assertEqual(output.stat().st_mode & 0o777,0o600)
            import zipfile
            with zipfile.ZipFile(output) as bundle:
                names=bundle.namelist()
                self.assertIn('logs/private.log',names)
                self.assertNotIn('logs/external.log',names)
                report=' '.join(bundle.read(name).decode('utf-8') for name in names)
            for secret in ('vpn.example.org','wlan0','topsecret','bearersecret','ghp_abcdefghijklmnopqrstuvwxyz123456','person@example.com','203.0.113.42','2001:db8::1','eth9','/home/alice'):
                self.assertNotIn(secret,report)
            self.assertIn('[REDACTED]',report)
            self.assertIn('Проверьте содержимое архива',report)

    def test_noninteractive_diagnostic_archive_requires_explicit_yes(self):
        with tempfile.TemporaryDirectory() as temporary:
            output=Path(temporary)/'support.zip'
            with patch.object(diagnostics.sys.stdin,'isatty',return_value=False):
                with self.assertRaisesRegex(RuntimeError,'--yes'):
                    diagnostics.create_diagnostic_archive(temporary,output,yes=False,output_fn=lambda _:None)
            self.assertFalse(output.exists())


if __name__ == '__main__':
    unittest.main()
