package editor

import "bred:buffer"
import "bred:command"
import "bred:portal"
import "bred:status"

import "core:log"
import rl "vendor:raylib"

EditorState :: struct {
    buffers:        [dynamic]buffer.Buffer,
    status_bar:     status.StatusBar,
    command_buffer: command.CommandBuffer,
    portals:        [8]portal.Portal,
    active_portal:  int,
}

create :: proc(allocator := context.allocator) -> (state: EditorState) {
    state.buffers = make([dynamic]buffer.Buffer, allocator = allocator)
    state.status_bar.cb = &state.command_buffer
    
    return
}

destroy :: proc(state: ^EditorState) {
    for b in state.buffers {
        buffer.destroy(b)
    }

    delete(state.buffers)
}

update :: proc(state: ^EditorState) {
    inputs := command.tick(&state.command_buffer)

    active_buffer := state.portals[state.active_portal].contents.(^buffer.Buffer)
    state.status_bar.active_buffer = active_buffer

    for input in inputs {
        switch c in input {
        case byte:
            buffer.insert_character(active_buffer, c)
        case command.KeySequence:
            cmd, command_exists := command.get_command(c)
            if !command_exists do continue

            switch cmd_proc in cmd {
            case command.BufferCommand:
                cmd_proc(active_buffer)
            case command.CommandBufferCommand:
                cmd_proc(&state.command_buffer)
            case command.EditorCommand:
                cmd_proc(state)
            }
        }
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

    _, portal_has_buffer := state.portals[state.active_portal].contents.(^buffer.Buffer)
    for !state.portals[state.active_portal].active || !portal_has_buffer {
        state.active_portal += 1
        state.active_portal %= len(state.portals)

        _, portal_has_buffer = state.portals[state.active_portal].contents.(^buffer.Buffer)
    }
}

previous_portal :: proc(state: ^EditorState) {
    state.active_portal += len(state.portals) - 1
    state.active_portal %= len(state.portals)

    _, portal_has_buffer := state.portals[state.active_portal].contents.(^buffer.Buffer)
    for !state.portals[state.active_portal].active || !portal_has_buffer {
        state.active_portal += len(state.portals) - 1
        state.active_portal %= len(state.portals)

        _, portal_has_buffer = state.portals[state.active_portal].contents.(^buffer.Buffer)
    }
}
