# بناء تطبيق مصغر (Widget) في أندرويد لربطه بتطبيق Flutter

في هذا التوثيق نستعرض كيفية بناء تطبيق مصغر (App Widget) للشاشة الرئيسية في نظام Android، بحيث يتم تحديث بياناته مباشرةً من خدمة تعمل في الخلفية (Foreground Service) دون الحاجة للاعتماد على حزم خارجية في Flutter (مثل `home_widget`) وذلك لضمان الأداء والكفاءة العالية.

## المكونات الأساسية (Native Android)

لبناء الـ Widget في أندرويد بطريقة صحيحة نحتاج إلى الخطوات والمكونات التالية:

### 1. تصميم واجهة الـ Widget (XML Layouts)
يتم وضع التصاميم في مجلد `android/app/src/main/res/layout/`.
قمنا بإنشاء ملف `widget_usage.xml` الذي يعتمد على `RelativeLayout` (أو `FrameLayout`) لترتيب العناصر بشكل متناسق مع الواجهة المطلوبة.

كذلك تم تخصيص شكل الـ Widget بإضافة أشكال مرسومة في `res/drawable`:
- `widget_background.xml`: لرسم شكل ذو حواف دائرية ولون خلفية داكن.
- `ic_lightning_widget.xml`: لرسم أيقونة (Vector Drawable).

### 2. إعدادات الـ Widget (AppWidgetProviderInfo)
ملف XML في `res/xml/usage_widget_info.xml`، وظيفته إخبار نظام أندرويد بخصائص هذا التطبيق المصغر:
- `minWidth` و `minHeight`: الأبعاد الأولية.
- `updatePeriodMillis`: وقت التحديث التلقائي (نحن نجعله `0` لأننا سنحدثه يدوياً من الخدمة).
- `initialLayout`: التصميم المبدئي (وهو `widget_usage`).

### 3. الكلاس المسؤول `AppWidgetProvider`
كلاس مكتوب بلغة Kotlin (مثل `UsageWidgetProvider.kt`) يرث من `AppWidgetProvider`.
وظيفته الأساسية هي معالجة أحداث الويدجت (مثل `onUpdate`).
يحتوي على دالة لتحديث الواجهة `updateAppWidget` باستخدام كائن `RemoteViews`، حيث يتم:
- تغيير النصوص عبر `setTextViewText`.
- تحديد أحداث النقر عبر `setOnClickPendingIntent` لفتح التطبيق عند النقر على الويدجت.

### 4. تسجيل المكونات في `AndroidManifest.xml`
يجب تعريف الـ `AppWidgetProvider` داخل وسم `<receiver>` وإضافة فلتر للأحداث `<action android:name="android.appwidget.action.APPWIDGET_UPDATE" />` وربطه بملف الإعدادات من خلال `<meta-data>`.

### 5. تحديث الـ Widget من الخدمة الخلفية (Foreground Service)
بما أننا نملك بالفعل `DataUsageService` تقوم بحساب الاستهلاك وتحديث الإشعار (Notification)، يمكننا استغلال نفس الـ Timer ليقوم بالبحث عن الـ Widgets النشطة وتحديثها مباشرة:
```kotlin
private fun updateWidget(usageStr: String) {
    val appWidgetManager = android.appwidget.AppWidgetManager.getInstance(this)
    val componentName = android.content.ComponentName(this, UsageWidgetProvider::class.java)
    val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
    for (appWidgetId in appWidgetIds) {
        UsageWidgetProvider.updateAppWidget(this, appWidgetManager, appWidgetId, usageStr)
    }
}
```

## ملخص المعرفة المكتسبة:
- **تحديث البيانات فورياً:** استخدام الكود الأصلي (Native Kotlin) يتيح تحديث الـ Widget مباشرة من الخدمة الخلفية (Service) بمجرد حصول تغيير في البيانات.
- **توفير الموارد:** لا نحتاج لفتح Flutter Engine أو استخدام قنوات اتصال (MethodChannels) متكررة لتحديث واجهة صغيرة في الشاشة الرئيسية.
- **RemoteViews:** نظراً لأن الـ Widget يعمل في عملية (Process) منفصلة تابعة للشاشة الرئيسية (Launcher)، لا يمكننا التعديل على واجهته بشكل مباشر، بل نستخدم كائن `RemoteViews` لإرسال التعليمات (تغيير نص، تغيير لون، إضافة حدث نقر) لنظام الأندرويد ليقوم بتطبيقها.
