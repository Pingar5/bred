package file_editor

import "bred:builtin/commands"
import "bred:core"

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
    commands.page_up(state, wildcards)

    ensure_cursor_visible(state, &state.portals[state.active_portal], -1)

    return true
}

page_down :: proc(state: ^core.EditorState, wildcards: []core.WildcardValue) -> bool {
    commands.page_down(state, wildcards)

    ensure_cursor_visible(state, &state.portals[state.active_portal], 1)

    return true
}
