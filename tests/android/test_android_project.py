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

    def test_vpn_service_fails_closed_until_engine_is_ready(self):
        engine = (ANDROID / "app/src/main/java/ru/antidpi/mobile/AndroidPacketEngine.java").read_text()
        service = (ANDROID / "app/src/main/java/ru/antidpi/mobile/AntiDpiVpnService.java").read_text()
        activity = (ANDROID / "app/src/main/java/ru/antidpi/mobile/MainActivity.java").read_text()

        self.assertRegex(engine, r"static boolean isReady\(\)\s*\{\s*return false;")
        self.assertIn("if (!AndroidPacketEngine.isReady())", service)
        self.assertNotIn(".establish()", service)
        self.assertIn('button("Запустить DPI", AndroidPacketEngine.isReady())', activity)

    def test_gradle_wrapper_and_project_configuration_are_present(self):
        jar = ANDROID / "gradle/wrapper/gradle-wrapper.jar"
        self.assertTrue(jar.is_file())
        self.assertGreater(jar.stat().st_size, 10_000)
        self.assertTrue((ANDROID / "gradlew").is_file())
        props = (ANDROID / "gradle/wrapper/gradle-wrapper.properties").read_text()
        self.assertIn("gradle-8.9-bin.zip", props)
        manifest = (ANDROID / "app/src/main/AndroidManifest.xml").read_text()
        self.assertIn("BIND_VPN_SERVICE", manifest)
        self.assertIn("android.permission.INTERNET", manifest)


if __name__ == "__main__":
    unittest.main()
