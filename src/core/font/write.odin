package font

import "bred:core"

import "core:strings"
import rl "vendor:raylib"

render_fragment :: proc(
    fragment: string,
    pos: core.Position,
    max_length: int,
    color: rl.Color,
) -> (
    consumed_length: int,
) {
    if max_length <= 0 do return 0

    visible := len(fragment) < max_length ? fragment : fragment[:max_length]
    write(pos, visible, color)
    return len(visible)
}

write :: proc(pos: core.Position, text: string, color: rl.Color) -> (ending_column: int) {
    c_text := strings.clone_to_cstring(text, context.temp_allocator)
    rl.DrawTextEx(
        ACTIVE_FONT.font,
        c_text,
        {
            f32(i32(pos.x) * ACTIVE_FONT.character_size.x),
            f32(i32(pos.y) * ACTIVE_FONT.character_size.y),
        },
        ACTIVE_FONT.size,
        0,
        color,
    )

    return pos.x + strings.rune_count(text)
}

draw_bg_rect :: proc(rect: core.Rect, color: rl.Color) {
    rl.DrawRectangle(
        ACTIVE_FONT.character_size.x * i32(rect.left),
        ACTIVE_FONT.character_size.y * i32(rect.top),
        ACTIVE_FONT.character_size.x * i32(rect.width),
        ACTIVE_FONT.character_size.y * i32(rect.height),
        color,
    )
}

draw_cell_outline :: proc(pos: core.Position, color: rl.Color) {
    rl.DrawRectangleLines(
        ACTIVE_FONT.character_size.x * i32(pos.x),
        ACTIVE_FONT.character_size.y * i32(pos.y),
        ACTIVE_FONT.character_size.x,
        ACTIVE_FONT.character_size.y,
        color,
    )
}
