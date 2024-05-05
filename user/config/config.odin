package user

import "bred:builtin/commands"
import "bred:builtin/components"
import "bred:core"
import "bred:core/buffer"
import "bred:core/command"
import "bred:core/portal"

open_default_buffers :: proc(state: ^core.EditorState) {
    for file_path, index in ([]string{"test.txt", "test2.txt"}) {
        b, buffer_ok := buffer.load_file(file_path)
        assert(buffer_ok, "Failed to load test file")
        append(&state.buffers, b)
    }
}

build_layouts :: proc(state: ^core.EditorState) {
    FILE := core.PortalDefinition(portal.create_file_portal)
    STATUS_BAR := core.PortalDefinition(components.create_status_bar)

    single_file := portal.create_absolute_split(.Bottom, 1, FILE, STATUS_BAR)

    double_file := portal.create_absolute_split(
        .Bottom,
        1,
        portal.create_percent_split(.Right, 50, FILE, FILE),
        STATUS_BAR,
    )

    portal.register_layout(state, single_file)
    portal.register_layout(state, double_file)
}

switch_layouts :: proc(state: ^core.EditorState, wildcards: []core.WildcardValue) {
    layout_id := wildcards[0].(int)
    if layout_id >= len(state.layouts) do return

    portal.activate_layout(state, layout_id)
}

init :: proc(state: ^core.EditorState) {
    open_default_buffers(state)
    build_layouts(state)

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

    command.register({.Ctrl}, {.LEFT}, commands.previous_portal, {})
    command.register({.Ctrl}, {.RIGHT}, commands.next_portal, {})
    command.register({.Ctrl}, {.L, .Num}, switch_layouts, {})
}
