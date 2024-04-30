package buffer

import "core:strings"
import "core:fmt"

import rl "vendor:raylib"

@(private = "file")
render_line :: proc(b: Buffer, line_idx, at_y: int) {
    line := b.lines[line_idx]
    character_size := rl.MeasureTextEx(b.font, " ", f32(b.font.baseSize), 0)
    
    rl.DrawTextEx(b.font, fmt.ctprintf("% 3d", line_idx + 1), {0, f32(at_y)}, f32(b.font.baseSize), 0, rl.GRAY)

    c_text := strings.clone_to_cstring(b.text[line.start:line.end], context.temp_allocator)
    rl.DrawTextEx(b.font, c_text, {character_size.x * 4, f32(at_y)}, f32(b.font.baseSize), 0, rl.WHITE)
}

@(private = "file")
render_cursor :: proc(b: Buffer) {
    line := b.lines[b.cursor.line]

    character_size := rl.MeasureTextEx(b.font, " ", f32(b.font.baseSize), 0)
    at_x := int(character_size.x) * min(b.cursor.column, line.end - line.start)
    at_y := (b.cursor.line - b.scroll) * int(character_size.y)
    rl.DrawRectangle(i32(character_size.x * 4) +i32(at_x), i32(at_y), i32(character_size.x), i32(character_size.y), rl.WHITE)

    if b.cursor.column < line.end - line.start {
        c_text_at := strings.clone_to_cstring(
            b.text[line.start + b.cursor.column:line.start + b.cursor.column + 1],
            context.temp_allocator,
        )
        rl.DrawTextEx(b.font, c_text_at, {character_size.x * 4 + f32(at_x), f32(at_y)}, f32(b.font.baseSize), 0, rl.BLACK)
    }
}

render :: proc(b: Buffer) {
    visible_line_count := get_visible_line_count(b)

    for screen_line_number in 0 ..< visible_line_count {
        line_idx := b.scroll + screen_line_number
        
        if line_idx >= len(b.lines) do break

        render_line(b, line_idx, screen_line_number * int(b.font.baseSize))
    }

    render_cursor(b)
}

@private
get_visible_line_count :: proc(b: Buffer) -> int {
    return int(rl.GetScreenHeight() / b.font.baseSize)
}