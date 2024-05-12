package font

import "bred:core"

import rl "vendor:raylib"

Font :: struct {
    font:           rl.Font,
    character_size: [2]i32,
    size:           f32,
}
ACTIVE_FONT: Font

init :: proc() {
    generate_codepoint_list()
}

quit :: proc() {
    delete(CODEPOINTS)
}

load :: proc(file_name: cstring, size: i32) {
    if ACTIVE_FONT != {} do unload()

    ACTIVE_FONT.font = rl.LoadFontEx(file_name, size, raw_data(CODEPOINTS), i32(len(CODEPOINTS)))
    ACTIVE_FONT.size = f32(size)
    rl.SetTextLineSpacing(size)

    character_size := rl.MeasureTextEx(ACTIVE_FONT.font, " ", ACTIVE_FONT.size, 0)
    ACTIVE_FONT.character_size = {i32(character_size.x), i32(character_size.y)}
}

unload :: proc() {
    rl.UnloadFont(ACTIVE_FONT.font)
}

calculate_window_dims :: proc() -> core.Position {
    assert(ACTIVE_FONT != {}, "Cannot calculate window dims before a font is loaded")

    screen_width, screen_height := rl.GetScreenWidth(), rl.GetScreenHeight()
    return ({
                int(screen_width / ACTIVE_FONT.character_size.x),
                int(screen_height / ACTIVE_FONT.character_size.y),
            })
}
