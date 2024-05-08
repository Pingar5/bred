package builtin_commands

import "bred:core/editor"

next_portal :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    editor.next_portal(state)
    return true
}

previous_portal :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    editor.previous_portal(state)
    return true
}
