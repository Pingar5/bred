package editor

import "core:log"
import rl "vendor:raylib"

import "bred:core"
import "bred:core/command"
import "bred:core/motion"
import "bred:core/portal"

@(private) EditorState :: core.EditorState

create :: proc(allocator := context.allocator) -> (state: ^EditorState) {
    state = new(EditorState, allocator)

    state.buffers = make([dynamic]core.Buffer, allocator = allocator)

    return
}

update :: proc(state: ^EditorState) {
    inputs := motion.tick(&state.command_buffer)

    active_buffer := state.portals[state.active_portal].contents

    for input in inputs {
        command_proc, wildcards, command_exists := command.get_command(input)

        if command_exists do command_proc(state, wildcards)
    }

    if rl.GetMouseWheelMove() != 0 {
        active_buffer.scroll += rl.GetMouseWheelMove() > 0 ? -1 : 1
        active_buffer.scroll = clamp(active_buffer.scroll, 0, len(active_buffer.lines) - 1)
    }
}

render :: proc(state: ^EditorState) {
    for &p, index in state.portals {
        if p.active {
            portal.render(&p, index == state.active_portal)
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
