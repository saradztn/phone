Sounds = {
    click = "assets/sounds/click.wav",
    back = "assets/sounds/back.wav",
    notification = "assets/sounds/notification.wav",
    message = "assets/sounds/message.wav",
    ringtone = "assets/sounds/ringtone.wav",
    accept = "assets/sounds/accept.wav",
    decline = "assets/sounds/decline.wav",
    unlock = "assets/sounds/unlock.wav",
    lock = "assets/sounds/lock.wav"
}

function playPhoneSound(name)
    if not Phone.settings.sounds then
        return
    end

    if Sounds[name] then
        playSound(Sounds[name])
    end
end
