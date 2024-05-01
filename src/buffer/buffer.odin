package buffer

import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"
import "ed:font"
import rl "vendor:raylib"

Line :: struct {
    start, end: int,
}

Cursor :: struct {
    absolute:       int,
    line, column:   int,
    virtual_column: int,
}

Buffer :: struct {
    file_path: string,
    text:      string,
    cursor:    Cursor,
    lines:     [dynamic]Line,
    font:      ^font.Font,
    scroll:    int,
}

load_file :: proc(
    file_name: string,
    font: ^font.Font,
    allocator := context.allocator,
) -> (
    b: Buffer,
    ok: bool,
) {
    buffer_data := os.read_entire_file(file_name, context.allocator) or_return

    b = load_string(string(buffer_data), font, allocator)

    b.file_path = file_name

    return b, true
}

load_string :: proc(
    text: string,
    font: ^font.Font,
    allocator := context.allocator,
) -> (
    b: Buffer,
) {
    stripped_text, was_alloc := strings.replace_all(text, "\r", "", context.allocator)
    if was_alloc do delete(text)

    b.text = stripped_text
    b.lines = make([dynamic]Line, allocator)
    b.font = font

    remap_lines(&b)

    return
}

save :: proc(b: Buffer) -> bool {
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

insert_character :: proc(b: ^Buffer, r: byte) {
    update_text(b, fmt.aprint(b.text[:b.cursor.absolute], rune(r), b.text[b.cursor.absolute:], sep = ""))
    move_cursor_right(b)
}

insert_string :: proc(b: ^Buffer, str: string) {
    update_text(b, fmt.aprint(b.text[:b.cursor.absolute], str, b.text[b.cursor.absolute:], sep = ""))
    
    for _ in 0 ..< len(str) {
        move_cursor_right(b)
    }
}

insert_line :: proc(b: ^Buffer) {
    insert_character(b, u8('\n'))
    insert_string(b, strings.repeat(" ", get_indent(b, b.cursor.line - 1), context.temp_allocator))
}

insert_line_above :: proc(b: ^Buffer) {
    line_idx := b.cursor.line
    
    log.debug(b.lines[line_idx])
    
    jump_to_line_start(b)
    
    insert_string(b, strings.repeat(" ", get_indent(b, b.cursor.line), context.temp_allocator))
    insert_character(b, u8('\n'))
    
    log.debug(b.lines[line_idx])
    
    line := b.lines[line_idx]
    b.cursor.absolute = line.end
    b.cursor.column = line.end - line.start
}

insert_line_below :: proc(b: ^Buffer) {
    jump_to_line_end(b)
    insert_line(b)
}

backspace_rune :: proc(b: ^Buffer) {
    if b.cursor.absolute == 0 do return
    
    old_cursor_position := b.cursor.absolute
    if b.text[old_cursor_position - 1] == '\n' {
        b.cursor.line -= 1
    
        line := b.lines[b.cursor.line]
    
        b.cursor.column = get_line_length(b^, b.cursor.line)
        b.cursor.absolute = line.end
        b.cursor.virtual_column = b.cursor.column
    } else {
        move_cursor_left(b)
    }

    update_text(b, fmt.aprint(b.text[:old_cursor_position - 1], b.text[old_cursor_position:], sep = ""))
}

delete_rune :: proc(b: ^Buffer) {
    if b.cursor.absolute == len(b.text) do return

    update_text(b, fmt.aprint(b.text[:b.cursor.absolute], b.text[b.cursor.absolute + 1:], sep = ""))
}

delete_line :: proc(b: ^Buffer) {
    line := b.lines[b.cursor.line]
    update_text(b, fmt.aprint(b.text[:line.start], b.text[line.end + 1:], sep = ""))
}

destroy :: proc(b: Buffer) {
    delete(b.text)
    delete(b.lines)
}

get_line_length :: proc(b: Buffer, line_idx: int) -> int {
    line := b.lines[line_idx]
    return line.end - line.start
}

@private
update_text :: proc(b: ^Buffer, new_text: string) {
    delete(b.text)
    
    b.text = new_text
    
    remap_lines(b)
}

@(private)
remap_lines :: proc(b: ^Buffer) {
    line_idx: uint
    current_line: Line
    for i in 0 ..< len(b.text) {
        r := b.text[i]

        if r == '\n' || i + 1 == len(b.text) {
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

    for line_idx < len(b.lines) {
        pop(&b.lines)
    }
}

@(private)
get_line :: proc(b: ^Buffer, line_idx: int) -> string {
    line := b.lines[line_idx]
    return b.text[line.start:line.end]
}

@private
get_indent :: proc(b: ^Buffer, line_idx: int) -> (indent: int) {
    for r in get_line(b, line_idx) {
        if r == ' ' do indent += 1
        else do break
    }
    
    return
}