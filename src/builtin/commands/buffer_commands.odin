package builtin_commands

import "core:log"
import "core:strings"
import rl "vendor:raylib"

import "bred:core"
import "bred:core/buffer"
import "bred:core/command"

@(private)
EditorState :: core.EditorState
@(private)
WildcardValue :: core.WildcardValue
@(private)
Buffer :: core.Buffer

@(private)
get_active_buffer :: proc(state: ^EditorState, loc := #caller_location) -> (^Buffer, bool) {
    active_buffer, ok := buffer.get_active_buffer(state)
    if !ok do log.error("Buffer command run without an active buffer\n", location = loc)
    return active_buffer, ok
}

insert_character :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    command.validate_wildcards(wildcards, {.Char}, "insert_character", true) or_return
    active_buffer := get_active_buffer(state) or_return
    
    buffer.start_history_state(active_buffer)

    for wildcard in wildcards {
        char, _ := wildcard.(byte)

        if char == 0 do continue

        buffer.insert_character(active_buffer, char, active_buffer.cursor.pos)
    }

    buffer.write_to_history(active_buffer)

    return true
}

insert_line :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    active_buffer := get_active_buffer(state) or_return
    
    buffer.start_history_state(active_buffer)

    buffer.insert_character(active_buffer, byte('\n'), active_buffer.cursor.pos)
    buffer.match_indent(active_buffer, active_buffer.cursor.pos.y - 1, active_buffer.cursor.pos.y)

    buffer.write_to_history(active_buffer)

    return true
}

delete_behind :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    active_buffer := get_active_buffer(state) or_return

    if active_buffer.cursor.index == 0 do return false
    
    buffer.start_history_state(active_buffer)

    buffer.delete_range(active_buffer, active_buffer.cursor.index - 1, active_buffer.cursor.index)

    buffer.write_to_history(active_buffer)

    return true
}

delete_ahead :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    active_buffer := get_active_buffer(state) or_return
    
    buffer.start_history_state(active_buffer)

    buffer.delete_range(active_buffer, active_buffer.cursor.index, active_buffer.cursor.index + 1)

    buffer.write_to_history(active_buffer)

    return true
}

jump_to_character :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    command.validate_wildcards(wildcards, {.Char}, "jump_to_character") or_return
    active_buffer := get_active_buffer(state) or_return

    index := strings.index_byte(active_buffer.text[active_buffer.cursor.index + 1:], wildcards[0].(byte))
    buffer.set_cursor_index(active_buffer, active_buffer.cursor.index + index + 1)

    return true
}

jump_back_to_character :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    command.validate_wildcards(wildcards, {.Char}, "jump_to_character") or_return
    active_buffer := get_active_buffer(state) or_return

    index := strings.last_index_byte(active_buffer.text[:active_buffer.cursor.index], wildcards[0].(byte))
    buffer.set_cursor_index(active_buffer, index)

    return true
}

move_cursor_up :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    command.validate_wildcards(wildcards, {.Num}, "move_cursor_up", allow_fewer = true) or_return
    active_buffer := get_active_buffer(state) or_return

    distance := len(wildcards) > 0 ? wildcards[0].(int) : 1
    buffer.move_cursor_vertical(active_buffer, -distance)

    return true
}

move_cursor_down :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    command.validate_wildcards(wildcards, {.Num}, "move_cursor_down", allow_fewer = true) or_return
    active_buffer := get_active_buffer(state) or_return

    distance := len(wildcards) > 0 ? wildcards[0].(int) : 1
    buffer.move_cursor_vertical(active_buffer, distance)

    return true
}

move_cursor_left :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    command.validate_wildcards(wildcards, {.Num}, "move_cursor_left", allow_fewer = true) or_return
    active_buffer := get_active_buffer(state) or_return

    distance := len(wildcards) > 0 ? wildcards[0].(int) : 1
    buffer.move_cursor_horizontal(active_buffer, -distance)

    return true
}

move_cursor_right :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    command.validate_wildcards(
        wildcards,
        {.Num},
        "move_cursor_right",
        allow_fewer = true,
    ) or_return
    active_buffer := get_active_buffer(state) or_return

    distance := len(wildcards) > 0 ? wildcards[0].(int) : 1
    buffer.move_cursor_horizontal(active_buffer, distance)

    return true
}

page_up :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    buffer.move_cursor_vertical(get_active_buffer(state) or_return, -15)

    return true
}

page_down :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    buffer.move_cursor_vertical(get_active_buffer(state) or_return, 15)

    return true
}

