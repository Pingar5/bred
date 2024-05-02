package font

import "bred:math"

import "core:strings"
import rl "vendor:raylib"

write :: proc(
    pos: math.Position,
    text: string,
    color: rl.Color,
) -> (
    ending_column: int,
) {
    c_text := strings.clone_to_cstring(text, context.temp_allocator)
    rl.DrawTextEx(
        ACTIVE_FONT.font,
        c_text,
        {f32(i32(pos.x) * ACTIVE_FONT.character_size.x), f32(i32(pos.y) * ACTIVE_FONT.character_size.y)},
        ACTIVE_FONT.size,
        0,
        color,
    )

    return pos.x + strings.rune_count(text)
}

draw_bg_rect :: proc(rect: math.Rect, color: rl.Color) {
    rl.DrawRectangle(
        ACTIVE_FONT.character_size.x * i32(rect.left),
        ACTIVE_FONT.character_size.y * i32(rect.top),
        ACTIVE_FONT.character_size.x * i32(rect.width),
        ACTIVE_FONT.character_size.y * i32(rect.height),
        color,
    )
}