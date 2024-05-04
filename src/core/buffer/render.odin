package buffer

import "bred:core"
import "bred:core/font"

import rl "vendor:raylib"

render_cursor :: proc(b: ^Buffer, rect: core.Rect) {
    line := b.lines[b.cursor.pos.y]

    column := min(b.cursor.pos.x, line.end - line.start)
    portal_line := b.cursor.pos.y - b.scroll

    if column >= rect.width || portal_line >= rect.height || portal_line < 0 do return

    screen_pos := core.Position{column + rect.left, portal_line + rect.top}

    when ODIN_DEBUG {
        index_pos := index_to_pos(b, b.cursor.index)
        index_screen_pos := index_pos + {rect.left, rect.top - b.scroll}
        rl.DrawRectangleLines(
            font.ACTIVE_FONT.character_size.x * i32(index_screen_pos.x),
            font.ACTIVE_FONT.character_size.y * i32(index_screen_pos.y),
            font.ACTIVE_FONT.character_size.x,
            font.ACTIVE_FONT.character_size.y,
            rl.RED,
        )
    }
    font.draw_bg_rect({vectors = {screen_pos, {1, 1}}}, rl.WHITE)

    if b.cursor.pos.x < get_line_length(b, b.cursor.pos.y) {
        font.write(
            screen_pos,
            b.text[line.start + b.cursor.pos.x:line.start + b.cursor.pos.x + 1],
            rl.BLACK,
        )
    }
}

render :: proc(b: ^Buffer, rect: core.Rect) {
    for line_offset in 0 ..< rect.height {
        screen_line := rect.top + line_offset
        buffer_line := b.scroll + line_offset

        if buffer_line >= len(b.lines) do break

        remaining_length := font.render_fragment(
            get_line_str(b, buffer_line),
            {rect.left, screen_line},
            rect.width,
            rl.WHITE,
        )
    }
}
