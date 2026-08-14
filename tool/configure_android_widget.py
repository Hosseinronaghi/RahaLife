from pathlib import Path

root = Path('android/app/src/main')
res = root / 'res'
for folder in ['layout', 'xml', 'drawable', 'values', 'values-night', 'values-fa']:
    (res / folder).mkdir(parents=True, exist_ok=True)
kt = root / 'kotlin/com/raha/raha_life'
kt.mkdir(parents=True, exist_ok=True)

(res / 'values/raha_widget_colors.xml').write_text('''<resources>
    <color name="raha_widget_background">#F8FAFC</color>
    <color name="raha_widget_text">#0F172A</color>
    <color name="raha_widget_secondary">#475569</color>
    <color name="raha_widget_accent">#16A34A</color>
</resources>
''', encoding='utf-8')
(res / 'values-night/raha_widget_colors.xml').write_text('''<resources>
    <color name="raha_widget_background">#111827</color>
    <color name="raha_widget_text">#F8FAFC</color>
    <color name="raha_widget_secondary">#CBD5E1</color>
    <color name="raha_widget_accent">#4ADE80</color>
</resources>
''', encoding='utf-8')
(res / 'values/raha_widget_strings.xml').write_text('''<resources>
    <string name="raha_widget_today">Raha Life Today</string>
    <string name="raha_widget_affairs">Raha Life Affairs</string>
    <string name="raha_widget_medication">Raha Life Medicine</string>
    <string name="raha_widget_appointment">Raha Life Appointment</string>
    <string name="raha_widget_shopping">Raha Life Shopping</string>
    <string name="raha_widget_birthday">Raha Life Birthday</string>
    <string name="raha_widget_quick_add">Raha Life Quick Add</string>
</resources>
''', encoding='utf-8')
(res / 'values-fa/raha_widget_strings.xml').write_text('''<resources>
    <string name="raha_widget_today">امروز رها لایف</string>
    <string name="raha_widget_affairs">امور رها لایف</string>
    <string name="raha_widget_medication">داروی رها لایف</string>
    <string name="raha_widget_appointment">قرار رها لایف</string>
    <string name="raha_widget_shopping">خرید رها لایف</string>
    <string name="raha_widget_birthday">تولد رها لایف</string>
    <string name="raha_widget_quick_add">افزودن سریع رها لایف</string>
</resources>
''', encoding='utf-8')
(res / 'drawable/raha_widget_background.xml').write_text('''<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="@color/raha_widget_background" />
    <corners android:radius="22dp" />
    <padding android:left="16dp" android:top="14dp" android:right="16dp" android:bottom="14dp" />
</shape>
''', encoding='utf-8')

(res / 'layout/raha_today_widget.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:gravity="start|center_vertical"
    android:padding="16dp"
    android:background="@drawable/raha_widget_background"
    android:textDirection="locale">

    <TextView
        android:id="@+id/widget_title"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Raha Life"
        android:textColor="@color/raha_widget_accent"
        android:textSize="13sp"
        android:textStyle="bold"
        android:gravity="start" />

    <TextView
        android:id="@+id/widget_summary"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="6dp"
        android:text="Today"
        android:textColor="@color/raha_widget_text"
        android:textSize="18sp"
        android:textStyle="bold"
        android:maxLines="1"
        android:ellipsize="end"
        android:gravity="start" />

    <TextView
        android:id="@+id/widget_next"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="4dp"
        android:text="Nothing scheduled"
        android:textColor="@color/raha_widget_secondary"
        android:textSize="13sp"
        android:maxLines="2"
        android:ellipsize="end"
        android:gravity="start" />
</LinearLayout>
''', encoding='utf-8')

(res / 'layout/raha_compact_widget.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_root"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:gravity="start|center_vertical"
    android:padding="14dp"
    android:background="@drawable/raha_widget_background"
    android:textDirection="locale">

    <TextView
        android:id="@+id/widget_title"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Raha Life"
        android:textColor="@color/raha_widget_accent"
        android:textSize="12sp"
        android:textStyle="bold"
        android:gravity="start" />

    <TextView
        android:id="@+id/widget_summary"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="5dp"
        android:text="Summary"
        android:textColor="@color/raha_widget_text"
        android:textSize="16sp"
        android:textStyle="bold"
        android:maxLines="2"
        android:ellipsize="end"
        android:gravity="start" />
</LinearLayout>
''', encoding='utf-8')

