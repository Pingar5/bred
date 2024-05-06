package buffer

import "bred:core"

import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"

@(private)
Line :: core.Line
@(private)
Cursor :: core.Cursor
@(private)
Buffer :: core.Buffer

create_empty :: proc(allocator := context.allocator) -> Buffer {
    return {lines = make([dynamic]Line, 1, allocator)}
}

load_file :: proc(file_name: string, allocator := context.allocator) -> (b: Buffer, ok: bool) {
    buffer_data := os.read_entire_file(file_name, context.allocator) or_return

    b = load_string(string(buffer_data), allocator)

    b.file_path = file_name

    return b, true
}

load_string :: proc(text: string, allocator := context.allocator) -> (b: Buffer) {
    stripped_text, was_alloc := strings.replace_all(text, "\r", "", context.allocator)
    if was_alloc do delete(text)

    b = create_empty(allocator)
    b.text = stripped_text

    remap_lines(&b)

    return
}

save :: proc(b: Buffer) -> bool {
    if !b.is_dirty do return true

    if b.file_path == "" {
        log.error("Cannot save buffer, it does not have a file path\n")
        return false
    }

    ok := os.write_entire_file(b.file_path, transmute([]byte)(b.text))
    if !ok {
        log.error("Failed to write to file")
    }

    return ok
}

insert_character :: proc(b: ^Buffer, r: byte, at: core.Position) {
    index := pos_to_index(b, at)

    update_text(b, fmt.aprint(b.text[:index], rune(r), b.text[index:], sep = ""))

    if index <= b.cursor.index do move_cursor_horizontal(b, 1)
}

insert_string :: proc(b: ^Buffer, str: string, at: core.Position) {
    index := pos_to_index(b, at)

    update_text(b, fmt.aprint(b.text[:index], str, b.text[index:], sep = ""))

    if index <= b.cursor.index do move_cursor_horizontal(b, len(str))
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
    set_cursor_index(b, new_index)
}

delete_range :: proc {
    delete_range_index,
    delete_range_position,
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
    delete(b.text)

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
