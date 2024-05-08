package builtin_commands

import "core:log"

import "bred:core/motion"

clear_modifiers :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    motion.clear_modifiers(&state.motion_buffer)
    return true
}