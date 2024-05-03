package builtin_commands

import "core:log"

import "bred:command"

clear_modifiers :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    command.clear_modifiers(&state.command_buffer)
}

next_portal :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    command.next_portal(state)
}

previous_portal :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    command.previous_portal(state)
}
