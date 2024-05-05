package editor

import "core:log"
import rl "vendor:raylib"

import "bred:core"
import "bred:core/command"
import "bred:core/motion"
import "bred:core/portal"

@(private)
EditorState :: core.EditorState

create :: proc(allocator := context.allocator) -> (state: ^EditorState) {
    state = new(EditorState, allocator)

    state.buffers = make([dynamic]core.Buffer, allocator = allocator)

    return
}

update :: proc(state: ^EditorState) {
    motions := motion.tick(&state.motion_buffer)

    active_portal := state.portals[state.active_portal]

    for motion in motions {
        listings := command.get_commands(motion)

        for listing in listings {
            if listing.constraints.requires_buffer && active_portal.buffer == nil do continue

            listing.procedure(state, command.parse_wildcards(motion, listing.path))
        }
    }

    if active_portal.buffer != nil {
        if rl.GetMouseWheelMove() != 0 {
            active_portal.buffer.scroll += rl.GetMouseWheelMove() > 0 ? -1 : 1
            active_portal.buffer.scroll = clamp(
                active_portal.buffer.scroll,
                0,
                len(active_portal.buffer.lines) - 1,
            )
        }
    }
}

render :: proc(state: ^EditorState) {
    for &p, index in state.portals {
        if p.active {
            p->render(state)
        }
    }
}

next_portal :: proc(state: ^EditorState) {
    state.active_portal += 1
    state.active_portal %= len(state.portals)

    for !state.portals[state.active_portal].active {
        state.active_portal += 1
        state.active_portal %= len(state.portals)
    }
}

previous_portal :: proc(state: ^EditorState) {
    state.active_portal += len(state.portals) - 1
    state.active_portal %= len(state.portals)

    for !state.portals[state.active_portal].active {
        state.active_portal += len(state.portals) - 1
        state.active_portal %= len(state.portals)
    }
}
