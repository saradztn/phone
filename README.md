# AURA Phone v2 — هاتف ذكي داخل اللعبة لـ MTA:SA

نظام هاتف كامل (DX) لسيرفرات Roleplay: **صورة جهاز حقيقية** (ليست رسماً بالكود)،
**خطوط Noto Sans** (لاتيني + عربي)، **فأرة أو لوحة مفاتيح**، و16 تطبيقاً.

**الافتتاح:** `F8` (قابل للتعديل من `shared/config.lua`).

---

## 1) ما الجديد في v2

| الميزة | التفاصيل |
|---|---|
| صورة جهاز حقيقية | `assets/phone/device.png` مولّدة وخلفية شفافة — تُرسم فوقها الواجهة بالكامل |
| خطوط TTF | `Noto Sans` (إنجليزي) + `Noto Sans Arabic` (عربي) — Regular + Bold، بحجم مختلف لكل نص (نظام `Phone.pickFont`) |
| نظام لغات | `PhoneConfig.language = "en" / "ar"` + `L("key")` — ملاحظة: MTA لا يوصلح تشكيل العربية (RTL)، الإنجليزي الموصى به |
| استكشاف البيئة | عند الفتح يفتح الكونسول سطر `environment ok` أو تحذيراً بما ينقص العميل |
| وضع لوحة المفاتيح | إن لم يتوفر API الفأرة في العميل: الأسهم = تنقل، Enter = تفعيل، Backspace = رجوع |
| بدائل آمنة | `dxfCreateImage` ← `dxCreateTexture`، `getScreenSize` ← قيم افتراضية، `getTickCount` ← `os.clock` |
| أيقونات احتياطية | إن تعذّر تحميل الصور: بلاطات ملوّنة بحرف التطبيق الأول (بلا أخطاء) |

## 2) الهيكل

```
phone/
├── meta.xml                  ترتيب التحميل + الأصول (خطوط + صورة الجهاز)
├── shared/
│   ├── config.lua            المفتاح، الحدود، POIs، الوظائف، قاعدة البيانات، الجهاز، الخطوط، اللغة
│   ├── utils.lua             تنسيق المال/الوقت/المدة
│   ├── lang.lua              السلاسل ثنائية اللغة + L()
│   └── apps.lua              كتالوج التطبيقات الـ16
├── server/                   (8 ملفات — نفس v1، تعمل على 1.5.9 و1.6)
│   ├── database.lua          MySQL + 12 جدول + escape كامل
│   ├── security.lua          validators + rate limits + audit + SEC.export (تصدير متوافق)
│   ├── main.lua              الهوية، الأرقام الفريدة، handshake (يرسل الرقم الشخصي)
│   ├── messages.lua          الرسائل + غير المقروء
│   ├── calls.lua             آلة حالات المكالمات + سجل
│   ├── contacts.lua          جهات الاتصال
│   ├── bank.lua              البنك والتحويلات (مُتحقق 100% من السيرفر)
│   ├── assets.lua            المركبات + العقارات + الوظائف
│   └── services.lua          ملاحظات/متجر/إعدادات/معلومات سيرفر/طوارئ
├── client/
│   ├── core.lua              الحالة، Env (استكشاف البيئة)، الخطوط، الصور، الصوت، الفتح/الإغلاق
│   ├── draw.lua              D.* — النص (بخطوط)، rrect، أيقونات، أزرار، حقول، قوائم virtualized
│   ├── input.lua             فأرة (نقر/سحب) + لوحة مفاتيح + مؤشر لوحة المفاتيح الاحتياطي
│   ├── ui.lua                جهاز + شريط حالة + شاشة قفل + home + مكالمة + Toasts + Shade
│   └── apps/                 17 ملفاً (16 تطبيقاً + home)
├── assets/
│   ├── phone/device.png      صورة الجهاز (573×1198، خلفية شفافة)
│   ├── fonts/                4 ملفات TTF (Noto Sans + Arabic, Regular + Bold)
│   ├── icons/                16 أيقونة PNG+SVG
│   ├── wallpapers/           خلفيتان
│   ├── sounds/               5 أصوات
│   └── ui/                  textures
└── sql/phone.sql             مخطط الجداول (اختياري)
```

## 3) التثبيت

```
1) MySQL: شغّل MySQL/MariaDB على جهاز السيرفر + استورد sql/phone.sql (أو دع الـ resource ينشئها)
2) عدّل shared/config.lua: database, openKey, poi
3) انسخ phone/ إلى mods/deathmatch/resources/
4) refresh + start phone
5) داخل اللعبة: F8
```

**الأجهزة المدعومة:**
- خادم: MTA 1.5.9 أو 1.6 (windows/ARM) — exports تعمل على النسختين
- عميل: **MTA على PC** (فأرة). عملاء الموبايل (MTA Mobile) تفتقر لـ API الفأرة والصور — سيظهر تحذير واحد فقط ولن تُرسم الواجهة (محدودية المنصة)

## 4) أخطاء محتملة

| المشكلة | الحل |
|---|---|
| `[phone] WARNING: this client is missing: images` | العميل لا يملك dxfCreateImage — استخدم عميل PC قياسي |
| `Can't connect to MySQL (10061)` | MySQL غير مشغّل — شغّله ثم `stop/start phone` |
| الزر لا يفتح | المفتاح محجوز — غيّر `openKey` |
| لا تظهر الأيقونات | تأكد من نسخ `assets/` كاملاً (يوجد فallback بالبلاطات تلقائياً) |
| عربي يظهر غير متصل الحروف | مTA لا يدعم تشكيل العربية في dxDrawText — استخدم `language = "en"` |

## 5) إضافة تطبيق جديد

1. `shared/apps.lua`: `{ id = "music", name = "Music", icon = "assets/icons/music.png", order = 17, desc = "…" }`
2. أيقونة في `assets/icons/music.png`
3. `client/apps/music.lua`:
   ```lua
   registerPhoneApp({
       id = "music", name = "Music",
       onOpen = function() triggerServerEvent("phone:music:fetch") end,
       render = function()
           D.rrect(0, 0, 360, 740, 0, D.t().screen)
           D.header("Music")
           D.btn(20, 84, 320, 48, function() Sound.play("notify") end, { style = "primary", label = "Play" })
       end,
   })
   ```
4. `<script src="client/apps/music.lua" type="client" />` في meta.xml

## 6) Exports (سيرفر)

```lua
phoneNotify(player, "City", "تم قبولك.", "notifications")
phoneGetNumber(player)
phoneSetJob(player, "police")
phoneAddProperty(player, "Villa Palm", "Villa", -167, 115, 20)
```

## 7) الأحداث (عينة)

```lua
-- سيرفر ← كلاينت
triggerClientEvent(player, "phone:notify", player, "bank", "AURA Bank", "Received $2,500", "bank")
-- كلاينت ← سيرفر
triggerServerEvent("phone:msg:send", "0551234567", "Hello")
triggerServerEvent("phone:bank:transfer", "0559876543", 2500)
```
