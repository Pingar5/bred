package colors

import rl "vendor:raylib"

Color :: rl.Color

BACKGROUND := hex(0x2b2b2b)
TEXT :: rl.WHITE
ESCAPED_CHARACTER :: rl.GRAY

GUTTER_BACKGROUND :: rl.Color{34, 34, 36, 255}

STATUS_BAR_BACKGROUND :: rl.Color{34, 34, 36, 255}
MODIFIER_ACTIVE :: rl.Color{69, 102, 209, 255}
MODIFIER_LOCKED :: rl.Color{230, 144, 39, 255}

@(private)
ThemeEntry :: struct {
    name:  string,
    color: Color,
}

THEME: #soa[dynamic]ThemeEntry

init :: proc() {
    register_color("", {255, 255, 255, 255})
}

quit :: proc() {
    delete(THEME)
}

register_default_color :: proc(color: Color) {
    THEME[0].color = color
}

register_color :: proc(name: string, color: Color) {
    append_soa(&THEME, ThemeEntry{name, color})
}

hex :: proc(hex: uint) -> (c: Color) {
    hex := hex
    
    if hex >= 0x1_00_00_00 {
        c.a = u8(hex & 0xFF)
        hex >>= 8
    } else {
        c.a = 255
    }
    
    c.b = u8(hex & 0xFF)
    hex >>= 8
    c.g = u8(hex & 0xFF)
    hex >>= 8
    c.r = u8(hex & 0xFF)

    return
}
