package buffer

import "bred:core"
import "bred:util/pool"

create :: proc(state: ^core.EditorState, data := core.Buffer{}) -> (id: core.BufferId, ref: ^Buffer) {
    id = auto_cast pool.add(&state.buffers, data)
    ref, _ = pool.get(&state.buffers, auto_cast id)
    
    return
}

get_buffer :: proc(state: ^core.EditorState, id: core.BufferId) -> (^Buffer, bool) {
    return pool.get(&state.buffers, auto_cast id)
}

get_active_buffer :: proc(state: ^core.EditorState) -> (^Buffer, bool) {
    active_portal := state.portals[state.active_portal]

    if active_portal.buffer == {} do return nil, false

    return get_buffer(state, active_portal.buffer)
}

close_buffer :: proc(state: ^core.EditorState, id: core.BufferId) -> bool {
    buffer := get_buffer(state, id) or_return
    core.destroy(buffer^)
    return pool.remove(&state.buffers, auto_cast id)
}