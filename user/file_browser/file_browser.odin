package file_browser

import "base:runtime"
import "core:log"
import "core:os"
import "core:strings"
import rl "vendor:raylib"

import "bred:colors"
import "bred:core"
import "bred:core/buffer"
import "bred:core/font"

import glo "user:globals"

FileBrowserData :: struct {
    search_path:  string,
    query:        string,
    cursor_index: int,
    options:      [dynamic]string,
    allocator:    runtime.Allocator,
    scroll:       int,
    selection:    int,
    old_portal:   core.Portal,
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

    return ({
                components = {
                    self.rect.left + 2,
                    self.rect.top + 1,
                    self.rect.width - 4,
                    self.rect.height - 2,
                },
            })
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

@(private)
update_search_path :: proc(data: ^FileBrowserData) {
    if len(data.query) > 0 {
        last_char := data.query[len(data.query) - 1]
        if last_char == '/' || last_char == '\\' {
            new_search_path: string
            if strings.has_prefix(data.query, "..") {
                last_folder_start :=
                    strings.last_index(data.search_path[:len(data.search_path) - 1], "\\") + 1

                new_search_path = strings.clone(data.search_path[:last_folder_start])
            } else {
                replaced, was_alloc := strings.replace_all(
                    data.query,
                    "/",
                    "\\",
                    context.temp_allocator,
                )

                new_search_path = strings.concatenate({data.search_path, replaced}, data.allocator)
            }

            delete(data.search_path)
            data.search_path = new_search_path

            delete(data.query)
            data.query = ""
            data.cursor_index = 0
            data.selection = 0

            load_options(data)
        }
    }
}

render_file_browser :: proc(self: ^core.Portal, state: ^core.EditorState) {
    data := transmute(^FileBrowserData)self.config
    usable_rect := render_popup(self, state)

    update_search_path(data)

    query_start_column: int
    {     // Render path
        column := font.render_fragment(
            data.search_path,
            usable_rect.start,
            usable_rect.width,
            colors.TEXT,
        )
        query_start_column = column
        column = font.render_fragment(
            data.query,
            usable_rect.start + {column, 0},
            usable_rect.width - column,
            colors.TEXT,
        )
    }

    {     // Render cursor
        cursor_screen_pos := core.Position {
            usable_rect.left + query_start_column + data.cursor_index,
            usable_rect.top,
        }
        font.draw_bg_rect({vectors = {cursor_screen_pos, {1, 1}}}, rl.WHITE)
        if data.cursor_index < len(data.query) {
            font.write(
                cursor_screen_pos,
                data.query[data.cursor_index:data.cursor_index + 1],
                rl.BLACK,
            )
        }
    }

    {     // Render options

        row := 1
        for option, index in data.options {
            if !strings.contains(option, data.query) do continue

            if index < data.scroll do continue
            if row >= usable_rect.height do break

            if index == data.selection {
                font.draw_bg_rect(
                    {components = {usable_rect.left, usable_rect.top + row, usable_rect.width, 1}},
                    colors.MODIFIER_ACTIVE,
                )
            }

            font.render_fragment(
                option,
                usable_rect.start + {0, row},
                usable_rect.width,
                colors.TEXT,
            )
            row += 1
        }
    }
}

create_file_browser :: proc(state: ^core.EditorState) -> (portal: core.Portal) {
    old_portal := state.portals[state.active_portal]

    portal = {
        type           = "file_browser",
        rect           = old_portal.rect,
        render         = render_file_browser,
        destroy        = destroy_file_browser,
        command_set_id = glo.CMD_FILE_BROWSER,
    }

    config := new(FileBrowserData, context.allocator)
    portal.config = auto_cast config
    config.allocator = context.allocator
    config.old_portal = old_portal

    if old_portal.buffer != nil {
        last_slash := strings.last_index(old_portal.buffer.file_path, "\\")
        config.search_path = strings.clone(old_portal.buffer.file_path[:last_slash + 1])
    } else {
        config.search_path = strings.clone("F:\\GitHub\\editor\\")
    }

    load_options(config)

    return
}

destroy_file_browser :: proc(portal: ^core.Portal) {
    data := transmute(^FileBrowserData)portal.config

    for option in data.options {
        delete(option)
    }

    delete(data.query)
    delete(data.options)
    delete(data.search_path)
    free(data)
}
