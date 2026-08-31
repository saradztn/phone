Animations = {
    phone = {
        value = 0,
        target = 0,
        start = 0,
        started = 0,
        duration = 260
    }
}

function animatePhone(target)
    local animation = Animations.phone

    animation.start = animation.value
    animation.target = target
    animation.started = safeTickCount()
    animation.duration = Config.animationTime
end

function updateAnimations()
    local animation = Animations.phone

    local progress = clamp(
        (safeTickCount() - animation.started) / animation.duration,
        0,
        1
    )

    progress = 1 - (1 - progress) * (1 - progress)

    animation.value =
        animation.start
        + (animation.target - animation.start) * progress
end
