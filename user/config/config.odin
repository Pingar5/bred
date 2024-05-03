package user

import "bred:builtin/commands"
import "bred:core/command"

init :: proc() {
    command.register_default_command(commands.insert_character)

    // Normal
    command.register({}, {.LEFT}, commands.move_cursor_left)
    command.register({}, {.RIGHT}, commands.move_cursor_right)
    command.register({}, {.UP}, commands.move_cursor_up)
    command.register({}, {.DOWN}, commands.move_cursor_down)

    command.register({}, {.ENTER}, commands.insert_line)
    command.register({.Shift}, {.ENTER}, commands.insert_line_above)

    command.register({}, {.BACKSPACE}, commands.delete_behind)
    command.register({}, {.DELETE}, commands.delete_ahead)

    command.register({}, {.END}, commands.jump_to_line_end)
    command.register({}, {.HOME}, commands.jump_to_line_start)
    command.register({}, {.PAGE_UP}, commands.page_up)
    command.register({}, {.PAGE_DOWN}, commands.page_down)

    command.register({}, {.ESCAPE}, commands.clear_modifiers, {requires_buffer = false})

    // Control
    command.register({.Ctrl}, {.F, .Char}, commands.jump_to_character)

    command.register({.Ctrl}, {.H}, commands.move_cursor_left)
    command.register({.Ctrl}, {.L}, commands.move_cursor_right)
    command.register({.Ctrl}, {.K}, commands.move_cursor_up)
    command.register({.Ctrl}, {.J}, commands.move_cursor_down)

    command.register({.Ctrl}, {.Num, .H}, commands.move_cursor_left)
    command.register({.Ctrl}, {.Num, .L}, commands.move_cursor_right)
    command.register({.Ctrl}, {.Num, .K}, commands.move_cursor_up)
    command.register({.Ctrl}, {.Num, .J}, commands.move_cursor_down)

    command.register({.Ctrl}, {.ENTER}, commands.insert_line_below)
    command.register({.Ctrl, .Shift}, {.ENTER}, commands.insert_line_above)

    command.register({.Ctrl}, {.D, .D}, commands.delete_lines_below)
    command.register({.Ctrl}, {.D, .Num, .D}, commands.delete_lines_below)
    command.register({.Ctrl, .Shift}, {.D, .Num, .D}, commands.delete_lines_above)

    command.register({.Ctrl}, {.LEFT}, commands.previous_portal, {requires_buffer = false})
    command.register({.Ctrl}, {.RIGHT}, commands.next_portal, {requires_buffer = false})

}
