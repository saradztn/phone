-- ============================================================================
-- AURA Phone - shared configuration
-- Every tunable of the resource lives here.
-- ============================================================================
PhoneConfig = {
    -- key that opens/closes the phone (any bindKey name, e.g. "F8", "PAGEUP")
    openKey = "F10",

    carrier = "AURA",          -- carrier name shown in the status bar
    appName = "AURA X1",       -- device model name shown in Settings/About

    -- phone numbers are numberPrefix + random digits (total numberLength)
    numberPrefix = "055",
    numberLength = 11,

    -- limits
    maxMessageLength = 500,
    maxMessagesPerMinute = 10,
    maxCallsPerMinute = 5,
    maxTransfersPerHour = 20,
    maxContactName = 32,
    maxContacts = 100,
    maxNoteLength = 600,
    maxNoteTitle = 40,
    maxNotes = 50,
    maxVehicles = 5,
    maxTransfer = 10000000,    -- max single bank transfer
    callTimeout = 30,          -- seconds before a call is marked missed

    battery = { start = 100, drainPerMin = 0.6, chargePerMin = 12 },

    animations = { open = 420, close = 340, app = 240, toast = 380, shade = 260 },

    sounds = {
        ring = "assets/sounds/ring.wav",
        notify = "assets/sounds/notify.wav",
        send = "assets/sounds/send.wav",
        click = "assets/sounds/click.wav",
        back = "assets/sounds/back.wav",
    },

    -- wallpaper files (rounded-corner PNGs matching the screen ratio)
    wallpapers = {
        "assets/wallpapers/aurora.png",
        "assets/wallpapers/nebula.png",
    },

    -- apps that exist on the device (order = home screen order)
    enabledApps = {
        "calls", "contacts", "messages", "camera", "gallery", "maps",
        "bank", "store", "settings", "notifications", "notes",
        "vehicles", "properties", "jobs", "emergency", "weather",
    },
    dockApps = { "calls", "messages", "maps", "camera" },

    -- coming-soon items shown in the App Store (not functional)
    storeComingSoon = {
        { id = "music",  name = "Music",  icon = "assets/icons/gallery.png",     desc = "Play your favorite tracks." },
        { id = "radio",  name = "Radio",  icon = "assets/icons/notifications.png", desc = "Tune into the city stations." },
        { id = "wallet", name = "Wallet", icon = "assets/icons/bank.png",       desc = "Digital cards and passes." },
    },

    database = {
        type = "mysql",
        host = "127.0.0.1",
        name = "mta_rp",
        user = "root",
        pass = "root",
        port = 3306,
        prefix = "phone_",
    },

    -- points of interest for the Maps app (San Andreas coordinates, tweak them)
    poi = {
        { id = "police",   name = "Police Department", x = -152.5, y = 385.5,  z = 10.8 },
        { id = "hospital", name = "Hospital",          x = 121.0,  y = -1060.5, z = 8.6 },
        { id = "bank",     name = "Bank",              x = -194.5, y = 70.5,   z = 22.9 },
        { id = "mechanic", name = "Mechanic",          x = -267.9, y = 365.5,  z = 12.1 },
        { id = "gas",      name = "Gas Station",       x = -172.5, y = 36.5,   z = 10.0 },
        { id = "jobs",     name = "Job Center",        x = -233.0, y = 100.0,  z = 12.0 },
        { id = "garage",   name = "Garage",            x = -167.9, y = 115.5,  z = 20.0 },
        { id = "mall",     name = "Mall",              x = -173.6, y = -236.5, z = 10.3 },
    },

    -- jobs available in the Jobs app
    jobs = {
        { id = "unemployed", name = "Unemployed",      salary = 0,    x = -233.0,  y = 100.0,   z = 12.0,  desc = "No current employment." },
        { id = "police",     name = "Police Officer",  salary = 8500, x = -152.5,  y = 385.5,   z = 10.8,  desc = "Keep the city safe." },
        { id = "medic",      name = "Medic",           salary = 6800, x = 121.0,   y = -1060.5, z = 8.6,   desc = "Save lives at the hospital." },
        { id = "mechanic",   name = "Mechanic",        salary = 5200, x = -267.9,  y = 365.5,   z = 12.1,  desc = "Fix and modify vehicles." },
        { id = "delivery",   name = "Delivery Driver", salary = 3900, x = -172.5,  y = 36.5,    z = 10.0,  desc = "Deliver packages around the city." },
        { id = "taxi",       name = "Taxi Driver",     salary = 4500, x = -167.9,  y = 115.5,   z = 20.0,  desc = "Pick up and drop off passengers." },
    },

    weather = "Sunny • 27°C",  -- decorative weather line for the Server app

    -- optional voice bridge (fills in if your server has a voice system)
    voice = { enabled = false, channel = "phone_call" },
}

PhoneConfig.language = "en"
PhoneConfig.fonts = {
    en     = "assets/fonts/NotoSans-Regular.ttf",
    enBold = "assets/fonts/NotoSans-Bold.ttf",
    ar     = "assets/fonts/NotoSansArabic-Regular.ttf",
    arBold = "assets/fonts/NotoSansArabic-Bold.ttf",
}
PhoneConfig.device = {
    img    = "assets/phone/device.png",
    aspect = 573 / 1198,
    screen = { x0 = 0.046, y0 = 0.040, x1 = 0.954, y1 = 0.960 },
}
