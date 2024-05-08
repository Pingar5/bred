package builtin_commands

import "core:log"

import "bred:core/editor"

next_portal :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    editor.next_portal(state)
    return true
}

previous_portal :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    editor.previous_portal(state)
    return true
}
