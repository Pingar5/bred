package builtin_commands

import "core:log"
import "core:strings"
import rl "vendor:raylib"

import "bred:core"
import "bred:core/buffer"

@(private)
EditorState :: core.EditorState
@(private)
WildcardValue :: core.WildcardValue
@(private)
Buffer :: core.Buffer

@(private)
get_active_buffer :: proc(state: ^EditorState, loc := #caller_location) -> ^Buffer {
    portal := &state.portals[state.active_portal]

    assert(portal.buffer != nil, "Buffer command run against non-buffer portal", loc)

    return portal.buffer
}

insert_character :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    assert(len(wildcards) > 0, "insert_character requires at least one Wildcard.Char in it's path")

    active_buffer := get_active_buffer(state)

    for wildcard in wildcards {
        char, is_char := wildcard.(byte)
        assert(is_char, "insert_character command can only accept Wildchar.Char values")

        if char == 0 do continue

        buffer.insert_character(active_buffer, char, active_buffer.cursor.pos)
    }

    buffer.write_to_history(active_buffer)
}

insert_line :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)

    buffer.insert_character(active_buffer, byte('\n'), active_buffer.cursor.pos)
    buffer.match_indent(active_buffer, active_buffer.cursor.pos.y - 1, active_buffer.cursor.pos.y)

    buffer.write_to_history(active_buffer)
}

delete_behind :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)

    if active_buffer.cursor.index == 0 do return

    buffer.delete_range(active_buffer, active_buffer.cursor.index - 1, active_buffer.cursor.index)

    buffer.write_to_history(active_buffer)
}

delete_ahead :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)

    buffer.delete_range(active_buffer, active_buffer.cursor.index, active_buffer.cursor.index + 1)

    buffer.write_to_history(active_buffer)
}

jump_to_character :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    assert(
        len(wildcards) == 1,
        "jump_to_character requires exactly one Wildcard.Char in it's path",
    )

    log.debugf("Jumping to %v\n", rune(wildcards[0].(byte)))
}

move_cursor_up :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)

    distance := 1
    if len(wildcards) > 0 {
        is_int: bool
        distance, is_int = wildcards[0].(int)
        assert(is_int, "move_cursor_up command can only accept a Wildcard.Num")
    }

    buffer.move_cursor_vertical(active_buffer, -distance)
}

move_cursor_down :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)

    distance := 1
    if len(wildcards) > 0 {
        is_int: bool
        distance, is_int = wildcards[0].(int)
        assert(is_int, "move_cursor_down command can only accept a Wildcard.Num")
    }

    buffer.move_cursor_vertical(active_buffer, distance)
}

move_cursor_left :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)

    distance := 1
    if len(wildcards) > 0 {
        is_int: bool
        distance, is_int = wildcards[0].(int)
        assert(is_int, "move_cursor_left command can only accept a Wildcard.Num")
    }

    buffer.move_cursor_horizontal(active_buffer, -distance)
}

move_cursor_right :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)

    distance := 1
    if len(wildcards) > 0 {
        is_int: bool
        distance, is_int = wildcards[0].(int)
        assert(is_int, "move_cursor_right command can only accept a Wildcard.Num")
    }

    buffer.move_cursor_horizontal(active_buffer, distance)
}

page_up :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    buffer.move_cursor_vertical(get_active_buffer(state), -15)
}

page_down :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    buffer.move_cursor_vertical(get_active_buffer(state), 15)
}

insert_line_above :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)

    current_line_bounds := active_buffer.lines[active_buffer.cursor.pos.y - 1]
    buffer.set_cursor_index(active_buffer, current_line_bounds.end)

    buffer.insert_character(active_buffer, byte('\n'), active_buffer.cursor.pos)
    buffer.match_indent(active_buffer, active_buffer.cursor.pos.y + 1, active_buffer.cursor.pos.y)

    buffer.write_to_history(active_buffer)
}

insert_line_below :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)

    current_line_bounds := active_buffer.lines[active_buffer.cursor.pos.y]
    buffer.set_cursor_index(active_buffer, current_line_bounds.end)

    buffer.insert_character(active_buffer, byte('\n'), active_buffer.cursor.pos)
    buffer.match_indent(active_buffer, active_buffer.cursor.pos.y - 1, active_buffer.cursor.pos.y)

    buffer.write_to_history(active_buffer)
}

delete_lines_above :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)

    line_count := 1
    if len(wildcards) > 0 {
        is_int: bool
        line_count, is_int = wildcards[0].(int)
        assert(is_int, "delete_lines_below command can only accept a Wildcard.Num")
    }

    end_line := active_buffer.cursor.pos.y
    buffer.delete_range_position(
        active_buffer,
        {0, max(end_line - (line_count - 1), 0)},
        {buffer.get_line_length(active_buffer, end_line) + 1, end_line},
    )

    buffer.write_to_history(active_buffer)
}

delete_lines_below :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)

    line_count := 1
    if len(wildcards) > 0 {
        is_int: bool
        line_count, is_int = wildcards[0].(int)
        assert(is_int, "delete_lines_below command can only accept a Wildcard.Num")
    }

    end_line := min(active_buffer.cursor.pos.y + (line_count - 1), len(active_buffer.lines) - 1)
    buffer.delete_range_position(
        active_buffer,
        {0, active_buffer.cursor.pos.y},
        {buffer.get_line_length(active_buffer, end_line) + 1, end_line},
    )

    buffer.write_to_history(active_buffer)
}

jump_to_line_end :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)

    buffer.set_cursor_pos(
        active_buffer,
        {
            buffer.get_line_length(active_buffer, active_buffer.cursor.pos.y),
            active_buffer.cursor.pos.y,
        },
    )
}

jump_to_line_start :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)

    line_indent := buffer.get_indent(active_buffer, active_buffer.cursor.pos.y)

    buffer.set_cursor_pos(
        active_buffer,
        {active_buffer.cursor.pos.x == line_indent ? 0 : line_indent, active_buffer.cursor.pos.y},
    )
}

save :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)
    buffer.save(active_buffer)
}

paste_from_system_clipboard :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)

    clipboard_content := rl.GetClipboardText()
    buffer.insert(active_buffer, clipboard_content, active_buffer.cursor.pos)

    buffer.write_to_history(active_buffer)
}

copy_line_to_system_clipboard :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)

    line_bounds := active_buffer.lines[active_buffer.cursor.pos.y]
    str := buffer.get_range(active_buffer, line_bounds.start, line_bounds.end + 1)
    cstr, err := strings.clone_to_cstring(str, context.temp_allocator)
    rl.SetClipboardText(cstr)
}

undo :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)
    buffer.undo(active_buffer)
}

redo :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    active_buffer := get_active_buffer(state)
    buffer.redo(active_buffer)
}