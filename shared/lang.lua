-- ============================================================================
-- AURA Phone v2 - language strings (shared)
-- L("key") returns the string for PhoneConfig.language ("en" | "ar")
-- NOTE: MTA's dxDrawText does not shape Arabic (RTL/ligatures). English is
-- the recommended UI language; Arabic is available but may render unconnected.
-- ============================================================================
local STR = {
    -- generic
    close =        { en = "Close",      ar = "إغلاق" },
    cancel =       { en = "Cancel",     ar = "إلغاء" },
    save =         { en = "Save",       ar = "حفظ" },
    send =         { en = "Send",       ar = "إرسال" },
    delete =       { en = "Delete",     ar = "حذف" },
    edit =         { en = "Edit",       ar = "تعديل" },
    open =         { en = "Open",       ar = "فتح" },
    get =          { en = "Get",        ar = "تثبيت" },
    remove =       { en = "Remove",     ar = "إزالة" },
    soon =         { en = "Soon",       ar = "قريباً" },
    back =         { en = "Back",       ar = "رجوع" },
    ok =           { en = "OK",         ar = "حسناً" },
    error =        { en = "Error",      ar = "خطأ" },
    search =       { en = "Search…",    ar = "بحث…" },
    none =         { en = "Nothing here yet", ar = "لا شيء بعد" },
    noMatches =    { en = "No matches", ar = "لا نتائج" },
    gps =          { en = "GPS",        ar = "موقعي" },
    call =         { en = "Call",       ar = "اتصال" },
    message =      { en = "Message",    ar = "رسالة" },
    favorite =     { en = "Favorite",   ar = "مفضلة" },
    unfavorite =   { en = "Unfavorite", ar = "إلغاء المفضلة" },
    -- lock
    unlock =       { en = "Tap to unlock", ar = "اضغط للفتح" },
    pinPad =       { en = "Enter PIN",  ar = "أدخل الرقم السري" },
    pinWrong =     { en = "Wrong PIN",  ar = "رقم خاطئ" },
    -- status / misc
    carrier =      { en = "AURA",       ar = "أورا" },
    -- calls
    recents =      { en = "Recents",    ar = "السجل" },
    keypad =       { en = "Keypad",     ar = "لوحة الأرقام" },
    missed =       { en = "Missed",     ar = "فاتك" },
    declined =     { en = "Declined",   ar = "مرفوض" },
    busy =         { en = "Busy",       ar = "مشغول" },
    calling =      { en = "Calling…",   ar = "جارٍ الاتصال…" },
    ringing =      { en = "Ringing…",   ar = "يرن…" },
    active =       { en = "On call",    ar = "مكالمة جارية" },
    ended =        { en = "Ended",      ar = "انتهت" },
    accept =       { en = "Accept",     ar = "قبول" },
    decline =      { en = "Decline",    ar = "رفض" },
    invalidNumber = { en = "Invalid number", ar = "رقم غير صالح" },
    -- messages
    messages =     { en = "Messages",   ar = "الرسائل" },
    noChats =      { en = "No conversations yet", ar = "لا محادثات بعد" },
    typeMsg =      { en = "Message",    ar = "اكتب رسالة" },
    -- contacts
    contacts =     { en = "Contacts",   ar = "جهات الاتصال" },
    noContacts =   { en = "No contacts yet", ar = "لا جهات اتصال" },
    newContact =   { en = "New contact", ar = "جهة جديدة" },
    editContact =  { en = "Edit contact", ar = "تعديل جهة" },
    name =         { en = "Name",       ar = "الاسم" },
    phoneNumber =  { en = "Phone number", ar = "الرقم" },
    -- bank
    bank =         { en = "Bank",       ar = "البنك" },
    balance =      { en = "Available balance", ar = "الرصيد المتاح" },
    transfer =     { en = "Transfer",   ar = "تحويل" },
    activity =     { en = "Recent activity", ar = "آخر العمليات" },
    noTx =         { en = "No transactions yet", ar = "لا عمليات بعد" },
    recipient =    { en = "Recipient number", ar = "رقم المستلم" },
    amount =       { en = "Amount",     ar = "المبلغ" },
    -- maps
    maps =         { en = "Maps",       ar = "الخرائط" },
    noWp =         { en = "No active waypoint", ar = "لا وجهة نشطة" },
    noLoc =        { en = "No locations found", ar = "لا أماكن" },
    setWp =        { en = "Set GPS",    ar = "تحديد الموقع" },
    clearWp =      { en = "Clear",      ar = "مسح" },
    -- notes
    notes =        { en = "Notes",      ar = "ملاحظات" },
    newNote =      { en = "New note",   ar = "ملاحظة جديدة" },
    editNote =     { en = "Edit note",  ar = "تعديل الملاحظة" },
    noteTitle =    { en = "Title",      ar = "العنوان" },
    writeNote =    { en = "Write something…", ar = "اكتب شيئاً…" },
    noNotes =      { en = "No notes yet", ar = "لا ملاحظات" },
    emptyNote =    { en = "Empty note", ar = "ملاحظة فارغة" },
    -- vehicles
    garage =       { en = "Garage",     ar = "الكراج" },
    noVehicles =   { en = "No vehicles yet", ar = "لا مركبات" },
    locked =       { en = "Locked",     ar = "مقفلة" },
    unlocked =     { en = "Ready",      ar = "جاهزة" },
    engineOn =     { en = "Engine on",  ar = "المحرك يعمل" },
    inVehicle =    { en = "You are in a vehicle", ar = "أنت في مركبة" },
    notInVehicle = { en = "No active vehicle", ar = "لا مركبة نشطة" },
    addVehicle =   { en = "Add",        ar = "إضافة" },
    lock =         { en = "Lock",       ar = "قفل" },
    unlock2 =      { en = "Unlock",     ar = "فتح" },
    engine =       { en = "Engine",     ar = "المحرك" },
    -- properties
    homes =        { en = "Homes",      ar = "المنازل" },
    noProps =      { en = "No properties yet", ar = "لا عقارات بعد" },
    location =     { en = "Location",   ar = "الموقع" },
    -- jobs
    jobs =         { en = "Jobs",       ar = "الوظائف" },
    currentJob =   { en = "Current job", ar = "وظيفتك الحالية" },
    openings =     { en = "Available positions", ar = "الوظائف المتاحة" },
    salary =       { en = "Salary",     ar = "الراتب" },
    noOpenings =   { en = "No openings right now", ar = "لا وظائف حالياً" },
    -- emergency
    emergency =    { en = "Emergency",  ar = "طوارئ" },
    call911 =      { en = "Call 911",   ar = "اتصال 911" },
    police =       { en = "Police",     ar = "الشرطة" },
    hospital =     { en = "Hospital",   ar = "المستشفى" },
    sendUnit =     { en = "Send unit",  ar = "إرسال دورية" },
    emergencyInfo = { en = "In an emergency: stay calm, give your location, do not hang up.",
                     ar = "في الطوارئ: اهدأ، أعطِ موقعك، ولا تقطع المكالمة." },
    -- store
    store =        { en = "App Store",  ar = "متجر التطبيقات" },
    storeSub =     { en = "All apps are free", ar = "كل التطبيقات مجانية" },
    noStore =      { en = "Loading…",   ar = "جارٍ التحميل…" },
    -- settings
    settings =     { en = "Settings",   ar = "الإعدادات" },
    appearance =   { en = "Appearance", ar = "المظهر" },
    darkMode =     { en = "Dark mode",  ar = "الوضع الداكن" },
    wallpaper =    { en = "Wallpaper",  ar = "خلفية" },
    classic =      { en = "Classic",    ar = "كلاسيكي" },
    uiScale =      { en = "UI scale",   ar = "حجم الواجهة" },
    sound =        { en = "Sound",      ar = "الصوت" },
    ringtone =     { en = "Ringtone",   ar = "نغمة الرنين" },
    notif =        { en = "Notifications", ar = "الإشعارات" },
    sfx =          { en = "Sounds",     ar = "الأصوات" },
    phone =        { en = "Phone",      ar = "الهاتف" },
    phoneName =    { en = "Phone name", ar = "اسم الهاتف" },
    pinLock =      { en = "PIN lock",   ar = "قفل PIN" },
    off =          { en = "Off",        ar = "إيقاف" },
    newPin =       { en = "New PIN (4 digits)", ar = "PIN جديد (4 أرقام)" },
    invalidPin =   { en = "Use exactly 4 digits", ar = "أدخل 4 أرقام بالضبط" },
    language =     { en = "Language",   ar = "اللغة" },
    about =        { en = "About",      ar = "حول" },
    -- weather/server
    server =       { en = "Server",     ar = "السيرفر" },
    players =      { en = "Players online", ar = "اللاعبون المتصلون" },
    mtaVersion =   { en = "MTA version", ar = "إصدار MTA" },
    ping =         { en = "Your ping",  ar = "البينغ" },
    yourPhone =    { en = "Phone",      ar = "الهاتف" },
    -- notifications
    notifications = { en = "Notifications", ar = "الإشعارات" },
    noNotif =      { en = "No notifications", ar = "لا إشعارات" },
    -- vehicles/state
    vehicleState = { en = "Vehicle state", ar = "حالة المركبة" },
}

function L(key)
    local t = STR[key]
    if not t then return key end
    return t[PhoneConfig.language] or t.en
end

--- does this string contain Arabic chars? (for font selection)
function isArabic(s)
    return s:find("[%u0600-%u06FF%uFB50-%uFDFF%uFE70-%uFEFF]") ~= nil
end
