package user

import "core:log"

import "bred:builtin/commands"
import "bred:builtin/components"
import "bred:core"
import "bred:core/buffer"
import "bred:core/command"
import "bred:core/layout"
import "bred:core/portal"

EDITOR_COMMAND_SET: int

create_file_portal :: proc(rect: core.Rect) -> (p: core.Portal) {
    p = portal.create_file_portal(rect)
    p.command_set_id = EDITOR_COMMAND_SET
    return
}

open_default_buffers :: proc(state: ^core.EditorState) {
    for file_path, index in ([]string{"test.txt", "test2.txt"}) {
        b, buffer_ok := buffer.load_file(file_path)
        assert(buffer_ok, "Failed to load test file")
        append(&state.buffers, b)
    }
}

build_layouts :: proc(state: ^core.EditorState) {
    FILE := core.PortalDefinition(create_file_portal)
    STATUS_BAR := core.PortalDefinition(components.create_status_bar)

    single_file := layout.create_absolute_split(.Bottom, 1, FILE, STATUS_BAR)

    double_file := layout.create_absolute_split(
        .Bottom,
        1,
        layout.create_percent_split(.Right, 50, FILE, FILE),
        STATUS_BAR,
    )

    layout.register_layout(state, single_file)
    layout.register_layout(state, double_file)
}

switch_layouts :: proc(state: ^core.EditorState, wildcards: []core.WildcardValue) {
    layout_id := wildcards[0].(int)
    if layout_id >= len(state.layouts) do return

    layout.activate_layout(state, layout_id)

    switch layout_id {
    case 0:
        state.portals[0].buffer = &state.buffers[0]
    case 1:
        state.portals[0].buffer = &state.buffers[0]
        state.portals[1].buffer = &state.buffers[1]

    }
}

init :: proc(state: ^core.EditorState) {
    open_default_buffers(state)
    build_layouts(state)

    EDITOR_COMMAND_SET = command.register_command_set(state)

    command.register(state, command.GLOBAL_SET, {}, {.ESCAPE}, commands.clear_modifiers)
    command.register(state, command.GLOBAL_SET, {.Ctrl}, {.LEFT}, commands.previous_portal)
    command.register(state, command.GLOBAL_SET, {.Ctrl}, {.RIGHT}, commands.next_portal)
    command.register(state, command.GLOBAL_SET, {.Ctrl}, {.L, .Num}, switch_layouts)

    factory := command.factory_create(state, EDITOR_COMMAND_SET)
    factory->register({.Char}, commands.insert_character)
    factory->register({.LEFT}, commands.move_cursor_left)
    factory->register({.RIGHT}, commands.move_cursor_right)
    factory->register({.UP}, commands.move_cursor_up)
    factory->register({.DOWN}, commands.move_cursor_down)

    factory->register({.ENTER}, commands.insert_line)
    factory->register({.BACKSPACE}, commands.delete_behind)
    factory->register({.DELETE}, commands.delete_ahead)
    factory->register({.END}, commands.jump_to_line_end)
    factory->register({.HOME}, commands.jump_to_line_start)
    factory->register({.PAGE_UP}, commands.page_up)
    factory->register({.PAGE_DOWN}, commands.page_down)

    factory.modifiers = {.Shift}
    factory->register({.Char}, commands.insert_character)
    factory->register({.ENTER}, commands.insert_line_above)

    factory.modifiers = {.Ctrl}
    factory->register({.F, .Char}, commands.jump_to_character)
    factory->register({.H}, commands.move_cursor_left)
    factory->register({.L}, commands.move_cursor_right)
    factory->register({.K}, commands.move_cursor_up)
    factory->register({.J}, commands.move_cursor_down)
    factory->register({.Num, .H}, commands.move_cursor_left)
    factory->register({.Num, .L}, commands.move_cursor_right)
    factory->register({.Num, .K}, commands.move_cursor_up)
    factory->register({.Num, .J}, commands.move_cursor_down)
    factory->register({.ENTER}, commands.insert_line_below)
    factory->register({.D, .D}, commands.delete_lines_below)
    factory->register({.D, .Num, .D}, commands.delete_lines_below)

    factory.modifiers = {.Ctrl, .Shift}
    factory->register({.ENTER}, commands.insert_line_above)
    factory->register({.D, .Num, .D}, commands.delete_lines_above)
}
