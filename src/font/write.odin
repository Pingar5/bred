package font

import "core:strings"
import rl "vendor:raylib"

write :: proc(
    font: ^Font,
    #any_int line: i32,
    #any_int column: i32,
    text: string,
    color: rl.Color,
) -> (
    ending_column: int,
) {
    c_text := strings.clone_to_cstring(text, context.temp_allocator)
    rl.DrawTextEx(
        font.font,
        c_text,
        {f32(column * font.character_size.x), f32(line * font.character_size.y)},
        font.size,
        0,
        color,
    )

    return int(column) + strings.rune_count(text)
}
