package builtin_commands

import "bred:buffer"
import "bred:command"

EditorState :: command.EditorState
Motion :: command.Motion
Buffer :: buffer.Buffer

@(private)
get_active_buffer :: proc(state: ^EditorState) -> ^Buffer {
    portal := &state.portals[state.active_portal]

    return portal.contents
}

insert_character :: proc(state: ^EditorState, motion: Motion) -> bool {
    active_buffer := get_active_buffer(state)

    if len(motion.keys) > 1 do return false
    
    char := motion.chars[0]
    
    if char == 0 do return false
    
    buffer.insert_character(active_buffer, char)

    return true
}

insert_line :: proc(state: ^EditorState, motion: Motion) -> bool {
    active_buffer := get_active_buffer(state)

    buffer.insert_line(active_buffer)

    return true
}
