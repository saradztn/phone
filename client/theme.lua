Theme = {}

Theme.dark = {
    frame = {20, 20, 24, 255},
    screen = {10, 11, 16, 255},

    card = {30, 32, 40, 240},
    cardSoft = {45, 47, 57, 240},

    primary = {84, 130, 255, 255},
    primaryDeep = {50, 90, 210, 255},

    text = {245, 247, 255, 255},
    sub = {170, 175, 190, 255},
    faint = {105, 110, 125, 255},

    danger = {255, 80, 95, 255},
    success = {70, 210, 140, 255},
    info = {80, 170, 255, 255},

    input = {24, 26, 34, 255},
    border = {70, 73, 88, 255},

    dock = {30, 32, 40, 220},
    toast = {35, 37, 45, 245},

    dim = {0, 0, 0, 150}
}

Theme.light = {
    frame = {25, 25, 28, 255},
    screen = {238, 240, 248, 255},

    card = {255, 255, 255, 240},
    cardSoft = {240, 242, 248, 240},

    primary = {55, 110, 240, 255},
    primaryDeep = {35, 85, 200, 255},

    text = {25, 27, 35, 255},
    sub = {95, 100, 115, 255},
    faint = {145, 150, 165, 255},

    danger = {230, 65, 80, 255},
    success = {40, 170, 100, 255},
    info = {40, 130, 230, 255},

    input = {235, 237, 243, 255},
    border = {205, 208, 218, 255},

    dock = {245, 247, 252, 225},
    toast = {255, 255, 255, 245},

    dim = {0, 0, 0, 120}
}

Theme.current = Theme.dark
T = Theme.current

function Theme.apply(name)
    Theme.current = Theme[name] or Theme.dark
    T = Theme.current
end
