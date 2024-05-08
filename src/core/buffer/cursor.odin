package buffer

import "bred:core"
import "bred:util/history"

LOOK_AHEAD_DISTANCE :: 15

set_cursor_index :: proc(b: ^Buffer, new_index: int) {
    if len(b.text) > 0 {
        b.cursor.index = clamp(new_index, 0, len(b.text))
        b.cursor.pos = index_to_pos(b, b.cursor.index)
    } else {
        b.cursor.index = 0
        b.cursor.pos = {0, 0}
    }

    history.get_ref(&b.history).cursor_index = b.cursor.index
}

set_cursor_pos :: proc(b: ^Buffer, new_pos: core.Position) {
    b.cursor.pos.y = clamp(new_pos.y, 0, len(b.lines))
    b.cursor.pos.x = clamp(new_pos.x, 0, get_line_length(b, b.cursor.pos.y))

    b.cursor.index = pos_to_index(b, b.cursor.pos)
    history.get_ref(&b.history).cursor_index = b.cursor.index
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
}

page_down :: proc(b: ^Buffer) {
    b.cursor.pos.y += 15
    b.cursor.pos.y = min(b.cursor.pos.y, len(b.lines) - 1)

    new_line_bounds := b.lines[b.cursor.pos.y]
    b.cursor.pos.x = min(b.cursor.virtual_column, get_line_length(b, b.cursor.pos.y))
    b.cursor.index = new_line_bounds.start + b.cursor.pos.x
}
