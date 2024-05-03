package command

import "bred:buffer"
import "bred:portal"
import "bred:status"

import "core:log"
import rl "vendor:raylib"

EditorState :: struct {
    buffers:        [dynamic]buffer.Buffer,
    command_buffer: CommandBuffer,
    portals:        [8]portal.Portal,
    active_portal:  int,
}

create :: proc(allocator := context.allocator) -> (state: ^EditorState) {
    state = new(EditorState, allocator)

    state.buffers = make([dynamic]buffer.Buffer, allocator = allocator)

    return
}

destroy :: proc(state: ^EditorState) {
    for b in state.buffers {
        buffer.destroy(b)
    }

    delete(state.buffers)
    free(state)
}

update :: proc(state: ^EditorState) {
    inputs := tick(&state.command_buffer)

    active_buffer := state.portals[state.active_portal].contents

    for input in inputs {
        command_proc, wildcards, command_exists := get_command(input)

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
