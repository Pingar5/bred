package user

import "core:log"
import "core:strings"

import "bred:builtin/commands"
import "bred:builtin/components"
import "bred:core"
import "bred:core/buffer"
import "bred:core/command"
import "bred:core/layout"
import "bred:core/portal"

import "user:file_browser"
import glo "user:globals"

create_file_portal :: proc(rect: core.Rect) -> (p: core.Portal) {
    p = portal.create_file_portal(rect)
    p.command_set_id = glo.CMD_EDITOR
    return
}

open_default_buffers :: proc(state: ^core.EditorState) {
    for file_path, index in ([]string {
            strings.clone("F:\\GitHub\\editor\\.build\\test.txt"),
            strings.clone("F:\\GitHub\\editor\\.build\\test2.txt"),
        }) {
        id, ref := buffer.create(state)
        load_ok := buffer.load_file(ref, file_path)
        assert(load_ok, "Failed to load test file")
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

    glo.LAYOUT_SINGLE = layout.register_layout(state, single_file)
    glo.LAYOUT_DOUBLE = layout.register_layout(state, double_file)
}

switch_layouts :: proc(state: ^core.EditorState, wildcards: []core.WildcardValue) -> bool {
    layout_id := wildcards[0].(int)
    if layout_id >= len(state.layouts) do return false
    
    primary_buffer := state.portals[0].buffer

    layout.activate_layout(state, layout_id)

    switch layout_id {
    case 0:
        state.portals[0].buffer = primary_buffer
    case 1:
        state.portals[0].buffer = primary_buffer
        state.portals[1].buffer = {}
    }
    
    return true
}

open_file_browser :: proc(state: ^core.EditorState, wildcards: []core.WildcardValue) -> bool {
    browser := file_browser.create_file_browser(state)
    state.portals[state.active_portal] = browser
    return true
}

init :: proc(state: ^core.EditorState) {
    open_default_buffers(state)
    build_layouts(state)

    glo.CMD_EDITOR = command.register_command_set(state)
    glo.CMD_FILE_BROWSER = command.register_command_set(state)

    command.register(state, command.GLOBAL_SET, {}, {.ESCAPE}, commands.clear_modifiers)
    command.register(state, command.GLOBAL_SET, {.Ctrl}, {.LEFT}, commands.previous_portal)
    command.register(state, command.GLOBAL_SET, {.Ctrl}, {.RIGHT}, commands.next_portal)
    command.register(state, command.GLOBAL_SET, {.Ctrl}, {.O}, open_file_browser)
    command.register(state, command.GLOBAL_SET, {.Alt}, {.L, .Num}, switch_layouts)

    factory := command.factory_create(state, glo.CMD_EDITOR)
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
    factory->register({.S}, commands.save)
    factory->register({.V}, commands.paste_from_system_clipboard)
    factory->register({.C}, commands.copy_line_to_system_clipboard)
    factory->register({.Z}, commands.undo)
    factory->register({.W}, commands.close)

    factory.modifiers = {.Ctrl, .Shift}
    factory->register({.ENTER}, commands.insert_line_above)
    factory->register({.D, .Num, .D}, commands.delete_lines_above)
    factory->register({.Z}, commands.redo)

    factory = command.factory_create(state, glo.CMD_FILE_BROWSER)
    factory->register({.Char}, file_browser.insert_character)
    factory->register({.LEFT}, file_browser.move_cursor_left)
    factory->register({.RIGHT}, file_browser.move_cursor_right)
    factory->register({.UP}, file_browser.move_cursor_up)
    factory->register({.DOWN}, file_browser.move_cursor_down)
    factory->register({.BACKSPACE}, file_browser.delete_behind)
    factory->register({.DELETE}, file_browser.delete_ahead)
    factory->register({.ENTER}, file_browser.submit)

    factory.modifiers = {.Shift}
    factory->register({.Char}, file_browser.insert_character)
}
