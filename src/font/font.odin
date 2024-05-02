package font

import "bred:math"

import rl "vendor:raylib"

FONT_SIZE :: 24

Font :: struct {
    font:           rl.Font,
    character_size: [2]i32,
    size:           f32,
}

init :: proc() {
    generate_codepoint_list()
}

quit :: proc() {
    delete(CODEPOINTS)
}

load :: proc(file_name: cstring, allocator := context.allocator) -> (font: ^Font) {
    font = new(Font, allocator)

    font.font = rl.LoadFontEx(file_name, FONT_SIZE, raw_data(CODEPOINTS), i32(len(CODEPOINTS)))
    font.size = FONT_SIZE

    character_size := rl.MeasureTextEx(font.font, " ", font.size, 0)
    font.character_size = {i32(character_size.x), i32(character_size.y)}

    return
}

unload :: proc(font: ^Font) {
    rl.UnloadFont(font.font)
    free(font)
}

calculate_window_dims :: proc(font: ^Font) -> math.Position {
    screen_width, screen_height := rl.GetScreenWidth(), rl.GetScreenHeight()
    return {int(screen_width / font.character_size.x), int(screen_height / font.character_size.y)}
}
