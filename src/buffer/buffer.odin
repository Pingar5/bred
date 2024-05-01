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

load_string :: proc(text: string, font: ^font.Font, allocator := context.allocator) -> (b: Buffer) {
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

insert_rune :: proc(b: ^Buffer, r: rune) {
    old_text := b.text

    b.text = fmt.aprint(b.text[:b.cursor.absolute], r, b.text[b.cursor.absolute:], sep = "")
    delete(old_text)

    remap_lines(b)
    move_cursor_right(b)
}

backspace_rune :: proc(b: ^Buffer) {
    if b.cursor.absolute == 0 do return

    old_text := b.text

    b.text = fmt.aprint(b.text[:b.cursor.absolute - 1], b.text[b.cursor.absolute:], sep = "")
    delete(old_text)

    remap_lines(b)
    move_cursor_left(b)
}

delete_rune :: proc(b: ^Buffer) {
    if b.cursor.absolute == len(b.text) do return

    old_text := b.text

    b.text = fmt.aprint(b.text[:b.cursor.absolute], b.text[b.cursor.absolute + 1:], sep = "")
    delete(old_text)

    remap_lines(b)
}

delete_line :: proc(b: ^Buffer) {
    line := b.lines[b.cursor.line]
    old_text := b.text

    b.text = fmt.aprint(b.text[:line.start], b.text[line.end + 1:], sep = "")
    delete(old_text)

    remap_lines(b)
    
}

destroy :: proc(b: Buffer) {
    delete(b.text)
    delete(b.lines)
}

get_line_length :: proc(b: Buffer, line_idx: int) -> int {
    line := b.lines[line_idx]
    return strings.rune_count(b.text[line.start:line.end])
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
