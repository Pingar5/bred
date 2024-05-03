package builtin_commands

import "core:log"

import "bred:core/motion"

clear_modifiers :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    motion.clear_modifiers(&state.command_buffer)
}