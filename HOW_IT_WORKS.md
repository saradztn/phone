# الدليل الشامل والموسوعي لمكتبة NovaUI (`v3.0.0`) لـ MTA:SA
## كيف تعمل المكتبة داخليًا + شرح كل ملف وكل دالة وكل مكوّن (55 مكوّنًا) بالتفصيل

هذا الملف هو المرجع الكامل والنهائي لفهم **كل شيء حرفيًا** داخل مكتبة **`NovaUI`**: كيف صُممت، كيف تعمل خلف الكواليس في كل Frame، كيف تتعامل مع الذاكرة والمدخلات وDGS، وكيف يمكنك استخدام كل ميزة وكل مكوّن من الـ **55 مكوّنًا** لبناء أي واجهة تتخيلها داخل **MTA:SA**.

---

## الفهرس العام

1. [الفكرة الأساسية: كيف تعمل NovaUI خلف الكواليس؟](#1-الفكرة-الأساسية-كيف-تعمل-novaui-خلف-الكواليس)
2. [ماذا يحدث في كل Frame؟ (رحلة الرسم خطوة بخطوة)](#2-ماذا-يحدث-في-كل-frame-رحلة-الرسم-خطوة-بخطوة)
3. [تشريح جميع ملفات المكتبة (ملفًا بملف)](#3-تشريح-جميع-ملفات-المكتبة-ملفًا-بملف)
4. [نظام الإحداثيات والتحجيم الذكي (Responsive Scaling)](#4-نظام-الإحداثيات-والتحجيم-الذكي-responsive-scaling)
5. [الكائن الأساسي Component ودورة حياته (Lifecycle & Universal API)](#5-الكائن-الأساسي-component-ودورة-حياته-lifecycle--universal-api)
6. [نظام الأحداث (Events) ونظام المدخلات الموحد (Input System)](#6-نظام-الأحداث-events-ونظام-المدخلات-الموحد-input-system)
7. [نظام التصميم المركزي ومحرك الثيمات (Design System & Themes)](#7-نظام-التصميم-المركزي-ومحرك-الثيمات-design-system--themes)
8. [محرك الحركات والانتقالات (Animation Engine)](#8-محرك-الحركات-والانتقالات-animation-engine)
9. [موسوعة المكونات الـ 55 (شرح كل مكوّن بالتفصيل الممل)](#9-موسوعة-المكونات-الـ-55-شرح-كل-مكوّن-بالتفصيل-الممل)
   - [9.1 المكونات الأساسية Core (9 مكونات)](#91-المكونات-الأساسية-core-9-مكونات)
   - [9.2 مكونات الإدخال Input (14 مكوّنًا)](#92-مكونات-الإدخال-input-14-مكوّنًا)
   - [9.3 مكونات التنقل Navigation (6 مكونات)](#93-مكونات-التنقل-navigation-6-مكونات)
   - [9.4 مكونات البيانات والـ Virtualization (6 مكونات)](#94-مكونات-البيانات-والـ-virtualization-6-مكونات)
   - [9.5 مكونات التنبيهات والتفاعل Feedback (10 مكونات)](#95-مكونات-التنبيهات-والتفاعل-feedback-10-مكونات)
   - [9.6 المكونات المتقدمة والرسوم البيانية Advanced (10 مكونات)](#96-المكونات-المتقدمة-والرسوم-البيانية-advanced-10-مكونات)
10. [نظام الأيقونات (48 أيقونة) وإدارة الصور والخطوط](#10-نظام-الأيقونات-48-أيقونة-وإدارة-الصور-والخطوط)
11. [كيف يعمل الربط مع DGS وطبقة التوافق والـ Exports؟](#11-كيف-يعمل-الربط-مع-dgs-وطبقة-التوافق-والـ-exports)
12. [تطبيقات عملية كاملة جاهزة للنسخ والتشغيل](#12-تطبيقات-عملية-كاملة-جاهزة-للنسخ-والتشغيل)

---

## 1. الفكرة الأساسية: كيف تعمل NovaUI خلف الكواليس؟

### الفرق بين الطريقة القديمة في MTA وطريقة `NovaUI`
في برمجة MTA:SA التقليدية (Immediate Mode DX):
- يضطر المبرمج لكتابة حدث `onClientRender` ويضع بداخله عشرات من دوال `dxDrawRectangle` و`dxDrawText` ويحسب موقع الماوس يدويًا في كل Frame.
- هذا يجعل الكود فوضويًا وصعب الصيانة ويستهلك الأداء إذا لم يتم تحسينه.

أما **`NovaUI`** فتعمل بنظام **Retained-Mode Scene Graph (شجرة المشهد المحتفظ بها)**:
1. **أنت تنشئ العنصر مرة واحدة فقط** (مثلاً عند فتح اللوحة):
   ```lua
   local win = NovaUI.create("window", { title = "حسابي", width = 600, height = 400 })
   local btn = win:create("button", { x = 20, y = 20, width = 140, height = 38, text = "حفظ" })
   ```
2. يصبح `win` كائنًا (Object) داخل شجرة العناصر (`NovaUI._registry.rootElements`)، ويصبح `btn` ابنًا (`child`) داخل `win.children`.
3. **مكتبة `NovaUI` تتكفل بكل شيء تلقائيًا في الخلفية**:
   - ترسم النافذة والأزرار في كل Frame.
   - تكتشف مرور الماوس (`hover`) والضغط (`click`) والسحب (`drag`) والتمرير (`scroll`).
   - تطبق الثيم النشط (`NovaUI.Theme`) والحركات (`NovaUI.Animation`).
   - تتجاهل رسم أي عنصر مخفي أو خارج حدود الشاشة (`Off-Screen Culling`) للحفاظ على أعلى FPS ممكن.

---

## 2. ماذا يحدث في كل Frame؟ (رحلة الرسم خطوة بخطوة)

في ملف `client/rendering/renderer.lua` توجد حلقة رسم واحدة فقط مربوطة بـ `onClientRender` وهي `Renderer.renderFrame()`. في كل Frame (60 مرة في الثانية) تقوم بالخطوات الـ 7 التالية بالترتيب:

```text
[بداية الـ Frame في onClientRender]
       │
       ▼
1. NovaUI.Animation.tick(now)
   ├── تحديث جميع الحركات النشطة (الشفافية، الموقع، الحجم، تدرج الألوان)
   └── حذف أي حركة انتهت مدتها تلقائيًا
       │
       ▼
2. Renderer.sortRoots()
   └── ترتيب العناصر الجذرية حسب طبقة الـ zIndex ثم حسب آخر نافذة تم التركيز عليها (_focusOrder)
       │
       ▼
3. رسم العناصر الجذرية وأبنائها (Renderer.renderComponent)
   ├── حساب الموقع الفعلي على الشاشة (absX, absY) والشفافية المتوارثة (alphaRatio)
   ├── فحص الـ Culling: هل العنصر داخل منطقة الرؤية؟ إذا كان خارجها يتم تخطيه فورًا (0 استهلاك!)
   ├── استدعاء comp:render(...) لرسم العنصر نفسه
   └── رسم الأبناء (comp.children) بإحداثيات نسبية لمنطقة محتوى الأب
       │
       ▼
4. NovaUI.ModalManager.renderAll()
   └── إذا كانت هناك نافذة تأكيد أو Modal مفتوحة، يتم رسم الخلفية المعتمة (Overlay) وفوقها الـ Modal
       │
       ▼
5. تنفيذ طابور الطبقات العائمة (Renderer.overlayQueue)
   └── رسم القوائم المنسدلة المفتوحة (Dropdown / ComboBox / ContextMenu) فوق كل النوافذ حتى لا تنقصّ!
       │
       ▼
6. NovaUI.NotificationManager.renderAll()
   └── رسم إشعارات الـ Toast في أعلى يمين الشاشة مع شريط الوقت المتبقي
       │
       ▼
7. NovaUI.TooltipManager.render()
   └── رسم التلميح العائم (Tooltip) بجوار مؤشر الماوس إذا كان اللاعب متوقفًا فوق عنصر له تلميح
```

---

## 3. تشريح جميع ملفات المكتبة (ملفًا بملف)

### أ. النواة الأساسية (`client/core/`)
1. **`client/core/namespace.lua`**:
   - ينشئ الجدول العام `NovaUI`، إعدادات `NovaUI.Config`، سجل العناصر الداخلي `NovaUI._registry`، ودوال التسجيل والتحقق (`NovaUI.log`, `NovaUI.warn`, `NovaUI.error`, `NovaUI.validate`) المزودة بنظام **Rate-Limiting** يمنع تكرار نفس رسالة التحذير في كل Frame.
   - يوفر `NovaUI.setTimer` و`NovaUI.killTimer` لتتبع المؤقتات وتدميرها تلقائيًا عند إيقاف السكربت.
2. **`client/core/utils.lua`**:
   - دوال الرياضيات والهندسة والألوان: `clamp`, `lerp`, `round`, `pointInRect` (فحص وجود الماوس داخل مستطيل), `intersectRect` (تقاطع مستطيلين للـ Clipping), `unpackColor` (تحويل `#RRGGBB` أو `{r,g,b,a}` أو `tocolor`), `lerpColor` (دمج لونين بنعومة), `rgbToHex`, `hsvToRGB`, `rgbToHSV`, ودوال النصوص `utf8Len`, `utf8Sub`, `formatNumber`.
3. **`client/core/class.lua`**:
   - نظام البرمجة الكائنية (OOP) الخاص بالمكتبة `NovaUI.Class(name, super)` الذي يدعم الوراثة (`Inheritance`) وفحص النوع (`:isInstanceOf()`).
4. **`client/core/lifecycle.lua`**:
   - الكلاس الأب **`NovaUI.Component`** الذي ترث منه جميع المكونات الـ 55. يدير الإنشاء (`init` -> `onCreate` -> `mount`), التحديث (`update`), الأبناء (`children`), الموقع والحجم، والتدمير الآمن الكامل (`destroy`).
5. **`client/core/factory.lua`**:
   - يسجل المكونات عبر `NovaUI.registerComponent` ويوفر الواجهة الموحدة `NovaUI.create(type, props, parent)` بالإضافة إلى المختصرات مثل `NovaUI.window(...)` و`NovaUI.button(...)`.
6. **`client/core/bootstrap.lua`**:
   - يدير الإغلاق الآمن للمكتبة عند إيقاف المورد (`NovaUI.shutdown()`) ويوفر دوال الـ `Exports` (`novaCreate`, `novaDestroy`, `novaSetTheme`, إلخ).

### ب. الثيمات والتصميم (`client/theme/`)
7. **`client/theme/tokens.lua`**: القيم المعيارية المركزية (`spacing`, `radius`, `fontSize`, `fontWeight`, `shadows`, `border`, `opacity`, `animation`, `zIndex`).
8. **`client/theme/palettes.lua`**: تعريف لوحات الألوان الخمس المدمجة (`dark`, `midnight`, `ocean`, `emerald`, `light`).
9. **`client/theme/manager.lua`**: محرك الثيمات التفاعلي (`NovaUI.Theme`, `NovaUI.setTheme`, `NovaUI.createTheme`, `NovaUI.getThemes`).

### ج. الرسم والتحجيم (`client/rendering/`)
10. **`client/rendering/scaling.lua`**: محرك التحجيم المتجاوب عبر جميع الدقات (`NovaUI.scale`, `NovaUI.scaleFont`, `NovaUI.fitToViewport`).
11. **`client/rendering/primitives.lua`**: دوال الرسم الأولية المحسّنة (`drawRoundedRect`, `drawShadow`, `drawGlassPanel`, `drawCircle`, `drawArc`, `drawText`, `drawLine`).
12. **`client/rendering/renderer.lua`**: مدير شجرة المشهد والـ Clipping والـ Culling وترتيب الطبقات.

### د. الحركات والمدخلات والأحداث والموارد
13. **`client/events/emitter.lua`**: نظام الأحداث (`:on`, `:once`, `:off`, `:emit`).
14. **`client/input/manager.lua`**: مدير المدخلات الموحد (الماوس، الكيبورد، السحب، عجلة التمرير، التركيز، الاختصارات).
15. **`client/animation/easing.lua`**: مكتبة تضم 24 معادلة رياضية للتسارع (`outCubic`, `outBack`, `spring`, إلخ).
16. **`client/animation/engine.lua`**: محرك الحركات (`NovaUI.animate`, `fadeIn`, `fadeOut`, `slideTo`, `resizeTo`).
17. **`client/assets/manager.lua`**: مدير تحميل وتخزين الصور (`Texture Caching & Fallback`).
18. **`client/assets/icons.lua`**: محرك رسم الأيقونات المتجهة (48 أيقونة بصيغة SVG + DX Fallback).
19. **`client/fonts/manager.lua`**: مدير تحميل وتخزين الخطوط (`Font Caching`).
20. **`client/adapters/dgs/adapter.lua`** و **`compat.lua`**: جسر الربط مع مكتبة DGS وطبقة التوافق للمشاريع القديمة.

---

## 4. نظام الإحداثيات والتحجيم الذكي (Responsive Scaling)

### القاعدة الأهم في الإحداثيات
عندما تكتب في `NovaUI`:
```lua
local panel = NovaUI.create("panel", {
    x = 100,
    y = 50,
    width = 400,
    height = 300,
})
```
- الأرقام `100, 50, 400, 300` هي بأبعاد شاشة قياسية **`1920x1080`**.
- تقوم `NovaUI` **تلقائيًا** بتحويلها لتناسب شاشة اللاعب (سواء كانت `800x600` أو `1366x768` أو `4K`).
- **تحذير مهم**: لا تكتب `width = NovaUI.scale(400)` داخل `NovaUI.create` لأن `NovaUI.create` يقوم باستدعاء `NovaUI.scale` تلقائيًا! (إلا إذا مررت الخيار `autoScale = false`).

### الإحداثيات النسبية للأب (`Parent-Relative Coordinates`)
عندما تضيف عنصرًا داخل `window` أو `card` أو `panel`:
```lua
local win = NovaUI.create("window", { title = "المتجر", width = 500, height = 350 })
local btn = win:create("button", { x = 20, y = 20, width = 120, height = 38, text = "شراء" })
```
- موقع الزر `x = 20, y = 20` يُقاس من **بداية منطقة المحتوى داخل النافذة (أسفل شريط العنوان مباشرة)** وليس من زاوية الشاشة!
- عند سحب النافذة بالماوس، يتحرك الزر معها تلقائيًا دون أي كود إضافي.

### دوال التحجيم المتاحة للمطور
| الدالة | وظيفتها |
| :--- | :--- |
| `NovaUI.scale(value)` | تحجيم رقم (بيكسل) بشكل متناسق مع أبعاد الشاشة الحالية. |
| `NovaUI.scaleX(value)` | تحجيم أفقي نسبي لعرض الشاشة. |
| `NovaUI.scaleY(value)` | تحجيم عمودي نسبي لارتفاع الشاشة. |
| `NovaUI.scaleFont(ptSize)` | تحجيم حجم الخط بمنحنى بصري يحافظ على وضوح القراءة في الشاشات الصغيرة (`800x600`). |
| `NovaUI.unscale(pixels)` | عكس التحجيم (تحويل البيكسلات الفعلية إلى إحداثيات `1080p` القياسية). |
| `NovaUI.getScreenSize()` | تُعيد `screenW, screenH` للشاشة الحالية. |
| `NovaUI.getScaleFactor()` | تُعيد معامل التحجيم الحالي `factor, factorX, factorY`. |
| `NovaUI.getBreakpoint()` | تُعيد تصنيف حجم الشاشة: `"xs"` أو `"sm"` أو `"md"` أو `"lg"` أو `"xl"` أو `"xxl"`. |
| `NovaUI.fitToViewport(x, y, w, h, margin)` | تضبط أي مستطيل ليضمن عدم خروجه خارج حدود الشاشة أبدًا. |

---

## 5. الكائن الأساسي Component ودورة حياته (Lifecycle & Universal API)

كل عنصر تنشئه في `NovaUI` يمر بـ 5 مراحل واضحة:
1. **`create` (`onCreate`)**: تهيئة الخصائص الأولية والحالة (`state`).
2. **`mount` (`onMount`)**: ربط العنصر بشجرة المشهد وإطلاق حدث `"mount"`.
3. **`update` (`onUpdate`)**: تعديل الخصائص ديناميكيًا عبر `:update({...})` أو الدوال مثل `:setText()`.
4. **`render`**: رسم العنصر في كل Frame طالما أنه ظاهر (`visible = true`) وداخل حدود الرؤية.
5. **`destroy` (`onDestroy`)**: التدمير الكامل للعنصر وأبنائه وحركاته ومؤقتاته وصوره ومستمعات أحداثه.

### جميع الدوال المشتركة في كل مكوّن (Universal Component Methods)

```lua
-- 1. إنشاء الأبناء وإدارة الشجرة
local child = element:create("button", { x = 10, y = 10, text = "فرعي" })
element:addChild(otherComponent)
element:removeChild(child)
element:clearChildren() -- يحذف ويدمر جميع الأبناء داخل العنصر

-- 2. الموقع والحجم
element:setPosition(x, y)            -- يقبل إحداثيات 1080p ويحجمها تلقائيًا
local x, y = element:getPosition()   -- يُعيد الإحداثيات المحجمة بالنسبة للأب
local sx, sy = element:getScreenPosition() -- يُعيد الإحداثيات المطلقة على الشاشة
element:setSize(width, height)
local w, h = element:getSize()

-- 3. الإظهار والإخفاء والتفعيل
element:setVisible(true)             -- إظهار أو إخفاء
element:show()                       -- اختصار لـ setVisible(true)
element:hide()                       -- اختصار لـ setVisible(false)
element:toggle()                     -- عكس حالة الظهور الحالية
local vis = element:isVisible()      -- يتحقق من ظهور العنصر وجميع آبائه
element:setEnabled(false)            -- تعطيل العنصر (يظهر باهتًا ولا يستجيب للضغط)
local en = element:isEnabled()

-- 4. الشفافية والنص والقيمة
element:setAlpha(200)                -- من 0 (مخفي تمامًا) إلى 255 (كامل الوضوح)
local a = element:getAlpha()
element:setText("نص جديد")
local txt = element:getText()
element:setValue(newValue, silent)   -- يحدّث القيمة ويطلق حدث "change" (إلا إذا كان silent = true)
local val = element:getValue()

-- 5. التلميحات والتركيز والترتيب والحركة
element:setTooltip("يظهر هذا النص عند تمرير الماوس")
element:focus()                      -- إعطاء التركيز للعنصر ورفعه للمقدمة
element:blur()                       -- إزالة التركيز
element:bringToFront()               -- رفع العنصر (ونافذته) فوق باقي النوافذ
element:sendToBack()                 -- إرسال للخلف
element:animate({ alpha = 120, duration = 300 })

-- 6. التحديث الجماعي والتدمير
element:update({ text = "محدث", width = 200, disabled = false })
element:destroy()                    -- حذف نهائي وتنظيف الذاكرة
```

---

## 6. نظام الأحداث (Events) ونظام المدخلات الموحد (Input System)

### كيفية استخدام الأحداث
```lua
-- الاستماع لحدث
local _, listenerFn = element:on("click", function(self, mouseX, mouseY)
    outputChatBox("تم النقر على العنصر!")
end)

-- الاستماع لمرة واحدة فقط (يحذف نفسه تلقائيًا بعد أول تنفيذ)
element:once("hover", function(isHovered, mx, my)
    outputChatBox("مرت الفأرة لأول مرة!")
end)

-- إزالة مستمع معين أو جميع مستمعات حدث معين
element:off("click", listenerFn)
element:off("click")         -- يحذف كل مستمعات حدث click
element:removeAllListeners() -- يحذف جميع المستمعات من العنصر
```

### جدول جميع الأحداث في `NovaUI`
| اسم الحدث | المعاملات الممررة للدالة (`Arguments`) | متى ينطلق؟ |
| :--- | :--- | :--- |
| `"click"` | `(self, mouseX, mouseY)` | عند النقر بالزر الأيسر للماوس على العنصر. |
| `"doubleClick"` | `(self, mouseX, mouseY)` | عند النقر المزدوج السريع (خلال 320ms). |
| `"contextMenu"` | `(self, mouseX, mouseY)` | عند النقر بالزر الأيمن للماوس على العنصر. |
| `"mouseDown"` | `(button, mouseX, mouseY)` | لحظة ضغط زر الماوس لأسفل. |
| `"mouseUp"` | `(button, mouseX, mouseY)` | لحظة إفلات زر الماوس. |
| `"hover"` | `(isHovered, mouseX, mouseY)` | عند دخول الماوس للعنصر (`true`) أو خروجه منه (`false`). |
| `"mouseEnter"` | `(mouseX, mouseY)` | لحظة دخول الماوس حدود العنصر. |
| `"mouseLeave"` | `(mouseX, mouseY)` | لحظة خروج الماوس من حدود العنصر. |
| `"change"` | `(newValue, oldValue)` | عند تغيّر قيمة العنصر (`Edit`, `Slider`, `Switch`, `Checkbox`, `Dropdown`, `Tabs`, إلخ). |
| `"select"` | `(selectedItem, index)` | عند اختيار صف أو عنصر في `Table`, `List`, `Dropdown`, `Tree`, `ContextMenu`. |
| `"submit"` | `(value)` | عند الضغط على `Enter` داخل حقل كتابة `Edit`. |
| `"focus"` / `"blur"`| `(self)` | عند اكتساب أو فقدان التركيز. |
| `"drag"` / `"dragEnd"`| `(mx, my, dx, dy)` | أثناء سحب العنصر بالماوس وعند انتهاء السحب. |
| `"scroll"` | `(direction)` | عند التمرير بعجلة الماوس (`1` للأعلى، `-1` للأسفل). |
| `"close"` | `(self)` | عند إغلاق `Window` أو `Modal` أو `Alert` (إرجاع `false` في `Window` يلغي الإغلاق!). |
| `"minimize"` / `"maximize"` | `(state)` | عند تصغير أو تكبير النافذة. |
| `"move"` / `"resize"`| `(x, y)` / `(w, h)` | عند تغيّر موقع أو حجم العنصر. |
| `"destroy"` | `(self)` | لحظة تدمير العنصر عبر `:destroy()`. |

### حماية أزرار اللعب أثناء الكتابة
عندما ينقر اللاعب داخل أي حقل كتابة (`Edit`, `SearchBox`, `PasswordInput`, `NumberInput`, `TextArea`)، يقوم `NovaUI.Input` تلقائيًا بتفعيل `guiSetInputMode("no_binds")` حتى لا تفتح دردشة اللعبة عند ضغط حرف `T` أو يخرج اللاعب من المركبة عند ضغط `F`، وبمجرد الخروج من الحقل يعيدها إلى `"allow_binds"`.

---

## 7. نظام التصميم المركزي ومحرك الثيمات (Design System & Themes)

### الثيمات الخمسة الجاهزة
1. **`"midnight"`** (الافتراضي): كحلي فضائي عميق مع سماوي كهربائي وبنفسجي نيون.
2. **`"dark"`**: رمادي داكن عصري مستوحى من لوحات تحكم SaaS الحديثة.
3. **`"ocean"`**: أزرق محيطي عميق مع تدرجات الفيروزي (`Teal` & `Aqua`).
4. **`"emerald"`**: أخضر زمردي داكن مستوحى من واجهات الأنظمة التكتيكية.
5. **`"light"`**: ثيم نهاري أبيض نقي وعصري.

```lua
-- تغيير الثيم في أي وقت (تتغير ألوان جميع النوافذ والعناصر المفتوحة تلقائيًا!)
NovaUI.setTheme("emerald")

-- معرفة اسم الثيم الحالي
local current = NovaUI.getThemeName()

-- الاستماع لتغير الثيم
NovaUI.onThemeChange(function(themeName, themeTable)
    outputChatBox("تم تفعيل الثيم: " .. themeName)
end)
```

### إنشاء ثيم خاص بك (`NovaUI.createTheme`)
```lua
NovaUI.createTheme("desert_gold", {
    label           = "Desert Gold",
    isDark          = true,
    background      = { 18, 15, 11, 248 },
    backgroundAlt   = { 24, 20, 15, 255 },
    surface         = { 30, 25, 18, 255 },
    surfaceElevated = { 40, 33, 24, 255 },
    surfaceHover    = { 52, 43, 31, 255 },
    header          = { 22, 18, 13, 255 },
    sidebar         = { 20, 16, 12, 255 },
    primary         = "#F59E0B", -- يقبل جدول {r,g,b,a} أو كود Hex مباشرة!
    primaryHover    = "#FBBF24",
    primarySoft     = { 245, 158, 11, 38 },
    secondary       = "#FB923C",
    text            = { 254, 243, 199, 255 },
    textSecondary   = { 214, 195, 165, 255 },
    textMuted       = { 156, 140, 116, 255 },
    border          = { 72, 58, 40, 220 },
    borderFocus     = "#F59E0B",
}, "dark") -- يرث أي خاصية لم تذكرها من ثيم "dark"

NovaUI.setTheme("desert_gold")
```

---

## 8. محرك الحركات والانتقالات (Animation Engine)

يدعم `NovaUI.animate` تحريك أي خاصية رقمية (`x`, `y`, `width`, `height`, `alpha`, `rotation`, `value`, إلخ) وأي خاصية لونية (`backgroundColor`, `color`, إلخ):

```lua
NovaUI.animate(myCard, {
    from = { alpha = 0, y = 120 }, -- قيم البداية (اختياري)
    alpha = 255,                   -- القيمة النهائية للشفافية
    y = 80,                        -- القيمة النهائية للموقع العمودي
    duration = 350,                -- المدة بالملي ثانية
    delay = 50,                    -- تأخير قبل البدء (اختياري)
    easing = "outBack",            -- دالة التسارع
    onUpdate = function(target, progress, easedProgress)
        -- يُستدعى في كل Frame أثناء الحركة
    end,
    onComplete = function(target)
        -- يُستدعى فور انتهاء الحركة
    end,
})
```

### جميع دوال التسارع الـ 24 المتوفرة (`Easing Functions`)
- `linear`
- `inQuad`, `outQuad`, `inOutQuad`
- `inCubic`, `outCubic`, `inOutCubic`
- `inQuart`, `outQuart`, `inOutQuart`
- `inQuint`, `outQuint`, `inOutQuint`
- `inSine`, `outSine`, `inOutSine`
- `inExpo`, `outExpo`
- `inBack`, `outBack`, `inOutBack`
- `outElastic`, `outBounce`, `spring`

---

## 9. موسوعة المكونات الـ 55 (شرح كل مكوّن بالتفصيل الممل)

---

### 9.1 المكونات الأساسية Core (9 مكونات)

#### 1. `Window` (`"window"`)
نافذة متكاملة تدعم السحب، تغيير الحجم من الزاوية السفلية، التصغير (`Minimize`), التكبير لملء الشاشة (`Maximize`), الإغلاق (`Close`), شريط عنوان مع أيقونة وعنوان فرعي، وشريط سفلي (`Footer`).
```lua
local win = NovaUI.create("window", {
    title = "إدارة الحساب",
    subtitle = "تعديل البيانات الشخصية والأمان",
    icon = "shield",
    width = 700,
    height = 460,
    minWidth = 320,
    minHeight = 220,
    draggable = true,
    resizable = true,
    minimizable = true,
    maximizable = true,
    closable = true,
    showFooter = true,
    footerText = "جميع الحقوق محفوظة • NovaUI v3.0",
    destroyOnClose = false, -- إذا كانت true يتم تدمير النافذة نهائيًا عند إغلاقها بدلاً من إخفائها
})
-- دوال إضافية خاصة بالنافذة:
win:setTitle("عنوان جديد", "وصف فرعي جديد")
win:minimize()
win:maximize()
win:close()
```

#### 2. `Panel` (`"panel"`)
لوحة سطحية لتجميع العناصر مع دعم الظلال والحدود والزجاج الضبابي (`glass`).
```lua
local pnl = win:create("panel", {
    x = 20, y = 20, width = 300, height = 180,
    title = "معلومات الشخصية", -- اختياري
    variant = "elevated",       -- "surface" | "elevated" | "glass" | "outlined" | "ghost"
    radius = "md",              -- "none" | "xs" | "sm" | "md" | "lg" | "xl"
    shadow = "md",              -- "none" | "sm" | "md" | "lg" | "xl"
})
```

#### 3. `Container` (`"container"`)
حاوية تخطيط خفيفة تدعم الترتيب التلقائي العمودي (`"column"`) أو الأفقي (`"row"`).
```lua
local col = win:create("container", {
    x = 20, y = 20, width = 260, height = 300,
    layout = "column",          -- "none" | "column" | "row"
    gap = 10,                   -- المسافة بين كل عنصرين
    padding = 12,               -- الهامش الداخلي
    stretchChildren = true,     -- يمدد عرض الأبناء تلقائيًا ليملأ عرض الحاوية
})
col:create("button", { height = 38, text = "زر 1" })
col:create("button", { height = 38, text = "زر 2" })
```

#### 4. `Label` (`"label"`)
عنصر النصوص والعناوين بمقاييس تايبوغرافي متعددة.
```lua
win:create("label", {
    x = 20, y = 20, width = 300, height = 30,
    text = "مرحباً بك في السيرفر",
    variant = "h2",             -- "display" | "h1" | "h2" | "h3" | "title" | "subtitle" | "body" | "small" | "caption"
    color = "primary",          -- اسم لون من الثيم ("primary", "success", "danger", "textMuted") أو جدول {r,g,b,a}
    alignX = "left",            -- "left" | "center" | "right"
    alignY = "center",          -- "top" | "center" | "bottom"
    wordBreak = true,           -- التفاف النص في عدة أسطر
})
```

#### 5. `Button` (`"button"`)
زر تفاعلي بـ 7 أنماط لونية و4 أحجام مع دعم الأيقونة وحالة التحميل (`loading`).
```lua
local btn = win:create("button", {
    x = 20, y = 70, width = 160, height = 40,
    text = "إرسال الطلب",
    variant = "primary",        -- "primary" | "secondary" | "outline" | "ghost" | "danger" | "success" | "warning"
    size = "md",                -- "xs" | "sm" | "md" | "lg"
    icon = "check",
    iconPosition = "left",      -- "left" | "right"
    loading = false,
})
btn:setLoading(true)            -- يحول الزر إلى مؤشر تحميل دوّار ويمنع النقر المكرر!
```

#### 6. `Image` (`"image"`)
عرض صورة مع تخزين مؤقت (`Texture Cache`) وبديل تلقائي عند فقدان الصورة.
```lua
local img = win:create("image", {
    x = 20, y = 20, width = 64, height = 64,
    src = "assets/images/logo.png",
    radius = "sm",
})
img:setSource("assets/images/avatar_default.png")
```

#### 7. `Icon` (`"icon"`)
عرض أيقونة متجهة (`Vector Icon`) مستقلة مع إمكانية إضافة خلفية ملونة.
```lua
local ic = win:create("icon", {
    x = 20, y = 20, size = 36,
    name = "shield",
    color = NovaUI.Theme.primary,
    backgroundColor = NovaUI.Theme.primarySoft,
    radius = "sm",
})
ic:setIcon("star")
```

#### 8. `Divider` (`"divider"`)
خط فاصل أفقي أو عمودي مع إمكانية وضع عنوان وسطي.
```lua
win:create("divider", {
    x = 20, y = 120, width = 400,
    orientation = "horizontal", -- "horizontal" | "vertical"
    text = "أو اختر من القائمة", -- اختياري
})
```

#### 9. `Spacer` (`"spacer"`)
عنصر مسافة فارغة يُستخدم داخل `Container` ذات الترتيب التلقائي (`column` / `row`).
```lua
col:create("spacer", { size = 16 })
```

---

### 9.2 مكونات الإدخال Input (14 مكوّنًا)

#### 10. `Edit` (`"edit"`)
حقل إدخال نصي أحادي السطر يدعم المؤشر (`Caret`) والأسهم والمسح والأيقونة وزر الحذف السريع (`clearable`).
```lua
local nameEdit = win:create("edit", {
    x = 20, y = 20, width = 280, height = 38,
    value = "",
    placeholder = "اكتب اسم المستخدم...",
    icon = "user",
    clearable = true,
    maxLength = 32,
})
nameEdit:on("change", function(text) end)
nameEdit:on("submit", function(text) end) -- عند ضغط Enter
```

#### 11. `SearchBox` (`"searchbox"`)
حقل بحث جاهز بأيقونة عدسة البحث وزر مسح سريع.
```lua
local search = win:create("searchbox", {
    x = 20, y = 20, width = 280, height = 38,
    placeholder = "ابحث عن لاعب أو مركبة...",
})
```

#### 12. `PasswordInput` (`"passwordinput"` أو `"password"`)
حقل كلمة مرور يخفي الحروف بـ `•` مع زر عين تفاعلي (`eye` / `eye-off`) لإظهار أو إخفاء كلمة المرور.
```lua
local pass = win:create("passwordinput", {
    x = 20, y = 70, width = 280, height = 38,
    placeholder = "أدخل كلمة المرور...",
})
```

#### 13. `NumberInput` (`"numberinput"` أو `"number"`)
حقل إدخال رقمي فقط مزود بأزرار `-` و `+` وحد أدنى وأقصى (`min`, `max`, `step`).
```lua
local num = win:create("numberinput", {
    x = 20, y = 120, width = 180, height = 38,
    value = 50, min = 0, max = 500, step = 10,
})
num:increment()
num:decrement()
```

#### 14. `TextArea` (`"textarea"` أو `"memo"`)
حقل نصي متعدد الأسطر للتعليقات والرسائل الطويلة.
```lua
local bio = win:create("textarea", {
    x = 20, y = 170, width = 320, height = 96,
    placeholder = "اكتب وصف التذكرة أو البلاغ هنا...",
})
```

#### 15. `Slider` (`"slider"`)
شريط تمرير رقمي يدعم السحب بالماوس والعنوان واللاحقة (`%`, `km/h`, إلخ).
```lua
local vol = win:create("slider", {
    x = 20, y = 20, width = 280, height = 42,
    label = "مستوى الصوت",
    value = 75, min = 0, max = 100, step = 1, suffix = "%",
})
```

#### 16. `RangeSlider` (`"rangeslider"`)
شريط تمرير بمقبضين لتحديد نطاق (`[minVal, maxVal]`).
```lua
local priceRange = win:create("rangeslider", {
    x = 20, y = 75, width = 280, height = 42,
    label = "نطاق السعر المطلوب",
    value = { 20, 80 }, min = 0, max = 100, step = 5,
})
priceRange:on("change", function(rangeTbl)
    local low, high = rangeTbl[1], rangeTbl[2]
end)
```

#### 17. `Checkbox` (`"checkbox"`)
مربع اختيار صح/خطأ.
```lua
local cb = win:create("checkbox", {
    x = 20, y = 130, width = 220, height = 26,
    label = "تذكر بيانات الدخول",
    checked = true,
})
local state = cb:isChecked()
```

#### 18. `Switch` (`"switch"`)
مفتاح تبديل انسيابي متحرك (`Animated Pill Toggle`).
```lua
local sw = win:create("switch", {
    x = 20, y = 165, width = 220, height = 28,
    label = "تفعيل الوضع الليلي",
    checked = true,
})
```

#### 19. `Radio` (`"radio"`)
زر اختيار حصري ضمن مجموعة (`group`): عند اختيار زر واحد في نفس الـ `group` يتم إلغاء تحديد البقية تلقائيًا.
```lua
win:create("radio", { x = 20,  y = 205, width = 110, group = "spawn", label = "لوس سانتوس", checked = true })
win:create("radio", { x = 140, y = 205, width = 110, group = "spawn", label = "سان فييرو" })
win:create("radio", { x = 260, y = 205, width = 110, group = "spawn", label = "لاس فينتوراس" })
```

#### 20. `Dropdown` (`"dropdown"`)
قائمة منسدلة ترسم قائمتها المفتوحة في طبقة الـ Overlay العليا فلا تنقصّ أبدًا بحدود النافذة، وتدعم التمرير بعجلة الماوس.
```lua
local dd = win:create("dropdown", {
    x = 20, y = 245, width = 240, height = 38,
    placeholder = "اختر الوظيفة...",
    options = {
        { label = "شرطي",   value = "police" },
        { label = "مسعف",   value = "medic" },
        { label = "ميكانيكي", value = "mechanic" },
    },
})
```

#### 21. `ComboBox` (`"combobox"`)
قائمة منسدلة تدعم البحث السريع بكتابة الحروف بالكيبورد لتصفية الخيارات.

#### 22. `ColorPicker` (`"colorpicker"`)
منتقي ألوان تفاعلي بطيف HSV + مربعات ألوان سريعة (`Swatches`) + عرض كود الـ `#HEX`.
```lua
local cp = win:create("colorpicker", {
    x = 20, y = 20, width = 260, height = 116,
    value = { 56, 189, 248, 255 },
})
cp:on("change", function(rgba)
    local hex = cp:getHex() -- مثل "#38BDF8"
end)
```

#### 23. `Keybind` (`"keybind"`)
مكوّن التقاط زر اختصار من الكيبورد (عند النقر عليه يعرض `"Press Key..."` وينتظر ضغطة الكيبورد التالية).
```lua
local kb = win:create("keybind", {
    x = 20, y = 150, width = 260, height = 36,
    label = "زر فتح الحقيبة",
    value = "I",
})
```

---

### 9.3 مكونات التنقل Navigation (6 مكونات)

#### 24. `TabBar` (`"tabbar"`)
شريط تبويبات مستقل بنمطين (`"pills"` أو `"underline"`).
```lua
local bar = win:create("tabbar", {
    x = 20, y = 20, width = 400, height = 40,
    variant = "pills",
    tabs = { "العامة", "الصوتيات", "الرسوميات" },
})
```

#### 25. `Tabs` (`"tabs"`)
حاوية تبويبات كاملة تنشئ لوحة محتوى خاصة بكل تبويب وتبدل بينها تلقائيًا عند النقر!
```lua
local tabs = win:create("tabs", {
    x = 20, y = 20, width = 600, height = 340,
    variant = "pills",
})
local generalTab = tabs:addTab("الإعدادات العامة", "general")
local audioTab   = tabs:addTab("إعدادات الصوت", "audio")

-- تضيف عناصر داخل كل تبويب مباشرة:
generalTab:create("switch", { x = 16, y = 16, width = 200, label = "إظهار الخريطة", checked = true })
audioTab:create("slider",   { x = 16, y = 16, width = 260, label = "صوت المحرك", value = 90 })
```

#### 26. `Sidebar` (`"sidebar"`)
شريط تنقل جانبي للوحات التحكم مع شعار وعنوان وقائمة عناصر بأيقونات وشارات (`Badges`).

#### 27. `Navbar` (`"navbar"`)
شريط علوي للتطبيقات يعرض العنوان الرئيسي والوصف الفرعي.

#### 28. `Breadcrumb` (`"breadcrumb"`)
مسار تنقل تسلسلي (`الرئيسية / الإعدادات / الأمان`).

#### 29. `Pagination` (`"pagination"`)
شريط ترقيم صفحات تفاعلي (`< 1 2 3 4 5 >`).

---

### 9.4 مكونات البيانات والـ Virtualization (6 مكونات)

#### 30. `ScrollPanel` (`"scrollpanel"`)
لوحة قابلة للتمرير بعجلة الماوس مع شريط تمرير جانبي وقص تلقائي (`Clipping`) وإخفاء ذكي للأبناء خارج منطقة الرؤية.
```lua
local sp = win:create("scrollpanel", { x = 20, y = 20, width = 360, height = 240, border = true })
for i = 1, 30 do
    sp:create("button", { x = 12, y = (i - 1) * 44 + 12, width = 320, height = 36, text = "عنصر رقم " .. i })
end
```

#### 31 & 32. `VirtualList` (`"virtuallist"`) و `List` (`"list"`)
قائمة فائقة السرعة تستخدم تقنية **Virtualization**: حتى لو مررت لها **10,000 عنصر**، فإنها تحسب فقط الصفوف الظاهرة حاليًا على الشاشة (حوالي 8 إلى 12 صفًا) وترسمها فقط!
```lua
local vlist = win:create("virtuallist", {
    x = 20, y = 20, width = 360, height = 260,
    rowHeight = 36,
    items = {
        { title = "سلاح M4", subtitle = "ذخيرة 5.56mm", badge = "$3,500" },
        { title = "درع تكتيكي", subtitle = "حماية 100%", badge = "$1,200" },
    },
})
```

#### 33. `Grid` (`"grid"`)
شبكة بطاقات متعددة الأعمدة (`columns = 3`) تدعم الـ Virtualization والاختيار.

#### 34. `Table` (`"table"`)
جدول بيانات احترافي يدعم:
- فرز الأعمدة تصاعديًا وتنازليًا بالنقر على عنوان العمود (`sortable = true`).
- البحث الفوري في جميع الأعمدة عبر `table:setFilter(query)`.
- خلايا من نوع `"badge"` أو `"status"` تتلون تلقائيًا بالأخضر (`Online`, `Active`, `Paid`) أو الأصفر (`Away`, `Pending`) أو الأحمر (`Offline`, `Banned`).
- Virtualization للصفوف للحفاظ على 60 FPS مهما كبر حجم البيانات.

#### 35. `Tree` (`"tree"`)
شجرة هرمية قابلة للطي والتوسيع (`Expand / Collapse`) للمجلدات والتصنيفات المتداخلة.

---

### 9.5 مكونات التنبيهات والتفاعل Feedback (10 مكونات)

#### 36 & 37. `Notification` / `Toast` و `NovaUI.notify(...)`
نظام إشعارات منبثقة متراصة بأنيمايشن دخول وخروج وشريط تقدم زمني:
```lua
NovaUI.notify({
    type = "success", -- "info" | "success" | "warning" | "error" | "custom"
    title = "تمت العملية",
    message = "تم تحويل 50,000$ إلى حساب الصديق بنجاح.",
    duration = 4000,
})
```

#### 38. `Tooltip` (`"tooltip"`)
تلميح عائم يظهر تلقائيًا عند تمرير الماوس فوق أي عنصر استُدعي عليه `element:setTooltip("النص")`.

#### 39, 40 & 41. `Modal`, `Dialog`, `ConfirmDialog` و `NovaUI.confirm(...)`
نوافذ حوارية فوق خلفية معتمة تمنع التفاعل مع ما خلفها وتغلق بزر `Escape`:
```lua
NovaUI.confirm({
    title = "تأكيد بيع العقار",
    message = "هل أنت متأكد من بيع هذا العقار مقابل 250,000$؟ لا يمكن التراجع عن هذه العملية.",
    confirmText = "نعم، بيع الآن",
    cancelText = "إلغاء",
    confirmVariant = "danger",
    onConfirm = function()
        NovaUI.notify({ type = "success", title = "تم البيع", message = "تم بيع العقار بنجاح." })
    end,
})
```

#### 42. `ProgressBar` (`"progressbar"`)
شريط تقدم بنسبة مئوية أو وضع لا نهائي متحرك (`indeterminate = true`):
```lua
local pb = win:create("progressbar", {
    x = 20, y = 20, width = 300, height = 32,
    label = "جاري تحميل المودات...",
    value = 45,
    variant = "primary",
})
pb:setProgress(90, true) -- يتحرك بنعومة من 45% إلى 90%!
```

#### 43. `Spinner` (`"spinner"`)
حلقة تحميل دوّارة ناعمة.

#### 44. `Loading` (`"loading"`)
بطاقة انتظار جاهزة تحتوي على `Spinner` مع نص حالة التحميل.

#### 45. `Alert` (`"alert"`)
شريط تنبيه داخل الواجهة (`info`, `success`, `warning`, `danger`) مع إمكانية إغلاقه (`closable = true`).

---

### 9.6 المكونات المتقدمة والرسوم البيانية Advanced (10 مكونات)

#### 46. `ContextMenu` (`"contextmenu"`)
قائمة كليك يمين عائمة تدعم الأيقونات، اختصارات الكيبورد، الفواصل (`divider = true`)، والخيارات الحمراء الخطرة (`danger = true`).
```lua
win:create("contextmenu", {
    target = myTable, -- يربط القائمة بزر الماوس الأيمن على الجدول تلقائيًا!
    items = {
        { label = "نسخ الاسم", icon = "copy", shortcut = "Ctrl+C", onClick = function() end },
        { divider = true },
        { label = "طرد اللاعب", icon = "error", danger = true, onClick = function() end },
    },
})
```

#### 47. `Accordion` (`"accordion"`)
أقسام قابلة للطي والفتح لعرض الأسئلة الشائعة أو الإعدادات المتقدمة.

#### 48. `Card` (`"card"`)
بطاقة محتوى أنيقة بعنوان ووصف فرعي وأيقونة وظل.

#### 49. `StatsCard` (`"statscard"`)
بطاقة إحصائيات KPI للوحات التحكم تعرض العنوان، الرقم الرئيسي، نسبة التغير (`+18.4%`)، الأيقونة، ورسمًا بيانيًا مصغرًا (`sparkline`).

#### 50, 51 & 52. `Badge` (`"badge"`), `Avatar` (`"avatar"`), `Status` (`"status"`)
- `Badge`: شارة كبسولية ملونة.
- `Avatar`: صورة شخصية دائرية مع نقطة حالة الاتصال (`online`, `away`, `busy`, `offline`).
- `Status`: مؤشر حالة نابض مع نص.

#### 53. `Stepper` (`"stepper"`)
مؤشر خطوات متسلسلة (`1. البيانات -> 2. التحقق -> 3. الاكتمال`) مع علامات صح للخطوات المكتملة.

#### 54. `Timeline` (`"timeline"`)
سجل أحداث زمني عمودي بنقاط ملونة ووقت ووصف لكل حدث.

#### 55. `Chart` (`"chart"`)
مكوّن رسوم بيانية متكامل يدعم **4 أنواع** داخل MTA:SA:
1. `"line"`: رسم بياني خطي مع نقاط وشبكة خلفية.
2. `"area"`: رسم بياني مساحي مظلل تحت المنحنى.
3. `"bar"`: أعمدة بيانية رأسية.
4. `"donut"`: حلقة دائرية مقسمة مع مجموع مركزي ومفتاح ألوان جانبي (`Legend`).

```lua
local chart = win:create("chart", {
    x = 20, y = 20, width = 440, height = 210,
    chartType = "area", -- "line" | "area" | "bar" | "donut"
    title = "عدد اللاعبين المتصلين خلال الأسبوع",
    labels = { "السبت", "الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة" },
    data = { 120, 135, 110, 145, 160, 210, 195 },
    variant = "primary",
})
```

---

## 10. نظام الأيقونات (48 أيقونة) وإدارة الصور والخطوط

### قائمة الـ 48 أيقونة المدمجة جاهزة للاستخدام بالاسم
يمكنك تمرير أي اسم من الأسماء التالية في خاصية `icon` لأي زر أو نافذة أو حقل إدخال أو قائمة:
```text
"search"       "close"        "check"        "plus"         "minus"
"chevron-down" "chevron-up"   "chevron-left" "chevron-right" "home"
"dashboard"    "settings"     "user"         "users"        "bell"
"info"         "warning"      "error"        "success"      "lock"
"unlock"       "eye"          "eye-off"      "edit"         "trash"
"copy"         "refresh"      "filter"       "sort"         "star"
"heart"        "shield"       "terminal"     "chart"        "folder"
"file"         "key"          "sliders"      "power"        "play"
"pause"        "clock"        "globe"        "sparkle"      "menu"
"more"         "minimize"     "maximize"
```

### إدارة الصور والخطوط
- لتحميل مجموعة صور مسبقًا عند بدء المورد لمنع أي تأخير:
  ```lua
  NovaUI.Assets.preload({
      "assets/images/logo.png",
      "assets/images/avatar_default.png",
  })
  ```
- إذا مررت مسار صورة غير موجود، لن تنهار الواجهة أبدًا؛ سيقوم `NovaUI.Assets` بطباعة تحذير واحد فقط في الـ Debug واستخدام صورة `assets/images/fallback.png` تلقائيًا.

---

## 11. كيف يعمل الربط مع DGS وطبقة التوافق والـ Exports؟

1. **`NovaUI.DGSAdapter` (`client/adapters/dgs/adapter.lua`)**:
   - يفحص تلقائيًا ما إذا كان مود `dgs` يعمل على السيرفر.
   - إذا كان `dgs` يعمل، يستفيد من قدرات الشيدر (`dgsCreateRoundRect`, `dgsCreateBlurBox`) وحقول الإدخال الأصلية (`dgsCreateEdit`) مع إبقاء المظهر البصري خاضعًا بالكامل لـ `NovaUI`.
   - إذا لم يكن `dgs` مشغّلاً على السيرفر، تعمل `NovaUI` بكفاءة 100% عبر محرك DirectX + SVG المدمج دون أن يتغير سطر واحد في كودك!
2. **طبقة التوافق `NovaUI.compat` (`client/adapters/dgs/compat.lua`)**:
   - تتيح تحويل كود DGS القديم بسهولة:
     ```lua
     local win = NovaUI.compat.createWindow(0.2, 0.2, 0.5, 0.5, "نافذة متوافقة", true)
     local btn = NovaUI.compat.createButton(20, 20, 140, 38, "زر", false, win)
     ```
3. **الاستخدام من موارد أخرى عبر `exports.NovaUI`**:
   ```lua
   local winId = exports.NovaUI:novaCreate("window", { title = "نافذة خارجية", width = 500, height = 340 })
   exports.NovaUI:novaNotify({ type = "success", title = "جاهز", message = "تم الفتح من مورد خارجي!" })
   ```

---

## 12. تطبيقات عملية كاملة جاهزة للنسخ والتشغيل

### تطبيق عملي: لوحة بنك / صراف آلي (ATM & Banking UI)
```lua
local bankWin = nil

function openBankUI(playerBalance)
    if bankWin and not bankWin._destroyed then
        bankWin:show()
        bankWin:bringToFront()
        showCursor(true)
        return
    end

    bankWin = NovaUI.create("window", {
        title = "البنك المركزي - لوس سانتوس",
        subtitle = "إدارة الرصيد والتحويلات المالية الفورية",
        icon = "shield",
        width = 680,
        height = 440,
    })

    -- بطاقة عرض الرصيد الحالي
    local balanceCard = bankWin:create("statscard", {
        x = 20, y = 20, width = 300, height = 110,
        title = "الرصيد المتاح",
        value = "$" .. NovaUI.Utils.formatNumber(playerBalance or 125000),
        trend = "حساب موثق نشط",
        trendUp = true,
        icon = "globe",
        variant = "success",
    })

    -- بطاقة إجراء تحويل مالي
    local transferCard = bankWin:create("card", {
        x = 340, y = 20, width = 320, height = 350,
        title = "تحويل أموال للاعب آخر",
        subtitle = "أدخل معرف اللاعب والمبلغ المطلوب",
        icon = "users",
    })

    transferCard:create("label", { x = 16, y = 14, width = 200, height = 18, text = "اسم أو رقم اللاعب المستلم", variant = "caption" })
    local targetInput = transferCard:create("edit", {
        x = 16, y = 36, width = 288, height = 38,
        placeholder = "مثال: Ghost_Operator",
        icon = "user",
        clearable = true,
    })

    transferCard:create("label", { x = 16, y = 88, width = 200, height = 18, text = "المبلغ المراد تحويله ($)", variant = "caption" })
    local amountInput = transferCard:create("numberinput", {
        x = 16, y = 110, width = 288, height = 38,
        value = 1000, min = 100, max = 1000000, step = 500,
    })

    local sendBtn = transferCard:create("button", {
        x = 16, y = 230, width = 288, height = 42,
        text = "تأكيد وإرسال الحوالة",
        icon = "check",
        variant = "primary",
    })

    sendBtn:on("click", function()
        local recipient = targetInput:getValue()
        local amount = amountInput:getValue()

        if recipient == "" then
            NovaUI.notify({ type = "error", title = "بيانات ناقصة", message = "يرجى كتابة اسم اللاعب المستلم أولاً." })
            return
        end

        NovaUI.confirm({
            title = "تأكيد التحويل المالي",
            message = string.format("هل أنت متأكد من تحويل مبلغ $%s إلى اللاعب %s؟", NovaUI.Utils.formatNumber(amount), recipient),
            confirmText = "نعم، حوّل المبلغ",
            cancelText = "تراجع",
            onConfirm = function()
                NovaUI.notify({
                    type = "success",
                    title = "تم التحويل بنجاح",
                    message = string.format("أرسلت $%s إلى %s.", NovaUI.Utils.formatNumber(amount), recipient),
                })
            end,
        })
    end)

    showCursor(true)
end
```
