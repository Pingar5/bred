package editor

import "bred:core"
import "bred:core/command"
import "bred:core/motion"
import "bred:util/pool"

@(private)
EditorState :: core.EditorState

create :: proc(allocator := context.allocator) -> (state: ^EditorState) {
    state = new(EditorState, allocator)

    pool.init(&state.buffers, allocator)

    return
}

update :: proc(state: ^EditorState) {
    motions := motion.tick(state)

    for motion in motions {
        dispatch_motion(state, motion)
    }
}

dispatch_motion :: proc(state: ^EditorState, m: core.Motion) {
    active_portal := state.portals[state.active_portal]
    listing, found := command.get_commands(state, active_portal.command_set_id, m)

    if !found {
        listing, found = command.get_commands(state, command.GLOBAL_SET, m)
    }

    if !found do return
    if listing.procedure == nil do return

    listing.procedure(state, command.parse_wildcards(m, listing.path))
    
    if listing.keep_as_last_motion do motion.store_motion(m, &state.last_motion)
}

render :: proc(state: ^EditorState) {
    for &p in state.portals {
        p->render(state)
    }
}

next_portal :: proc(state: ^EditorState) {
    state.active_portal += 1
    state.active_portal %= len(state.portals)
}

previous_portal :: proc(state: ^EditorState) {
    state.active_portal += len(state.portals) - 1
    state.active_portal %= len(state.portals)
}
