package font

import "bred:math"

import "core:strings"
import rl "vendor:raylib"

write :: proc(
    font: ^Font,
    pos: math.Position,
    text: string,
    color: rl.Color,
) -> (
    ending_column: int,
) {
    c_text := strings.clone_to_cstring(text, context.temp_allocator)
    rl.DrawTextEx(
        font.font,
        c_text,
        {f32(i32(pos.x) * font.character_size.x), f32(i32(pos.y) * font.character_size.y)},
        font.size,
        0,
        color,
    )

    return pos.x + strings.rune_count(text)
}
