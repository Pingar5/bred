package builtin_commands

import "core:log"

import "bred:core/motion"

clear_modifiers :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    motion.clear_modifiers(&state.motion_buffer)
    return true
}