insert_line_above :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    active_buffer := get_active_buffer(state) or_return
    
    buffer.start_history_state(active_buffer)

    current_line_bounds := active_buffer.lines[active_buffer.cursor.pos.y - 1]
    buffer.set_cursor_index(active_buffer, current_line_bounds.end)

    buffer.insert_character(active_buffer, byte('\n'), active_buffer.cursor.pos)
    buffer.match_indent(active_buffer, active_buffer.cursor.pos.y + 1, active_buffer.cursor.pos.y)

    buffer.write_to_history(active_buffer)

    return true
}

insert_line_below :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    active_buffer := get_active_buffer(state) or_return
    
    buffer.start_history_state(active_buffer)

    current_line_bounds := active_buffer.lines[active_buffer.cursor.pos.y]
    buffer.set_cursor_index(active_buffer, current_line_bounds.end)

    buffer.insert_character(active_buffer, byte('\n'), active_buffer.cursor.pos)
    buffer.match_indent(active_buffer, active_buffer.cursor.pos.y - 1, active_buffer.cursor.pos.y)

    buffer.write_to_history(active_buffer)

    return true
}

delete_lines_above :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    command.validate_wildcards(
        wildcards,
        {.Num},
        "delete_lines_above",
        allow_fewer = true,
    ) or_return
    active_buffer := get_active_buffer(state) or_return
    
    buffer.start_history_state(active_buffer)

    line_count := len(wildcards) > 0 ? wildcards[0].(int) : 1
    end_line := active_buffer.cursor.pos.y
    buffer.delete_range_position(
        active_buffer,
        {0, max(end_line - (line_count - 1), 0)},
        {buffer.get_line_length(active_buffer, end_line) + 1, end_line},
    )

    buffer.write_to_history(active_buffer)

    return true
}

delete_lines_below :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    command.validate_wildcards(
        wildcards,
        {.Num},
        "delete_lines_below",
        allow_fewer = true,
    ) or_return
    active_buffer := get_active_buffer(state) or_return
    
    buffer.start_history_state(active_buffer)

    line_count := len(wildcards) > 0 ? wildcards[0].(int) : 1
    end_line := min(active_buffer.cursor.pos.y + (line_count - 1), len(active_buffer.lines) - 1)
    buffer.delete_range_position(
        active_buffer,
        {0, active_buffer.cursor.pos.y},
        {buffer.get_line_length(active_buffer, end_line) + 1, end_line},
    )

    buffer.write_to_history(active_buffer)

    return true
}

jump_to_line_end :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    active_buffer := get_active_buffer(state) or_return

    buffer.set_cursor_pos(
        active_buffer,
        {
            buffer.get_line_length(active_buffer, active_buffer.cursor.pos.y),
            active_buffer.cursor.pos.y,
        },
    )

    return true
}

jump_to_line_start :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    active_buffer := get_active_buffer(state) or_return

    line_indent := buffer.get_indent(active_buffer, active_buffer.cursor.pos.y)

    buffer.set_cursor_pos(
        active_buffer,
        {active_buffer.cursor.pos.x == line_indent ? 0 : line_indent, active_buffer.cursor.pos.y},
    )

    return true
}

save :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    active_buffer := get_active_buffer(state) or_return
    buffer.save(active_buffer)

    return true
}

paste_from_system_clipboard :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    active_buffer := get_active_buffer(state) or_return

    buffer.start_history_state(active_buffer)
    
    clipboard_content := rl.GetClipboardText()
    buffer.insert(active_buffer, clipboard_content, active_buffer.cursor.pos)

    buffer.write_to_history(active_buffer)

    return true
}

copy_line_to_system_clipboard :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    active_buffer := get_active_buffer(state) or_return

    line_bounds := active_buffer.lines[active_buffer.cursor.pos.y]
    str := buffer.get_range(active_buffer, line_bounds.start, line_bounds.end + 1)
    cstr, err := strings.clone_to_cstring(str, context.temp_allocator)
    
    if err != .None do return false
    
    rl.SetClipboardText(cstr)

    return true
}

undo :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    active_buffer := get_active_buffer(state) or_return
    buffer.undo(active_buffer)

    return true
}

redo :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    active_buffer := get_active_buffer(state) or_return
    buffer.redo(active_buffer)

    return true
}

close :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    active_portal := &state.portals[state.active_portal]
    buffer.close_buffer(state, active_portal.buffer)

    return true
}
