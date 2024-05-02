package buffer

import "core:fmt"
import "core:strings"

import "bred:colors"
import "bred:font"
import "bred:math"

import rl "vendor:raylib"

@(private = "file")
render_fragment :: proc(b: Buffer, fragment: string, pos: math.Position, max_length: int, color: rl.Color) -> (consumed_length: int) {
    visible := len(fragment) < max_length ? fragment : fragment[:max_length]
    font.write(b.font, pos.y, pos.x, visible, color)
    return len(visible)
}

@(private = "file")
render_line :: proc(b: Buffer, buffer_line, screen_line: int, x_offset, max_length: int) {
    line := b.lines[buffer_line]
    remaining_length := max_length

    line_number_fragment: string
    line_number_color: rl.Color
    if buffer_line == b.cursor.line {
        line_number_fragment = fmt.tprintf("%- 3d", buffer_line + 1)
        line_number_color = colors.TEXT
    } else {
        line_number_fragment = fmt.tprintf("% 3d", abs(buffer_line - b.cursor.line))
        line_number_color = rl.GRAY
    }
    
    remaining_length -= render_fragment(b, line_number_fragment, {x_offset, screen_line}, max_length, line_number_color)
    render_fragment(b, b.text[line.start:line.end], {x_offset + 4, screen_line}, remaining_length, rl.WHITE)
}

@(private = "file")
render_cursor :: proc(b: Buffer, rect: math.Rect) {
    line := b.lines[b.cursor.line]

    column := min(b.cursor.column, line.end - line.start)
    portal_line := b.cursor.line - b.scroll
    
    if column >= rect.width || portal_line >= rect.height || portal_line < 0 do return
    
    screen_pos := math.Position{column + rect.left + 4, portal_line + rect.top}
    rl.DrawRectangle(
        b.font.character_size.x * i32(screen_pos.x),
        b.font.character_size.y * i32(screen_pos.y),
        b.font.character_size.x,
        b.font.character_size.y,
        rl.WHITE,
    )

    if b.cursor.column < get_line_length(b, b.cursor.line) {
        font.write(
            b.font,
            screen_pos.y,
            screen_pos.x,
            b.text[line.start + b.cursor.column:line.start + b.cursor.column + 1],
            rl.BLACK,
        )
    }
}

render :: proc(b: Buffer, rect: math.Rect) {
    for line_offset in 0 ..< rect.height {
        screen_line := rect.top + line_offset
        buffer_line := b.scroll + line_offset

        if buffer_line >= len(b.lines) do break

        render_line(b, buffer_line, screen_line, rect.left, rect.width)
    }

    render_cursor(b, rect)
}

@(private)
get_visible_line_count :: proc(b: Buffer) -> int {
    return int(rl.GetScreenHeight() / b.font.font.baseSize)
}
