package main

import "ed:buffer"
import "ed:command"

register_keybinds :: proc() {
    {     // Normal Mode
        command.register({keys = {.LEFT}}, buffer.move_cursor_left)
        command.register({keys = {.RIGHT}}, buffer.move_cursor_right)
        command.register({keys = {.UP}}, buffer.move_cursor_up)
        command.register({keys = {.DOWN}}, buffer.move_cursor_down)

        command.register({keys = {.BACKSPACE}}, buffer.backspace_rune)
        command.register({keys = {.DELETE}}, buffer.delete_rune)

        command.register({keys = {.ENTER}}, buffer.insert_line)
        command.register({shift = true, keys = {.ENTER}}, buffer.insert_line_above)
        // command.register({keys = {.TAB}}, )

        command.register({keys = {.ESCAPE}}, command.clear_modifiers)

        command.register({keys = {.END}}, buffer.jump_to_line_end)
        command.register({keys = {.HOME}}, buffer.jump_to_line_start)
        command.register({keys = {.PAGE_UP}}, buffer.page_up)
        command.register({keys = {.PAGE_DOWN}}, buffer.page_down)
    }

    {     // Control Mode
        command.register({ctrl = true, keys = {.H}}, buffer.move_cursor_left)
        command.register({ctrl = true, keys = {.L}}, buffer.move_cursor_right);;
        command.register({ctrl = true, keys = {.K}}, buffer.move_cursor_up)
        command.register({ctrl = true, keys = {.J}}, buffer.move_cursor_down)

        command.register({ctrl = true, keys = {.D, .D}}, buffer.delete_line)

        command.register({ctrl = true, keys = {.ENTER}}, buffer.insert_line_below)
        command.register({ctrl = true, shift = true, keys = {.ENTER}}, buffer.insert_line_above)
    }
}
