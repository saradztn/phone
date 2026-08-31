PHONE_W = 360
PHONE_H = 740

PHONE_NUMBER_MIN = 6
PHONE_NUMBER_MAX = 15

MESSAGE_MAX_LENGTH = 500
CONTACT_NAME_MAX_LENGTH = 32
NOTE_MAX_LENGTH = 2000

APP_GRID = {
    {id = "messages", name = "Messages", icon = "messages"},
    {id = "contacts", name = "Contacts", icon = "contacts"},
    {id = "calls", name = "Phone", icon = "phone"},
    {id = "camera", name = "Camera", icon = "camera"},
    {id = "gallery", name = "Gallery", icon = "gallery"},
    {id = "maps", name = "Maps", icon = "maps"},
    {id = "bank", name = "Bank", icon = "bank"},
    {id = "wallet", name = "Wallet", icon = "wallet"},
    {id = "vehicles", name = "Vehicles", icon = "vehicles"},
    {id = "properties", name = "Properties", icon = "properties"},
    {id = "jobs", name = "Jobs", icon = "jobs"},
    {id = "emergency", name = "Emergency", icon = "emergency"},
    {id = "notes", name = "Notes", icon = "notes"},
    {id = "calculator", name = "Calculator", icon = "calculator"},
    {id = "settings", name = "Settings", icon = "settings"},
    {id = "music", name = "Music", icon = "music"}
}

function validPhoneNumber(number)
    number = tostring(number or "")
    return number:match("^%d+$")
        and #number >= PHONE_NUMBER_MIN
        and #number <= PHONE_NUMBER_MAX
end
