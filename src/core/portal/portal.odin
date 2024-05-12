package portal

import "bred:core"

get_active_portal :: proc(state: ^core.EditorState) -> ^core.Portal {
    return &state.portals[state.active_portal]
}

is_active_portal :: proc(self: ^core.Portal, state: ^core.EditorState) -> bool {
    active_portal := &state.portals[state.active_portal]
    return self == active_portal
}
