package file_browser

import "core:fmt"
import "core:log"
import "core:strings"

import "bred:core"
import "bred:core/buffer"
import "bred:core/command"
import "bred:core/layout"
import "bred:util/pool"

import glo "user:globals"

@(private = "file")
EditorState :: core.EditorState
@(private = "file")
WildcardValue :: core.WildcardValue

@(private = "file")
get_active_browser :: proc(state: ^EditorState, loc := #caller_location) -> (^FileBrowserData, bool) {
    portal := &state.portals[state.active_portal]

    return auto_cast portal.config, portal.config != nil
}

@(private = "file")
update_query :: proc(data: ^FileBrowserData, new_text: string) {
    delete(data.query)
    data.query = new_text
}

@(private = "file")
delete_range :: proc(data: ^FileBrowserData, start_index, end_index: int) {
    if len(data.query) == 0 do return

    new_index := data.cursor_index
    if data.cursor_index > start_index {
        range_length := end_index - start_index
        new_index = max(start_index, new_index - range_length)
    }

    update_query(data, fmt.aprint(data.query[:start_index], data.query[end_index:], sep = ""))
    data.cursor_index = new_index
}

@(private = "file")
move_cursor_horizontal :: proc(data: ^FileBrowserData, distance: int) {
    data.cursor_index = clamp(data.cursor_index + distance, 0, len(data.query))
}

@(private = "file")
move_cursor_vertical :: proc(data: ^FileBrowserData, distance: int) {
    direction := distance / abs(distance)
    for _ in 0 ..< abs(distance) {
        new_selection := data.selection

        for {
            new_selection += direction

            if new_selection >= len(data.options) || new_selection < 0 do return

            if strings.contains(data.options[new_selection], data.query) do break
        }

        data.selection = new_selection
    }
}

insert_character :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    command.validate_wildcards(
        wildcards,
        {.Char},
        "insert_character",
        repeat_pattern = true,
    ) or_return

    data := get_active_browser(state) or_return

    for wildcard in wildcards {
        char, _ := wildcard.(byte)

        if char == 0 do continue

        update_query(
            data,
            fmt.aprint(
                data.query[:data.cursor_index],
                rune(char),
                data.query[data.cursor_index:],
                sep = "",
            ),
        )
        data.cursor_index += 1
    }

    if !strings.contains(data.options[data.selection], data.query) do move_cursor_vertical(data, 1)
    if !strings.contains(data.options[data.selection], data.query) do move_cursor_vertical(data, -1)

    return true
}

delete_behind :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    data := get_active_browser(state) or_return

    if data.cursor_index == 0 do return false

    delete_range(data, data.cursor_index - 1, data.cursor_index)

    return true
}

delete_ahead :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    data := get_active_browser(state) or_return

    delete_range(data, data.cursor_index, data.cursor_index + 1)

    return true
}

move_cursor_left :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    command.validate_wildcards(wildcards, {.Num}, "move_cursor_left", allow_fewer = true) or_return
    data := get_active_browser(state) or_return

    distance := len(wildcards) > 0 ? wildcards[0].(int) : 1
    move_cursor_horizontal(data, -distance)

    return true
}

move_cursor_right :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    command.validate_wildcards(
        wildcards,
        {.Num},
        "move_cursor_right",
        allow_fewer = true,
    ) or_return
    data := get_active_browser(state) or_return

    distance := len(wildcards) > 0 ? wildcards[0].(int) : 1
    move_cursor_horizontal(data, distance)

    return true
}


move_cursor_up :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    command.validate_wildcards(wildcards, {.Num}, "move_cursor_up", allow_fewer = true) or_return
    data := get_active_browser(state) or_return

    distance := len(wildcards) > 0 ? wildcards[0].(int) : 1
    move_cursor_vertical(data, -distance)

    return true
}

move_cursor_down :: proc(state: ^EditorState, wildcards: []WildcardValue) -> bool {
    command.validate_wildcards(wildcards, {.Num}, "move_cursor_down", allow_fewer = true) or_return
    data := get_active_browser(state) or_return

    distance := len(wildcards) > 0 ? wildcards[0].(int) : 1
    move_cursor_vertical(data, distance)

    return true
}

submit :: proc(state: ^EditorState, _: []WildcardValue) -> bool {
    data := get_active_browser(state) or_return

    option := data.options[data.selection]
    last_char := option[len(option) - 1]
    if last_char == '\\' {
        update_query(data, strings.clone(option))
    } else {
        full_path := strings.concatenate({data.search_path, option})

        buffer_id: core.BufferId
        found_existing: bool = false
        for existing_buffer in pool.iterate(&state.buffers, auto_cast &buffer_id) {
            if existing_buffer.file_path == full_path {
                found_existing = true
                break
            }
        }

        if !found_existing {
            id, ref := buffer.create(state)
            ok := buffer.load_file(ref, full_path)

            if !ok {
                log.errorf("Failed to load file at path:", full_path, "\n")
                return false
            }

            buffer_id = id
        } else {
            delete(full_path)
        }

        data.old_portal.buffer = buffer_id

        browser_portal := state.portals[state.active_portal]
        state.portals[state.active_portal] = data.old_portal
        browser_portal->destroy()
    }

    return true
}
