package buffer

import "bred:colors"
import "bred:core"
import "bred:core/font"

import rl "vendor:raylib"

render_cursor :: proc(b: ^Buffer, rect: core.Rect, scroll: int) {
    line := b.lines[b.cursor.pos.y]

    column := min(b.cursor.pos.x, line.end - line.start)
    portal_line := b.cursor.pos.y - scroll

    if column >= rect.width || portal_line >= rect.height || portal_line < 0 do return

    screen_pos := core.Position{column + rect.left, portal_line + rect.top}

    when ODIN_DEBUG {
        index_pos := index_to_pos(b, b.cursor.index)
        index_screen_pos := index_pos + {rect.left, rect.top - scroll}
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

render_by_lines :: proc(b: ^Buffer, rect: core.Rect, scroll: int) {
    for line_offset in 0 ..< rect.height {
        screen_line := rect.top + line_offset
        buffer_line := scroll + line_offset

        if buffer_line >= len(b.lines) do break

        font.render_fragment(
            get_line_str(b, buffer_line),
            {rect.left, screen_line},
            rect.width,
            rl.WHITE,
        )
    }
}

render_by_fragments :: proc(b: ^Buffer, rect: core.Rect, scroll: int) {
    prev_line := -1
    column := 0
    for fragment in b.fragments {
        if fragment.line_index < scroll do continue

        if fragment.line_index != prev_line {
            column = 0
            prev_line = fragment.line_index

            if (fragment.line_index - scroll) > rect.height do break
        }

        columns_consumed := font.render_fragment(
            b.text[fragment.start:fragment.end],
            {rect.left + column, rect.top + fragment.line_index - scroll},
            rect.width - column,
            colors.THEME[fragment.highlight.theme_index].color,
        )

        column += columns_consumed
    }
}


render :: proc(b: ^Buffer, rect: core.Rect, scroll: int) {
    if len(b.fragments) == 0 {
        render_by_lines(b, rect, scroll)
    } else {
        render_by_fragments(b, rect, scroll)
    }
}
