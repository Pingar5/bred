package user

import "bred:command"
import "bred:command/builtin"

init :: proc() {
    command.set_default_command(builtin.insert_character)

    // Normal
    command.register({}, {.LEFT}, builtin.move_cursor_left)
    command.register({}, {.RIGHT}, builtin.move_cursor_right)
    command.register({}, {.UP}, builtin.move_cursor_up)
    command.register({}, {.DOWN}, builtin.move_cursor_down)

    command.register({}, {.ENTER}, builtin.insert_line)
    command.register({.Shift}, {.ENTER}, builtin.insert_line_above)

    command.register({}, {.BACKSPACE}, builtin.delete_behind)
    command.register({}, {.DELETE}, builtin.delete_ahead)

    command.register({}, {.END}, builtin.jump_to_line_end)
    command.register({}, {.HOME}, builtin.jump_to_line_start)
    command.register({}, {.PAGE_UP}, builtin.page_up)
    command.register({}, {.PAGE_DOWN}, builtin.page_down)

    command.register({}, {.ESCAPE}, builtin.clear_modifiers)

    // Control
    command.register({.Ctrl}, {.F, .Char}, builtin.jump_to_character)

    command.register({.Ctrl}, {.H}, builtin.move_cursor_left)
    command.register({.Ctrl}, {.L}, builtin.move_cursor_right)
    command.register({.Ctrl}, {.K}, builtin.move_cursor_up)
    command.register({.Ctrl}, {.J}, builtin.move_cursor_down)

    command.register({.Ctrl}, {.Num, .H}, builtin.move_cursor_left)
    command.register({.Ctrl}, {.Num, .L}, builtin.move_cursor_right)
    command.register({.Ctrl}, {.Num, .K}, builtin.move_cursor_up)
    command.register({.Ctrl}, {.Num, .J}, builtin.move_cursor_down)

    command.register({.Ctrl}, {.ENTER}, builtin.insert_line_below)
    command.register({.Ctrl, .Shift}, {.ENTER}, builtin.insert_line_above)

    command.register({.Ctrl}, {.D, .D}, builtin.delete_lines_below)
    command.register({.Ctrl}, {.D, .Num, .D}, builtin.delete_lines_below)
    command.register({.Ctrl, .Shift}, {.D, .Num, .D}, builtin.delete_lines_above)

    command.register({.Ctrl}, {.LEFT}, builtin.previous_portal)
    command.register({.Ctrl}, {.RIGHT}, builtin.next_portal)

}
