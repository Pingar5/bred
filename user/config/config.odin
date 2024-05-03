package user

import "bred:command"
import "bred:command/builtin"

init :: proc() {
    command.set_default_command(builtin.insert_character)
    
    command.register({.Ctrl}, {.F, command.Wildcard.Char}, builtin.jump_to_character)
    // {     // Normal Mode
    //     command.register({{}, {.LEFT}}, buffer.move_cursor_left)
    //     command.register({{}, {.RIGHT}}, buffer.move_cursor_right)
    //     command.register({{}, {.UP}}, buffer.move_cursor_up)
    //     command.register({{}, {.DOWN}}, buffer.move_cursor_down)

    //     command.register({{}, {.BACKSPACE}}, buffer.backspace_rune)
    //     command.register({{}, {.DELETE}}, buffer.delete_rune)

    //     command.register({{}, {.ENTER}}, buffer.insert_line)
    //     command.register({{.Shift}, {.ENTER}}, buffer.insert_line_above)
    //     // command.register({{}, {.TAB}}, )

    //     command.register({{}, {.ESCAPE}}, command.clear_modifiers)

    //     command.register({{}, {.END}}, buffer.jump_to_line_end)
    //     command.register({{}, {.HOME}}, buffer.jump_to_line_start)
    //     command.register({{}, {.PAGE_UP}}, buffer.page_up)
    //     command.register({{}, {.PAGE_DOWN}}, buffer.page_down)
    // }

    // {     // Control Mode
    //     command.register({{.Ctrl}, {.H}}, buffer.move_cursor_left)
    //     command.register({{.Ctrl}, {.L}}, buffer.move_cursor_right)
    //     command.register({{.Ctrl}, {.K}}, buffer.move_cursor_up)
    //     command.register({{.Ctrl}, {.J}}, buffer.move_cursor_down)

    //     command.register({{.Ctrl}, {.LEFT}}, command.EditorCommand(command.previous_portal))
    //     command.register({{.Ctrl}, {.RIGHT}}, command.EditorCommand(command.next_portal))

    //     command.register({{.Ctrl}, {.D, .D}}, buffer.delete_line)

    //     command.register({{.Ctrl}, {.ENTER}}, buffer.insert_line_below)
    //     command.register({{.Ctrl, .Shift}, {.ENTER}}, buffer.insert_line_above)
    // }
}
