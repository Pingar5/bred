package font

import "bred:core"

import "core:strings"
import rl "vendor:raylib"

TextAlignment :: enum {
    Left,
    Right,
    Center,
}

font_pos_to_screen :: proc(pos: core.Position) -> rl.Vector2 {
    return {
        f32(i32(pos.x) * ACTIVE_FONT.character_size.x),
        f32(i32(pos.y) * ACTIVE_FONT.character_size.y),
    }
}

font_rect_to_screen :: proc(rect: core.Rect) -> core.Rect {
    return {
        components = {
            int(ACTIVE_FONT.character_size.x) * rect.left,
            int(ACTIVE_FONT.character_size.y) * rect.top,
            int(ACTIVE_FONT.character_size.x) * rect.width,
            int(ACTIVE_FONT.character_size.y) * rect.height,
        },
    }
}

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

write :: proc(
    pos: core.Position,
    text: string,
    color: rl.Color,
    align: TextAlignment = .Left,
) -> (
    ending_column: int,
) {
    c_text := strings.clone_to_cstring(text, context.temp_allocator)
    screen_pos := font_pos_to_screen(pos)
    
    if align != .Left {
        size := rl.MeasureTextEx(ACTIVE_FONT.font, c_text, ACTIVE_FONT.size, 0)
        
        if align == .Center {
            screen_pos.x -= size.x / 2
        } else {
            screen_pos.x -= size.x
        }
    }
    
    rl.DrawTextEx(ACTIVE_FONT.font, c_text, screen_pos, ACTIVE_FONT.size, 0, color)

    return pos.x + strings.rune_count(text)
}

write_free :: proc(pos: rl.Vector2, text: string, color: rl.Color) {
    c_text := strings.clone_to_cstring(text, context.temp_allocator)
    rl.DrawTextEx(ACTIVE_FONT.font, c_text, pos, ACTIVE_FONT.size, 0, color)
}

write_free_centered :: proc(pos: rl.Vector2, text: string, color: rl.Color) {
    c_text := strings.clone_to_cstring(text, context.temp_allocator)
    size := rl.MeasureTextEx(ACTIVE_FONT.font, c_text, ACTIVE_FONT.size, 0)
    rl.DrawTextEx(ACTIVE_FONT.font, c_text, pos - {size.x / 2, 0}, ACTIVE_FONT.size, 0, color)
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

draw_outline_rect :: proc(rect: core.Rect, color: rl.Color) {
    rl.DrawRectangleLines(
        ACTIVE_FONT.character_size.x * i32(rect.left),
        ACTIVE_FONT.character_size.y * i32(rect.top),
        ACTIVE_FONT.character_size.x * i32(rect.width),
        ACTIVE_FONT.character_size.y * i32(rect.height),
        color,
    )
}
