package buffer

import "core:fmt"
import "core:strings"
import "core:unicode/utf8"

import "bred:colors"
import "bred:font"

import rl "vendor:raylib"

@(private = "file")
render_line :: proc(b: Buffer, line_idx, at_y: int) {
    line := b.lines[line_idx]

    line_number: int
    if line_idx == b.cursor.line {
        font.write(b.font, at_y, 0, fmt.tprintf("%- 3d", line_idx + 1), colors.TEXT)
    } else {
        font.write(b.font, at_y, 0, fmt.tprintf("% 3d", abs(line_idx - b.cursor.line)), rl.GRAY)
    }

    font.write(b.font, at_y, 4, b.text[line.start:line.end], rl.WHITE)
}

@(private = "file")
render_cursor :: proc(b: Buffer) {
    line := b.lines[b.cursor.line]

    column := min(b.cursor.column, line.end - line.start)
    screen_line := b.cursor.line - b.scroll
    rl.DrawRectangle(
        b.font.character_size.x * i32(column + 4),
        b.font.character_size.y * i32(screen_line),
        b.font.character_size.x,
        b.font.character_size.y,
        rl.WHITE,
    )

    if b.cursor.column < get_line_length(b, b.cursor.line) {
        font.write(
            b.font,
            screen_line,
            4 + column,
            b.text[line.start + b.cursor.column:line.start + b.cursor.column + 1],
            rl.BLACK,
        )
    }
}

render :: proc(b: Buffer) {
    visible_line_count := get_visible_line_count(b)

    for screen_line_number in 0 ..< visible_line_count {
        line_idx := b.scroll + screen_line_number

        if line_idx >= len(b.lines) do break

        render_line(b, line_idx, screen_line_number)
    }

    render_cursor(b)
}

@(private)
get_visible_line_count :: proc(b: Buffer) -> int {
    return int(rl.GetScreenHeight() / b.font.font.baseSize)
}
