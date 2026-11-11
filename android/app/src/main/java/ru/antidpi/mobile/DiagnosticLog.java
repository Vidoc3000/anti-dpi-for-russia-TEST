package ru.antidpi.mobile;

import android.content.Context;
import android.content.SharedPreferences;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Locale;

/** Small, bounded, private app log used by the in-app log page and share sheet. */
final class DiagnosticLog {
    static final int INFO = 1;
    static final int WARN = 2;
    static final int ERROR = 3;

    private static final String PREFS = "diagnostic_log";
    private static final String ENTRIES = "entries";
    private static final int DEFAULT_LIMIT = 300;
    private static final int MAX_LIMIT = 600;
    private static final int MAX_LINE_LENGTH = 500;
    private static final int MAX_TOTAL_CHARS = 180_000;

    private DiagnosticLog() { }

    static synchronized void record(Context context, int level, String message) {
        if (context == null || message == null) return;
        Context app = context.getApplicationContext();
        if (level < WARN && !app.getSharedPreferences("android_settings", Context.MODE_PRIVATE)
                .getBoolean("verbose_diagnostics", true)) return;

        String line = message.replace('\n', ' ').replace('\r', ' ').trim();
        if (line.isEmpty()) return;
        if (line.length() > MAX_LINE_LENGTH) line = line.substring(0, MAX_LINE_LENGTH - 3) + "...";
        String levelName = level >= ERROR ? "E" : (level >= WARN ? "W" : "I");
        String timestamp = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
                .format(new Date());
        String entry = timestamp + " " + levelName + " " + line;

        SharedPreferences prefs = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        String existing = prefs.getString(ENTRIES, "");
        ArrayList<String> lines = split(existing);
        lines.add(entry);
        int limit = configuredLimit(app);
        int total = 0;
        for (int i = lines.size() - 1; i >= 0; i--) {
            total += lines.get(i).length() + 1;
            if (lines.size() - i > limit || total > MAX_TOTAL_CHARS) {
                lines.subList(0, i + 1).clear();
                break;
            }
        }
        prefs.edit().putString(ENTRIES, join(lines)).apply();
    }

    static synchronized String read(Context context) {
        String value = context.getApplicationContext()
                .getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(ENTRIES, "");
        return value.isEmpty() ? "Журнал пока пуст." : value;
    }

    static synchronized int count(Context context) {
        return split(context.getApplicationContext()
                .getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(ENTRIES, "")).size();
    }

    static synchronized void clear(Context context) {
        context.getApplicationContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().remove(ENTRIES).apply();
    }

    static synchronized void trim(Context context) {
        Context app = context.getApplicationContext();
        SharedPreferences prefs = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        ArrayList<String> lines = split(prefs.getString(ENTRIES, ""));
        int limit = configuredLimit(app);
        int total = 0;
        for (int i = lines.size() - 1; i >= 0; i--) {
            total += lines.get(i).length() + 1;
            if (lines.size() - i > limit || total > MAX_TOTAL_CHARS) {
                lines.subList(0, i + 1).clear();
                break;
            }
        }
        prefs.edit().putString(ENTRIES, join(lines)).apply();
    }

    static int configuredLimit(Context context) {
        int value = context.getApplicationContext()
                .getSharedPreferences("android_settings", Context.MODE_PRIVATE)
                .getInt("diagnostic_log_limit", DEFAULT_LIMIT);
        return value == 100 || value == 300 || value == MAX_LIMIT ? value : DEFAULT_LIMIT;
    }

    private static ArrayList<String> split(String value) {
        ArrayList<String> lines = new ArrayList<>();
        if (value == null || value.isEmpty()) return lines;
        for (String line : value.split("\\n")) if (!line.isEmpty()) lines.add(line);
        return lines;
    }

    private static String join(ArrayList<String> lines) {
        StringBuilder result = new StringBuilder();
        for (String line : lines) {
            if (result.length() > 0) result.append('\n');
            result.append(line);
        }
        return result.toString();
    }
}
