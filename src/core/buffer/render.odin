package buffer

import "core:fmt"
import "core:strings"

import "bred:colors"
import "bred:font"
import "bred:core"
import "bred:util"

import rl "vendor:raylib"

@(private = "file")
render_fragment :: proc(
    b: ^Buffer,
    fragment: string,
    pos: core.Position,
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
render_line :: proc(b: ^Buffer, screen_pos: core.Position, buffer_line, max_length: int) {
    line_bounds := b.lines[buffer_line]
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
    remaining_length -= render_fragment(
        b,
        b.text[line_bounds.start:line_bounds.end],
        screen_pos + {4, 0},
        remaining_length,
        rl.WHITE,
    )

    line_ending, _ := strings.replace(
        b.text[line_bounds.end:line_bounds.end + 1],
        "\n",
        "\\n",
        1,
        context.temp_allocator,
    )
    remaining_length -= render_fragment(
        b,
        line_ending,
        screen_pos + {4 + get_line_length(b, buffer_line), 0},
        remaining_length,
        rl.GRAY,
    )

}

@(private = "file")
render_cursor :: proc(b: ^Buffer, rect: core.Rect, is_active_buffer: bool) {
    line := b.lines[b.cursor.pos.y]

    column := min(b.cursor.pos.x, line.end - line.start)
    portal_line := b.cursor.pos.y - b.scroll

    if column >= rect.width || portal_line >= rect.height || portal_line < 0 do return

    screen_pos := core.Position{column + rect.left + 4, portal_line + rect.top}

    if is_active_buffer {
        font.draw_bg_rect({vectors = {screen_pos, {1, 1}}}, rl.WHITE)
        when ODIN_DEBUG {
            index_pos := index_to_pos(b, b.cursor.index)
            index_screen_pos := index_pos + {rect.left + 4, -b.scroll}
            rl.DrawRectangleLines(
                font.ACTIVE_FONT.character_size.x * i32(index_screen_pos.x),
                font.ACTIVE_FONT.character_size.y * i32(index_screen_pos.y),
                font.ACTIVE_FONT.character_size.x,
                font.ACTIVE_FONT.character_size.y,
                rl.RED,
            )
        }

        if b.cursor.pos.x < get_line_length(b, b.cursor.pos.y) {
            font.write(
                screen_pos,
                b.text[line.start + b.cursor.pos.x:line.start + b.cursor.pos.x + 1],
                rl.BLACK,
            )
        }
    } else {
        font.draw_cell_outline(screen_pos, rl.WHITE)
    }
}

render :: proc(b: ^Buffer, rect: core.Rect, is_active_buffer: bool) {
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

    render_cursor(b, rect, is_active_buffer)
}
