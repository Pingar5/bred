package editor

import "core:log"
import rl "vendor:raylib"

import "bred:core"
import "bred:core/command"
import "bred:core/motion"
import "bred:core/portal"
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

    active_portal := state.portals[state.active_portal]

    for motion in motions {
        listing, found := command.get_commands(state, active_portal.command_set_id, motion)

        if !found {
            listing, found = command.get_commands(state, command.GLOBAL_SET, motion)
        }

        if !found do return

        listing.procedure(state, command.parse_wildcards(motion, listing.path))
    }
}

render :: proc(state: ^EditorState) {
    for &p, index in state.portals {
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
