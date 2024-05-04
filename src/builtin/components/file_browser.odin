package components

import "base:runtime"
import "core:log"
import "core:os"
import "core:strings"
import rl "vendor:raylib"

import "bred:colors"
import "bred:core"
import "bred:core/buffer"
import "bred:core/font"

FileBrowserData :: struct {
    search_path: string,
    options:     [dynamic]string,
    allocator:   runtime.Allocator,
    scroll:      int,
    selection:   int,
}

render_popup :: proc(self: ^core.Portal, state: ^core.EditorState) -> core.Rect {
    font.draw_bg_rect(self.rect, colors.BACKGROUND)

    cross_bar := strings.repeat("═", self.rect.width - 2, context.temp_allocator)
    font.render_fragment(
        strings.concatenate({"╔", cross_bar, "╗"}, context.temp_allocator),
        self.rect.start,
        len(cross_bar) + 8,
        colors.TEXT,
    )
    for y in 1 ..< self.rect.height - 1 {
        font.render_fragment("║", self.rect.start + {0, y}, 10, colors.TEXT)
        font.render_fragment("║", self.rect.start + {self.rect.width - 1, y}, 10, colors.TEXT)
    }
    font.render_fragment(
        strings.concatenate({"╚", cross_bar, "╝"}, context.temp_allocator),
        self.rect.start + {0, self.rect.height - 1},
        len(cross_bar) + 8,
        colors.TEXT,
    )

    return(
         {
            components =  {
                self.rect.left + 2,
                self.rect.top + 1,
                self.rect.width - 4,
                self.rect.height - 2,
            },
        } \
    )
}

load_options :: proc(data: ^FileBrowserData) {
    for option in data.options {
        delete(option)
    }
    clear(&data.options)

    folder, open_err := os.open(data.search_path)
    if open_err != 0 {
        log.errorf("Failed to open folder: %d\n", open_err)
        return
    }

    entries, read_err := os.read_dir(folder, 0, context.temp_allocator)
    if read_err != 0 {
        log.errorf("Failed to read folder contents: %d\n", read_err)
        return
    }

    for folder in entries {
        if !folder.is_dir do continue

        append(
            &data.options,
            strings.concatenate(
                {strings.clone(folder.name, context.temp_allocator), "\\"},
                data.allocator,
            ),
        )
    }

    for file in entries {
        if file.is_dir do continue

        append(&data.options, strings.clone(file.name, data.allocator))
    }

    os.close(folder)
}

create_file_browser :: proc(
    rect: core.Rect,
    query_buffer: ^core.Buffer,
    allocator := context.allocator,
) -> (
    portal: core.Portal,
) {
    render_file_browser :: proc(self: ^core.Portal, state: ^core.EditorState) {
        data := transmute(^FileBrowserData)self.config
        usable_rect := render_popup(self, state)

        if len(self.buffer.text) > 0 {
            last_char := self.buffer.text[len(self.buffer.text) - 1]
            if last_char == '/' || last_char == '\\' {
                new_search_path: string
                if strings.has_prefix(self.buffer.text, "..") {
                    last_folder_start :=
                        strings.last_index(data.search_path[:len(data.search_path) - 1], "\\") + 1

                    new_search_path = strings.clone(data.search_path[:last_folder_start])
                } else {
                    replaced, was_alloc := strings.replace_all(
                        self.buffer.text,
                        "/",
                        "\\",
                        context.temp_allocator,
                    )

                    new_search_path = strings.concatenate(
                        {data.search_path, replaced},
                        data.allocator,
                    )
                }

                delete(data.search_path)
                data.search_path = new_search_path

                buffer.delete_range(self.buffer, 0, len(self.buffer.text))

                load_options(data)
            }
        }

        column := font.render_fragment(
            data.search_path,
            usable_rect.start,
            usable_rect.width,
            colors.TEXT,
        )
        buffer_start_column := column
        for line_idx in 0 ..< len(self.buffer.lines) {
            column += font.render_fragment(
                buffer.get_line_str(self.buffer, line_idx),
                usable_rect.start + {column, 0},
                usable_rect.width - column,
                colors.TEXT,
            )

            if line_idx + 1 != len(self.buffer.lines) {
                column += font.render_fragment(
                    "\\n",
                    usable_rect.start + {column, 0},
                    usable_rect.width - column,
                    colors.ESCAPED_CHARACTER,
                )
            }
        }
        buffer.render_cursor(
            self.buffer,
             {
                vectors =  {
                    usable_rect.start + {buffer_start_column, 0},
                    usable_rect.size - {buffer_start_column, 0},
                },
            },
        )

        font.draw_bg_rect(
             {
                components =  {
                    usable_rect.left,
                    usable_rect.top + 1 + data.selection - data.scroll,
                    usable_rect.width,
                    1,
                },
            },
            colors.MODIFIER_ACTIVE,
        )

        row := 1
        for option, index in data.options {
            if !strings.contains(option, self.buffer.text) do continue
            
            if index < data.scroll do continue
            if row >= usable_rect.height do break

            font.render_fragment(
                option,
                usable_rect.start + {0, row},
                usable_rect.width,
                colors.TEXT,
            )
            row += 1
        }
    }

    portal = {
        active = true,
        rect   = rect,
        render = render_file_browser,
        buffer = query_buffer,
    }

    config := new(FileBrowserData, allocator)
    portal.config = auto_cast config
    config.allocator = allocator
    config.search_path = strings.clone("F:\\GitHub\\editor\\")
    load_options(config)

    return
}

close_file_browser :: proc(portal: ^core.Portal) {
    data := transmute(^FileBrowserData)portal.config

    for option in data.options {
        delete(option)
    }

    delete(data.options)
    delete(data.search_path)
    free(data)
}
