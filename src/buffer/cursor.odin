package buffer

import "core:log"

import "bred:math"

LOOK_AHEAD_DISTANCE :: 15

@(private)
ensure_cursor_visible :: proc(b: ^Buffer, move_direction: int) {
    // visible_line_count := get_visible_line_count(b)
    // cursor_screen_line := b.cursor.pos.y - b.scroll

    // if move_direction != 0 {
    //     cursor_screen_line += LOOK_AHEAD_DISTANCE * move_direction
    // }

    // if cursor_screen_line > visible_line_count {
    //     b.scroll += cursor_screen_line - visible_line_count
    // } else if cursor_screen_line < 0 {
    //     b.scroll += cursor_screen_line
    //     b.scroll = max(b.scroll, 0)
    // }
}

set_cursor_index :: proc(b: ^Buffer, new_index: int) {
    b.cursor.index = clamp(new_index, 0, len(b.text) - 1)
    b.cursor.pos = index_to_pos(b, b.cursor.index)
}

set_cursor_pos :: proc(b: ^Buffer, new_pos: math.Position) {
    b.cursor.pos.y = clamp(new_pos.y, 0, len(b.lines))
    b.cursor.pos.x = clamp(new_pos.x, 0, get_line_length(b, b.cursor.pos.y))

    b.cursor.index = pos_to_index(b, b.cursor.pos)
}

move_cursor_horizontal :: proc(b: ^Buffer, distance: int) {
    set_cursor_index(b, b.cursor.index + distance)

    b.cursor.virtual_column = b.cursor.pos.x
}

move_cursor_vertical :: proc(b: ^Buffer, distance: int) {
    b.cursor.pos.y += distance
    b.cursor.pos.y = clamp(b.cursor.pos.y, 0, len(b.lines) - 1)

    b.cursor.pos.x = min(b.cursor.virtual_column, get_line_length(b, b.cursor.pos.y))
    b.cursor.index = pos_to_index(b, b.cursor.pos)
}

page_up :: proc(b: ^Buffer) {
    b.cursor.pos.y -= 15
    b.cursor.pos.y = max(b.cursor.pos.y, 0)

    new_line_bounds := b.lines[b.cursor.pos.y]
    b.cursor.pos.x = min(b.cursor.virtual_column, get_line_length(b, b.cursor.pos.y))
    b.cursor.index = new_line_bounds.start + b.cursor.pos.x

    ensure_cursor_visible(b, -1)
}

page_down :: proc(b: ^Buffer) {
    b.cursor.pos.y += 15
    b.cursor.pos.y = min(b.cursor.pos.y, len(b.lines) - 1)

    new_line_bounds := b.lines[b.cursor.pos.y]
    b.cursor.pos.x = min(b.cursor.virtual_column, get_line_length(b, b.cursor.pos.y))
    b.cursor.index = new_line_bounds.start + b.cursor.pos.x

    ensure_cursor_visible(b, 1)
}
