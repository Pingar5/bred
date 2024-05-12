package file_editor

import "bred:builtin/commands"
import "bred:core"
import "bred:core/buffer"

move_cursor_up :: proc(state: ^core.EditorState, wildcards: []core.WildcardValue) -> bool {
    commands.move_cursor_up(state, wildcards) or_return

    ensure_cursor_visible(state, &state.portals[state.active_portal], -1)

    return true
}

move_cursor_down :: proc(state: ^core.EditorState, wildcards: []core.WildcardValue) -> bool {
    commands.move_cursor_down(state, wildcards) or_return

    ensure_cursor_visible(state, &state.portals[state.active_portal], 1)

    return true
}

move_cursor_left :: proc(state: ^core.EditorState, wildcards: []core.WildcardValue) -> bool {
    commands.move_cursor_left(state, wildcards) or_return

    ensure_cursor_visible(state, &state.portals[state.active_portal], 0)

    return true
}

move_cursor_right :: proc(state: ^core.EditorState, wildcards: []core.WildcardValue) -> bool {
    commands.move_cursor_right(state, wildcards) or_return

    ensure_cursor_visible(state, &state.portals[state.active_portal], 0)

    return true
}

page_up :: proc(state: ^core.EditorState, wildcards: []core.WildcardValue) -> bool {
    commands.page_up(state, wildcards) or_return

    ensure_cursor_visible(state, &state.portals[state.active_portal], -1)

    return true
}

page_down :: proc(state: ^core.EditorState, wildcards: []core.WildcardValue) -> bool {
    commands.page_down(state, wildcards) or_return

    ensure_cursor_visible(state, &state.portals[state.active_portal], 1)

    return true
}

jump_to_character :: proc(state: ^core.EditorState, wildcards: []core.WildcardValue) -> bool {
    active_buffer := buffer.get_active_buffer(state) or_return
    old_pos := active_buffer.cursor.pos

    commands.jump_to_character(state, wildcards) or_return

    jump_distance := active_buffer.cursor.pos.y - old_pos.y
    ensure_cursor_visible(
        state,
        &state.portals[state.active_portal],
        jump_distance / abs(jump_distance) if jump_distance > 0 else 0,
    )

    return true
}

jump_back_to_character :: proc(state: ^core.EditorState, wildcards: []core.WildcardValue) -> bool {
    active_buffer := buffer.get_active_buffer(state) or_return
    old_pos := active_buffer.cursor.pos

    commands.jump_to_character(state, wildcards) or_return

    jump_distance := active_buffer.cursor.pos.y - old_pos.y
    ensure_cursor_visible(
        state,
        &state.portals[state.active_portal],
        jump_distance / abs(jump_distance) if jump_distance > 0 else 0,
    )

    return true
}
