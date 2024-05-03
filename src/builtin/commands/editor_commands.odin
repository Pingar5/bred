package builtin_commands

import "core:log"

import "bred:core/editor"

next_portal :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    editor.next_portal(state)
}

previous_portal :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    editor.previous_portal(state)
}
