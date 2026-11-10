package ru.antidpi.mobile;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
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
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ListView;
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

/** Offline strategy browser and direct-connectivity checker for the Android preview. */
public final class MainActivity extends Activity {
    private static final int NAVY = Color.rgb(10, 16, 34);
    private static final int CARD = Color.rgb(20, 31, 57);
    private static final int CYAN = Color.rgb(72, 215, 223);
    private static final int TEXT = Color.rgb(240, 246, 255);
    private static final int MUTED = Color.rgb(164, 180, 205);
    private static final int WARNING = Color.rgb(255, 200, 115);

    private final ArrayList<Profile> allProfiles = new ArrayList<>();
    private final ArrayList<Family> families = new ArrayList<>();
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private ProfileAdapter profileAdapter;
    private EditText searchField;
    private Spinner familySpinner;
    private TextView selectionText;
    private TextView connectivityText;
    private TextView countText;
    private int familyFilter = 0;
    private String query = "";
    private Profile selected;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(NAVY);
        getWindow().setNavigationBarColor(NAVY);
        getWindow().getDecorView().setSystemUiVisibility(0);

        loadCatalogue();
        setContentView(buildScreen());
        restoreSelection();
        refreshProfiles();
    }

    private View buildScreen() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(NAVY);
        root.setPadding(dp(18), dp(16), dp(18), dp(12));

        TextView title = text("AntiDPI", 30, TEXT, true);
        root.addView(title, matchWrap());
        TextView subtitle = text("Стратегии и диагностика для Android", 14, MUTED, false);
        root.addView(subtitle, margins(matchWrap(), 0, dp(2), 0, dp(12)));

        LinearLayout notice = card();
        TextView noticeTitle = text("Режим предпросмотра", 16, CYAN, true);
        notice.addView(noticeTitle, matchWrap());
        TextView noticeBody = text(
                "Пакетный DPI-движок ещё не портирован на Android VpnService. " +
                "VPN не запускается, стратегии не применяются, трафик телефона не меняется.",
                13, TEXT, false);
        noticeBody.setLineSpacing(dp(2), 1.0f);
        notice.addView(noticeBody, margins(matchWrap(), 0, dp(6), 0, 0));
        root.addView(notice, margins(matchWrap(), 0, 0, 0, dp(12)));

        TextView section = text("Каталог стратегий", 18, TEXT, true);
        root.addView(section, margins(matchWrap(), 0, 0, 0, dp(7)));

        searchField = new EditText(this);
        searchField.setSingleLine(true);
        searchField.setTextColor(TEXT);
        searchField.setHintTextColor(MUTED);
        searchField.setTextSize(14);
        searchField.setHint("Поиск по номеру или названию");
        searchField.setPadding(dp(12), 0, dp(12), 0);
        searchField.setBackground(shape(CARD, dp(12)));
        root.addView(searchField, margins(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(48)), 0, 0, 0, dp(8)));

        familySpinner = new Spinner(this);
        familySpinner.setBackground(shape(CARD, dp(12)));
        ArrayList<String> familyNames = new ArrayList<>();
        familyNames.add("Все семейства");
        for (Family family : families) familyNames.add(family.name);
        ArrayAdapter<String> familyAdapter = new ArrayAdapter<String>(this,
                android.R.layout.simple_spinner_item, familyNames) {
            @Override
            public View getView(int position, View convertView, ViewGroup parent) {
                return spinnerLabel(position, parent, false);
            }

            @Override
            public View getDropDownView(int position, View convertView, ViewGroup parent) {
                return spinnerLabel(position, parent, true);
            }

            private View spinnerLabel(int position, ViewGroup parent, boolean dropdown) {
                TextView label = text(getItem(position), 14, TEXT, false);
                label.setGravity(Gravity.CENTER_VERTICAL);
                label.setPadding(dp(12), dp(dropdown ? 10 : 0), dp(12), dp(dropdown ? 10 : 0));
                label.setBackgroundColor(dropdown ? CARD : Color.TRANSPARENT);
                return label;
            }
        };
        familyAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        familySpinner.setAdapter(familyAdapter);
        root.addView(familySpinner, margins(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(46)), 0, 0, 0, dp(6)));

        countText = text("Загружаю каталог…", 12, MUTED, false);
        root.addView(countText, margins(matchWrap(), dp(2), 0, 0, dp(4)));

        ListView list = new ListView(this);
        list.setDivider(null);
        list.setDividerHeight(dp(5));
        list.setBackgroundColor(Color.TRANSPARENT);
        list.setCacheColorHint(Color.TRANSPARENT);
        profileAdapter = new ProfileAdapter();
        list.setAdapter(profileAdapter);
        root.addView(list, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 0, 1.0f));

        selectionText = text("Выберите стратегию для просмотра.", 13, MUTED, false);
        selectionText.setPadding(dp(12), dp(10), dp(12), dp(10));
        selectionText.setBackground(shape(CARD, dp(12)));
        root.addView(selectionText, margins(matchWrap(), 0, dp(8), 0, dp(8)));

        connectivityText = text("Проверка ниже оценивает прямой доступ к YouTube, без стратегии.",
                12, MUTED, false);
        root.addView(connectivityText, margins(matchWrap(), dp(2), 0, 0, dp(6)));

        LinearLayout actions = new LinearLayout(this);
        actions.setOrientation(LinearLayout.HORIZONTAL);
        Button checkButton = button("Проверить YouTube", true);
        checkButton.setOnClickListener(v -> runDirectProbe(checkButton));
        actions.addView(checkButton, new LinearLayout.LayoutParams(0, dp(48), 1));
        Button startButton = button("Запустить DPI", AndroidPacketEngine.isReady());
        startButton.setContentDescription("Недоступно: Android DPI-движок ещё не портирован");
        startButton.setOnClickListener(v -> Toast.makeText(this,
                "Сетевой движок для Android ещё не готов; трафик не изменён.", Toast.LENGTH_LONG).show());
        LinearLayout.LayoutParams startParams = new LinearLayout.LayoutParams(0, dp(48), 1);
        startParams.leftMargin = dp(8);
        actions.addView(startButton, startParams);
        root.addView(actions, matchWrap());

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
        list.setOnItemClickListener((parent, view, position, id) -> {
            selected = profileAdapter.getItem(position);
            selectionText.setText("Стратегия #" + selected.number + " · " + selected.familyName +
                    "\n" + selected.name);
            getPreferences(MODE_PRIVATE).edit().putInt("selected_profile", selected.number).apply();
        });
        return root;
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
                        row.getString("Name"), familyName));
            }
        } catch (Exception error) {
            allProfiles.clear();
            families.clear();
        }
    }

    private void restoreSelection() {
        int wanted = getPreferences(MODE_PRIVATE).getInt("selected_profile", 1);
        for (Profile profile : allProfiles) {
            if (profile.number == wanted) {
                selected = profile;
                selectionText.setText("Стратегия #" + selected.number + " · " + selected.familyName +
                        "\n" + selected.name);
                break;
            }
        }
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

    private void runDirectProbe(Button button) {
        button.setEnabled(false);
        connectivityText.setText("Проверяю прямой доступ к YouTube…");
        executor.execute(() -> {
            String result;
            HttpsURLConnection connection = null;
            try {
                connection = (HttpsURLConnection) new URL("https://www.youtube.com/generate_204").openConnection();
                connection.setRequestMethod("GET");
                connection.setConnectTimeout(5000);
                connection.setReadTimeout(5000);
                connection.setInstanceFollowRedirects(true);
                int code = connection.getResponseCode();
                result = code >= 200 && code < 400
                        ? "Прямой HTTPS-доступ ответил: " + code + ". Стратегии не применялись."
                        : "YouTube ответил HTTP " + code + ". Это только прямая проверка, не тест стратегии.";
            } catch (Exception error) {
                result = "Прямой HTTPS-тест не прошёл: " + error.getClass().getSimpleName()
                        + ". DPI-стратегия не применялась.";
            } finally {
                if (connection != null) connection.disconnect();
            }
            final String message = result;
            runOnUiThread(() -> {
                if (!isFinishing()) {
                    connectivityText.setText(message);
                    button.setEnabled(true);
                }
            });
        });
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
        Profile(int number, int familyId, String name, String familyName) {
            this.number = number;
            this.familyId = familyId;
            this.name = name;
            this.familyName = familyName;
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
                layout.setBackground(shape(CARD, dp(10)));
                TextView primary = text("", 14, TEXT, true);
                TextView secondary = text("", 11, MUTED, false);
                layout.addView(primary, matchWrap());
                layout.addView(secondary, margins(matchWrap(), 0, dp(3), 0, 0));
                row = new ProfileRow(primary, secondary);
                layout.setTag(row);
                convertView = layout;
            }
            Profile profile = getItem(position);
            row.primary.setText("#" + profile.number + "  " + profile.name);
            row.secondary.setText(profile.familyName);
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
