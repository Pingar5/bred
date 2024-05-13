package buffer

import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"

import "bred:core"
import ts "bred:lib/treesitter"
import "bred:lib/treesitter/highlight"
import "bred:util/history"

@(private)
Line :: core.Line
@(private)
Cursor :: core.Cursor
@(private)
Buffer :: core.Buffer

load_file :: proc(self: ^Buffer, file_name: string, allocator := context.allocator) -> (ok: bool) {
    buffer_data := os.read_entire_file(file_name, context.allocator) or_return

    extension := file_name[strings.last_index(file_name, ".") + 1:]
    self.language_id = ts.get_language_id(extension)

    load_string(self, string(buffer_data), allocator)

    self.file_path = file_name

    return true
}

load_string :: proc(self: ^Buffer, text: string, allocator := context.allocator) {
    stripped_text, was_alloc := strings.replace_all(text, "\r", "", context.allocator)
    if was_alloc do delete(text)

    self.lines = make([dynamic]Line, 1, allocator)
    self.text = stripped_text
    self.history = history.create_history(
        core.BufferState{text = self.text, cursor_index = 0},
        destroy_buffer_state,
        allocator,
    )

    remap_lines(self)

    if self.language_id != -1 {
        self.syntax_tree = ts.get_tree(self.language_id, self.text)
        bake_highlighting(self)
    }

    return
}

save :: proc(b: ^Buffer) -> bool {
    if !b.is_dirty do return true

    if b.file_path == "" {
        log.error("Cannot save buffer, it does not have a file path\n")
        return false
    }

    ok := os.write_entire_file(b.file_path, transmute([]byte)(b.text))
    if !ok {
        log.error("Failed to write to file")
    }
    b.is_dirty = false

    return ok
}

insert_character :: proc(b: ^Buffer, r: byte, at: core.Position) {
    index := pos_to_index(b, at)

    update_text(b, fmt.aprint(b.text[:index], rune(r), b.text[index:], sep = ""))
    update_tree(b, index, 0, 1)

    bake_highlighting(b)

    if index <= b.cursor.index do move_cursor_horizontal(b, 1)
}

insert_string :: proc(b: ^Buffer, str: string, at: core.Position) {
    index := pos_to_index(b, at)

    update_text(b, fmt.aprint(b.text[:index], str, b.text[index:], sep = ""))
    update_tree(b, index, 0, len(str))

    bake_highlighting(b)

    if index <= b.cursor.index do move_cursor_horizontal(b, len(str))
}

insert_cstring :: proc(b: ^Buffer, str: cstring, at: core.Position) {
    index := pos_to_index(b, at)

    update_text(b, fmt.aprint(b.text[:index], str, b.text[index:], sep = ""))
    update_tree(b, index, 0, len(str))

    bake_highlighting(b)

    if index <= b.cursor.index do move_cursor_horizontal(b, len(str))
}

insert :: proc {
    insert_character,
    insert_string,
    insert_cstring,
}

match_indent :: proc(b: ^Buffer, src_line, dest_line: int) {
    delta := get_indent(b, src_line) - get_indent(b, dest_line)

    if delta > 0 {
        indent_str := strings.repeat(" ", delta, context.temp_allocator)
        insert_string(b, indent_str, {0, dest_line})
    } else if delta < 0 {
        // TODO: Implement this
    }
}

delete_range_position :: proc(b: ^Buffer, start, end: core.Position) {
    start_index := pos_to_index(b, start)
    end_index := pos_to_index(b, end)

    delete_range_index(b, start_index, end_index)
}

delete_range_index :: proc(b: ^Buffer, start_index, end_index: int) {
    if len(b.text) == 0 do return

    new_index := b.cursor.index
    if b.cursor.index > start_index {
        range_length := end_index - start_index
        new_index = max(start_index, new_index - range_length)
    }

    update_text(b, fmt.aprint(b.text[:start_index], b.text[end_index:], sep = ""))
    update_tree(b, start_index, end_index - start_index, 0)

    bake_highlighting(b)
    set_cursor_index(b, new_index)
}

delete_range :: proc {
    delete_range_index,
    delete_range_position,
}

get_range_position :: proc(b: ^Buffer, start, end: core.Position) -> string {
    start_index := pos_to_index(b, start)
    end_index := pos_to_index(b, end)

    return get_range_index(b, start_index, end_index)
}

get_range_index :: proc(b: ^Buffer, start, end: int) -> string {
    return b.text[start:end]
}

get_range :: proc {
    get_range_index,
    get_range_position,
}

get_line_length :: proc(b: ^Buffer, line_idx: int) -> int {
    line_bounds := b.lines[line_idx]
    return line_bounds.end - line_bounds.start
}

pos_to_index :: proc(b: ^Buffer, pos: core.Position) -> int {
    if len(b.lines) == 0 do return 0

    line_bounds := b.lines[pos.y]
    return line_bounds.start + pos.x
}

index_to_pos :: proc(b: ^Buffer, index: int, loc := #caller_location) -> core.Position {
    if len(b.lines) == 0 do return {0, 0}

    assert(index <= len(b.text) && index >= 0, "Invalid index", loc)

    for line, line_index in b.lines {
        if index <= line.end {
            assert(index >= line.start, "Wrong line chosen")

            return {index - line.start, line_index}
        }
    }

    panic("Failed to find position matching index")
}

