package buffer

import "core:fmt"
import "core:strings"

import "bred:colors"
import "bred:font"
import "bred:math"

import rl "vendor:raylib"

@(private = "file")
render_fragment :: proc(
    b: ^Buffer,
    fragment: string,
    pos: math.Position,
    max_length: int,
    color: rl.Color,
) -> (
    consumed_length: int,
) {
    visible := len(fragment) < max_length ? fragment : fragment[:max_length]
    font.write(pos, visible, color)
    return len(visible)
}

@(private = "file")
render_line :: proc(b: ^Buffer, screen_pos: math.Position, buffer_line, max_length: int) {
    line := b.lines[buffer_line]
    remaining_length := max_length

    line_number_fragment: string
    line_number_color: rl.Color
    if buffer_line == b.cursor.pos.y {
        line_number_fragment = fmt.tprintf("%- 3d", buffer_line + 1)
        line_number_color = colors.TEXT
    } else {
        line_number_fragment = fmt.tprintf("% 3d", abs(buffer_line - b.cursor.pos.y))
        line_number_color = rl.GRAY
    }

    remaining_length -= render_fragment(
        b,
        line_number_fragment,
        screen_pos,
        max_length,
        line_number_color,
    )
    render_fragment(
        b,
        b.text[line.start:line.end],
        screen_pos + {4, 0},
        remaining_length,
        rl.WHITE,
    )
}

@(private = "file")
render_cursor :: proc(b: ^Buffer, rect: math.Rect) {
    line := b.lines[b.cursor.pos.y]

    column := min(b.cursor.pos.x, line.end - line.start)
    portal_line := b.cursor.pos.y - b.scroll

    if column >= rect.width || portal_line >= rect.height || portal_line < 0 do return

    screen_pos := math.Position{column + rect.left + 4, portal_line + rect.top}
    font.draw_bg_rect({vectors = {screen_pos, {1, 1}}}, rl.WHITE)

    if b.cursor.pos.x < get_line_length(b, b.cursor.pos.y) {
        font.write(
            screen_pos,
            b.text[line.start + b.cursor.pos.x:line.start + b.cursor.pos.x + 1],
            rl.BLACK,
        )
    }
}

render :: proc(b: ^Buffer, rect: math.Rect) {
    font.draw_bg_rect(
        {components = {rect.left, rect.top, 3, rect.height}},
        colors.GUTTER_BACKGROUND,
    )

    for line_offset in 0 ..< rect.height {
        screen_line := rect.top + line_offset
        buffer_line := b.scroll + line_offset

        if buffer_line >= len(b.lines) do break

        render_line(b, {rect.left, screen_line}, buffer_line, rect.width)
    }

    render_cursor(b, rect)
}
