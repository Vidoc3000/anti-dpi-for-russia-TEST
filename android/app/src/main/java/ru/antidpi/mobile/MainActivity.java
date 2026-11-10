package ru.antidpi.mobile;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.VpnService;
import android.os.Build;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.BaseAdapter;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.ScrollView;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import javax.net.ssl.HttpsURLConnection;

/** Android strategy catalogue, VPN controls, settings, and in-app connectivity tests. */
public final class MainActivity extends Activity {
    private static final int NAVY = Color.rgb(10, 16, 34);
    private static final int CARD = Color.rgb(20, 31, 57);
    private static final int CYAN = Color.rgb(72, 215, 223);
    private static final int TEXT = Color.rgb(240, 246, 255);
    private static final int MUTED = Color.rgb(164, 180, 205);
    private static final int WARNING = Color.rgb(255, 200, 115);
    private static final int VPN_REQUEST = 4101;
    private static final int NOTIFICATION_REQUEST = 4102;
    private static final int PAGE_STRATEGIES = 0;
    private static final int PAGE_TESTS = 1;
    private static final int PAGE_SETTINGS = 2;

    private final ArrayList<Profile> allProfiles = new ArrayList<>();
    private final ArrayList<Family> families = new ArrayList<>();
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private ProfileAdapter profileAdapter;
    private EditText searchField;
    private Spinner familySpinner;
    private TextView selectionText;
    private TextView countText;
    private TextView androidStrategyText;
    private TextView vpnStatusText;
    private TextView testResultText;
    private TextView testProfileText;
    private CheckBox blockQuicCheckBox;
    private Button vpnButton;
    private Button testButton;
    private Button[] navigationButtons;
    private FrameLayout pageHost;
    private int familyFilter = 0;
    private int currentPage = PAGE_STRATEGIES;
    private String query = "";
    private Profile selected;
    private final SharedPreferences.OnSharedPreferenceChangeListener vpnStateListener =
            (preferences, key) -> runOnUiThread(this::refreshVpnUi);

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(NAVY);
        getWindow().setNavigationBarColor(NAVY);
        getWindow().getDecorView().setSystemUiVisibility(0);
        loadCatalogue();
        selected = findProfile(getPreferences(MODE_PRIVATE).getInt("selected_profile", 1));
        setContentView(buildScreen());
        showPage(PAGE_STRATEGIES);
    }

    private View buildScreen() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(NAVY);
        root.setPadding(dp(16), dp(12), dp(16), dp(10));

        LinearLayout header = new LinearLayout(this);
        header.setGravity(Gravity.CENTER_VERTICAL);
        header.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout heading = new LinearLayout(this);
        heading.setOrientation(LinearLayout.VERTICAL);
        TextView title = text("AntiDPI", 26, TEXT, true);
        TextView subtitle = text("VPN · стратегии и диагностика", 12, MUTED, false);
        heading.addView(title, matchWrap());
        heading.addView(subtitle, matchWrap());
        header.addView(heading, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        TextView badge = text(AndroidPacketEngine.isReady() ? "ENGINE READY" : "ENGINE OFF", 10,
                AndroidPacketEngine.isReady() ? CYAN : WARNING, true);
        badge.setPadding(dp(9), dp(7), dp(9), dp(7));
        badge.setBackground(shape(CARD, dp(18)));
        header.addView(badge, wrap());
        root.addView(header, margins(matchWrap(), 0, 0, 0, dp(12)));

        LinearLayout navigation = new LinearLayout(this);
        navigation.setOrientation(LinearLayout.HORIZONTAL);
        navigation.setPadding(dp(4), dp(4), dp(4), dp(4));
        navigation.setBackground(shape(CARD, dp(14)));
        navigationButtons = new Button[] {
                navButton("Стратегии", PAGE_STRATEGIES),
                navButton("Тесты", PAGE_TESTS),
                navButton("Настройки", PAGE_SETTINGS)
        };
        for (int i = 0; i < navigationButtons.length; i++) {
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, dp(42), 1);
            if (i > 0) params.leftMargin = dp(4);
            navigation.addView(navigationButtons[i], params);
        }
        root.addView(navigation, margins(matchWrap(), 0, 0, 0, dp(10)));

        pageHost = new FrameLayout(this);
        root.addView(pageHost, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 0, 1));

        vpnButton = button("Запустить VPN", AndroidPacketEngine.isReady());
        vpnButton.setTextSize(15);
        vpnButton.setOnClickListener(v -> toggleVpn());
        root.addView(vpnButton, margins(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(52)), 0, dp(8), 0, dp(4)));
        vpnStatusText = text("VPN выключен", 12, MUTED, false);
        vpnStatusText.setGravity(Gravity.CENTER);
        root.addView(vpnStatusText, matchWrap());
        return root;
    }

    private Button navButton(String label, int page) {
        Button button = button(label, true);
        button.setTextSize(12);
        button.setOnClickListener(v -> showPage(page));
        return button;
    }

    private void showPage(int page) {
        if (pageHost == null) return;
        currentPage = page;
        pageHost.removeAllViews();
        View content;
        if (page == PAGE_TESTS) content = buildTestsPage();
        else if (page == PAGE_SETTINGS) content = buildSettingsPage();
        else content = buildStrategiesPage();
        pageHost.addView(content, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        for (int i = 0; i < navigationButtons.length; i++) {
            boolean active = i == page;
            navigationButtons[i].setBackground(shape(active ? CYAN : Color.TRANSPARENT, dp(11)));
            navigationButtons[i].setTextColor(active ? NAVY : MUTED);
        }
        refreshVpnUi();
    }

    private View buildStrategiesPage() {
        LinearLayout page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);

        TextView heading = text("Выберите профиль", 18, TEXT, true);
        page.addView(heading, margins(matchWrap(), 0, 0, 0, dp(7)));
        searchField = new EditText(this);
        searchField.setSingleLine(true);
        searchField.setTextColor(TEXT);
        searchField.setHintTextColor(MUTED);
        searchField.setTextSize(14);
        searchField.setHint("Поиск по номеру или названию");
        searchField.setPadding(dp(12), 0, dp(12), 0);
        searchField.setBackground(shape(CARD, dp(12)));
        page.addView(searchField, margins(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(46)), 0, 0, 0, dp(7)));

        familySpinner = new Spinner(this);
        familySpinner.setBackground(shape(CARD, dp(12)));
        ArrayList<String> familyNames = new ArrayList<>();
        familyNames.add("Все семейства");
        for (Family family : families) familyNames.add(family.name);
        ArrayAdapter<String> familyAdapter = new ArrayAdapter<String>(this,
                android.R.layout.simple_spinner_item, familyNames) {
            @Override public View getView(int position, View convertView, ViewGroup parent) {
                return spinnerLabel(position, parent, false);
            }
            @Override public View getDropDownView(int position, View convertView, ViewGroup parent) {
                return spinnerLabel(position, parent, true);
            }
            private View spinnerLabel(int position, ViewGroup parent, boolean dropdown) {
                TextView label = text(getItem(position), 13, TEXT, false);
                label.setGravity(Gravity.CENTER_VERTICAL);
                label.setPadding(dp(12), dp(dropdown ? 10 : 0), dp(12), dp(dropdown ? 10 : 0));
                label.setBackgroundColor(dropdown ? CARD : Color.TRANSPARENT);
                return label;
            }
        };
        familyAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        familySpinner.setAdapter(familyAdapter);
        page.addView(familySpinner, margins(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(42)), 0, 0, 0, dp(5)));

        countText = text("Загружаю каталог…", 11, MUTED, false);
        page.addView(countText, margins(matchWrap(), dp(2), 0, 0, dp(5)));
        ListView list = new ListView(this);
        list.setDivider(null);
        list.setDividerHeight(dp(6));
        list.setBackgroundColor(Color.TRANSPARENT);
        list.setCacheColorHint(Color.TRANSPARENT);
        profileAdapter = new ProfileAdapter();
        list.setAdapter(profileAdapter);
        page.addView(list, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 0, 1));

        selectionText = text("Выберите профиль каталога.", 12, MUTED, false);
        selectionText.setPadding(dp(12), dp(9), dp(12), dp(9));
        selectionText.setBackground(shape(CARD, dp(12)));
        page.addView(selectionText, margins(matchWrap(), 0, dp(6), 0, dp(4)));
        androidStrategyText = text("Android-адаптация профиля.", 10, WARNING, false);
        page.addView(androidStrategyText, margins(matchWrap(), dp(2), 0, 0, 0));

        searchField.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) { }
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) {
                query = s.toString().trim().toLowerCase(Locale.ROOT);
                refreshProfiles();
            }
            @Override public void afterTextChanged(Editable s) { }
        });
        familySpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                familyFilter = position == 0 ? 0 : families.get(position - 1).id;
                refreshProfiles();
            }
            @Override public void onNothingSelected(AdapterView<?> parent) { }
        });
        list.setOnItemClickListener((parent, view, position, id) -> selectProfile(profileAdapter.getItem(position)));
        refreshProfiles();
        showSelectedProfile();
        return page;
    }

    private View buildTestsPage() {
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        LinearLayout page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        page.setPadding(0, 0, 0, dp(8));
        scroll.addView(page);

        page.addView(text("Проверка соединения", 20, TEXT, true), margins(matchWrap(), 0, 0, 0, dp(8)));
        LinearLayout vpnCard = card();
        vpnCard.addView(text("Состояние VPN", 13, MUTED, true), matchWrap());
        testProfileText = text("", 13, TEXT, false);
        testProfileText.setLineSpacing(dp(2), 1.0f);
        vpnCard.addView(testProfileText, margins(matchWrap(), 0, dp(5), 0, 0));
        page.addView(vpnCard, margins(matchWrap(), 0, 0, 0, dp(10)));

        TextView explanation = text(
                "Проверка выполняет HTTPS-запросы к YouTube и Google. При включённом VPN запросы этого приложения идут через TUN и выбранную Android-адаптацию; при выключенном — напрямую. Успех проверки не гарантирует доступность всех сайтов.",
                13, MUTED, false);
        explanation.setLineSpacing(dp(2), 1.0f);
        page.addView(explanation, margins(matchWrap(), 0, 0, 0, dp(10)));

        testButton = button("Запустить тесты", true);
        testButton.setOnClickListener(v -> runConnectivityTests());
        page.addView(testButton, margins(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(48)), 0, 0, 0, dp(10)));
        testResultText = text("Результаты тестов появятся здесь.", 13, TEXT, false);
        testResultText.setPadding(dp(13), dp(12), dp(13), dp(12));
        testResultText.setLineSpacing(dp(3), 1.0f);
        testResultText.setBackground(shape(CARD, dp(13)));
        page.addView(testResultText, matchWrap());
        updateTestSummary();
        return scroll;
    }

    private View buildSettingsPage() {
        ScrollView scroll = new ScrollView(this);
        LinearLayout page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        page.setPadding(0, 0, 0, dp(8));
        scroll.addView(page);

        page.addView(text("Настройки", 20, TEXT, true), margins(matchWrap(), 0, 0, 0, dp(9)));
        LinearLayout networkCard = card();
        networkCard.addView(text("Сетевое поведение", 15, CYAN, true), matchWrap());
        blockQuicCheckBox = new CheckBox(this);
        blockQuicCheckBox.setText("Блокировать UDP/443 (QUIC)");
        blockQuicCheckBox.setTextColor(TEXT);
        blockQuicCheckBox.setTextSize(14);
        blockQuicCheckBox.setButtonTintList(android.content.res.ColorStateList.valueOf(CYAN));
        blockQuicCheckBox.setChecked(getPreferences(MODE_PRIVATE).getBoolean("block_quic", true));
        blockQuicCheckBox.setOnCheckedChangeListener((button, checked) -> {
            getPreferences(MODE_PRIVATE).edit().putBoolean("block_quic", checked).apply();
            if (AntiDpiVpnService.isRunning(this)) restartVpnForCurrentSelection("Настройка QUIC изменена");
        });
        networkCard.addView(blockQuicCheckBox, margins(matchWrap(), -dp(8), dp(4), 0, 0));
        TextView quicHelp = text("Может заставить некоторые приложения перейти на TCP/TLS. Не все приложения автоматически переключаются.",
                12, MUTED, false);
        quicHelp.setLineSpacing(dp(2), 1.0f);
        networkCard.addView(quicHelp, margins(matchWrap(), 0, dp(2), 0, 0));
        page.addView(networkCard, margins(matchWrap(), 0, 0, 0, dp(10)));

        LinearLayout strategyCard = card();
        strategyCard.addView(text("Применение стратегии", 15, CYAN, true), matchWrap());
        TextView restartHelp = text(
                "При выборе другого профиля активный VPN автоматически перезапускается. Во время перезапуска соединения могут кратковременно прерваться.",
                13, TEXT, false);
        restartHelp.setLineSpacing(dp(2), 1.0f);
        strategyCard.addView(restartHelp, margins(matchWrap(), 0, dp(6), 0, 0));
        page.addView(strategyCard, margins(matchWrap(), 0, 0, 0, dp(10)));

        LinearLayout aboutCard = card();
        aboutCard.addView(text("Ограничения Android", 15, CYAN, true), matchWrap());
        TextView about = text(
                "Без root доступны только stream-safe TLS-разбиение и приблизительные TCP write boundaries. Fake-пакеты, TTL/SEQ/TS и настоящее переупорядочивание desktop-профилей не применяются.",
                13, TEXT, false);
        about.setLineSpacing(dp(2), 1.0f);
        aboutCard.addView(about, margins(matchWrap(), 0, dp(6), 0, 0));
        page.addView(aboutCard, matchWrap());
        return scroll;
    }

    private void loadCatalogue() {
        try (InputStream input = getAssets().open("catalogue.json");
             ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = input.read(buffer)) != -1) output.write(buffer, 0, read);
            JSONObject catalogue = new JSONObject(output.toString("UTF-8"));
            JSONArray familyRows = catalogue.getJSONArray("FamilyRows");
            for (int i = 0; i < familyRows.length(); i++) {
                JSONObject row = familyRows.getJSONObject(i);
                families.add(new Family(row.getInt("Number"), row.getString("Name")));
            }
            JSONArray profiles = catalogue.getJSONArray("ProfileRows");
            for (int i = 0; i < profiles.length(); i++) {
                JSONObject row = profiles.getJSONObject(i);
                int familyId = row.getInt("Family");
                String familyName = "Семейство " + familyId;
                for (Family family : families) if (family.id == familyId) familyName = family.name;
                allProfiles.add(new Profile(row.getInt("Number"), familyId,
                        row.getString("Name"), familyName, row.getJSONArray("Args").toString()));
            }
        } catch (Exception error) {
            allProfiles.clear();
            families.clear();
        }
    }

    private Profile findProfile(int number) {
        for (Profile profile : allProfiles) if (profile.number == number) return profile;
        return allProfiles.isEmpty() ? null : allProfiles.get(0);
    }

    private void selectProfile(Profile profile) {
        if (profile == null) return;
        boolean changed = selected == null || selected.number != profile.number;
        selected = profile;
        getPreferences(MODE_PRIVATE).edit().putInt("selected_profile", selected.number).apply();
        showSelectedProfile();
        if (profileAdapter != null) profileAdapter.notifyDataSetChanged();
        updateTestSummary();
        if (changed && AntiDpiVpnService.isRunning(this)) {
            restartVpnForCurrentSelection("Стратегия изменена");
        }
    }

    private void showSelectedProfile() {
        if (selectionText == null || androidStrategyText == null || selected == null) return;
        selectionText.setText("Профиль #" + selected.number + " · " + selected.familyName +
                "\n" + selected.name);
        String adapted = AndroidPacketEngine.adaptProfileArgs(selected.argsJson);
        String activeNote = AntiDpiVpnService.isRunning(this)
                ? " VPN перезапускается автоматически при смене профиля." : "";
        androidStrategyText.setText("Android-адаптация: " + adapted + activeNote +
                "\nFake/TTL/SEQ/TS/reorder и прочие packet-level команды пропускаются.");
    }

    private void toggleVpn() {
        if (!AndroidPacketEngine.isReady()) {
            Toast.makeText(this, "В APK отсутствует Android packet engine.", Toast.LENGTH_LONG).show();
            return;
        }
        if (AntiDpiVpnService.isRunning(this)) {
            AntiDpiVpnService.stop(this);
            vpnStatusText.setText("Остановка VPN…");
            return;
        }
        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)
                != android.content.pm.PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{android.Manifest.permission.POST_NOTIFICATIONS}, NOTIFICATION_REQUEST);
            return;
        }
        requestVpnConsent();
    }

    private void requestVpnConsent() {
        Intent prepare = VpnService.prepare(this);
        if (prepare != null) startActivityForResult(prepare, VPN_REQUEST);
        else startVpnService();
    }

    private String selectedStrategy() {
        return selected == null ? "tlsrec:sni" : AndroidPacketEngine.adaptProfileArgs(selected.argsJson);
    }

    private boolean blockQuicEnabled() {
        return blockQuicCheckBox != null ? blockQuicCheckBox.isChecked()
                : getPreferences(MODE_PRIVATE).getBoolean("block_quic", true);
    }

    private void restartVpnForCurrentSelection(String reason) {
        if (!AntiDpiVpnService.isRunning(this)) return;
        vpnStatusText.setText(reason + " · перезапуск VPN…");
        startVpnService(true);
    }

    private void startVpnService() {
        startVpnService(false);
    }

    private void startVpnService(boolean forceRestart) {
        Intent intent = new Intent(this, AntiDpiVpnService.class)
                .setAction(AntiDpiVpnService.ACTION_START)
                .putExtra(AntiDpiVpnService.EXTRA_STRATEGY, selectedStrategy())
                .putExtra(AntiDpiVpnService.EXTRA_BLOCK_QUIC, blockQuicEnabled())
                .putExtra(AntiDpiVpnService.EXTRA_FORCE_RESTART, forceRestart);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent);
        else startService(intent);
        vpnStatusText.setText("Применяется профиль #" + (selected == null ? 1 : selected.number) + "…");
    }

    private void runConnectivityTests() {
        if (testButton == null || testResultText == null) return;
        final Button runningTestButton = testButton;
        final TextView runningResultView = testResultText;
        final boolean throughVpn = AntiDpiVpnService.isRunning(this);
        final int profileNumber = selected == null ? 1 : selected.number;
        String route = throughVpn ? "через активный VPN" : "напрямую (VPN выключен)";
        runningTestButton.setEnabled(false);
        runningResultView.setText("Проверяю HTTPS " + route + "…");
        executor.execute(() -> {
            String youtube = probe("https://www.youtube.com/generate_204");
            String google = probe("https://www.google.com/generate_204");
            String path = throughVpn ? "через VPN · профиль #" + profileNumber : "напрямую";
            String result = "Путь: " + path + "\n" +
                    "YouTube: " + youtube + "\n" +
                    "Google: " + google + "\n\n" +
                    "Это базовая HTTPS-проверка TCP, не гарантия обхода блокировки.";
            runOnUiThread(() -> {
                if (!isFinishing()) {
                    runningResultView.setText(result);
                    runningTestButton.setEnabled(true);
                }
            });
        });
    }

    private String probe(String address) {
        HttpsURLConnection connection = null;
        try {
            connection = (HttpsURLConnection) new URL(address).openConnection();
            connection.setRequestMethod("GET");
            connection.setConnectTimeout(7000);
            connection.setReadTimeout(7000);
            connection.setInstanceFollowRedirects(true);
            int code = connection.getResponseCode();
            return "HTTP " + code;
        } catch (Exception error) {
            return "ошибка " + error.getClass().getSimpleName();
        } finally {
            if (connection != null) connection.disconnect();
        }
    }

    private void updateTestSummary() {
        if (testProfileText == null) return;
        boolean running = AntiDpiVpnService.isRunning(this);
        testProfileText.setText((running ? "VPN активен" : "VPN выключен") + "\n" +
                (selected == null ? "Профиль не выбран" : "Профиль #" + selected.number + " · " +
                        AndroidPacketEngine.adaptProfileArgs(selected.argsJson)));
    }

    private void onVpnStateChanged() {
        refreshVpnUi();
        showSelectedProfile();
        updateTestSummary();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == VPN_REQUEST) {
            if (resultCode == RESULT_OK) startVpnService();
            else Toast.makeText(this, "Разрешение VPN не выдано; трафик не изменён.", Toast.LENGTH_LONG).show();
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == NOTIFICATION_REQUEST) requestVpnConsent();
    }

    private void refreshVpnUi() {
        if (vpnStatusText == null || vpnButton == null) return;
        boolean running = AntiDpiVpnService.isRunning(this);
        vpnStatusText.setText(AntiDpiVpnService.stateMessage(this));
        vpnButton.setText(running ? "Остановить VPN" : "Запустить VPN");
        vpnButton.setEnabled(AndroidPacketEngine.isReady());
        onVpnStateChanged();
    }

    @Override
    protected void onResume() {
        super.onResume();
        getSharedPreferences("vpn_state", MODE_PRIVATE).registerOnSharedPreferenceChangeListener(vpnStateListener);
        refreshVpnUi();
    }

    @Override
    protected void onPause() {
        getSharedPreferences("vpn_state", MODE_PRIVATE).unregisterOnSharedPreferenceChangeListener(vpnStateListener);
        super.onPause();
    }

    private void refreshProfiles() {
        if (profileAdapter == null) return;
        ArrayList<Profile> filtered = new ArrayList<>();
        for (Profile profile : allProfiles) {
            if (familyFilter != 0 && profile.familyId != familyFilter) continue;
            String needle = query;
            if (!needle.isEmpty() && !String.valueOf(profile.number).contains(needle)
                    && !profile.name.toLowerCase(Locale.ROOT).contains(needle)
                    && !profile.familyName.toLowerCase(Locale.ROOT).contains(needle)) continue;
            filtered.add(profile);
        }
        profileAdapter.setProfiles(filtered);
        if (countText != null) {
            countText.setText(allProfiles.isEmpty() ? "Не удалось загрузить каталог стратегий."
                    : "Показано " + filtered.size() + " из " + allProfiles.size() + " стратегий");
        }
    }

    private LinearLayout card() {
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(dp(14), dp(12), dp(14), dp(12));
        layout.setBackground(shape(CARD, dp(14)));
        return layout;
    }

    private TextView text(String value, int size, int color, boolean bold) {
        TextView text = new TextView(this);
        text.setText(value);
        text.setTextSize(size);
        text.setTextColor(color);
        if (bold) text.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        return text;
    }

    private Button button(String label, boolean enabled) {
        Button button = new Button(this);
        button.setText(label);
        button.setTextSize(13);
        button.setAllCaps(false);
        button.setTextColor(enabled ? NAVY : MUTED);
        button.setEnabled(enabled);
        button.setBackground(shape(enabled ? CYAN : CARD, dp(12)));
        return button;
    }

    private GradientDrawable shape(int color, int radius) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(color);
        drawable.setCornerRadius(radius);
        return drawable;
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private LinearLayout.LayoutParams matchWrap() {
        return new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT);
    }

    private LinearLayout.LayoutParams wrap() {
        return new LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT);
    }

    private LinearLayout.LayoutParams margins(LinearLayout.LayoutParams params,
                                               int left, int top, int right, int bottom) {
        params.setMargins(left, top, right, bottom);
        return params;
    }

    @Override
    protected void onDestroy() {
        executor.shutdownNow();
        super.onDestroy();
    }

    private static final class Family {
        final int id;
        final String name;
        Family(int id, String name) { this.id = id; this.name = name; }
    }

    private static final class Profile {
        final int number;
        final int familyId;
        final String name;
        final String familyName;
        final String argsJson;
        Profile(int number, int familyId, String name, String familyName, String argsJson) {
            this.number = number;
            this.familyId = familyId;
            this.name = name;
            this.familyName = familyName;
            this.argsJson = argsJson;
        }
    }

    private final class ProfileAdapter extends BaseAdapter {
        private List<Profile> profiles = new ArrayList<>();
        void setProfiles(List<Profile> value) { profiles = value; notifyDataSetChanged(); }
        @Override public int getCount() { return profiles.size(); }
        @Override public Profile getItem(int position) { return profiles.get(position); }
        @Override public long getItemId(int position) { return getItem(position).number; }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            ProfileRow row;
            if (convertView instanceof LinearLayout && convertView.getTag() instanceof ProfileRow) {
                row = (ProfileRow) convertView.getTag();
            } else {
                LinearLayout layout = new LinearLayout(MainActivity.this);
                layout.setOrientation(LinearLayout.VERTICAL);
                layout.setPadding(dp(12), dp(9), dp(12), dp(9));
                TextView primary = text("", 13, TEXT, true);
                TextView secondary = text("", 10, MUTED, false);
                layout.addView(primary, matchWrap());
                layout.addView(secondary, margins(matchWrap(), 0, dp(3), 0, 0));
                row = new ProfileRow(primary, secondary);
                layout.setTag(row);
                convertView = layout;
            }
            Profile profile = getItem(position);
            row.primary.setText("#" + profile.number + "  " + profile.name);
            row.secondary.setText(profile.familyName);
            convertView.setBackground(shape(profile == selected ? Color.rgb(31, 61, 83) : CARD, dp(10)));
            convertView.setContentDescription("Стратегия " + profile.number + ": " + profile.name);
            return convertView;
        }
    }

    private static final class ProfileRow {
        final TextView primary;
        final TextView secondary;
        ProfileRow(TextView primary, TextView secondary) {
            this.primary = primary;
            this.secondary = secondary;
        }
    }
}
