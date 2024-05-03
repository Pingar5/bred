package builtin_commands

import "core:log"

import "bred:buffer"
import "bred:command"

EditorState :: command.EditorState
WildcardValue :: command.WildcardValue
Buffer :: buffer.Buffer

@(private)
get_active_buffer :: proc(state: ^EditorState) -> ^Buffer {
    portal := &state.portals[state.active_portal]

    return portal.contents
}

insert_character :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    assert(len(wildcards) > 0, "insert_character requires at least one Wildcard.Char in it's path")

    active_buffer := get_active_buffer(state)

    for wildcard in wildcards {
        char, is_char := wildcard.(byte)
        assert(is_char, "insert_character command can only accept Wildchar.Char values")

        buffer.insert_character(active_buffer, char)
    }

    return true
}

insert_line :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    active_buffer := get_active_buffer(state)

    buffer.insert_line(active_buffer)

    return true
}

jump_to_character :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    assert(
        len(wildcards) == 1,
        "jump_to_character requires exactly one Wildcard.Char in it's path",
    )

    log.debugf("Jumping to %v\n", rune(wildcards[0].(byte)))


    return true
}
