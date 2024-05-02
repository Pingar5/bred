package buffer

import "core:log"

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

move_cursor_left :: proc(b: ^Buffer) {
    if b.cursor.index == 0 do return

    b.cursor.index -= 1
    b.cursor.pos.x -= 1

    if b.cursor.pos.x < 0 {
        b.cursor.pos.y -= 1

        b.cursor.pos.x = get_line_length(b, b.cursor.pos.y) - 1

        ensure_cursor_visible(b, -1)
    }

    b.cursor.virtual_column = b.cursor.pos.x
}

move_cursor_right :: proc(b: ^Buffer) {
    if b.cursor.index >= len(b.text) - 1 do return

    b.cursor.index += 1
    b.cursor.pos.x += 1

    if b.cursor.pos.x > get_line_length(b, b.cursor.pos.y) {
        b.cursor.pos.y += 1
        b.cursor.pos.x = 0

        ensure_cursor_visible(b, 1)
    }

    b.cursor.virtual_column = b.cursor.pos.x
}

move_cursor_down :: proc(b: ^Buffer) {
    b.cursor.pos.y += 1
    b.cursor.pos.y = min(b.cursor.pos.y, len(b.lines) - 1)

    new_line := b.lines[b.cursor.pos.y]
    b.cursor.pos.x = min(b.cursor.virtual_column, get_line_length(b, b.cursor.pos.y))
    b.cursor.index = new_line.start + b.cursor.pos.x

    ensure_cursor_visible(b, 1)
}

move_cursor_up :: proc(b: ^Buffer) {
    b.cursor.pos.y -= 1
    b.cursor.pos.y = max(b.cursor.pos.y, 0)

    new_line := b.lines[b.cursor.pos.y]
    b.cursor.pos.x = min(b.cursor.virtual_column, get_line_length(b, b.cursor.pos.y))
    b.cursor.index = new_line.start + b.cursor.pos.x

    ensure_cursor_visible(b, -1)
}

jump_to_line_end :: proc(b: ^Buffer) {
    b.cursor.pos.x = get_line_length(b, b.cursor.pos.y)
    b.cursor.index = b.lines[b.cursor.pos.y].start + b.cursor.pos.x
}

jump_to_line_start :: proc(b: ^Buffer) {
    b.cursor.pos.x = 0
    b.cursor.index = b.lines[b.cursor.pos.y].start
}

page_up :: proc(b: ^Buffer) {
    b.cursor.pos.y -= 15
    b.cursor.pos.y = max(b.cursor.pos.y, 0)

    new_line := b.lines[b.cursor.pos.y]
    b.cursor.pos.x = min(b.cursor.virtual_column, get_line_length(b, b.cursor.pos.y))
    b.cursor.index = new_line.start + b.cursor.pos.x

    ensure_cursor_visible(b, -1)
}

page_down :: proc(b: ^Buffer) {
    b.cursor.pos.y += 15
    b.cursor.pos.y = min(b.cursor.pos.y, len(b.lines) - 1)

    new_line := b.lines[b.cursor.pos.y]
    b.cursor.pos.x = min(b.cursor.virtual_column, get_line_length(b, b.cursor.pos.y))
    b.cursor.index = new_line.start + b.cursor.pos.x

    ensure_cursor_visible(b, 1)
}
