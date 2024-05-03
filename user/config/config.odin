package user

import "bred:builtins"
import "bred:core/command"

init :: proc() {
    command.set_default_command(builtins.insert_character)

    // Normal
    command.register({}, {.LEFT}, builtins.move_cursor_left)
    command.register({}, {.RIGHT}, builtins.move_cursor_right)
    command.register({}, {.UP}, builtins.move_cursor_up)
    command.register({}, {.DOWN}, builtins.move_cursor_down)

    command.register({}, {.ENTER}, builtins.insert_line)
    command.register({.Shift}, {.ENTER}, builtins.insert_line_above)

    command.register({}, {.BACKSPACE}, builtins.delete_behind)
    command.register({}, {.DELETE}, builtins.delete_ahead)

    command.register({}, {.END}, builtins.jump_to_line_end)
    command.register({}, {.HOME}, builtins.jump_to_line_start)
    command.register({}, {.PAGE_UP}, builtins.page_up)
    command.register({}, {.PAGE_DOWN}, builtins.page_down)

    command.register({}, {.ESCAPE}, builtins.clear_modifiers)

    // Control
    command.register({.Ctrl}, {.F, .Char}, builtins.jump_to_character)

    command.register({.Ctrl}, {.H}, builtins.move_cursor_left)
    command.register({.Ctrl}, {.L}, builtins.move_cursor_right)
    command.register({.Ctrl}, {.K}, builtins.move_cursor_up)
    command.register({.Ctrl}, {.J}, builtins.move_cursor_down)

    command.register({.Ctrl}, {.Num, .H}, builtins.move_cursor_left)
    command.register({.Ctrl}, {.Num, .L}, builtins.move_cursor_right)
    command.register({.Ctrl}, {.Num, .K}, builtins.move_cursor_up)
    command.register({.Ctrl}, {.Num, .J}, builtins.move_cursor_down)

    command.register({.Ctrl}, {.ENTER}, builtins.insert_line_below)
    command.register({.Ctrl, .Shift}, {.ENTER}, builtins.insert_line_above)

    command.register({.Ctrl}, {.D, .D}, builtins.delete_lines_below)
    command.register({.Ctrl}, {.D, .Num, .D}, builtins.delete_lines_below)
    command.register({.Ctrl, .Shift}, {.D, .Num, .D}, builtins.delete_lines_above)

    command.register({.Ctrl}, {.LEFT}, builtins.previous_portal)
    command.register({.Ctrl}, {.RIGHT}, builtins.next_portal)

}
