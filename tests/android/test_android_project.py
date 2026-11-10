import json
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
ANDROID = ROOT / "android"


class AndroidProjectTests(unittest.TestCase):
    def test_catalogue_is_in_sync_with_linux_source(self):
        source = json.loads((ROOT / "linux/data/catalogue.json").read_text(encoding="utf-8"))
        bundled = json.loads((ANDROID / "app/src/main/assets/catalogue.json").read_text(encoding="utf-8"))
        self.assertEqual(source, bundled)
        self.assertEqual(492, len(bundled["ProfileRows"]))

    def test_vpn_uses_userspace_engine_and_protects_egress(self):
        engine = (ANDROID / "app/src/main/java/ru/antidpi/mobile/AndroidPacketEngine.java").read_text()
        service = (ANDROID / "app/src/main/java/ru/antidpi/mobile/AntiDpiVpnService.java").read_text()
        activity = (ANDROID / "app/src/main/java/ru/antidpi/mobile/MainActivity.java").read_text()

        self.assertIn("engine.startTunnel(tun.getFd(), mtu, strategy, blockQuic)", engine)
        self.assertIn("service.protect((int) fd)", engine)
        self.assertIn("engine.tunnelStats()", engine)
        self.assertIn("if (!AndroidPacketEngine.isReady())", service)
        self.assertIn("builder.establish()", service)
        self.assertIn("builder.addDisallowedApplication(getPackageName())", service)
        self.assertIn("EXTRA_FORCE_RESTART", service)
        self.assertIn("startedProxy.start(AndroidPacketEngine.nativeProfileArgs(profileArgs,", service)
        self.assertIn("startedEngine.startTunnelViaProxy(startedTun, mtu", service)
        self.assertIn("startInBackground", service)
        self.assertIn("startupExecutor.execute", service)
        self.assertIn("nativeProxy.port()", service)
        self.assertIn("builder.addAllowedApplication(packageName)", service)
        self.assertIn("EXTRA_DNS_SERVERS", service)
        self.assertIn("EXTRA_MTU", service)
        self.assertIn("startupStage", service)
        self.assertIn("statsUpdater", service)
        self.assertIn("engine.stop()", service)
        self.assertIn("VpnService.prepare(this)", activity)
        self.assertIn("AndroidPacketEngine.describeNativeProfile(selected.argsJson)", activity)
        self.assertIn("EXTRA_PROFILE_ARGS", activity)
        self.assertIn("openConnection(proxy)", activity)
        self.assertIn("startVpnService(true)", activity)
        self.assertIn("navButton(\"Тесты\", PAGE_TESTS)", activity)
        self.assertIn("navButton(\"Настройки\", PAGE_SETTINGS)", activity)
        self.assertIn("showAppRoutingPicker()", activity)
        self.assertIn("configuredDnsServers()", activity)
        self.assertIn("configuredMtu()", activity)
        self.assertIn("EXTRA_BLOCK_IPV6", activity)
        self.assertIn("EXTRA_BLOCK_IPV6", service)
        self.assertIn("--no-ipv6", (ANDROID / "app/src/main/java/ru/antidpi/mobile/AndroidPacketEngine.java").read_text())
        self.assertIn("BlockIPv6:  blockIPv6", (ANDROID / "engine/mobile/api.go").read_text())
        self.assertIn("Настроить свои DNS-серверы", activity)
        self.assertIn("exceptionSummary(error)", activity)
        self.assertIn("IPv6 remains captured", (ANDROID / "engine/tunnel/tunnel.go").read_text())
        self.assertIn("Счётчики реального TUN", activity)
        self.assertIn("не проходит через TUN", activity)
        self.assertIn("TCP endpoint", activity)
        self.assertIn("upstream", activity)
        self.assertIn("FOREGROUND_SERVICE_TYPE_SPECIAL_USE", service)

    def test_android_build_includes_generated_engine_aar(self):
        gradle = (ANDROID / "app/build.gradle").read_text()
        workflow = (ROOT / ".github/workflows/android-preview.yml").read_text()
        self.assertIn("libs/antidpi-engine.aar", gradle)
        self.assertIn("src/main/cpp/CMakeLists.txt", gradle)
        self.assertTrue((ANDROID / "app/src/main/cpp/byedpi/LICENSE").is_file())
        self.assertTrue((ANDROID / "app/src/main/cpp/byedpi/main.c").is_file())
        self.assertIn("gomobile init", workflow)
        self.assertIn("./android/engine/build-aar.sh", workflow)
        self.assertIn("go test ./...", workflow)
        self.assertIn("ANDROID_PREVIEW_VERSION: '0.4.4-preview'", workflow)
        self.assertIn("versionCode 8", gradle)
        self.assertIn("versionName '0.4.4-preview'", gradle)
        self.assertTrue((ANDROID / "engine/THIRD_PARTY_NOTICES.md").is_file())
        self.assertTrue((ANDROID / "engine/LICENSE.zapret-mobile").is_file())

    def test_gradle_wrapper_and_vpn_permissions_are_present(self):
        jar = ANDROID / "gradle/wrapper/gradle-wrapper.jar"
        self.assertTrue(jar.is_file())
        self.assertGreater(jar.stat().st_size, 10_000)
        self.assertTrue((ANDROID / "gradlew").is_file())
        props = (ANDROID / "gradle/wrapper/gradle-wrapper.properties").read_text()
        self.assertIn("gradle-8.9-bin.zip", props)
        manifest = (ANDROID / "app/src/main/AndroidManifest.xml").read_text()
        self.assertIn("BIND_VPN_SERVICE", manifest)
        self.assertIn("android.permission.INTERNET", manifest)
        self.assertIn("FOREGROUND_SERVICE_SPECIAL_USE", manifest)
        self.assertIn('android:foregroundServiceType="specialUse"', manifest)


if __name__ == "__main__":
    unittest.main()
