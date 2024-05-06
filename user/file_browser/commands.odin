package file_browser

import "core:fmt"
import "core:log"
import "core:strings"

import "bred:core"
import "bred:core/buffer"
import "bred:core/layout"

import glo "user:globals"

@(private = "file")
EditorState :: core.EditorState
@(private = "file")
WildcardValue :: core.WildcardValue

@(private = "file")
get_active_browser :: proc(state: ^EditorState, loc := #caller_location) -> ^FileBrowserData {
    portal := &state.portals[state.active_portal]

    assert(portal.config != nil, "Browser command run against non-browser portal", loc)

    return auto_cast portal.config
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

insert_character :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    assert(len(wildcards) > 0, "insert_character requires at least one Wildcard.Char in it's path")

    data := get_active_browser(state)

    for wildcard in wildcards {
        char, is_char := wildcard.(byte)
        assert(is_char, "insert_character command can only accept Wildchar.Char values")

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
}

delete_behind :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    data := get_active_browser(state)

    if data.cursor_index == 0 do return

    delete_range(data, data.cursor_index - 1, data.cursor_index)
}

delete_ahead :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    data := get_active_browser(state)

    delete_range(data, data.cursor_index, data.cursor_index + 1)
}

move_cursor_left :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    data := get_active_browser(state)

    distance := 1
    if len(wildcards) > 0 {
        is_int: bool
        distance, is_int = wildcards[0].(int)
        assert(is_int, "move_cursor_left command can only accept a Wildcard.Num")
    }

    move_cursor_horizontal(data, -distance)
}

move_cursor_right :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    data := get_active_browser(state)

    distance := 1
    if len(wildcards) > 0 {
        is_int: bool
        distance, is_int = wildcards[0].(int)
        assert(is_int, "move_cursor_right command can only accept a Wildcard.Num")
    }

    move_cursor_horizontal(data, distance)
}


move_cursor_up :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    data := get_active_browser(state)

    distance := 1
    if len(wildcards) > 0 {
        is_int: bool
        distance, is_int = wildcards[0].(int)
        assert(is_int, "move_cursor_up command can only accept a Wildcard.Num")
    }

    move_cursor_vertical(data, -distance)
}

move_cursor_down :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    data := get_active_browser(state)

    distance := 1
    if len(wildcards) > 0 {
        is_int: bool
        distance, is_int = wildcards[0].(int)
        assert(is_int, "move_cursor_down command can only accept a Wildcard.Num")
    }

    move_cursor_vertical(data, distance)
}

submit :: proc(state: ^EditorState, wildcards: []WildcardValue) {
    data := get_active_browser(state)

    option := data.options[data.selection]
    last_char := option[len(option) - 1]
    if last_char == '\\' {
        update_query(data, strings.clone(option))
    } else {
        full_path := strings.concatenate({data.search_path, option})

        file_buffer: ^core.Buffer
        for &existing_buffer in state.buffers {
            if existing_buffer.file_path == full_path {
                file_buffer = &existing_buffer
                break
            }
        }

        if file_buffer == nil {
            b, ok := buffer.load_file(full_path)

            if !ok {
                log.errorf("Failed to load file at path:", full_path, "\n")
                return
            }

            append(&state.buffers, b)
            file_buffer = &state.buffers[len(state.buffers) - 1]
        } else {
            delete(full_path)
        }

        data.old_portal.buffer = file_buffer

        browser_portal := state.portals[state.active_portal]
        state.portals[state.active_portal] = data.old_portal
        browser_portal->destroy()
    }
}
