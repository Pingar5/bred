package buffer

import "core:log"

LOOK_AHEAD_DISTANCE :: 15

@(private)
ensure_cursor_visible :: proc(b: ^Buffer, move_direction: int) {
    visible_line_count := get_visible_line_count(b^)
    cursor_screen_line := b.cursor.line - b.scroll

    if move_direction != 0 {
        cursor_screen_line += LOOK_AHEAD_DISTANCE * move_direction
    }

    if cursor_screen_line > visible_line_count {
        b.scroll += cursor_screen_line - visible_line_count
    } else if cursor_screen_line < 0 {
        b.scroll += cursor_screen_line
        b.scroll = max(b.scroll, 0)
    }
}

move_cursor_left :: proc(b: ^Buffer) {
    if b.cursor.absolute == 0 do return

    b.cursor.absolute -= 1
    b.cursor.column -= 1

    if b.cursor.column < 0 {
        b.cursor.line -= 1

        new_line := b.lines[b.cursor.line]
        b.cursor.column = new_line.end - new_line.start

        ensure_cursor_visible(b, -1)
    }

    b.cursor.virtual_column = b.cursor.column
}

move_cursor_right :: proc(b: ^Buffer) {
    if b.cursor.absolute >= len(b.text) - 1 do return

    b.cursor.absolute += 1
    b.cursor.column += 1

    line := b.lines[b.cursor.line]
    if b.cursor.column > line.end - line.start {
        b.cursor.line += 1
        b.cursor.column = 0

        ensure_cursor_visible(b, 1)
    }

    b.cursor.virtual_column = b.cursor.column
}

move_cursor_down :: proc(b: ^Buffer) {
    b.cursor.line += 1
    b.cursor.line = min(b.cursor.line, len(b.lines) - 1)

    new_line := b.lines[b.cursor.line]
    b.cursor.column = min(b.cursor.virtual_column, new_line.end - new_line.start)
    b.cursor.absolute = new_line.start + b.cursor.column

    ensure_cursor_visible(b, 1)
}

move_cursor_up :: proc(b: ^Buffer) {
    b.cursor.line -= 1
    b.cursor.line = max(b.cursor.line, 0)

    new_line := b.lines[b.cursor.line]
    b.cursor.column = min(b.cursor.virtual_column, new_line.end - new_line.start)
    b.cursor.absolute = new_line.start + b.cursor.column

    ensure_cursor_visible(b, -1)
}