@(private)
update_text :: proc(b: ^Buffer, new_text: string) {
    b.text = new_text
    b.is_dirty = true

    remap_lines(b)
}

@(private)
remap_lines :: proc(b: ^Buffer) {
    line_idx: uint
    current_line: Line
    for i in 0 ..< len(b.text) {
        r := b.text[i]

        if r == '\n' {
            current_line.end = i

            if line_idx < len(b.lines) {
                b.lines[line_idx] = current_line
            } else {
                append(&b.lines, current_line)
            }
            line_idx += 1

            current_line.start = i + 1
        }
    }

    current_line.end = len(b.text)
    if line_idx < len(b.lines) {
        b.lines[line_idx] = current_line
    } else {
        append(&b.lines, current_line)
    }
    line_idx += 1

    for line_idx < len(b.lines) {
        pop(&b.lines)
    }
}

get_line_str :: proc(b: ^Buffer, line_idx: int) -> string {
    line_bounds := b.lines[line_idx]
    return b.text[line_bounds.start:line_bounds.end]
}

get_indent :: proc(b: ^Buffer, line_idx: int) -> (indent: int) {
    for r in get_line_str(b, line_idx) {
        if r == ' ' do indent += 1
        else do break
    }

    return
}

start_history_state :: proc(b: ^Buffer) {
    b.next_save_state_id += 1
    b.open_history_state = {
        id = b.next_save_state_id,
        edits = make([dynamic]core.BufferEdit),
    }
}

write_to_history :: proc(b: ^Buffer) {
    log.debug(b.open_history_state, "\n")
    b.open_history_state.cursor_index = b.cursor.index
    b.open_history_state.text = b.text
    history.write(&b.history, b.open_history_state)
    b.open_history_state = {}
}

undo :: proc(b: ^Buffer) -> bool {
    state := history.undo(&b.history) or_return

    b.text = state.text
    log.debug(state.id, b.last_saved_state_id, "\n")
    b.is_dirty = state.id != b.last_saved_state_id
    remap_lines(b)

    set_cursor_index(b, state.cursor_index)

    for edit in state.edits {
        update_tree(b, edit.start, edit.new_length, edit.old_length)
    }

    bake_highlighting(b)

    return true
}

redo :: proc(b: ^Buffer) -> bool {
    state := history.redo(&b.history) or_return

    b.text = state.text
    b.is_dirty = state.id != b.last_saved_state_id
    remap_lines(b)
    
    set_cursor_index(b, state.cursor_index)

    for edit in state.edits {
        update_tree(b, edit.start, edit.old_length, edit.new_length)
    }

    bake_highlighting(b)

    return true
}

destroy_buffer_state :: proc(state: core.BufferState) {
    delete(state.text)
    delete(state.edits)
}

update_tree :: proc(b: ^Buffer, at: int, old_length: int, new_length: int) {
    if b.language_id == -1 do return

    append(&b.open_history_state.edits, core.BufferEdit{at, old_length, new_length})

    start_pos := index_to_pos(b, at)
    old_end_pos := index_to_pos(b, at + old_length)
    new_end_pos := index_to_pos(b, at + new_length)

    old_tree := b.syntax_tree
    b.syntax_tree = ts.update_tree(
        b.language_id,
        b.syntax_tree,
        at,
        at + old_length,
        at + new_length,
        {u32(start_pos.y), u32(start_pos.x)},
        {u32(old_end_pos.y), u32(old_end_pos.x)},
        {u32(new_end_pos.y), u32(new_end_pos.x)},
        b.text,
    )
    ts.delete_tree(old_tree)
}

bake_highlighting :: proc(b: ^Buffer) {
    iter, _ := ts.start_highlight_iter(b.language_id, b.text, context.temp_allocator)

    highlight_stack := make([dynamic]highlight.Highlight, context.temp_allocator)
    current_fragment := core.Fragment{}
    fragment_index := 0

    for event in highlight.iterate_highlight_iter(&iter) {
        switch event_type in event {
        case highlight.StartEvent:
            append(&highlight_stack, current_fragment.highlight)
            current_fragment.highlight = event_type.highlight

        case highlight.SourceEvent:
            current_fragment.start = event_type.start
            current_fragment.end = event_type.end

            for b.lines[current_fragment.line_index].start > current_fragment.start do current_fragment.line_index += 1

            for current_fragment.start < event_type.end {
                if event_type.end > b.lines[current_fragment.line_index].end {
                    current_fragment.end = b.lines[current_fragment.line_index].end
                }

                if fragment_index < len(b.fragments) {
                    b.fragments[fragment_index] = current_fragment
                } else {
                    append(&b.fragments, current_fragment)
                }

                fragment_index += 1
                current_fragment.start = current_fragment.end + 1
                current_fragment.end = event_type.end

                if current_fragment.end > b.lines[current_fragment.line_index].end {
                    current_fragment.line_index += 1
                }
            }
        case highlight.EndEvent:
            current_fragment.highlight = pop(&highlight_stack)

        }
    }
    highlight.destroy_highlight_iter(&iter)

    for fragment_index < len(b.fragments) {
        pop(&b.fragments)
    }
}