(res / 'xml/raha_today_widget_info.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="250dp"
    android:minHeight="90dp"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/raha_today_widget"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" />
''', encoding='utf-8')
(res / 'xml/raha_compact_widget_info.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="120dp"
    android:minHeight="64dp"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/raha_compact_widget"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" />
''', encoding='utf-8')

support = '''package com.raha.raha_life

import android.app.PendingIntent
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

object RahaWidgetSupport {
    fun launchIntent(context: Context, target: String): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("rahalife://$target"),
        )

    fun compactViews(
        context: Context,
        title: String,
        summary: String,
        target: String,
    ): RemoteViews = RemoteViews(context.packageName, R.layout.raha_compact_widget).apply {
        setTextViewText(R.id.widget_title, title)
        setTextViewText(R.id.widget_summary, summary)
        setOnClickPendingIntent(R.id.widget_root, launchIntent(context, target))
    }
}
'''
(kt / 'RahaWidgetSupport.kt').write_text(support, encoding='utf-8')

(kt / 'RahaTodayWidget.kt').write_text('''package com.raha.raha_life

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class RahaTodayWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val data = HomeWidgetPlugin.getData(context)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.raha_today_widget).apply {
                setTextViewText(R.id.widget_title, data.getString("today_title", "Raha Life"))
                setTextViewText(R.id.widget_summary, data.getString("today_summary", "Today"))
                setTextViewText(R.id.widget_next, data.getString("today_next_item", ""))
                setOnClickPendingIntent(R.id.widget_root, RahaWidgetSupport.launchIntent(context, "today"))
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
''', encoding='utf-8')

widgets = [
    ('RahaAffairsWidget', 'affairs_title', 'affairs_summary', 'Affairs', 'affairs'),
    ('RahaMedicationWidget', 'medication_title', 'medication_summary', 'Medicine', 'medication'),
    ('RahaAppointmentWidget', 'appointment_title', 'appointment_summary', 'Appointment', 'appointment'),
    ('RahaShoppingWidget', 'shopping_title', 'shopping_summary', 'Shopping', 'shopping'),
    ('RahaBirthdayWidget', 'birthday_title', 'birthday_summary', 'Birthday', 'birthday'),
    ('RahaQuickAddWidget', 'quick_add_title', 'quick_add_label', 'Quick add', 'quick-add'),
]
for class_name, title_key, summary_key, fallback, target in widgets:
    (kt / f'{class_name}.kt').write_text(f'''package com.raha.raha_life

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import es.antonborri.home_widget.HomeWidgetPlugin

class {class_name} : AppWidgetProvider() {{
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {{
        val data = HomeWidgetPlugin.getData(context)
        for (appWidgetId in appWidgetIds) {{
            val views = RahaWidgetSupport.compactViews(
                context,
                data.getString("{title_key}", "{fallback}") ?: "{fallback}",
                data.getString("{summary_key}", "") ?: "",
                "{target}",
            )
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }}
    }}
}}
''', encoding='utf-8')

manifest = root / 'AndroidManifest.xml'
text = manifest.read_text(encoding='utf-8')
receivers = [
    ('RahaTodayWidget', '@string/raha_widget_today', '@xml/raha_today_widget_info'),
    ('RahaAffairsWidget', '@string/raha_widget_affairs', '@xml/raha_compact_widget_info'),
    ('RahaMedicationWidget', '@string/raha_widget_medication', '@xml/raha_compact_widget_info'),
    ('RahaAppointmentWidget', '@string/raha_widget_appointment', '@xml/raha_compact_widget_info'),
    ('RahaShoppingWidget', '@string/raha_widget_shopping', '@xml/raha_compact_widget_info'),
    ('RahaBirthdayWidget', '@string/raha_widget_birthday', '@xml/raha_compact_widget_info'),
    ('RahaQuickAddWidget', '@string/raha_widget_quick_add', '@xml/raha_compact_widget_info'),
]
blocks = []
for name, label, info in receivers:
    if f'android:name=".{name}"' in text:
        continue
    blocks.append(f'''        <receiver
            android:name=".{name}"
            android:exported="true"
            android:label="{label}">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="{info}" />
        </receiver>\n''')
if blocks:
    text = text.replace('</application>', ''.join(blocks) + '    </application>', 1)
manifest.write_text(text, encoding='utf-8')
print('Configured Android Raha Life widgets: Today, Affairs, Medicine, Appointment, Shopping, Birthday, Quick Add')
