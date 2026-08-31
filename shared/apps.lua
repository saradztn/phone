-- ============================================================================
-- AURA Phone - app catalog (shared)
-- The single source of truth for apps: the home screen, the App Store and
-- the server all read this table. To ship a new app: add a row here, create
-- client/apps/<id>.lua that calls registerPhoneApp, add icon + <script> tag.
-- ============================================================================
PhoneApps = {
    { id = "calls",         name = "Phone",       icon = "assets/icons/calls.png",         order = 1,  desc = "Make and receive calls." },
    { id = "contacts",      name = "Contacts",    icon = "assets/icons/contacts.png",      order = 2,  desc = "Manage your contact list." },
    { id = "messages",      name = "Messages",    icon = "assets/icons/messages.png",      order = 3,  desc = "Text players in the city." },
    { id = "camera",        name = "Camera",      icon = "assets/icons/camera.png",        order = 4,  desc = "Take screenshots of the city." },
    { id = "gallery",       name = "Photos",      icon = "assets/icons/gallery.png",       order = 5,  desc = "Your photo album." },
    { id = "maps",          name = "Maps",        icon = "assets/icons/maps.png",          order = 6,  desc = "Waypoints and city locations." },
    { id = "bank",          name = "Bank",        icon = "assets/icons/bank.png",          order = 7,  desc = "Balance, transfers and history." },
    { id = "store",         name = "App Store",   icon = "assets/icons/store.png",         order = 8,  desc = "Install and manage apps." },
    { id = "settings",      name = "Settings",    icon = "assets/icons/settings.png",      order = 9,  desc = "Appearance, sound and security." },
    { id = "notifications", name = "Alerts",      icon = "assets/icons/notifications.png", order = 10, desc = "All recent notifications." },
    { id = "notes",         name = "Notes",       icon = "assets/icons/notes.png",         order = 11, desc = "Quick notes, saved on the server." },
    { id = "vehicles",      name = "Garage",      icon = "assets/icons/vehicles.png",      order = 12, desc = "Your vehicles: lock, engine, GPS." },
    { id = "properties",    name = "Homes",       icon = "assets/icons/properties.png",    order = 13, desc = "Your real estate." },
    { id = "jobs",          name = "Jobs",        icon = "assets/icons/jobs.png",          order = 14, desc = "Work in the city." },
    { id = "emergency",     name = "Emergency",   icon = "assets/icons/emergency.png",     order = 15, desc = "911 and quick responders." },
    { id = "weather",       name = "Server",      icon = "assets/icons/weather.png",       order = 16, desc = "Server info and weather." },
}

PhoneAppMap = {}
for _, app in ipairs(PhoneApps) do
    PhoneAppMap[app.id] = app
end
